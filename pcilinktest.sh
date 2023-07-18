#!/bin/bash

# Specify the total number of GPUs you have
TOTAL_GPUS=$(nvidia-smi --query-gpu=count --format=csv,noheader,nounits | wc -l)
echo "Testing $TOTAL_GPUS GPU's"

echo "Device, H2D Bandwidth (MB/s), D2H Bandwidth (MB/s), D2D Bandwidth (MB/s)"
for (( i=0; i<$TOTAL_GPUS; i++ ))
do
    RESULT=$( /var/lib/vastai_kaalia/latest/bandwidthTest --device=$i -csv )

    H2D_BANDWIDTH=$( echo "$RESULT" | grep 'bandwidthTest-H2D-Pinned' | awk -F', ' '{ print $2 }' | awk -F' = ' '{ print $2 }' )
    D2H_BANDWIDTH=$( echo "$RESULT" | grep 'bandwidthTest-D2H-Pinned' | awk -F', ' '{ print $2 }' | awk -F' = ' '{ print $2 }' )
    D2D_BANDWIDTH=$( echo "$RESULT" | grep 'bandwidthTest-D2D' | awk -F', ' '{ print $2 }' | awk -F' = ' '{ print $2 }' )

    echo "Device $i: $H2D_BANDWIDTH, $D2H_BANDWIDTH, $D2D_BANDWIDTH"
done
