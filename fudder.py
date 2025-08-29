import requests

webhook_url = 'https://discord.com/api/webhooks/1411023027860410490/tX-RGpPD7WxrwbTmOcDaU8BZG-2-FDfJsvMi9DXF2Dc57h1WJQMVReBZ-RF2AnmPV095'
data = {
    'content': 'Hello!'
}

requests.post(webhook_url, json=data)
