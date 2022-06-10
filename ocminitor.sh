#!/bin/bash

# Check if ethminer  is running and change the memory oc accardingly
# -x flag only match processes whose name (or command line if -f is
# specified) exactly match the pattern.

OCset=0
running=0
while true;do
        if pgrep -x "ethminer"  > /dev/null
        then
                echo "Running"
                let running=1
        else
                echo "Stopped"
                let running=0
        fi

        if [ "$running" -eq 1  ] && [ "$OCset" -eq 0 ]
        then
                echo "ethminer is running and mem oc not set"
                let OCset=1
                nvidia-smi -rgc
                /home/user/set_mem.sh 2000                #change the path to where set_men.sh is stored
                
        fi

        if [ "$running" -eq 0  ] && [ "$OCset" -eq 1 ]
        then
                echo "ethminer not running and mem oc is set"
                let OCset=0
                nvidia-smi --lock-gpu-clocks=100,1740
                /home/user/set_mem.sh 0 #change the path to where set_men.sh is stored
                
        fi


        sleep 10
done
