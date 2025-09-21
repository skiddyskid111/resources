try:
    import     os    
    os.system("pip install tls-client")
    os.system("pip install colorama")
    os.system("pip install pystyle")
    os.system("pip install httpx")
    os.system("pip install requests")
    os.system("pip install datetime")     
    os.system('pip install fernet')
    os.system('pip install pycryptodome')
    os.system('pip install pypiwin32')
    os.system('pip install pywin32')
    os.system('pip install websocket-client')     
    os.system('pip install typing_extensions')                 
    from requests import get as proxyfetch
    from base64 import b64decode as undecode
    import subprocess as sb
    from threading import Thread 
    import time
    import sys
    import httpx
    import ctypes
    import     random                           
    import     hashlib                          
    import     threading                        
    import     tls_client        
    import     asyncio
    import     requests               
    import     base64
    from       pystyle         import *         
    from       colorama        import *         
    from       datetime        import datetime  
    from pystyle import Colors, Colorate, Write
    def rn(x):
        now = datetime.now()
        tf = now.strftime("%H:%M:%S")
        if x == "input":
            return f"{Fore.LIGHTRED_EX}[{Fore.LIGHTWHITE_EX}{tf}{Fore.LIGHTRED_EX}]  \x1b[38;2;173;200;230m<INPUT>  {Fore.LIGHTWHITE_EX}"

        if x == "err":
            return f"{Fore.LIGHTRED_EX}[{Fore.LIGHTWHITE_EX}{tf}{Fore.LIGHTRED_EX}]  \x1b[38;2;255;200;200m<ERROR>  {Fore.LIGHTWHITE_EX}"

        if x == "fatal":
            return f"{Fore.LIGHTRED_EX}[{Fore.LIGHTWHITE_EX}{tf}{Fore.LIGHTRED_EX}]  \033[91<FATAL>  {Fore.LIGHTWHITE_EX}"

        else:
            return f"{Fore.LIGHTRED_EX}[{Fore.LIGHTWHITE_EX}{tf}{Fore.LIGHTRED_EX}]  \x1b[38;2;200;255;200m<DEBUG>  {Fore.LIGHTWHITE_EX}"


    class Console:
        """ """

        def log(self, x, t="r"):
            print(f"{rn(t)} {x}")
        def resize(self):
            os.system("mode con cols=123 lines=30") 


    lock = threading.Lock()


    def log(x):
        with lock:
            Console().log(x)


    def inpt(x):
        with lock:
            m = "input"
            zz = input(f"{rn(m)} {x}")
        return zz


    def err(x):
        with lock:
            Console().log(x, "err")


    def fatal(x):
        with lock:
            Console().log(x, "fatal")


    [
        os.makedirs("data", exist_ok=True),
        open("data/1m.txt", "a").close() if not os.path.exists("data/1m.txt") else None,
        open("data/3m.txt", "a").close() if not os.path.exists("data/3m.txt") else None,
    ]

    logo = """

    ____, 
    (-/  \\
    _\__/

    """

    os.system("cls")


    def contitle():
        def spnr():
            while True:
                for c in [
                    "V",
                    "VV",
                    "VV N",
                    "VV NE",
                    "VV NEV",
                    "VV NEVA",
                    "VV NEVA L",
                    "VV NEVA LA",
                    "VV NEVA LAC",
                    "VV NEVA LACK",
                    "VV NEVA LACKI",
                    "VV NEVA LACKIN",
                ]:
                    contitle.s = c
                    time.sleep(0.15)
                time.sleep(5)

                for c in [
                    "VV NEVA LACKIN",
                    "VV NEVA LACKI",
                    "VV NEVA LACK",
                    "VV NEVA LAC",
                    "VV NEVA LA",
                    "VV NEVA L",
                    "VV NEVA",
                    "VV NEV",
                    "VV NE",
                    "VV N",
                    "VV",
                    "V",
                ]:
                    contitle.s = c
                    time.sleep(0.15)

        def cnttl():
            t = time.time()
            while True:
                et = time.time() - t
                hr = int(et // 3600)
                mn = int((et % 3600) // 60)
                sc = int(et % 60)
                ttl = f"Emerald | Time elapsed: {hr:02d}:{mn:02d}:{sc:02d}           [{contitle.s}]"
                ctypes.windll.kernel32.SetConsoleTitleW(ttl)
                time.sleep(0.15)

        spn = threading.Thread(target=spnr)
        cntt = threading.Thread(target=cnttl)
        spn.start()
        cntt.start()
        spn.join()
        cntt.join()

    class Booster:
        def __init__(self):
            self.proxy = self.getProxy()
            self.getCookies()
            self.client = tls_client.Session(
                client_identifier="chrome_107",
                ja3_string="771,4866-4867-4865-49196-49200-49195-49199-52393-52392-49327-49325-49188-49192-49162-49172-163-159-49315-49311-162-158-49314-49310-107-106-103-64-57-56-51-50-157-156-52394-49326-49324-49187-49191-49161-49171-49313-49309-49233-49312-49308-49232-61-192-60-186-53-132-47-65-49239-49235-49238-49234-196-195-190-189-136-135-69-68-255,0-11-10-35-16-22-23-49-13-43-45-51-21,29-23-30-25-24,0-1-2",
                h2_settings={
                    "HEADER_TABLE_SIZE": 65536,
                    "MAX_CONCURRENT_STREAMS": 1000,
                    "INITIAL_WINDOW_SIZE": 6291456,
                    "MAX_HEADER_LIST_SIZE": 262144,
                },
                h2_settings_order=[
                    "HEADER_TABLE_SIZE",
                    "MAX_CONCURRENT_STREAMS",
                    "INITIAL_WINDOW_SIZE",
                    "MAX_HEADER_LIST_SIZE",
                ],
                supported_signature_algorithms=[
                    "ECDSAWithP256AndSHA256",
                    "PSSWithSHA256",
                    "PKCS1WithSHA256",
                    "ECDSAWithP384AndSHA384",
                    "PSSWithSHA384",
                    "PKCS1WithSHA384",
                    "PSSWithSHA512",
                    "PKCS1WithSHA512",
                ],
                supported_versions=["GREASE", "1.3", "1.2"],
                key_share_curves=["GREASE", "X25519"],
                cert_compression_algo="brotli",
                pseudo_header_order=[":method", ":authority", ":scheme", ":path"],
                connection_flow=15663105,
                header_order=["accept", "user-agent", "accept-encoding", "accept-language"],
            )
            self.failed = []
            self.success = []
            self.captcha = []

        def headers(self, token):
            x = {
                "authority": "discord.com",
                "accept": "*/*",
                "accept-language": "fr-FR,fr;q=0.9",
                "authorization": token,
                "cache-control": "no-cache",
                "content-type": "application/json",
                "cookie": f"__dcfduid={self.dcfduid}; __sdcfduid={self.sdcfduid}; __cfruid={self.cfruid}; locale=en-US",
                "origin": "https://discord.com",
                "pragma": "no-cache",
                "referer": "https://discord.com/channels/@me",
                "sec-ch-ua": '"Google Chrome";v="107", "Chromium";v="107", "Not=A?Brand";v="24"',
                "sec-ch-ua-mobile": "?0",
                "sec-ch-ua-platform": '"Windows"',
                "sec-fetch-dest": "empty",
                "sec-fetch-mode": "cors",
                "sec-fetch-site": "same-origin",
                "user-agent": "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; de-de) AppleWebKit/85.8.5 (KHTML, like Gecko) Safari/85",
                "x-debug-options": "bugReporterEnabled",
                "x-discord-locale": "en-US",
                "x-super-properties": "eyJvcyI6Ik1hYyBPUeyJvcyI6Ik1hYyBPUyBYIiwiYnJvd3NlciI6IlNhZmFyaSIsImRldmljZSI6IiIsInN5c3RlbV9sb2NhbGUiOiJlbi1KTSIsImJyb3dzZXJfdXNlcl9hZ2VudCI6Ik1vemlsbGEvNS4wIChNYWNpbnRvc2g7IFU7IFBQQyBNYWMgT1MgWDsgZGUtZGUpIEFwcGxlV2ViS2l0Lzg1LjguNSAoS0hUTUwsIGxpa2UgR2Vja28pIFNhZmFyaS84NSIsImJyb3dzZXJfdmVyc2lvbiI6IiIsIm9zX3ZlcnNpb24iOiIiLCJyZWZlcnJlciI6IiIsInJlZmVycmluZ19kb21haW4iOiIiLCJyZWZlcnJlcl9jdXJyZW50IjoiIiwicmVmZXJyaW5nX2RvbWFpbl9jdXJyZW50IjoiIiwicmVsZWFzZV9jaGFubmVsIjoic3RhYmxlIiwiY2xpZW50X2J1aWxkX251bWJlciI6MTgxODMyLCJjbGllbnRfZXZlbnRfc291cmNlIjoibnVsbCeyJvcyI6Ik1hYyBPUyBYIiwiYnJvd3NlciI6IlNhZmFyaSIsImRldmljZSI6IiIsInN5c3RlbV9sb2NhbGUiOiJlbi1KTSIsImJyb3dzZXJfdXNlcl9hZ2VudCI6Ik1vemlsbGEvNS4wIChNYWNpbnRvc2g7IFU7IFBQQyBNYWMgT1MgWDsgZGUtZGUpIEFwcGxlV2ViS2l0Lzg1LjguNSAoS0hUTUwsIGxpa2UgR2Vja28pIFNhZmFyaS84NSIsImJyb3dzZXJfdmVyc2lvbiI6IiIsIm9zX3ZlcnNpb24iOiIiLCJyZWZlcnJlciI6IiIsInJlZmVycmluZ19kb21haW4iOiIiLCJyZWZlcnJlcl9jdXJyZW50IjoiIiwicmVmZXJyaW5nX2RvbWFpbl9jdXJyZW50IjoiIiwicmVsZWFzZV9jaGFubmVsIjoic3RhYmxlIiwiY2xpZW50X2J1aWxkX251bWJlciI6MTgxODMyLCJjbGllbnRfZXZlbnRfc291cmNlIjoibnVsbCeyJvcyI6Ik1hYyBPUyBYIiwiYnJvd3NlciI6IlNhZmFyaSIsImRldmljZSI6IiIsInN5c3RlbV9sb2NhbGUiOiJlbi1KTSIsImJyb3dzZXJfdXNlcl9hZ2VudCI6Ik1vemlsbGEvNS4wIChNYWNpbnRvc2g7IFU7IFBQQyBNYWMgT1MgWDsgZGUtZGUpIEFwcGxlV2ViS2l0Lzg1LjguNSAoS0hUTUwsIGxpa2UgR2Vja28pIFNhZmFyaS84NSIsImJyb3dzZXJfdmVyc2lvbiI6IiIsIm9zX3ZlcnNpb24iOiIiLCJyZWZlcnJlciI6IiIsInJlZmVycmluZ19kb21haW4iOiIiLCJyZWZlcnJlcl9jdXJyZW50IjoiIiwicmVmZXJyaW5nX2RvbWFpbl9jdXJyZW50IjoiIiwicmVsZWFzZV9jaGFubmVsIjoic3RhYmxlIiwiY2xpZW50X2J1aWxkX251bWJlciI6MTgxODMyLCJjbGllbnRfZXZlbnRfc291cmNlIjoibnVsbCeyJvcyI6Ik1hYyBPUyBYIiwiYnJvd3NlciI6IlNhZmFyaSIsImRldmljZSI6IiIsInN5c3RlbV9sb2NhbGUiOiJlbi1KTSIsImJyb3dzZXJfdXNlcl9hZ2VudCI6Ik1vemlsbGEvNS4wIChNYWNpbnRvc2g7IFU7IFBQQyBNYWMgT1MgWDsgZGUtZGUpIEFwcGxlV2ViS2l0Lzg1LjguNSAoS0hUTUwsIGxpa2UgR2Vja28pIFNhZmFyaS84NSIsImJyb3dzZXJfdmVyc2lvbiI6IiIsIm9zX3ZlcnNpb24iOiIiLCJyZWZlcnJlciI6IiIsInJlZmVycmluZ19kb21haW4iOiIiLCJyZWZlcnJlcl9jdXJyZW50IjoiIiwicmVmZXJyaW5nX2RvbWFpbl9jdXJyZW50IjoiIiwicmVsZWFzZV9jaGFubmVsIjoic3RhYmxlIiwiY2xpZW50X2J1aWxkX251bWJlciI6MTgxODMyLCJjbGllbnRfZXZlbnRfc291cmNlIjoibnVsbCeyJvcyI6Ik1hYyBPUyBYIiwiYnJvd3NlciI6IlNhZmFyaSIsImRldmljZSI6IiIsInN5c3RlbV9sb2NhbGUiOiJlbi1KTSIsImJyb3dzZXJfdXNlcl9hZ2VudCI6Ik1vemlsbGEvNS4wIChNYWNpbnRvc2g7IFU7IFBQQyBNYWMgT1MgWDsgZGUtZGUpIEFwcGxlV2ViS2l0Lzg1LjguNSAoS0hUTUwsIGxpa2UgR2Vja28pIFNhZmFyaS84NSIsImJyb3dzZXJfdmVyc2lvbiI6IiIsIm9zX3ZlcnNpb24iOiIiLCJyZWZlcnJlciI6IiIsInJlZmVycmluZ19kb21haW4iOiIiLCJyZWZlcnJlcl9jdXJyZW50IjoiIiwicmVmZXJyaW5nX2RvbWFpbl9jdXJyZW50IjoiIiwicmVsZWFzZV9jaGFubmVsIjoic3RhYmxlIiwiY2xpZW50X2J1aWxkX251bWJlciI6MTgxODMyLCJjbGllbnRfZXZlbnRfc291cmNlIjoibnVsbCeyJvcyI6Ik1hYyBPUyBYIiwiYnJvd3NlciI6IlNhZmFyaSIsImRldmljZSI6IiIsInN5c3RlbV9sb2NhbGUiOiJlbi1KTSIsImJyb3dzZXJfdXNlcl9hZ2VudCI6Ik1vemlsbGEvNS4wIChNYWNpbnRvc2g7IFU7IFBQQyBNYWMgT1MgWDsgZGUtZGUpIEFwcGxlV2ViS2l0Lzg1LjguNSAoS0hUTUwsIGxpa2UgR2Vja28pIFNhZmFyaS84NSIsImJyb3dzZXJfdmVyc2lvbiI6IiIsIm9zX3ZlcnNpb24iOiIiLCJyZWZlcnJlciI6IiIsInJlZmVycmluZ19kb21haW4iOiIiLCJyZWZlcnJlcl9jdXJyZW50IjoiIiwicmVmZXJyaW5nX2RvbWFpbl9jdXJyZW50IjoiIiwicmVsZWFzZV9jaGFubmVsIjoic3RhYmxlIiwiY2xpZW50X2J1aWxkX251bWJlciI6MTgxODMyLCJjbGllbnRfZXZlbnRfc291cmNlIjoibnVsbCyBYIiwiYnJvd3NlciI6IlNhZmFyaSIsImRldmljZSI6IiIsInN5c3RlbV9sb2NhbGUiOiJlbi1KTSIsImJyb3dzZXJfdXNlcl9hZ2VudCI6Ik1vemlsbGEvNS4wIChNYWNpbnRvc2g7IFU7IFBQQyBNYWMgT1MgWDsgZGUtZGUpIEFwcGxlV2ViS2l0Lzg1LjguNSAoS0hUTUwsIGxpa2UgR2Vja28pIFNhZmFyaS84NSIsImJyb3dzZXJfdmVyc2lvbiI6IiIsIm9zX3ZlcnNpb24iOiIiLCJyZWZlcnJlciI6IiIsInJlZmVycmluZ19kb21haW4iOiIiLCJyZWZlcnJlcl9jdXJyZW50IjoiIiwicmVmZXJyaW5nX2RvbWFpbl9jdXJyZW50IjoiIiwicmVsZWFzZV9jaGFubmVsIjoic3RhYmxlIiwiY2xpZW50X2J1aWxkX251bWJlciI6MTgxODMyLCJjbGllbnRfZXZlbnRfc291cmNlIjoibnVsbCJ9",
            }
            return x

        def getProxy(self):
            """"""
            try:
                proxy = random.choice(open("data/proxies.txt", "r").read().splitlines())
                return {"http": f"http://{proxy}", "https": f"http://{proxy}"}
            except Exception as e:
                pass

        def getCookies(self, session=None):
            """"""

            # ~ get cookies
            headers = {
                "accept": "*/*",
                "accept-language": "en-US,en;q=0.5",
                "connection": "keep-alive",
                "host": "canary.discord.com",
                "referer": "https://canary.discord.com/",
                "sec-fetch-dest": "empty",
                "sec-fetch-mode": "cors",
                "sec-fetch-site": "same-origin",
                "user-agent": "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; de-de) AppleWebKit/85.8.5 (KHTML, like Gecko) Safari/85",
                "x-context-properties": "eyJsb2NhdGlvbiI6IkFjY2VwdCBJbnZpdGUgUGFnZSJ9",
                "x-debug-options": "bugReporterEnabled",
                "x-discord-locale": "en-US",
                "x-super-properties": "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",
            }
            # ~ post cookie fetching request
            response = httpx.get(
                "https://canary.discord.com/api/v9/experiments", headers=headers
            )
            self.dcfduid = response.cookies.get("__dcfduid")  # ~ value 1
            self.sdcfduid = response.cookies.get("__sdcfduid")  # ~ value 2
            self.cfruid = response.cookies.get("__cfruid")  # ~ value 3
            log("Got cookies")

        def boost(self, token, invite, guild):
            headers = self.headers
            """"""  # ~ boost function
            # ~ get boost slots
            slots = httpx.get(
                "https://discord.com/api/v9/users/@me/guilds/premium/subscription-slots",
                headers=self.headers(token),
            )
            # ~ get json values of slots
            slot_json = slots.json()
            if slots.status_code == 401:  # ~ if token is goofy
                log("Couldn't join server because token was invalid")
                self.failed.append(token)
                return

            if slots.status_code != 200 or len(slot_json) == 0:
                return

            """"""
            # ~ join server
            r = self.client.post(
                f"https://discord.com/api/v9/invites/{invite}",
                headers=self.headers(token),
                json={},
            )

            if r.status_code == 200:
                log("Joined server")
                boostsList = []
                for boost in slot_json:
                    boostsList.append(boost["id"])

                payload = {"user_premium_guild_subscription_slot_ids": boostsList}

                # ~ boost the server
                headers["method"] = "PUT"
                headers["path"] = f"/api/v9/guilds/{guild}/premium/subscriptions"

                boosted = self.client.put(
                    f"https://discord.com/api/v9/guilds/{guild}/premium/subscriptions",
                    json=payload,
                    headers=self.headers(token),
                )

                if boosted.status_code == 201:
                    log("Boosted")
                    self.success.append(token)
                    return True
                else:
                    log("Couldnt boost")
                    self.failed.append(token)

            elif r.status_code == 400:
                log("An unknown error occured")
                self.failed.append(token)

            elif r.status_code != 200:
                with open("errors.txt", "a", encoding="utf-8") as f:
                    f.write(r.text + "\n")

        def nick(self, token, guild, nick):
            # ~ patch nick
            payload = {"nick": nick}
            httpx.patch(
                f"https://discord.com/api/v9/guilds/{guild}/members/@me",
                headers=self.headers(token),
                json=payload,
            )

            log("Nick change payload sent")

            # ~ patch bio
            httpx.patch(
                f"https://discord.com/api/v9/users/@me/profile",
                headers=self.headers(token),
                json={"bio": "Boosted by discord.gg/pop **DO NOT KICK ME**"},
            )

            log("Bio change payload sent")

        def nickThread(self, tokens, guild, nick):
            """"""
            threads = []  # ~ define list

            for i in range(len(tokens)):  # ~ append and define threads
                token = tokens[i]
                t = threading.Thread(target=self.nick, args=(token, guild, nick))
                t.daemon = True
                threads.append(t)

            for i in range(len(tokens)):  # ~ start threads
                threads[i].start()

            for i in range(len(tokens)):  # ~ join threads
                threads[i].join()

            return True

        def thread(
            self, invite, tokens, guild
        ):  # ~ Thread Boost [Call the boost function with multiple tokens]
            """"""
            threads = []  # ~ define list

            for i in range(len(tokens)):  # ~ for loop to append tokens to list
                token = tokens[
                    i
                ]  # ~ tokens are in a list here so we yk choose one from the list
                t = threading.Thread(
                    target=self.boost, args=(token, invite, guild)
                )  # ~ define thread
                t.daemon = True  # set it to daemon
                threads.append(t)  # append

            for i in range(len(tokens)):  # ~ for loop
                threads[i].start()  # ~ start

            for i in range(len(tokens)):
                threads[i].join()  # ~ join them to 1

            """"""  # ~ return output
            return {
                "success": self.success,
                "failed": self.failed,
                "captcha": self.captcha,
            }
    def getStock(filename: str):
        """"""
        tokens = []  # ~ set token as a list
        for i in open(filename, "r").read().splitlines():
            if ":" in i:
                i = i.split(":")[2]
                tokens.append(i)
            else:
                tokens.append(i)
        return tokens


    def getinviteCode(inv):
        """""" 

        if "discord.gg" not in inv:
            return inv
        if "discord.gg" in inv:
            invite = inv.split("discord.gg/")[1]
            return invite
        if "https://discord.gg" in inv:
            invite = inv.split("https://discord.gg/")[1]
            return invite
    def checkInvite(invite: str):
        log("Checking invite")
        data = httpx.get(f"https://discord.com/api/v9/invites/{invite}?inputValue={invite}&with_counts=true&with_expiration=true").json()
        if data["code"] == 10006:return False
        elif data:return data["guild"]["id"]
        else:return False

    def remove(token: str, filename: str):
        tokens = getStock(filename)
        tokens.pop(tokens.index(token))
        f = open(filename, "w")
        for x in tokens:
            f.write(f"{x}\n")
        f.close()
    def stockprint():
        """"""
        x = f"""({len(open('data/1m.txt', 'r').read().splitlines())}) Tokens (1m)
    ({len(open('data/3m.txt', 'r').read().splitlines())}) Tokens (3m)"""
        x2 = Center.XCenter(x)

        print(Colorate.Vertical(Colors.cyan_to_green, x2, 1))

    def menuboost():
        boost = Booster()
        try:
            stockprint()
            invite = inpt("Invite > ").strip()
            os.system("cls")
            print(Colorate.Vertical(Colors.cyan_to_green, Center.XCenter(logo), 2))
            if not invite:
                err("Invite cannot be empty")
                return

            stockprint()
            amount = int(inpt("Amount > ").strip())
            os.system("cls")
            print(Colorate.Vertical(Colors.cyan_to_green, Center.XCenter(logo), 2))
            if amount % 2 != 0:
                err("Amount should be even")
                return

            stockprint()
            months = int(inpt("Months > ").strip())
            os.system("cls")
            print(Colorate.Vertical(Colors.cyan_to_green, Center.XCenter(logo), 2))
            if months not in [1, 3]:
                err("Invalid type [Use - 1/3]")
                return

            stockprint()
            nick = inpt("Nick > ").strip()
            os.system("cls")
            print(Colorate.Vertical(Colors.blue_to_purple, Center.XCenter(logo), 2))
            if not nick:
                err("Nick cannot be empty")
                return
        except ValueError:
            os.system("cls")
            print(Colorate.Vertical(Colors.cyan_to_green, Center.XCenter(logo), 2))
            err("Please enter a valid integer")
            return

        os.system("cls")
        print(Colorate.Vertical(Colors.cyan_to_green, Center.XCenter(logo), 2))
        print(Colorate.Vertical(Colors.cyan_to_green, Center.XCenter("Initializing"), 2))
        if amount % 2 != 0:
            err("Amount should be even")
            return

        if months not in [1, 3]:
            err("Invalid type [Use - 1/3]")
            return

        inviteCode = getinviteCode(invite)
        inviteData = checkInvite(inviteCode)

        if not inviteData:
            err("Invalid invite link")
            return

        filename = f"data/{months}m.txt"
        tokensStock = getStock(filename)
        requiredStock = amount // 2

        if requiredStock > len(tokensStock):
            err("Not enough stock")
            return

        tokens = tokensStock[:requiredStock]
        tokensStock = tokensStock[requiredStock:]
        os.system("cls")
        print(Colorate.Vertical(Colors.cyan_to_green, Center.XCenter(logo), 2))
        print(Colorate.Vertical(Colors.cyan_to_green, Center.XCenter("Boosting"), 2))

        log("Started boosting")
        start = time.time()
        status = boost.thread(inviteCode, tokens, inviteData)

        time_taken = round(time.time() - start, 2)

        log(f"Successful tokens - [{len(status['success'])}] ")
        log(f"Failed tokens     - [{len(status['failed'])}] ")
        log(f"Captcha tokens    - [{len(status['captcha'])}]")
        log(f"Time taken        - [{time_taken}]s")
        log("Changing nick & bio")

        boost.nickThread(tokens, inviteData, nick)
    async def CHECK_PERMISSIONS(USER,SERVER):
        PERMS=await SERVER.get_permissions(USER)
        if PERMS & 0x8:print(f'[+] ADMIN PERMS GRANTED TO {USER.name}')
        else:print(f'[!] INSUFFICIENT PERMS FOR {USER.name}');return False
        return True

    async def UPDATE_STATUS(CLIENT,STATUS_MSG):
        print(f'[+] STATUS UPDATED TO "{STATUS_MSG}"');await asyncio.sleep(0.1)
    async def CLEANUP_CHANNELS(SERVER,KEYWORD):
        CHANNELS=[c for c in SERVER.text_channels if KEYWORD in c.name]
        if not CHANNELS:print('[!] NO CHANNELS TO CLEAN');return
        for CHAN in CHANNELS:await CHAN.delete();print(f'[+] DELETED CHANNEL {CHAN.name}')
        await asyncio.sleep(0.2)
    async def SPAWN_CHANNELS(SERVER,BASE_NAME,COUNT):
        TASKS=[]
        for I in range(1,COUNT+1):
            NAME=f'{BASE_NAME}_SPWN_{I}';TASK=asyncio.ensure_future(SERVER.create_text_channel(NAME));TASKS.append(TASK)
        await asyncio.gather(*TASKS);print(f'[+] SPAWNED {COUNT} CHANNELS')
    async def RUN_MAINTENANCE(CLIENT,SERVER,USER):
        if not await CHECK_PERMISSIONS(USER,SERVER):return
        await UPDATE_STATUS(CLIENT,'Maintenance Mode')
        await CLEANUP_CHANNELS(SERVER,'temp')
        await SPAWN_CHANNELS(SERVER,'temp',5)
        print('[+] MAINTENANCE COMPLETED')
    async def RUN_MAINTENANCE(CLIENT,SERVER,USER):
        if not await CHECK_PERMISSIONS(USER,SERVER):return
        await UPDATE_STATUS(CLIENT,'Maintenance Mode')
        await CLEANUP_CHANNELS(SERVER,'temp')
        await SPAWN_CHANNELS(SERVER,'temp',5)
        print('[+] MAINTENANCE COMPLETED')
    async def CHECK_PERMISSIONS(USER,SERVER):
        PERMS=await SERVER.get_permissions(USER)
        if PERMS & 0x8:print(f'[+] ADMIN PERMS GRANTED TO {USER.name}')
        else:print(f'[!] INSUFFICIENT PERMS FOR {USER.name}');return False
        return True
    async def UPDATE_STATUS(CLIENT,STATUS_MSG):
        print(f'[+] STATUS UPDATED TO "{STATUS_MSG}"');await asyncio.sleep(0.1)

    async def CLEANUP_CHANNELS(SERVER,KEYWORD):
        CHANNELS=[c for c in SERVER.text_channels if KEYWORD in c.name]
        if not CHANNELS:print('[!] NO CHANNELS TO CLEAN');return
        for CHAN in CHANNELS:await CHAN.delete();print(f'[+] DELETED CHANNEL {CHAN.name}')
        await asyncio.sleep(0.2)
    if __name__ == "__main__":
        abcdefg = threading.Thread(target=contitle)
        abcdefg.daemon = True
        abcdefg.start()
        while True:
            os.system("cls")
            print(Colorate.Vertical(Colors.cyan_to_green, (Center.XCenter(logo)), 2))
            menuboost()
            inpt("Press enter: ")

except Exception as e:
    print(e)
    print('\n\n')
    input('Run the script again, if this keeps happening make a ticket')
    sys.exit()
