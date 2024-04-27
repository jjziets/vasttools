#!/bin/bash
# Overview: This script is designed to manage Docker services and GPU-related operations on Linux systems.
# It performs the following tasks:
# 1. Stops the Docker and runpod services to ensure a clean state before operations.
# 2. Starts the Docker services necessary for running containers.
# 3. Deploys a Docker container to perform a GPU burn-in test to stress test the GPUs.
# 4. Downloads and prepares a GPU temperature monitoring tool from a GitHub repository.
# 5. Executes the GPU temperature monitoring tool for 300 seconds to collect temperature data during the test.
# This script requires administrative privileges (sudo) to manage system services and Docker operations.


# Stopping necessary services
echo "Stopping services..."
sudo systemctl stop runpod.service docker.socket docker.service

# Starting Docker services
echo "Starting Docker services..."
sudo systemctl start docker.socket docker.service

# Running the GPU stress test Docker container
echo "Running GPU stress test container..."
sudo docker run --detach --gpus all --rm oguzpastirmaci/gpu-burn 300

# Downloading the GPU temperature monitoring tool
echo "Downloading GPU temperature monitoring tool..."
sudo wget https://github.com/jjziets/gddr6_temps/raw/master/nvml_direct_access

# Making the downloaded script executable
echo "Setting execute permissions for the temperature monitoring tool..."
sudo chmod +x nvml_direct_access

# Running the temperature monitoring tool for 300 seconds
echo "Monitoring GPU temperature for 300 seconds..."
sudo timeout 300 ./nvml_direct_access

echo "Operation completed."
sudo systemctl start runpod
