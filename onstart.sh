#!/bin/bash

# Update and install necessary packages
apt update && apt install -y wget libcurl4 libjansson4

# Download the qli-Client
wget https://dl.qubic.li/downloads/qli-Client-1.9.7-Linux-x64.tar.gz
tar -xf qli-Client-1.9.7-Linux-x64.tar.gz

# Calculate the number of threads based on CPU quota and period
CPU_QUOTA=$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us)
CPU_PERIOD=$(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)
if [ "$CPU_PERIOD" -gt 0 ]; then
    NUM_CORES=$((CPU_QUOTA / CPU_PERIOD))
    THREADS=$((NUM_CORES / 2))
else
    THREADS=1
fi

# Create appsettings.json if it does not exist
if [ ! -f appsettings.json ]; then
    cat <<EOF > appsettings.json
{
  "Settings": {
    "baseUrl": "https://mine.qubic.li/",
    "amountOfThreads": $THREADS,
    "payoutId": null,
    "accessToken": "eyJhbGciOiJIUzUxMiIsInR5cCI6IkpXVCJ9.eyJJZCI6ImJlNzcyMzYxLWJlYWUtNGVjNC05NDc2LWRjMjIyZmRiZTRlMCIsIk1pbmluZyI6IiIsIm5iZiI6MTcxMTQ2Mzc0MiwiZXhwIjoxNzQyOTk5NzQyLCJpYXQiOjE3MTE0NjM3NDIsImlzcyI6Imh0dHBzOi8vcXViaWMubGkvIiwiYXVkIjoiaHR0cHM6Ly9xdWJpYy5saS8ifQ.o1d1xoaFDUctPdoZCp_2r3SocC7BFK8ndvD809De0WZA2R_e3Bx323GeRQ7QA50qYuUfbpmk2caPBOQj3rU6Jw",
    "alias": "qubic.li Client"
  }
}
EOF
fi

# Run the qli-Client
./qli-Client
