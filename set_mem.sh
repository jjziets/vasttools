#!/bin/bash

# set_mem.sh  This script will OC the memory of Nvidia 3000
#
# Description:  A script to set memory OC on headless (non-X) Linux nodes

# Original Script by Axel Kohlmeyer <akohlmey@gmail.com>
# https://sites.google.com/site/akohlmey/random-hacks/nvidia-gpu-coolness
#
# Modified for newer drivers and removed old work-arounds
# Tested on Ubuntu 14.04 with driver 352.41
# Copyright 2015, squadbox

# Requirements:
# * An Nvidia GPU
# * Nvidia Driver V285 or later
# * xorg
# * Coolbits enabled and empty config setting
#     nvidia-xconfig -a --cool-bits=28 --allow-empty-initial-configuration
#  * dependencies  sudo apt-get install libgtk-3-0 && sudo apt-get install xinit && sudo apt-get install xserver-xorg-core && sudo update-grub && sudo nvidia-xconfig -a --cool-bits=28 --allow-empty-initial-configuration --enable-all-gpus


# You may have to run this as root or with sudo if the current user is not authorized to start X sessions.


# Paths to the utilities we will need
SMI='/usr/bin/nvidia-smi'
SET='/usr/bin/nvidia-settings'

# Determine major driver version
VER=`awk '/NVIDIA/ {print $8}' /proc/driver/nvidia/version | cut -d . -f 1`

# Drivers from 285.x.y on allow persistence mode setting
if [ ${VER} -lt 285 ]
then
    echo "Error: Current driver version is ${VER}. Driver version must be greater than 285."; exit 1;
fi

# Read a numerical command line arg between 0 and 3000
if [ "$1" -eq "$1" ] 2>/dev/null && [ "0$1" -ge "0" ]  && [ "0$1" -le "3000" ]
then
    $SMI -pm 1 # enable persistence mode
    speed=$1   # set speed

    echo "Setting memory OC to $speed."

    # how many GPUs are in the system?
    NUMGPU="$(nvidia-smi -L | wc -l)"

    # loop through each GPU and individually set mem oc
    n=0
    while [  $n -lt  $NUMGPU ];
    do
        # start an X session, and call nvidia-settings to enable memory OC
        xinit ${SET} -a [gpu:${n}]/GPUPowerMizerMode=1   -a [gpu:${n}]/GPUMemoryTransferRateOffsetAllPerformanceLevels=$speed   --  :0 -once

        let n=n+1
    done

    echo "Complete"; exit 0;

elif [ "x$1" = "xstop" ]
then
    $SMI -pm 0 # disable persistence mode

    echo "Enabling default automatic memory control."

    # how many GPUs are in the system?
    NUMGPU="$(nvidia-smi -L | wc -l)"

    # loop through each GPU and individually set mem oc
    n=0
    while [  $n -lt  $NUMGPU ];
    do
        # start an X session, and call nvidia-settings to enable memory OC
        xinit ${SET} -a [gpu:${n}]/GPUMemoryTransferRateOffsetAllPerformanceLevels=0 --  :0 -once
        let n=n+1
    done

    echo "Complete"; exit 0;

else
    echo "Error: Please pick a Memory Offset Clock speed between 0 and 3000, or stop."; exit 1;
fi
