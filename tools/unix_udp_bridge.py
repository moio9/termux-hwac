#!/bin/python
import subprocess
import re
import time
import socket
import threading
import psutil
import struct
from struct import pack
from threading import Thread

# Funcție pentru a obține PID-ul unui proces după nume și argumente
def get_pid(process_name):
	""" Caută PID-ul unui proces folosind numele și argumentele sale. """
	for proc in psutil.process_iter(attrs=['pid', 'name', 'cmdline']):
		try:
			if proc.info['cmdline'] and process_name in " ".join(proc.info['cmdline']):
				return proc.info['pid']
		except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
			pass  

	return None  

class StraceReader:
	def __init__(self, pid, network_manager):
		self.command = f"strace -xx -p {pid} -e trace=read -f"
		self.process = None
		self.network_manager = network_manager
		self.running = True
		self.thread = Thread(target=self.run, daemon=True)

	def start(self):
		self.thread.start()

	def stop(self):
		self.running = False
		if self.process:
			self.process.terminate()

	def run(self):
		try:
			self.process = subprocess.Popen(
				self.command,
				shell=True,
				stdout=subprocess.PIPE,
				stderr=subprocess.PIPE,
				text=True,
				bufsize=1
			)
			for line in self.process.stderr:
				match = re.search(r'read\([^,]+, "([^"]*)"', line)
				if match:
					data = match.group(1)
					self.process_input(data)
			self.process.wait()
		except Exception as e:
			print(f"Error in strace processing: {e}")

	def process_input(self, data):
		raw = data.split("\\")
		net = self.network_manager
		def decode_in_signed_int(byte_list):
			try:
				if len(byte_list) == 0:
					raise ValueError("Lista nu poate fi goală.")

				elif len(byte_list) == 1:
					byte_value = int(byte_list[0].replace("x", "0x"), 16)
					combined_value = struct.unpack('b', bytes([byte_value]))[0]
					return combined_value

				elif len(byte_list) == 2:
					int_byte1 = int(byte_list[0].replace("x", "0x"), 16)
					int_byte2 = int(byte_list[1].replace("x", "0x"), 16)

					combined_value = struct.unpack('h', bytes([int_byte1, int_byte2]))[0]
					return combined_value
	
				else:
					raise ValueError("Lista trebuie să conțină exact 1 sau 2 caractere hexazecimale.")

			except ValueError as ve:
				print(f"Eroare de valoare: {ve}")
				return 0

			except Exception as e:
				print(f"Eroare necunoscută: {e}")
				return 0

		if data.startswith("\\x0e\\x"):
			axisX = raw[4:6]
			axisY = raw[6:8]
			axisID = raw[8:9]

			StickX = decode_in_signed_int(axisX)
			StickY = decode_in_signed_int(axisY)
			StickID = decode_in_signed_int(axisID)
			
			net.update_axis(StickX, StickY, StickID) #Maybe skip decoding
			print(StickX, StickY, "ID: ", StickID)

		elif data.startswith("\\x06\\x"): #Process buttons
			BUTTON_MAP = {
			    56: "BUTTON_A",
			    57: "BUTTON_B",
			    59: "BUTTON_Y",
			    60: "BUTTON_X",
			    62: "BUTTON_L1",
			    63: "BUTTON_R1",
			    66: "BUTTON_START",
			    67: "BUTTON_SHARE",
			    68: "BUTTON_HOME"
			}
			buttonID = decode_in_signed_int(raw[3:4])
			pressed = True if raw[5] == "x01" else False
			
			if buttonID in BUTTON_MAP:
				button_name = BUTTON_MAP[buttonID]

				if pressed:
					net.press_button(button_name)
				else:
					net.release_button(button_name) 

			print("Button:", buttonID, "| Pressed:", pressed)
		

class NetworkManager:
	def __init__(self):
		self.socket = None
		self.socket_check = None
		self.ready = True
		self.running = False
		self.fail = False
		self.gamepadNameBYTE = bytearray([
			 0x08, 0x03, 0x00, 0x00, 0x00, 0x01,  
			 0x1F, 0x00, 0x00, 0x00,  # Dimensiune, rezervat
			 0x49, 0x4C, 0x41, 0x4E,  # "ILAN" (numele controller-ului)
			 0x00, 0x00, *[0x00] * 47  # Restul de bytes setați la 0
])
		self.gamepadStateBYTE = bytearray(64)  # Asigură 64 bytes
		self.gamepadStateBYTE[0:4] = [0x09, 0x01, 0x03, 0x01]
 
		self.dummy = bytearray([0x0A] + [0x00] * 63)
		self.BUTTON_A = False
		self.BUTTON_B = False
		self.BUTTON_Y = False
		self.BUTTON_X = False
		self.BUTTON_L1 = False
		self.BUTTON_R1 = False
		self.BUTTON_L2 = False
		self.BUTTON_R2 = False
		self.BUTTON_START = False
		self.BUTTON_SHARE = False
		self.BUTTON_HOME = False

	def start_server(self):
		self.running = True
		threading.Thread(target=self._run_server, daemon=True).start()
		threading.Thread(target=self._run_check_server, daemon=True).start()
		threading.Thread(target=self.continuous_update, daemon=True).start()

	def _run_server(self):
		port = 7947
		try:
			self.socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
			self.socket.bind(('', port))
			print(f"Server started on port {port}")
			while self.running:
				packet, addr = self.socket.recvfrom(64)
				first_byte = packet[0]
				print(f"Packet received from {addr}: {packet.hex()}")
				response = self.generate_response(first_byte)
				self.socket.sendto(response, addr)
		except Exception as e:
			print(f"Error in server: {e}")
		finally:
			if self.socket:
				self.socket.close()

	def _run_check_server(self):
		port = 7949
		try:
			self.socket_check = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
			self.socket_check.bind(('', port))
			print(f"Check server started on port {port}")
			while self.running:
				time.sleep(0.1)
		except Exception as e:
			print(f"Error in check server: {e}")
		finally:
			if self.socket_check:
				self.socket_check.close()

	def continuous_update(self):
		while self.running:
			#self.update_gamepad_state()
			time.sleep(0.1)

	def generate_response(self, first_byte):
		if first_byte == 9:
			self.update_gamepad_state()
			return self.gamepadStateBYTE
		elif first_byte == 8:
			return self.gamepadNameBYTE
		elif first_byte == 10:
			return self.dummy
		else:
			return self.dummy


	def update_axis(self, axisX, axisY, axisID):
		if axisID < 1:
			self.gamepadStateBYTE[9:11] = struct.pack("h", axisX)  # Stick Stânga X
			self.gamepadStateBYTE[11:13] = struct.pack("h", axisY)  # Stick Stânga Y
		elif axisID < 2:
			self.gamepadStateBYTE[13:15] = struct.pack("h", axisX)  # Stick Dreapta X
			self.gamepadStateBYTE[15:17] = struct.pack("h", axisY)  # Stick Dreapta Y

		elif axisID < 3:
			l = int(max(0, min(255, axisX)))
			r = int(max(0, min(255, axisY)))
			self.gamepadStateBYTE[17] = l
			self.gamepadStateBYTE[18] = r
			self.BUTTON_R2 = False
			self.BUTTON_L2 = False
			if r != 0:
				self.BUTTON_R2 = True
			if l != 0:
				self.BUTTON_L2 = True
		elif axisID < 4:
			dpad = 255
			if axisX == -255:
			    dpad = 6
			elif axisX == 255:
			    dpad = 2
			elif axisY == -255:
			    dpad = 0
			elif axisY == 255:
			    dpad = 4
				
			self.gamepadStateBYTE[8] = dpad

			print(f"🔄 Gamepad actualizat: Stick X Stick Y", axisX)





	def update_gamepad_state(self):
		"""
		Actualizează starea gamepad-ului pe baza butoanelor apăsate.
		"""
		buttons_1 = (1 if self.BUTTON_A else 0) | \
					((1 if self.BUTTON_B else 0) << 1) | \
					((1 if self.BUTTON_X else 0) << 2) | \
					((1 if self.BUTTON_Y else 0) << 3) | \
					((1 if self.BUTTON_L1 else 0) << 4) | \
					((1 if self.BUTTON_R1 else 0) << 5) | \
					((1 if self.BUTTON_START else 0) << 6) | \
					((1 if self.BUTTON_SHARE else 0) << 7) | \
					((1 if self.BUTTON_HOME else 0) << 8)

		self.gamepadStateBYTE[6] = buttons_1 & 0xFF  
		print(f"Updated gamepad state: {self.gamepadStateBYTE[:20].hex()}")

		self.gamepadStateBYTE[7] = (
				   ((1 if self.BUTTON_R2 else 0) << 3) |
				   ((1 if self.BUTTON_L2 else 0) << 2) 
		)


	def stop_server(self):
		self.running = False
		if self.socket:
			self.socket.close()
		if self.socket_check:
			self.socket_check.close()

	def press_button(self, button_name):
		if hasattr(self, button_name):
			setattr(self, button_name, True)
			self.update_gamepad_state()
			print(f"Button {button_name} pressed.")

	def release_button(self, button_name):
		if hasattr(self, button_name):
			setattr(self, button_name, False)
			self.update_gamepad_state()
			print(f"Button {button_name} released.")

if __name__ == "__main__":
	manager = NetworkManager()
	manager.start_server()

	# Obține PID-ul procesului dinamic
	process_name = "app_process"
	pid = get_pid(process_name)

	if pid is None:
		print(f"Procesul '{process_name}' nu a fost găsit. Ieșire...")
		exit(1)

	strace_reader = StraceReader(pid, manager)
	strace_reader.start()
	
	try:
		while True:
			time.sleep(1)
	except KeyboardInterrupt:
		strace_reader.stop()
		manager.stop_server()
		print("Stopped.")
