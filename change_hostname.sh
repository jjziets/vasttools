#!/bin/bash

# Check if a new hostname is provided as an argument
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 new_hostname"
    exit 1
fi

new_hostname="$1"

# Change the hostname temporarily
sudo hostname "$new_hostname"

# Update /etc/hostname for a permanent change
echo "$new_hostname" | sudo tee /etc/hostname

# Update /etc/hosts to ensure proper resolution
sudo sed -i "s/127.0.1.1 .*/127.0.1.1 $new_hostname/" /etc/hosts

# Restart systemd-logind to apply changes
sudo systemctl restart systemd-logind.service

echo "Hostname changed to $new_hostname"
