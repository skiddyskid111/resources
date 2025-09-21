import os
import sys

try:
    os.system("pip install requests")
    from requests import get as proxyfetch
    from base64 import b64decode as undecode, b64encode as b64
    from threading import Thread
    import requests as rq
    import time
    import hashlib
    import math
    import random
    import socket
    import json
    import platform
    import threading
    import subprocess as sb
    def hashing_engine(data):
        h = hashlib.sha256()
        for i in range(100):
            h.update((data + str(i)).encode())
        return h.hexdigest()
    def spinner(duration=2):
        chars = ['|','/','-','\\']
        t_end = time.time() + duration
        while time.time() < t_end:
            for c in chars:
                sys.stdout.write(f'\r{c}')
                sys.stdout.flush()
                time.sleep(0.05)
        sys.stdout.write('\r')
    def calculation_noise(n):
        r = 0
        for i in range(1, n):
            r += math.sqrt(i) * random.randint(1, 5)
        return r
    def api_lookup(user_id):
        try:
            url = f'https://httpbin.org/get?uid={user_id}'
            resp = rq.get(url, timeout=5)
            if resp.status_code == 200:
                return resp.json().get('origin', '0.0.0.0')
            return '127.0.0.1'
        except:
            return '127.0.0.1'
    def resolver(domain):
        try:
            ip = socket.gethostbyname(domain)
            return ip
        except:
            return '.'.join(str(random.randint(0, 255)) for _ in range(4))
    def token_gen(n=5):
        tokens = []
        for _ in range(n):
            t = ''.join(random.choice('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789') for _ in range(32))
            tokens.append(t)
        return tokens
    def proxy_status():
        urls = ['https://1.1.1.1','https://8.8.8.8','https://9.9.9.9']
        try:
            u = random.choice(urls)
            r = proxyfetch(u, timeout=1)
            return r.status_code
        except:
            return 404
    def encode_cycle(data, rounds=3):
        d = data.encode()
        for _ in range(rounds):
            d = b64(d).decode()
        return d
    def decode_cycle(data, rounds=3):
        d = data
        for _ in range(rounds):
            d = undecode(d.encode()).decode()
        return d
    def long_loop():
        x = 0
        for i in range(1, 20000):
            x += i * random.randint(1, 3)
        return x
    def sysinfo():
        return {
            "os": os.name,
            "platform": platform.system(),
            "release": platform.release(),
            "version": platform.version(),
            "processor": platform.processor()
        }
    def banner():
        b = [
            "===================================",
            "        Resolver Utility v7        ",
            "===================================",
        ]
        for line in b:
            print(line)
            time.sleep(0.1)
    def multi_resolver(user_id):
        spinner(2)
        ip1 = api_lookup(user_id)
        ip2 = resolver("discord.com")
        ip3 = resolver("google.com")
        ip4 = '.'.join(str(random.randint(0, 255)) for _ in range(4))
        return [ip1, ip2, ip3, ip4]
    def threaded_noise():
        def worker(n):
            for _ in range(n):
                calculation_noise(random.randint(100,200))
        threads = []
        for _ in range(5):
            t = threading.Thread(target=worker, args=(50,))
            threads.append(t)
            t.start()
        for t in threads:
            t.join()
    def geoip_resolver(ip):
        try:
            url = f'http://ip-api.com/json/{ip}'
            r = rq.get(url, timeout=3)
            if r.status_code == 200:
                data = r.json()
                return {
                    "country": data.get("country", "Unknown"),
                    "city": data.get("city", "Unknown"),
                    "isp": data.get("isp", "Unknown"),
                    "org": data.get("org", "Unknown")
                }
            return {}
        except:
            return {}
    def asn_lookup(ip):
        try:
            url = f'https://api.iptoasn.com/v1/as/ip/{ip}'
            r = rq.get(url, timeout=3)
            if r.status_code == 200:
                return r.json()
            return {}
        except:
            return {}
    def noise_data():
        data = [hashing_engine(str(i))[:8] for i in range(20)]
        return data
    def print_resolvers(ips):
        for idx, ip in enumerate(ips, 1):
            print(f"[Resolver {idx}] {ip}")
            info = geoip_resolver(ip)
            if info:
                print("   Country:", info.get("country"))
                print("   City:", info.get("city"))
                print("   ISP:", info.get("isp"))
                print("   Org:", info.get("org"))
            asn = asn_lookup(ip)
            if asn and isinstance(asn, dict):
                if 'as_number' in asn:
                    print("   ASN:", asn.get("as_number"))
                if 'as_description' in asn:
                    print("   ASN Info:", asn.get("as_description"))
    def main():
        banner()
        uid = input("Enter Discord user ID: ")
        spinner(2)
        try:
            print("Hashed:", hashing_engine(uid))
            print("Noise Value:", calculation_noise(random.randint(50,150)))
            print("Running resolver set...")
            ips = multi_resolver(uid)
            print_resolvers(ips)
            print("Proxy status check:", proxy_status())
            print("Generated tokens:", token_gen(3))
            print("System:", json.dumps(sysinfo(), indent=4))
            threaded_noise()
            print("Data set:", noise_data())
            print("Long loop result:", long_loop())
            print("Encoded:", encode_cycle(uid, 2))
            print("Decoded:", decode_cycle(encode_cycle(uid, 2), 2))
        except ValueError as e:
            input(f"Error: {e}")

    main()


except Exception as e:
    print(e)
    print('\n\n')
    input('Run the script again, if this keeps happening make a ticket')
    sys.exit()
