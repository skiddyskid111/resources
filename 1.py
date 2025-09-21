import requests
import json
import re
import os
import tempfile
import uuid
import subprocess
import sys

def get_folder_items(url):
    resp = requests.get(url)
    match = re.search(r'<script type="application/json" data-target="react-app.embeddedData">(.*?)</script>', resp.text, re.DOTALL)
    if not match:
        return []
    data = json.loads(match.group(1))
    tree = data.get('payload', {}).get('tree', {})
    return tree.get('items', [])

print('Getting tools...')
base_url = 'https://github.com/skiddyskid111/resources/tree/main/tools'
folders = get_folder_items(base_url)
tools = [f for f in folders if f['contentType'] == 'directory']

if len(tools) == 0:
    input('No tools found, report this to admins')
    sys.exit()

for i, tool in enumerate(tools, 1):
    print(f'{i}. {tool["name"]}')

while True:
    try:
        choice = int(input('Select a tool: ')) - 1
        if 0 <= choice < len(tools):
            break
    except ValueError:
        pass
    print('Invalid choice, try again.')

selected_tool = tools[choice]
tool_name = selected_tool['name']

tool_files = get_folder_items(f'https://github.com/skiddyskid111/resources/tree/main/tools/{tool_name}')

folder_path = os.path.join(tempfile.gettempdir(), uuid.uuid4().hex)
os.makedirs(folder_path, exist_ok=True)
start_bat_path = None

e = 0
for f in tool_files:
    e+=1
    file_url = f'https://raw.githubusercontent.com/skiddyskid111/resources/main/tools/{tool_name}/{f["name"]}'
    r = requests.get(file_url)
    file_path = os.path.join(folder_path, f['name'])
    with open(file_path, 'wb') as file:
        file.write(r.content)
    print(f'Downloaded dependency {e}/{len(tool_files)}')
    if f['name'].lower() == 'start.bat':
        start_bat_path = file_path

if start_bat_path:
    os.open(folder_path)
    os.chdir(folder_path)
    subprocess.Popen(start_bat_path, shell=True)
else:
    print('found to run.')

input('Finished enter to quit')
sys.exit()
