import random

import requests
import json

api_url = "https://api.etherscan.io/api"

address = input("Enter the address you want to analyze: ")
api_key = input("Enter your EtherScan api key")
task_url = f'https://api.etherscan.io/api?module=account&action=txlist&address={address}&startblock=0&endblock=99999999&page=1&offset=10&sort=asc&apikey={api_key}'

ratio = 0
count = 0
trust = 0

others = []

def mockBlacklist(address):
    if 0 == random.randint(0,100):
        return True
    else:
        return False

def recu(addressr, count):
    others.append(addressr)
    toGo = []
    response = requests.get(task_url)
    parsed = json.loads(response.content)['result']

    valin = 0
    valou = 0
    couin = 0
    couou = 0

    tempru = 0
    tempco = 0
    tempra = 0

    try:
        for i in parsed:
            print(i['from'])
            print(i['to'])
            print(i['value'])
            print("-------------------------------------")

            if i['to'] == addressr:
                valin += int(i['value'])
                couin += 1
                if i['from'] not in others:
                    toGo.append(i['from'])
            else:
                valou += int(i['value'])
                couou += 1
                if i['to'] not in others:
                    toGo.append(i['to'])

            tempra = count * valin/valou
            tempco = count * couin/couou

            if mockBlacklist(addressr):
                tempru += (tempra * tempco) / (count * 15)
            else:
                tempru += tempra * tempco

            for i in toGo:
                res = recu(i,count-1)
                tempru += res[2]
                tempco += res[1]
                tempra += res[0]
            return tempra, tempco, tempru
    except:
        print(parsed)
        return (0,0,0)


ratio, count, trust = recu(address,6)

print("Ratio: " + str(ratio) + " | Count: " + str(count) + " | Trust: " + str(trust))