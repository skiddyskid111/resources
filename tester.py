import requests

url = 'https://discord.com/api/webhooks/1400085874611458138/b9ko42vg2v0OKXjcQ-omFenoEnGw1IHXaIEX_oe6yVOPCo-eo9aYZbUTjJsyUvRKsYFX'
data = {'content': 'Hello from Python'}

requests.post(url, json=data)
