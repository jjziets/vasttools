#!/bin/bash
#this script will create a window in tmux for each docker running shwoing the logs .

        containerIDs=($(docker ps | sed 's/|/ /'  | awk '{print $1}' )) # get all the instanses number from vast
        unset containerIDs[0] #delte the first index as it containe ID
        tmux new -d -s DockerLogs
        for i in "${containerIDs[@]}"; do
                echo "creat new window of container $i"
                #echo  "$i -t DockerLogs: docker logs -f -n 100  $i"
                tmux new-window -n "$i" -t DockerLogs: "docker logs -f -n 100  $i"
                #tmux new -d -s DockerLogs -n "$i"  "docker logs -f -n 100  $i"  #set the price for each
        done

