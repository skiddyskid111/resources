import os, requests, tls_client, datetime, sys, hashlib, threading, random, json, time, websocket, httpx, typing
from colorama import Fore
from concurrent.futures import ThreadPoolExecutor
r = Fore.RESET; c = Fore.MAGENTA; g = Fore.LIGHTBLACK_EX;

banner = f"""\n{c} 
                                     ___  __             __    {r}_   _____ 
                             {c}       / _ )/ /__  ___  ___/ /_ _{r}| | / /_  |
                              {c}     / _  / / _ \/ _ \/ _  / // /{r} |/ / __/ 
                              {c}    /____/_/\___/\___/\_,_/\_, /{r}|___/____/ 
                                                    {c}    /___/           
                                                    
                                                    """

def dmid(token, user_id, msgmsg):
        url = "https://discord.com/api/users/@me/channels"
        headers = {'Authorization': f'{token}',
                   'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36 Edg/110.0.1587.69',
                   'Origin': 'discord.com',
                   'Accept': '*/*',
                   'X-Super-Properties': 'eyJvcyI6IldpbmRvd3MiLCJicm93c2VyIjoiQ2hyb21lIiwiZGV2aWNlIjoiIiwic3lzdGVtX2xvY2FsZSI6ImRlIiwiYnJvd3Nlcl91c2VyX2FnZW50IjoiTW96aWxsYS81LjAgKFdpbmRvd3MgTlQgMTAuMDsgV2luNjQ7IHg2NCkgQXBwbGVXZWJLaXQvNTM3LjM2IChLSFRNTCwgbGlrZSBHZWNrbykgQ2hyb21lLzExMC4wLjAuMCBTYWZhcmkvNTM3LjM2IEVkZy8xMTAuMC4xNTg3LjY5IiwiYnJvd3Nlcl92ZXJzaW9uIjoiMTEwLjAuMC4wIiwib3NfdmVyc2lvbiI6IjEwIiwicmVmZXJyZXIiOiIiLCJyZWZlcnJpbmdfZG9tYWluIjoiIiwicmVmZXJyZXJfY3VycmVudCI6IiIsInJlZmVycmluZ19kb21haW5fY3VycmVudCI6IiIsInJlbGVhc2VfY2hhbm5lbCI6InN0YWJsZSIsImNsaWVudF9idWlsZF9udW1iZXIiOjE4MDEzNSwiY2xpZW50X2V2ZW50X3NvdXJjZSI6bnVsbCwiZGVzaWduX2lkIjowfQ==',
                   'Accept-Language': 'de,de-DE;q=0.9,en;q=0.8,en-GB;q=0.7,en-US;q=0.6'}
        data = {
            "recipient_id": user_id
        }
        response = requests.post(url, headers=headers, json=data)
        if response.status_code == 200:
            channel_id = response.json()["id"]
            url = f"https://discord.com/api/channels/{channel_id}/messages"
            data = {
                "content": msgmsg
            }
            response = requests.post(url, headers=headers, json=data)
            if response.status_code == 429:
                print(f"{datetime.datetime.now().strftime(f'{g}%H:%M:%S')}{r}    {c}[CAPTCHA]   {g}->    {r}Soldier {c}{token}{g}****{r} was captched {c}[RIP]{r}")
            if response.status_code == 204:
                print(f"{datetime.datetime.now().strftime(f'{g}%H:%M:%S')}{r}    {c}[SUCCESS]   {g}->   {r}Successfully sent {c}{token}{g}****{r}")
            elif response.status_code == 200:
                print(f"{datetime.datetime.now().strftime(f'{g}%H:%M:%S')}{r}    {c}[SUCCESS]   {g}->   {r}Successfully sent {c}{token}{g}****{r}")
            elif response.status_code == 403:
                print(f"{datetime.datetime.now().strftime(f'{g}%H:%M:%S')}{r}    {c}[ERROR]     {g}->    {r}Failed {c}{token}{g}****{r}")
            elif response.status_code == 404:
                print(f"{datetime.datetime.now().strftime(f'{g}%H:%M:%S')}{r}    {c}[ERROR]     {g}->    {r}Failed {c}{token}{g}****{r}")

def main():
   os.system('title BLOODY v2.0'); os.system('cls'); print(banner)
   tokens = []
   with open("data/tokens.txt", "r") as f:
       tokens = f.read().splitlines()
       user_ids = []
   with open("data/ids.txt", "r")as x:
       user_ids = x.read().splitlines()
       msgmsg = str(input(f"{datetime.datetime.now().strftime(f'{g}%H:%M:%S')}{r}    {r}Message {g}» {c}"))
       os.system('title BLOODY v2.0'); os.system('cls'); print(banner)
   for i, user_id in enumerate(user_ids):
       token = tokens[i % len(tokens)]
       dmid_thread = threading.Thread(target=dmid, args=(token, user_id, msgmsg))
       dmid_thread.start()
       dmid_thread.join()

main()