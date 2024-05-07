#!/bin/bash

# Update and Upgrade the system
echo "Updating and upgrading the system..."
sudo apt-get update && sudo apt-get upgrade -y

# Install stress-ng and sysbench
echo "Installing stress-ng and sysbench..."
sudo apt-get install -y stress-ng sysbench

# Calculate the number of cores minus one
total_cores=$(nproc --all)
let "stress_cores = total_cores - 1"

# Calculate 90% of total memory
total_mem_kib=$(grep MemTotal /proc/meminfo | awk '{print $2}') # Total memory in KiB
ninety_percent_mem_kib=$((total_mem_kib * 90 / 100)) # 90% of total memory in KiB
ninety_percent_mem_mib=$((ninety_percent_mem_kib / 1024)) # Convert KiB to MiB
ninety_percent_mem_bytes=$((ninety_percent_mem_mib * 1024 * 1024)) # Convert MiB to bytes


# Run stress-ng tests
echo "Running stress-ng CPU stress test on $stress_cores cores..."
stress-ng --cpu $stress_cores --timeout 60s --metrics-brief

echo "Running stress-ng drive stress test..."
stress-ng --hdd $stress_core --timeout 60s --metrics-brief

echo "Running stress-ng memory stress test..."
stress-ng --vm $stress_core --vm-bytes ${ninety_percent_mem_mib}M --timeout 60s --metrics-brief

# Run sysbench memory tests
echo "Running sysbench memory latency test..."
sysbench memory --memory-block-size=1K --memory-total-size=$ninety_percent_mem_bytes --memory-access-mode=rnd --time=60 run

echo "Running sysbench memory speed test..."
sysbench memory --memory-block-size=1M --memory-total-size=$ninety_percent_mem_bytes --memory-access-mode=seq --time=60 run

echo "All tests completed successfully."
