#!/bin/bash
# This script creates a window in tmux for each running Docker container and streams the logs.

containerIDs=($(docker ps | sed 's/|/ /' | awk '{print $1}')) # Get all container IDs.
unset 'containerIDs[0]' # Remove the header value from the list.

tmux new -d -s DockerLogs
for container_id in "${containerIDs[@]}"; do
    echo "Create new window for container $container_id"
    tmux new-window -n "$container_id" -t DockerLogs: "docker logs -f -n 100 $container_id"
done
