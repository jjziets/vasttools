#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import subprocess
import json
import datetime
from geopy.geocoders import Nominatim
import pycountry

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

# Initialize geolocator
geolocator = Nominatim(user_agent="my_app")

# Enter the city and country name
city = data["server"]["location"]
country = data["server"]["country"]

# Combine the city and country name into a single address
location = geolocator.geocode(f"{city}, {country}")

longitude  = float(location.longitude)
latitude   = float(location.latitude)


def country_to_code(country_name):
    try:
        country_code = pycountry.countries.search_fuzzy(country_name)[0].alpha_2
    except LookupError:
        country_code = None
    return country_code



# Extract the desired fields and format them in a new dictionary
result = {
    "client": {
        "rating": "0",
        "loggedin": "0",
        "isprating": "0",
        "ispdlavg": "0",
        "ip": data["interface"]["externalIp"],
        "isp": data["isp"],
        "lon": str(longitude), #"0", #"data["server"]["lon"],
        "ispulavg": "0",
        "country": country_to_code(data["server"]["country"]),
        "lat": str(latitude) #"0", #data["server"]["lat"]
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
        "name": data["server"]["location"],
        "url": "http://{}:{}/upload.php".format(data['server']['host'], data['server']['port']),
        "country": data["server"]["country"],
        "lon":  str(longitude), #"0",  #data["server"]["lon"],
        "cc": country_to_code(data["server"]["country"]),
        "host": "{}:{}".format(data['server']['host'], data['server']['port']),
        "sponsor": data["server"]["name"],
        "lat": str(latitude), # "0", # data["server"]["lat"],
        "id": str(data["server"]["id"]),
        "d": data["ping"]["latency"]/1000.0
    }
}

# Print the result as a JSON string
print(json.dumps(result))
