#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import subprocess
import json
import datetime
#from geopy.geocoders import Nominatim
#import pycountry

max_retries = 3
retry_count = 0

while retry_count < max_retries:
    try:
        # Run the speedtest command and capture the output
        output = subprocess.check_output(["speedtest", "--accept-license", "--accept-gdpr", "--format=json"])
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
#geolocator = Nominatim(user_agent="my_app")

# Enter the city and country name
city = data["server"]["location"]
country = data["server"]["country"]

# Combine the city and country name into a single address
#location = geolocator.geocode(f"{city}, {country}")

#longitude  = round(float(location.longitude),4)
#latitude   = round(float(location.latitude),4)


#def country_to_code(country_name):
#    try:
#        country_code = pycountry.countries.search_fuzzy(country_name)[0].alpha_2
#    except LookupError:
#        country_code = None
#    return country_code



# Extract the desired fields and format them in a new dictionary
result = {
    "client": {
        "rating": "0",
        "loggedin": "0",
        "isprating": "3.1",
        "ispdlavg": "0",
        "ip": data["interface"]["externalIp"],
        "isp": data["isp"],
        "lon": "0", #str(longitude),
        "ispulavg": "0",
        "country": " ", #country_to_code(data["server"]["country"]),
        "lat": "0", # str(latitude)
    },
    "bytes_sent": data["upload"]["bytes"],
    "download": float(str(data["download"]["bandwidth"]) + '.123300') * 8,
    "timestamp": datetime.datetime.utcnow().isoformat() + 'Z',
    "share": None,
    "bytes_received": data["download"]["bytes"],
    "ping": data["ping"]["latency"],
    "upload": float(str(data["upload"]["bandwidth"]) + '.12300') * 8,
    "server": {
        "latency": data["ping"]["latency"],
        "name": data["server"]["location"],
        "url": "http://{}:{}/upload.php".format(data['server']['host'], data['server']['port']),
        "country": data["server"]["country"],
        "lon":  "0", # str(longitude), #"0",  #data["server"]["lon"],
        "cc": "  ", #country_to_code(data["server"]["country"]),
        "host": "{}:{}".format(data['server']['host'], data['server']['port']),
        "sponsor": data["server"]["name"],
        "lat": "0", #str(latitude), # "0", # data["server"]["lat"],
        "id": "0", #str(data["server"]["id"]),
        "d": data["ping"]["latency"]
    }
}

# Print the result as a JSON string
print(json.dumps(result))
