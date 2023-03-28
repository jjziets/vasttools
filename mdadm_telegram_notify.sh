#!/bin/bash
#custom script to send notifications via Telegram when a drive fails or encounters any issues.
#sudo apt-get install jq curl
#Edit the /etc/mdadm/mdadm.conf file (or /etc/mdadm.conf depending on your system) and add the following line:
#PROGRAM /path/to/mdamd_telegram_notify.sh


# Load environment variables from the .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/.env"

API_TOKEN="${TELEGRAM_TOKEN}"
CHAT_ID="${CHAT_ID}"

# Customize the message to include relevant information about the failure
MESSAGE="mdadm: Disk failure detected on $(hostname) - Device: $1 - Event: $2"

curl -s -X POST "https://api.telegram.org/bot${API_TOKEN}/sendMessage" -d chat_id="${CHAT_ID}" -d text="${MESSAGE}" -d parse_mode="Markdown"

