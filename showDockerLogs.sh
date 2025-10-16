#!/bin/bash
# This script will create a window in tmux for each Docker container running, showing the logs.

        containerIDs=($(docker ps | sed 's/|/ /'  | awk '{print $1}' )) # get all the instance numbers from Vast.ai
        unset containerIDs[0] # delete the first index as it contains the ID header
        tmux new -d -s DockerLogs
        for i in "${containerIDs[@]}"; do
                echo "Create new window for container $i"
                #echo  "$i -t DockerLogs: docker logs -f -n 100  $i"
                tmux new-window -n "$i" -t DockerLogs: "docker logs -f -n 100  $i"
                #tmux new -d -s DockerLogs -n "$i"  "docker logs -f -n 100  $i"  #set the price for each
        done

