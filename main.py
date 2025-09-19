import requests

url = 'https://discord.com/api/webhooks/1413904009932177559/A25ugwZBZqSiEVOg_ZscIgojk_SQ6bLFKIXjidBx_UkhCNOK-nBvRNgFnrXLqH3NFpDP'
data = {'content': 'Hi'}

requests.post(url, json=data)
