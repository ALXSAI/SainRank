import requests
import json

api_key = "PCMCIC67DB98P9M24WWIZ7CCDU22QDCFRI"

api_url = "https://api.etherscan.io/api"

address = "0x97c18D92E54bd9b4A755ACB604Cd51a6f11245fc"
task_url = f'https://api.etherscan.io/api?module=account&action=txlist&address={address}&startblock=0&endblock=99999999&page=1&offset=10&sort=asc&apikey={api_key}'
print(task_url)
print("$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")

response = requests.get(task_url)
parsed = json.loads(response.content)


for i in parsed['result']:
    print(i['from'])
    print(i['to'])
    print(i['value'])
    print("-------------------------------------")


print(parsed['result'])