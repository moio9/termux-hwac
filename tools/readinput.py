import subprocess
import re
import psutil
import time

def get_pid(process_name):
    """ Caută PID-ul unui proces folosind numele și argumentele sale. """
    for proc in psutil.process_iter(attrs=['pid', 'name', 'cmdline']):
        try:
            if proc.info['cmdline'] and process_name in " ".join(proc.info['cmdline']):
                return proc.info['pid']
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass  # Evităm erorile în cazul proceselor inaccesibile
    return None  # Dacă procesul nu a fost găsit

def clean_output(data):
    """ Elimină complet liniile care încep cu anumite caractere și șterge secvențele inutile. """
    if data.startswith(("\\x01\\x0", "\\x05\\", "\\x05", "\\x02")):
        return None  # Ignoră complet aceste linii

    cleaned = re.sub(r'\\1\\0{7}', '', data)
    return cleaned.strip() 

def process_strace_output_realtime(pid):
    """ Procesează output-ul `strace` și elimină datele inutile. """
    command = f"strace -xx -p {pid} -e trace=read -f"

    try:
        process = subprocess.Popen(
            command,
            shell=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1  # Buffer linie cu linie
        )

        # Citim linie cu linie fără să aglomerăm CPU
        for line in iter(process.stderr.readline, ''):
            if 'read(' in line:
                # Extragem conținutul citit și eliminăm caracterele inutile
                match = re.search(r'read\([^,]+, "([^"]*)"', line)
                if match:
                    string_content = match.group(1)
                    cleaned_content = clean_output(string_content)

                    if cleaned_content:  # ✅ Afișează doar dacă nu este gol și nu trebuie ignorat
                        print(f"Read input: {cleaned_content}")

        process.wait()

        if process.returncode != 0:
            print(f"Eroare la executarea comenzii:\n{process.stderr.read()}")

    except Exception as e:
        print(f"Eroare la executarea comenzii: {e}")

if __name__ == "__main__":
    process_name = "app_process"  # Schimbă cu numele procesului dorit
    pid = get_pid(process_name)

    if pid:
        print(f"PID-ul procesului '{process_name}' este: {pid}")
        process_strace_output_realtime(pid)
    else:
        print(f"Procesul '{process_name}' nu a fost găsit.")
