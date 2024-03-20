#!/bin/bash

# Define log file
log_file="$(dirname "$0")/cleanup_log.txt"

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$log_file"
}

# Check disk usage of /var/lib/docker
disk_usage=$(df /var/lib/docker | awk 'NR==2 {print $5}' | sed 's/%//g')

# Proceed if disk usage is greater than 90%
if [ "$disk_usage" -gt 90 ]; then
    log_message "Disk usage of /var/lib/docker is above 90%. Running cleanup..."

    # Find containers with 'registry' in their name
    registry_containers=$(docker ps --filter "name=registry" --format "{{.Names}}")

    # Check if the list is empty
    if [ -z "$registry_containers" ]; then
        log_message "No registry containers found. Exiting."
        exit 0
    fi

    for container in $registry_containers; do
        log_message "Stopping $container..."
        docker stop "$container"

        log_message "Running garbage collection for $container..."
        docker run --rm --volumes-from "$container" registry:2 bin/registry garbage-collect /etc/docker/registry/config.yml

        log_message "Starting $container..."
        docker start "$container"
    done

    log_message "Cleanup complete."
#else
#    log_message "Disk usage of /var/lib/docker is below 90%. No cleanup needed."
fi
