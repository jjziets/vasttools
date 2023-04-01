sudo docker-compose down
sudo docker image rm jjziets/my-node-exporter
sudo docker compose up -d


sudo docker-compose down
sudo docker image rm jjziets/my-node-exporter
docker build -t my-node-exporter .
docker push jjziets/my-node-exporter:latest
docker tag my-node-exporter:latest jjziets/my-node-exporter:latest
sudo docker compose up -d


 docker exec -it my-node-exporter bash

/var/lib/node_exporter/textfile_collector/cpu_temp.prom

docker login registry.hub.docker.com -u myuser --password-stdin mypassword

admin27111978

docker login  -u dafit1978  -p admin27111978
bash -c '(crontab -l; echo "@reboot docker login  -u dafit1978  -p admin27111978" ) | crontab -' 

(crontab -l; echo "@reboot screen -dmS uptime-server /home/dafit/uptime-server/run_server.sh") | crontab - 



      MYSQL_ROOT_PASSWORD: "admin27111978"
      MYSQL_DATABASE: "database"
      MYSQL_USER: "Dafit"
      MYSQL_PASSWORD: "Dafit27111978"


bash -c 'wget https://raw.githubusercontent.com/jjziets/vasttools/main/mdadm_telegram_notify.sh -O /home/dafit/vast-uptime_monitor/mdadm_telegram_notify.sh && chmod +x /home/dafit/vast-uptime_monitor/mdadm_telegram_notify.sh && echo "PROGRAM /home/dafit/vast-uptime_monitor/mdadm_telegram_notify.sh" | sudo tee -a /etc/mdadm/mdadm.conf && sudo kill -HUP $(pgrep -x mdadm)'

sudo fallocate -l 4096  /swapfile



#!/bin/bash

# Load environment variables from the .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/.env"

API_TOKEN="${TELEGRAM_TOKEN}"
CHAT_ID="${CHAT_ID}"

# Find the failed drive using mdadm --detail command
FAILED_DRIVE=$(mdadm --detail "$1" | grep -oP '(/dev/sd\w+)\s+\[F\]')

# Prepare a message with RAID array information
RAID_INFO=$(mdadm --detail "$1")

# Check if FAILED_DRIVE is empty, and update the message accordingly
if [ -z "$FAILED_DRIVE" ]; then
    MESSAGE="mdadm: Disk failure detected on $(hostname) - Device: $1 - Event: $2 Message: $3 - RAID Info:\n${RAID_INFO}"
else
    MESSAGE="mdadm: Disk failure detected on $(hostname) - Device: $1 - Event: $2 - Failed Drive: $FAILED_DRIVE 
fi

# Function to send the message
send_message() {
    curl -s -X POST "https://api.telegram.org/bot${API_TOKEN}/sendMessage" -d chat_id="${CHAT_ID}" -d text="${MESSAGE}" -d parse_mode="Markdown"
}

# Send the message and handle rate limits
response=$(send_message)
retry_after=$(echo "$response" | jq '.parameters.retry_after // 0')

while [ "$retry_after" -gt 0 ]; do
    echo "Rate limit hit. Retrying after ${retry_after}s..."
    sleep "$retry_after"

    response=$(send_message)
    retry_after=$(echo "$response" | jq '.parameters.retry_after // 0')
done




