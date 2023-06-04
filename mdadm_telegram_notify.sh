#!/bin/bash

# Load environment variables from the .env file
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &> /dev/null && pwd)"
source "${SCRIPT_DIR}/.env"

API_TOKEN="${TELEGRAM_TOKEN}"
CHAT_ID="${CHAT_ID}"

# Find the failed drive using mdadm --detail command
FAILED_DRIVE=$(mdadm --detail "$2" | grep -oP '(/dev/sd\w+)\s+\[F\]')

# Prepare a message with RAID array information
RAID_INFO=$(mdadm --detail "$2")

# Get RAID state
RAID_STATE=$(echo "$RAID_INFO" | grep "State :" | awk '{for(i=3; i<=NF; i++) printf $i" "; print ""}')
RAID_STATE=$(echo "$RAID_STATE" | xargs)  # trim leading and trailing white space

# Array of RAID states to exclude
EXCLUDED_STATES=("clean" "clean, checking" "active" "active, checking" "clean, resyncing" "active, resyncing" )

# Check if the RAID state is in the excluded states, skip sending the message
for state in "${EXCLUDED_STATES[@]}"; do
    if [[ "$RAID_STATE" == "$state" ]]; then
        echo "RAID array status is '$RAID_STATE', skipping Telegram message."
        exit 0
    fi
done

# Check if FAILED_DRIVE is empty, and update the message accordingly
if [ -z "$FAILED_DRIVE" ]; then
    MESSAGE="mdadm: Disk event detected on $(hostname) - Device: $2 - Event: $1  info: $3 - RAID Info: \n ${RAID_INFO}"
else
    MESSAGE="mdadm: Disk event detected on $(hostname) - Device: $2 - Event: $1  info: $3 Failed Drive: $FAILED_DRIVE"
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

