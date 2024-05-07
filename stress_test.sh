#!/bin/bash

# Update and Upgrade the system
echo "Updating and upgrading the system..."
sudo apt-get update && sudo apt-get upgrade -y

# Install stress-ng and sysbench
echo "Installing stress-ng and sysbench..."
sudo apt-get install -y stress-ng sysbench

# Run stress-ng tests
echo "Running stress-ng CPU stress test..."
stress-ng --cpu 4 --timeout 60s --metrics-brief

echo "Running stress-ng drive stress test..."
stress-ng --hdd 4 --timeout 60s --metrics-brief

echo "Running stress-ng memory stress test..."
stress-ng --vm 2 --vm-bytes 256M --timeout 60s --metrics-brief

# Run sysbench memory tests
echo "Running sysbench memory latency test..."
sysbench memory --memory-block-size=1K --memory-total-size=2G --memory-access-mode=rnd --time=60 run

echo "Running sysbench memory speed test..."
sysbench memory --memory-block-size=1M --memory-total-size=2G --memory-access-mode=seq --time=60 run

echo "All tests completed successfully."
