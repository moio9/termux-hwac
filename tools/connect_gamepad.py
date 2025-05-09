#!/usr/bin/python
import socket
import time
import struct
import subprocess
import re
import threading

SERVER_IP = "127.0.0.1"
SERVER_PORT = 7949
CLIENT_PORT = 7947
BUFFER_SIZE = 64

# Coduri de cerere
REQUEST_CODE_GET_GAMEPAD = 8
REQUEST_CODE_GET_GAMEPAD_STATE = 9
REQUEST_CODE_RELEASE_GAMEPAD = 10

# Butoane
BUTTON_A = 0
BUTTON_B = 1
BUTTON_X = 2
BUTTON_Y = 3
BUTTON_L1 = 4
BUTTON_R1 = 5
BUTTON_START = 6
BUTTON_SELECT = 7
BUTTON_L3 = 8
BUTTON_R3 = 9
BUTTON_HOME = 11

BUTTON_MAP = {
	56: BUTTON_A,
	57: BUTTON_B,
	59: BUTTON_Y,
	60: BUTTON_X,
	62: BUTTON_L1,
	63: BUTTON_R1,
	66: BUTTON_START,
	67: BUTTON_SELECT,
	68: BUTTON_HOME,
	69: BUTTON_L3,
	70: BUTTON_R3
}

BUTTON_MAP2 = {
	1: BUTTON_A,
	2: BUTTON_B,
	3: BUTTON_Y,
	4: BUTTON_X,
	5: BUTTON_L1,
	6: BUTTON_R1,
	7: BUTTON_START,
	8: BUTTON_SELECT,
	9: BUTTON_HOME,
	10: BUTTON_L3,
	11: BUTTON_R3
}

# Stare gamepad
gamepad_state = {
	"buttons": 0,
	"thumb_lx": 0,
	"thumb_ly": 0,
	"thumb_rx": 0,
	"thumb_ry": 0,
	"left_trigger": 0,
	"right_trigger": 0,
	"dpad": 255  # D-Pad neutru (255)
}

CONNECTED = False

def create_gamepad_request():
	buffer = bytearray(BUFFER_SIZE)
	buffer[0] = REQUEST_CODE_GET_GAMEPAD
	struct.pack_into('<i', buffer, 1, 1)  # gamepad_id (4 bytes)
	buffer[5] = 0x04  # FLAG_INPUT_TYPE_XINPUT
	return buffer

def create_gamepad_state():
	buffer = bytearray(BUFFER_SIZE)
	buffer[0] = REQUEST_CODE_GET_GAMEPAD_STATE
	buffer[1] = 1  # num_gamepads
	struct.pack_into('<i', buffer, 2, 1)  # gamepad_id
	
	struct.pack_into('<h', buffer, 6, gamepad_state["buttons"])
	
	# D-Pad
	buffer[8] = gamepad_state["dpad"]

	# Stick-uri și trigger-e
	struct.pack_into('<h', buffer, 9, gamepad_state["thumb_lx"])
	struct.pack_into('<h', buffer, 11, gamepad_state["thumb_ly"])
	struct.pack_into('<h', buffer, 13, gamepad_state["thumb_rx"])
	struct.pack_into('<h', buffer, 15, gamepad_state["thumb_ry"])
	
	# Trigger-e
	buffer[17] = gamepad_state["left_trigger"]
	buffer[18] = gamepad_state["right_trigger"]

	return buffer

def strace_input_reader():
	command = "strace -xx -p $(pgrep app_process) -e trace=read -f"
	process = subprocess.Popen(
		command,
		shell=True,
		stdout=subprocess.PIPE,
		stderr=subprocess.PIPE,
		text=True,
		bufsize=1
	)

	for line in process.stderr:
		match = re.search(r'read\([^,]+, "([^"]*)"', line)
		if match:
			data = match.group(1)
			process_input(data)

def process_input(data):
	raw = data.split("\\")
	
	def decode_signed_int(byte_list):
		if len(byte_list) == 1:
			return struct.unpack('b', bytes([int(byte_list[0].replace("x", "0x"), 16)]))[0]
		elif len(byte_list) == 2:
			return struct.unpack('h', bytes([int(byte_list[0].replace("x", "0x"), 16), int(byte_list[1].replace("x", "0x"), 16)]))[0]
		return 0

	if data.startswith("\\x0f\\x"):  # Axele controllerului
		buttonID = decode_signed_int(raw[2:3])
		pressed = raw[3] == "x01"
		axisX = decode_signed_int(raw[4:6])
		axisY = decode_signed_int(raw[6:8])
		axisID = decode_signed_int(raw[8:9])
		
		if buttonID in BUTTON_MAP2:
			if pressed:
				gamepad_state["buttons"] |= (1 << BUTTON_MAP2[buttonID])
			else:
				gamepad_state["buttons"] &= ~(1 << BUTTON_MAP2[buttonID])

		if axisID == 0:  # Stick stânga
			gamepad_state["thumb_lx"] = axisX
			gamepad_state["thumb_ly"] = axisY
		elif axisID == 1:  # Stick dreapta
			gamepad_state["thumb_rx"] = axisX
			gamepad_state["thumb_ry"] = axisY
		elif axisID == 2:  # Triggers
			gamepad_state["left_trigger"] = max(0, min(255, axisX))
			gamepad_state["right_trigger"] = max(0, min(255, axisY))
		elif axisID < 4:  # D-Pad
			dpad = 255  # Neutru
			if axisX == -255:
				dpad = 6  # Stânga
			elif axisX == 255:
				dpad = 2  # Dreapta
			elif axisY == -255:
				dpad = 0  # Sus
			elif axisY == 255:
				dpad = 4  # Jos

			gamepad_state["dpad"] = dpad

	elif data.startswith("\\x07\\x"):  # Butoane
		buttonID = decode_signed_int(raw[3:4])
		pressed = raw[5] == "x01"

		if buttonID in BUTTON_MAP:
			if pressed:
				gamepad_state["buttons"] |= (1 << BUTTON_MAP[buttonID])
			else:
				gamepad_state["buttons"] &= ~(1 << BUTTON_MAP[buttonID])

def send_gamepad_states(sock):
	while True:
		state_packet = create_gamepad_state()
		sock.sendto(state_packet, (SERVER_IP, SERVER_PORT))
		print("Stare trimisă:", gamepad_state)  # DEBUG
		time.sleep(0.01)  # Trimite datele la fiecare 10ms (100Hz)

def main():
	global CONNECTED
	sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
	sock.bind(("0.0.0.0", CLIENT_PORT))
	sock.settimeout(2)

	try:
		while True:
			try:
				# Trimite cererea de conectare
				sock.sendto(create_gamepad_request(), (SERVER_IP, SERVER_PORT))
				print("Sending connection request...")

				# Așteaptă răspuns
				data, addr = sock.recvfrom(BUFFER_SIZE)
				if data and data[0] == REQUEST_CODE_GET_GAMEPAD:
					print("Controller conectat cu succes!")

					if not CONNECTED:  # Start threads doar prima dată
						CONNECTED = True
						threading.Thread(target=strace_input_reader, daemon=True).start()
						threading.Thread(target=send_gamepad_states, args=(sock,), daemon=True).start()
				
				time.sleep(1)  # Așteaptă înainte de a retrimite cererea de conectare
				
			except socket.timeout:
				print("Timeout - Check if server is running")
	
	except KeyboardInterrupt:
		print("\nDeconectare...")
		sock.sendto(bytearray([REQUEST_CODE_RELEASE_GAMEPAD]), (SERVER_IP, SERVER_PORT))
		sock.close()


if __name__ == "__main__":
	main()
