#!/bin/bash

# Check if ethminer is running and adjust the memory OC accordingly.
# The -x flag only matches processes whose name (or command line if -f is
# specified) exactly matches the pattern.

OCset=0
running=0
while true; do
    if pgrep -x "ethminer" > /dev/null; then
        echo "Running"
        let running=1
    else
        echo "Stopped"
        let running=0
    fi

    if [ "$running" -eq 1 ] && [ "$OCset" -eq 0 ]; then
        echo "ethminer is running and memory OC is not set"
        let OCset=1
        nvidia-smi -rgc
        /home/user/set_mem.sh 2000 # Change this path to where set_mem.sh is stored.
    fi

    if [ "$running" -eq 0 ] && [ "$OCset" -eq 1 ]; then
        echo "ethminer not running and memory OC is set"
        let OCset=0
        nvidia-smi --lock-gpu-clocks=100,1740
        /home/user/set_mem.sh 0 # Change this path to where set_mem.sh is stored.
    fi

    sleep 10
done
