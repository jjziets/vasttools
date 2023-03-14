#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import subprocess
import json
import datetime

max_retries = 3
retry_count = 0

while retry_count < max_retries:
    try:
        # Run the speedtest command and capture the output
        output = subprocess.check_output(["speedtest", "--format=json"])
        break
    except subprocess.CalledProcessError as e:
        print(f"Error running speedtest: {e}")
        retry_count += 1
        if retry_count == max_retries:
            print("Max retries exceeded. Exiting.")
            exit()

# Load the output as a JSON string
data = json.loads(output)

# Extract the desired fields and format them in a new dictionary
result = {
    "client": {
        "rating": "0",
        "loggedin": "0",
        "isprating": "0",
        "ispdlavg": "0",
        "ip": data["interface"]["externalIp"],
        "isp": data["isp"],
        "lon": "0", #"data["server"]["lon"],
        "ispulavg": "0",
        "country": data["server"]["country"],
        "lat": "0", #data["server"]["lat"]
    },
    "bytes_sent": data["upload"]["bytes"],
    "download": data["download"]["bandwidth"],
    "timestamp": datetime.datetime.utcnow().isoformat() + 'Z',
    "share": None,
    "bytes_received": data["download"]["bytes"],
    "ping": data["ping"]["latency"],
    "upload": data["upload"]["bandwidth"],
    "server": {
        "latency": data["ping"]["latency"],
        "name": data["server"]["name"],
        "url": "http://{}:{}/upload.php".format(data['server']['host'], data['server']['port']),
        "country": data["server"]["country"],
        "lon": "0",  #data["server"]["lon"],
        "cc": data["server"]["country"],
        "host": "{}:{}".format(data['server']['host'], data['server']['port']),
        "sponsor": data["server"]["name"],
        "lat": "0", # data["server"]["lat"],
        "id": str(data["server"]["id"]),
        "d": data["ping"]["latency"]/1000.0
    }
}

# Print the result as a JSON string
print(json.dumps(result))
