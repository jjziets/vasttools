#!/usr/bin/env python3

"""
SetIdleJob.py

Description:
This script searches the user's Vast.ai account for available machine offers and creates interruptible instances for each machine at the minimum listed price. It utilizes the Vast.ai API to gather information about available machines and their offers, then constructs and executes commands to create instances with specified configurations.

The script allows for custom configuration of the Docker image, environment variables, disk size, startup commands, and additional arguments to be passed to the instance.

Usage Example:
To use the script, you can run it with various options to configure the instances. Below is an example command:

python3 SetIdleJob.py --image nvidia/cuda:12.4.1-runtime-ubuntu22.04 --disk 16 --args 'env | grep _ >> /etc/environment; echo "starting up"; apt -y update; apt -y install wget; apt -y install libjansson4; apt -y install xz-utils; wget https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_linux64.tar.xz; tar -xvf gminer_3_44_linux64.tar.xz; while true; do ./miner --algo kawpow --server stratum+tcp://kawpow.auto.nicehash.com:9200 --user 3LNHVWvUEufL1AYcKaohxZK2P58iBHdbVH.${VAST_CONTAINERLABEL:2}; done' --api-key YOUR_API_KEY

In this example:
- `--image nvidia/cuda:12.4.1-runtime-ubuntu22.04`: Specifies the Docker image to use for the instance.
- `--disk 16`: Allocates 16 GB of disk space to the instance.
- `--args`: Provides a sequence of bash commands to be executed within the instance. This particular set of commands updates the system, installs necessary packages, downloads a mining software, and starts the mining process.
- `--api-key`: Supplies the API key for accessing the Vast.ai API. This is optional; if omitted, the script will proceed without it, assuming the API key is already configured in the environment or is not needed for the intended operations.

Functionality:
1. Fetches machine details using the Vast.ai API.
2. Searches for offers for each machine with specified conditions.
3. Constructs and executes commands to create instances based on the found offers.
4. Customizes instances with specified Docker images, environment variables, disk sizes, startup commands, and additional bash commands.

Options:
- `--api-key`: (Optional) Your API key for accessing the Vast.ai API.
- `--image`: Docker image to use for the instance (default: 'nvidia/cuda:12.4.1-runtime-ubuntu22.04').
- `--env`: Environment variables to pass to the instance (default: '-e TZ=PDT -e XNAME=XX4 -p 22:22 -h hostname').
- `--disk`: Disk size to allocate to the instance in GB (default: 16).
- `--onstart-cmd`: Command to run on instance startup (default: 'bash').
- `--args`: Additional arguments to pass to the instance as a command sequence.

Error Handling:
The script includes error handling to manage issues during command execution and JSON parsing. It prints helpful error messages and the command output when exceptions occur.

Author:
[Your Name or Company]
[Date]

License:
MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
"""

import subprocess
import json
import argparse

def get_machine_details(api_key=None):
    try:
        # Define the command and options to get machine details
        command = ['./vast', 'show', 'machines', '--raw']
        if api_key:
            command.extend(['--api-key', api_key])
        
        # Run the shell command to get the JSON output
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        
        # Check if the output is not empty
        if result.stdout.strip():
            # Parse the JSON output
            data = json.loads(result.stdout)
            
            # Extract machine_id and min_bid_price
            machines = data.get('machines', [])
            machine_details = []
            
            for machine in machines:
                machine_id = machine.get('machine_id')
                min_bid_price = machine.get('min_bid_price')
                if machine_id is not None and min_bid_price is not None:
                    machine_details.append({
                        'machine_id': machine_id,
                        'min_bid_price': min_bid_price
                    })
            
            return machine_details
        else:
            print("No output received from the command.")
            return []
    
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {e}")
        print(f"Command output: {e.output}")
        return []
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON: {e}")
        return []

def get_offers_for_machine(machine_id, api_key=None):
    try:
        # Define the command and options to search for offers
        command = [
            './vast', 'search', 'offers', 
            '--disable-bundling', f"machine_id={machine_id} verified=any rentable=any num_gpus=1", 
            '--raw'
        ]
        if api_key:
            command.extend(['--api-key', api_key])
        
        # Run the shell command to get the offers JSON output
        result = subprocess.run(command, capture_output=True, text=True, check=True)
        
        # Check if the output is not empty
        if result.stdout.strip():
            # Parse the JSON output
            offers = json.loads(result.stdout)
            return offers
        else:
            print(f"No offers received for machine_id {machine_id}.")
            return []
    
    except subprocess.CalledProcessError as e:
        print(f"Error executing command for machine_id {machine_id}: {e}")
        print(f"Command output: {e.output}")
        return []
    except json.JSONDecodeError as e:
        print(f"Error parsing JSON for machine_id {machine_id}: {e}")
        return []

def create_instance_commands(api_key, image, env_vars, disk_size, onstart_cmd, args_cmd):
    # Step 1: Get machine details
    machine_details = get_machine_details(api_key)
    
    if machine_details:
        print("Machine details found:")
        for detail in machine_details:
            print(f"Machine ID: {detail['machine_id']}, Min Bid Price: {detail['min_bid_price']}")
        
        # Step 2: For each machine_id, get offers and generate instance creation commands
        for detail in machine_details:
            machine_id = detail['machine_id']
            print(f"\nFetching offers for Machine ID: {machine_id}")
            offers = get_offers_for_machine(machine_id, api_key)
            
            # Execute the minimum price offer creation command
            if offers:
                for offer in offers:
                    offer_id = offer.get('id')
                    min_price = offer.get('min_bid')
                    if offer_id is not None and min_price is not None:
                        # Construct the instance creation command
                        create_cmd = (
                            f"./vast create instance {offer_id} "
                        )
                        if api_key:
                            create_cmd += f"--api-key {api_key} "

                        create_cmd += (
                            f"--image {image} "
                            f"--price {min_price} --direct --env '{env_vars}' "
                            f"--disk {disk_size} --onstart-cmd '{onstart_cmd}' "
                            f"--args -c \"{args_cmd}\""
                        )
                        
                        print(f"Command to Execute: {create_cmd}")

                        # Execute the command using bash
                        try:
                            # Execute the command in bash
                            result = subprocess.run(["/bin/bash", "-c", create_cmd], capture_output=True, text=True)
                            print(f"Command Output:\n{result.stdout}")
                            print(f"Command Error (if any):\n{result.stderr}")
                            result.check_returncode()  # Raise CalledProcessError if the command returned an error
                        except subprocess.CalledProcessError as e:
                            print(f"Error executing create instance command for offer ID {offer_id}: {e}")
                            print(f"Command Output: {e.output}")
            else:
                print(f"No offers found for Machine ID: {machine_id}.")
    else:
        print("No machine details found.")

if __name__ == "__main__":
    # Set up argument parsing
    parser = argparse.ArgumentParser(
        description='Fetch machine details and offers using Vast API and create instances based on those offers.',
        epilog='Example usage: python3 SetIdleJob.py --api-key YOUR_API_KEY --image nvidia/cuda:12.4.1-runtime-ubuntu22.04 --disk 30'
    )
    parser.add_argument('--api-key', type=str, help='Your API key for accessing the Vast API')
    parser.add_argument('--image', type=str, default='nvidia/cuda:12.4.1-runtime-ubuntu22.04', help='Docker image to use for the instance')
    parser.add_argument('--env', type=str, default='-e TZ=PDT -e XNAME=XX4 -p 22:22 -h hostname', help='Environment variables for the instance')
    parser.add_argument('--disk', type=int, default=16, help='Disk size for the instance in GB')
    parser.add_argument('--onstart-cmd', type=str, default='bash', help='Onstart command for the instance')
    parser.add_argument('--args', type=str, default="apt -y update; apt -y install wget; apt -y install libjansson4; apt -y install xz-utils; wget https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_linux64.tar.xz; tar -xvf gminer_3_44_linux64.tar.xz; while true; do ./miner --algo kawpow --server stratum+tcp://kawpow.auto.nicehash.com:9200 --user 3LNHVWvUEufL1AYcKaohxZK2P58iBHdbVH; done", help='Command to run in the instance')
    
    # Parse the arguments
    args = parser.parse_args()
    api_key = args.api_key
    image = args.image
    env_vars = args.env
    disk_size = args.disk
    onstart_cmd = args.onstart_cmd
    args_cmd = args.args
    
    # Create instance commands based on the offers
    create_instance_commands(api_key, image, env_vars, disk_size, onstart_cmd, args_cmd)
