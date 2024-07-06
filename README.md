# vasttools

***I am open to assisting in deployment on Vast.ai,Runpod.io,CUDO Compute and TensorDock, as well as continued support.*** Find me on Discord Etherion#0700

The aim is to set up a list of tools that can be used with Vastai.
The tools are free to use, modify and distribute. If you find this helpful and would like to donate, you can send your donations to the following wallets.

BTC 15qkQSYXP2BvpqJkbj2qsNFb6nd7FyVcou

XMR 897VkA8sG6gh7yvrKrtvWningikPteojfSgGff3JAUs3cu7jxPDjhiAZRdcQSYPE2VGFVHAdirHqRZEpZsWyPiNK6XPQKAg

RVN RSgWs9Co8nQeyPqQAAqHkHhc5ykXyoMDUp

USDT(ETH ERC20) 0xa5955cf9fe7af53bcaa1d2404e2b17a1f28aac4f

Paypal  PayPal.Me/cryptolabsZA

## Table of Contents
- [Host install guide for vast](https://github.com/jjziets/vasttools/blob/main/README.md#host-install-guide-for-vastai)
- [Self-verification test](https://github.com/jjziets/vasttools/blob/main/README.md#self-verification-test)
- [Speedtest-cli fix for vast](https://github.com/jjziets/vasttools/blob/main/README.md#speedtest-cli-fix-for-vast)
- [Analytics dashboard](https://github.com/jjziets/vasttools?tab=readme-ov-file#analytics-dashboard)
- [nvml-error-when-using-ubuntu-22-and-24](https://github.com/jjziets/vasttools/blob/main/README.md#addressing-nvml-error-when-using-ubuntu-22-and-24)
- [Remove Pressitent red error messages](https://github.com/jjziets/vasttools/blob/main/README.md#remove-pressitent-red-error-messages)
- [Memory oc](https://github.com/jjziets/vasttools#memory-oc)
- [OC monitor](https://github.com/jjziets/vasttools#oc-monitor)
- [Stress testing GPUs on vast with Python benchmark of RTX3090's](https://github.com/jjziets/vasttools?tab=readme-ov-file#stress-testing-gpus-on-vast-with-this-python-benchmark-of-rtx3090s)
- [Telegram-Vast-Uptime-Bot](#telegram-vast-uptime-bot)
- [Auto update the price for host listing based on mining profits](#auto-update-the-price-for-host-listing-based-on-mining-profits)
- [Background job or idle job for vast](#background-job-or-idle-job-for-vast)
- [Setting fan speeds if you have a headless system](https://github.com/jjziets/vasttools/blob/main/README.md#setting-fans-speeds-if-you-have-headless-system)
- [Remove unattended-upgrades package](#remove-unattended-upgrades-package)
- [How to update a host](#how-to-update-a-host)
- [How to move your vast docker driver to another drive](#how-to-move-your-vast-docker-driver-to-another-drive)
- [Backup varlibdocker to another machine on your network](https://github.com/jjziets/vasttools/blob/main/README.md#backup-varlibdocker-to-another-machine-on-your-network)
- [Connecting to running instance with VNC to see applications GUI](#connecting-to-running-instance-with-vnc-to-see-applications-gui)
- [Setting up 3D accelerated desktop in web browser on vastai](https://github.com/jjziets/vasttools#setting-up-3d-accelerated-desktop-in-webbrowser-on-vastai)
- [Useful commands](#useful-commands)
- [How to set up a docker registry for the systems on your network](https://github.com/jjziets/vasttools/blob/main/README.md#how-to-set-up-a-docker-registry-for-the-systems-on-your-network)

## Host install guide for vast.ai 

```
#Start with a clean install of ubuntu 22.04.x HWE Kernal server. Just add openssh.
sudo apt update && sudo apt upgrade -y && sudo apt dist-upgrade -y && sudo apt install update-manager-core -y
#if you did not install HWE kernels do the following  
sudo apt install --install-recommends linux-generic-hwe-22.04 -y
sudo reboot

#install the drivers.
sudo apt install build-essential -y
sudo add-apt-repository ppa:graphics-drivers/ppa -y
sudo apt update
# to search for available NVIDIA drivers: use this command 
sudo apt search nvidia-driver | grep nvidia-driver | sort -r
sudo apt install nvidia-driver-555  -y    # assuming the latest is 555

#Remove unattended-upgrades Package so that the dirver don't upgrade when you have clients
sudo apt purge --auto-remove unattended-upgrades -y
sudo systemctl disable apt-daily-upgrade.timer
sudo systemctl mask apt-daily-upgrade.service 
sudo systemctl disable apt-daily.timer
sudo systemctl mask apt-daily.service

# This is needed to remove xserver and genome if you started with ubunut desktop. clients can't run a desktop gui in an continer wothout if you have a xserver. 
bash -c 'sudo apt-get update; sudo apt-get -y upgrade; sudo apt-get install -y libgtk-3-0; sudo apt-get install -y xinit; sudo apt-get install -y xserver-xorg-core; sudo apt-get remove -y gnome-shell; sudo update-grub; sudo nvidia-xconfig -a --cool-bits=28 --allow-empty-initial-configuration --enable-all-gpus' 


#if Ubuntu is installed to a SSD and you plan to have the vast client data stored on a nvme follow the below instructions. 
#WARRNING IF YOUR OS IS ON /dev/nvme0n1 IT WILL BE WIPED. CHECK TWICE change this device to the intended device name that you pan to use.

# this is one command that will create the xfs partion and write it to the disk /dev/nvme0n1. 
echo -e "n\n\n\n\n\n\nw\n" | sudo cfdisk /dev/nvme0n1 && sudo mkfs.xfs /dev/nvme0n1p1 
sudo mkdir /var/lib/docker

#I added discard so that the ssd is trimeds by ubunut and nofail if there is some problem with the drive the system will still boot.  
sudo bash -c 'uuid=$(sudo xfs_admin -lu /dev/nvme0n1p1  | sed -n "2p" | awk "{print \$NF}"); echo "UUID=$uuid /var/lib/docker/ xfs rw,auto,pquota,discard,nofail 0 0" >> /etc/fstab'

sudo mount -a

# check that /dev/nvme0n1p1 is mounted to /var/lib/docker/
df -h

#this will enable Persistence mode on reboot so that the gpus can go to idle power when not used 
sudo bash -c '(crontab -l; echo "@reboot nvidia-smi -pm 1" ) | crontab -' 

#run the install command for vast
sudo apt install python3 -y
sudo wget https://console.vast.ai/install -O install; sudo python3 install YourKey; history -d $((HISTCMD-1)); 

echo 'GRUB_CMDLINE_LINUX=systemd.unified_cgroup_hierarchy=false' > /etc/default/grub.d/cgroup.cfg
update-grub

#if you get  nvml error then run this 
sudo wget https://raw.githubusercontent.com/jjziets/vasttools/main/nvml_fix.py
sudo python3 nvml_fix.py
sudo reboot

#follow the Configure Networking instructions as per https://console.vast.ai/host/setup

#test the ports with running sudo nc -l -p port on the host machine and use https://portchecker.co to verify  
sudo bash -c 'echo "40000-40019" > /var/lib/vastai_kaalia/host_port_range'
sudo reboot 

#After reboot, check that the drive is mounted to /var/lib/docker and that your systems show up on the vast dashboard.
df -h # look for /var/lib/docker mount
sudo systemctl status vast 
sudo systemctl status docker

```
## Self verification test 
You can run the following test to ensure your new machine will be on the shortlist for verification testing. If you pass, it means that there is a high chance that your machine will be eligible for verification  

### Overview

The `autoverify_machineid.sh` script is part of a suite of tools designed to automate the testing of machines on the Vast.ai marketplace. This script specifically tests a single machine to determine if it meets the minimum requirements necessary for further verification.

### Prerequisites

Before you start using `./autoverify_machineid.sh`, ensure you have the following:

1. **Vast.ai Command Line Interface (vastcli)**: This tool is used to interact with the Vast.ai platform.
2. **Vast.ai **: The machine should be listed on the vast marketplace.
3. **Ubuntu OS**: The scripts are designed to run on Ubununt 20.04 or newer.

### Setup and Installation

1. **Download and Setup `vastcli`**:
   - Download the Vast.ai CLI tool using the following command:
     ```bash
     wget https://raw.githubusercontent.com/vast-ai/vast-python/master/vast.py -O vast
     chmod +x vast
     ```

   - Set your Vast.ai API key:
     ```bash
     ./vast set api-key 6189d1be9f15ad2dced0ac4e3dfd1f648aeb484d592e83d13aaf50aee2d24c07
     ```

2. **Download autoverify_machineid.sh**:
   - Use wget to download autoverify_machineid.sh to your local machine:
     ```bash
     wget https://github.com/jjziets/VastVerification/releases/download/0.3-beta/autoverify_machineid.sh
     ```
     
3. **Make Scripts Executable**:
   - Change the permissions of the main scripts to make them executable:
     ```bash
     chmod +x autoverify_machineid.sh
     ```

### Using `./autoverify_machineid.sh`

1. **Check Machine Requirements**:
   - The `./autoverify_machineid.sh` script is designed to test if a single machine meets the minimum requirements for verification. This is useful for hosts who want to verify their own machines.
   - To test a specific machine by its `machine_id`, use the following command:
     ```bash
     ./autoverify_machineid.sh <machine_id>
     ```
     Replace `<machine_id>` with the actual ID of the machine you want to test.

2. **To Ignore Requirements Check**:
    ```bash
    ./autoverify_machineid.sh --ignore-requirements <machine_id>
    ```
    This command runs the tests for the machine, regardless of whether it meets the minimum requirements.

### Monitoring and Results

- **Progress and Results Logging**:
  - The script logs the progress and results of the tests.
  - Successful results and machines that pass the requirements will be logged in `Pass_testresults.log`.
  - Machines that do not meet the requirements or encounter errors during testing will be logged in `Error_testresults.log`.

- **Understanding the Logs**:
  - **`Pass_testresults.log`**: This file contains entries for machines that successfully passed all tests.
  - **`Error_testresults.log`**: This file contains entries for machines that failed to meet the minimum requirements or encountered errors during testing.

### Example Usage

Here’s how you can run the `autoverify_machineid.sh` script to test a machine with `machine_id` 10921:

```bash
./autoverify_machineid.sh 10921
```

### Troubleshooting

- **API Key Issues**: Ensure your API key is correctly set using `./vast set api-key <your-api-key>`.
- **Permission Denied**: If you encounter permission issues, make sure the script files have executable permissions (`chmod +x <script_name>`).
- **Connection Issues**: Verify your network connection and ensure the Vast.ai CLI can communicate with the Vast.ai servers.

### Summary

By following this guide, you will be able to use the `./autoverify_machineid.sh` script to test individual machines on the Vast.ai marketplace. This process helps ensure that machines meet the required specifications for GPU and system performance, making them candidates for further verification and use in the marketplace.


## Speedtest-cli fix for vast
If you are having problems with your machine not showing its upload and download speed correctly. 
combined
```
bash -c "sudo apt-get install curl -y && sudo curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash && sudo apt-get install speedtest -y && sudo apt install python3 -y && cd /var/lib/vastai_kaalia/latest && sudo mv speedtest-cli speedtest-cli.old && sudo wget -O speedtest-cli https://raw.githubusercontent.com/jjziets/vasttools/main/speedtest-cli.py && sudo chmod +x speedtest-cli"
```
or step by step
```
sudo apt-get install curl
sudo curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest -y
sudo apt install python3 -y
cd /var/lib/vastai_kaalia/latest
sudo mv speedtest-cli speedtest-cli.old
sudo wget -O speedtest-cli https://raw.githubusercontent.com/jjziets/vasttools/main/speedtest-cli.py
sudo chmod +x speedtest-cli
```

This updated your speed test to the newer one and translated the output so that Vast Demon can use it. 
If you now get slower speeds, follow this

```
## If migrating from prior bintray install instructions please first...
# sudo rm /etc/apt/sources.list.d/speedtest.list
# sudo apt-get update
# sudo apt-get remove speedtest -y
## Other non-official binaries will conflict with Speedtest CLI
# Example how to remove using apt-get
# sudo apt-get remove speedtest-cli
sudo apt-get install curl
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.deb.sh | sudo bash
sudo apt-get install speedtest
```


## Analytics dashboard
![image](https://github.com/jjziets/vasttools/assets/19214485/4107d6a2-6a4a-4edd-973d-a733d8430071)

Prometheus Grafana monitoring systems, send alerts and track all metrics regarding your equipment and also track earnings and rentals. 
https://github.com/jjziets/DCMontoring

## Addressing nvml error when using Ubuntu 22 and 24
run the script below if you have a problem with vast installer on 22,24 and nvml error
this script is based on Bo26fhmC5M so credit go to him
```bash
sudo wget https://raw.githubusercontent.com/jjziets/vasttools/main/nvml_fix.py
sudo python nvml_fix.py
 
```

## Remove Pressitent red error messages
if you have a red error message on your machine that you have confirmed has been addressed. It might help to delete /var/lib/vastai_kaalia/kaalia.log and reboot
```
sudo rm /var/lib/vastai_kaalia/kaalia.log
sudo systemctl restart vastai
```

## Memory oc

set the OC of the RTX 3090
It requires the following

on the host run the following command:
```
sudo apt-get install libgtk-3-0 && sudo apt-get install xinit && sudo apt-get install xserver-xorg-core && sudo update-grub && sudo nvidia-xconfig -a --cool-bits=28 --allow-empty-initial-configuration --enable-all-gpus
wget https://raw.githubusercontent.com/jjziets/vasttools/main/set_mem.sh
sudo chmod +x set_mem.sh
sudo ./set_mem.sh 2000 # this will set the memory OC to +1000mhs on all the gpus. You can use 3000 on some gpu's which will give 1500mhs OC. 
```

## OC monitor
setup the monitoring program that will change the memory oc based on what programe is running. it designed for RTX3090's and targets ethminer at this stage.
It requires both set_mem.sh and ocmonitor.sh to run in the root.

```
wget https://raw.githubusercontent.com/jjziets/vasttools/main/ocminitor.sh
sudo chmod +x ocminitor.sh
sudo ./ocminitor.sh # I suggest running this in tmux or screen so that when you close the ssh connetion. It looks for ethminer and if it finds it it will set the oc based on your choice. you can also set powerlimits with nvidia-smi -pl 350 
```

Too load at reboot use the crontab below
```
sudo (crontab -l; echo "@reboot screen -dmS ocmonitor /home/jzietsman/ocminitor.sh") | crontab -  #replace the user with your user
```

## Stress testing gpus on vast with this python Benchmark of RTX3090's
Mining does not stress your system the same as python work loads do, so this is a good test to run as well. 
https://github.com/jjziets/pytorch-benchmark-volta

a full suit of stress tests can be found docker image jjziets/vastai-benchmarks:latest 
in folder /app/
```
stress-ng - CPU stress
stress-ng - Drive stress
stress-ng - Memory stress
sysbench - Memory latency and speed benchmark
dd - Drive speed benchmark
Hashcat - Benchmark
bandwithTest - GPU bandwith benchmark
pytorch - Pytorch DL benchmark
```
#test or bash inteface
```
sudo docker run --shm-size 1G --rm -it --gpus all jjziets/vastai-benchmarks /bin/bash
apt update && apt upgrade -y
./benchmark.sh
```
#Run using default settings
Results are saved to ./output.

```
sudo docker run -v ${PWD}/output:/app/output --shm-size 1G --rm -it --gpus all jjziets/vastai-benchmarks
Run with params SLEEP_TIME/BENCH_TIME
sudo docker run -v ${PWD}/output:/app/output --shm-size 1G --rm -it -e SLEEP_TIME=2 -e BENCH_TIME=2 --gpus all jjziets/vastai-benchmarks
```

*based on leona / vast.ai-tools

## Telegram-Vast-Uptime-Bot
This is a set of scripts for monitoring machine crashes. Run the client on your vast machine and the server on a remote one. You get notifications on Telegram if no heartbeats are sent within the timeout (default 12 seconds).
https://github.com/jjziets/Telegram-Vast-Uptime-Bot

## Auto update the price for host listing based on mining profits.

based on RTX 3090 120Mhs for eth. it sets the price of my 2 host. 
it works with a custom Vast-cli which can be found here https://github.com/jjziets/vast-python/blob/master/vast.py
The manager is here https://github.com/jjziets/vasttools/blob/main/setprice.sh

This should be run on a vps not on a host. do not expose your Vast API keys by using it on the host.
```
wget https://github.com/jjziets/vast-python/blob/master/vast.py 
sudo chmod +x vast.py
./vast.py set api-key UseYourVasset
wget https://github.com/jjziets/vasttools/blob/main/setprice.sh
sudo chmod +x setprice.sh
```

## Background job or idle job for vast.
The best way to manage your idle job is via the vast cli. To my knowledge, the GUI set job is broken. So to set an idle job follow the following steps. You will need to download the vast cli and run the following commands.
The idea is to rent yourself as an interruptible job. The vast cli allows you to set one idle job for all the GPUs or one GPU per instance. You can also set the SSH connection method or any other method.
Go to  https://cloud.vast.ai/cli/ and install your cli flavour. 

setup your account key so that you can use the vast cli. you get this key from your account page.
```
./vast set api-key API_KEY 
```
You can use my SetIdleJob.py scrip to setup your idle job based on the minimum price set on your machines.
```
wget https://github.com/jjziets/vasttools/blob/main/SetIdleJob.py
```

Here is an example of how I mine to nicehash

```
python3 SetIdleJob.py --args 'env | grep _ >> /etc/environment; echo "starting up"; apt -y update; apt -y install wget; apt -y install libjansson4; apt -y install xz-utils; wget https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_linux64.tar.xz; tar -xvf gminer_3_44_linux64.tar.xz; while true; do ./miner --algo kawpow --server stratum+tcp://kawpow.auto.nicehash.com:9200 --user 3LNHVWvUEufL1AYcKaohxZK2P58iBHdbVH.${VAST_CONTAINERLABEL:2}; done'
```
Or the full command if you don't want to use the defaults
```
python3 SetIdleJob.py --image nvidia/cuda:12.4.1-runtime-ubuntu22.04 --disk 16 --args 'env | grep _ >> /etc/environment; echo "starting up"; apt -y update; apt -y install wget; apt -y install libjansson4; apt -y install xz-utils; wget https://github.com/develsoftware/GMinerRelease/releases/download/3.44/gminer_3_44_linux64.tar.xz; tar -xvf gminer_3_44_linux64.tar.xz; while true; do ./miner --algo kawpow --server stratum+tcp://kawpow.auto.nicehash.com:9200 --user 3LNHVWvUEufL1AYcKaohxZK2P58iBHdbVH.${VAST_CONTAINERLABEL:2}; done' --api-key b149b011a1481cd852b7a1cf1ccc9248a5182431b23f9410c1537fca063a68b1

```

Alternatively, you can rent yourself with the following command and then log in and load what you want to run. Make sure to add your process to onstart.sh 
to rent your self first find your machine with he machine id
```
./vast search offers "machine_id=14109 verified=any gpu_frac=1 " # gpu_frac=1 will give you the instance with all the gpus. 
```
or
```
./vast search offers -i "machine_id=14109 verified=any  min_bid>0.1 num_gpus=1" # it will give you the instance with one GPU
```
Once you have the offe_id. and in this case, the search with a -i switch will give you an interruptible instance_id

Let's assume you want to mine with lolminer 

```
./vast create instance 9554646 --price 0.2 --image nvidia/cuda:12.0.1-devel-ubuntu20.04   --env '-p 22:22' --onstart-cmd 'bash -c "apt  -y update; apt  -y install wget; apt  -y install libjansson4; apt -y install xz-utils; wget https://github.com/Lolliedieb/lolMiner-releases/releases/download/1.77b/lolMiner_v1.77b_Lin64.tar.gz; tar -xf lolMiner_v1.77b_Lin64.tar.gz -C ./; cd 1.77b; ./lolMiner --algo ETCHASH --pool etc.2miners.com:1010 --user 0xYour_Wallet_Goes_Here.VASTtest"'  --ssh  --direct --disk 100 
```
it will start the instance on price 0.2. 
```
./vast show instances # will give you the list of instance
./vast change bid 9554646  --price 0.3 # This will change the price to 0.3 for the instance 
```


## setting fans speeds if you have headless system.
Here is a repo with two programs and a few scripts that you can use to manage your fans
https://github.com/jjziets/GPU_FAN_OC_Manager/tree/main

```  
bash -c "wget https://github.com/jjziets/GPU_FAN_OC_Manager/raw/main/set_fan_curve; chmod +x set_fan_curve; CURRENT_PATH=\$(pwd); nohup bash -c \"while true; do \$CURRENT_PATH/set_fan_curve 65; sleep 1; done\" > output.txt & (crontab -l; echo \"@reboot screen -dmS gpuManger bash -c 'while true; do \$CURRENT_PATH/set_fan_curve 65; sleep 1; done'\") | crontab -"

```  



## Remove unattended-upgrades Package
If your system updates while vast is running or even worse when a client is renting you then you might get de-verified or banned. It's advised to only update when the system is unrented and delisted. best would be to set an end date of your listing and conduct updates and upgrades at that stage. 
to stop unattended-upgrades run the following commands.
```
sudo apt purge --auto-remove unattended-upgrades -y
sudo systemctl disable apt-daily-upgrade.timer
sudo systemctl mask apt-daily-upgrade.service 
sudo systemctl disable apt-daily.timer
sudo systemctl mask apt-daily.service
```

## How to update a host.
When the system is idle and delisted run the following commands. vast demon and docker services are stopped. It is also a good idea to upgrade Nvidia drivers like this. If you don't and the upgrades brakes a package you might get de-verifyed or even banned from vast. 
```
bash -c ' sudo systemctl stop vastai; sudo systemctl stop docker.socket; sudo systemctl stop docker; sudo apt update; sudo apt upgrade -y; sudo systemctl start docker.socket ; sudo systemctl start docker; sudo systemctl start vastai'
```

## How to move your vast docker driver to another drive
This guide illustrates how to back up vastai Docker data from an existing drive and transfer it to a new drive . in this case a raid driver /dev/md0
### Prerequisites:
- No clients are running and that you are un listed from the vast market.
- Docker data exists on the current drive.
### Steps:
1. **Install required tools**:
   ```
   sudo apt install pv pixz
   ```
2. **Stop and disable relevant services**:
   ```
   sudo systemctl stop vastai docker.socket docker
   sudo systemctl disable vastai docker.socket docker
   ```
3. **Backup the Docker directory**:
   Create a compressed backup of the `/var/lib/docker` directory. Ensure there's enough space on the OS drive for this backup. Or move the data to backup server. see https://github.com/jjziets/vasttools/blob/main/README.md#backup-varlibdocker-to-another-machine-on-your-network
   ```
   sudo tar -c -I 'pixz -k -1' -f ./docker.tar.pixz /var/lib/docker | pv  #you can change ./ to a destination directory
   ```
   Note: `pixz` utilizes multiple cores for faster compression.
4. **Unmount the Docker directory**:
   If you're planning to shut down and install a new drive:
   ```
   sudo umount /var/lib/docker
   ```
5. **Update `/etc/fstab`**:
   Disable auto-mounting of the current Docker directory at startup to prevent boot issues:
   ```
   sudo nano /etc/fstab
   ```
   Comment out the line associated with `/var/lib/docker` by adding a `#` at the start of the line.
6. **Partition the New Drive**:
   (Adjust the device name based on your system. The guide uses `/dev/md0` for RAID and `/dev/nvme0n1` for NVMe drives as examples.)
   ```
   sudo cfdisk /dev/md0
   ```
7. **Format the new partition with XFS**:
   ```
   sudo mkfs.xfs -f /dev/md0p1
   ```
8. **Retrieve the UUID**:
   You'll need the UUID for updating `/etc/fstab`.
   ```
   sudo xfs_admin -lu /dev/md0p1
   ```
9. **Update `/etc/fstab` with the New Drive**:
   ```
   sudo nano /etc/fstab
   ```
   Add the following line (replace the UUID with the one you retrieved):
   ```
   UUID="YOUR_UUID_HERE" /var/lib/docker xfs rw,auto,pquota,discard,nofail 0 0
   ```
10. **Mount the new partition**:
    ```
    sudo mount -a
    ```
    Confirm the mount:
    ```
    df -h
    ```
    Ensure `/dev/md0p1` (or the appropriate device name) is mounted to `/var/lib/docker`.
11. **Restore the Docker data**:
    Navigate to the root directory:
    ```bash
    cd /
    ```
    Decompress and restore:  Ensure to change the user to the relevent name 
    ```
    sudo cat /home/user/docker.tar.pixz | pv | sudo tar -x -I 'pixz -d -k'
    ```
12. **Enable services**:
    ```
    sudo systemctl enable vastai docker.socket docker
    ```
13. **Reboot**:
    ```
    sudo reboot
    ```
### Post-Reboot:
Check if the desired drive is mounted to `/var/lib/docker` and ensure `vastai` is operational.

## Backup `/var/lib/docker` to Another Machine on Your Network
If you're looking to migrate your Docker setup to another machine, whether for replacing the drive or setting up a RAID, follow this guide. For this example, we'll assume the backup server's IP address is `192.168.1.100`.

### Setup on the Backup Server:
1. **Temporarily Enable Root SSH Login**:
   It's essential to ensure uninterrupted SSH communication during the backup process, especially when transferring large files like compressed Docker data.
   a. Open the SSH configuration:
   ```
   sudo nano /etc/ssh/sshd_config
   ```
   b. Locate and change the line:
   ```
   PermitRootLogin no
   ```
   to:
   ```
   PermitRootLogin yes
   ```
   c. Reload the SSH configuration:
   ```
   sudo systemctl restart sshd
   ```
### Setup on the Source Machine:
2. **Generate an SSH Key and Transfer it to the Backup Server**:
   a. Create the SSH key:
   ```
   sudo ssh-keygen
   ```
   b. Copy the SSH key to the backup server:
   ```
   sudo ssh-copy-id -i ~/.ssh/id_rsa root@192.168.1.100
   ```
3. **Disable Root Password Authentication**:
   Ensure only the SSH key can be used for root login, enhancing security.
   a. Modify the SSH configuration:
   ```
   sudo nano /etc/ssh/sshd_config
   ```
   b. Change the line to:
   ```bash
   PermitRootLogin prohibit-password
   ```
   c. Reload the SSH configuration:
   ```
   sudo systemctl restart sshd
   ```
4. **Preparation for Backup**:
   Before backing up, ensure relevant services are halted:
   ```
   sudo systemctl stop docker.socket
   sudo systemctl stop docker
   sudo systemctl stop vastai
   sudo systemctl disable vastai 
   sudo systemctl disable docker.socket 
   sudo systemctl disable docker
   ```
5. **Backup Procedure**:
   This procedure compresses the `/var/lib/docker` directory and transfers it to the backup server.
   a. Switch to the root user and install necessary tools:
   ```
   sudo su
   apt install pixz
   apt install pv
   ```
   It mght be a good idea to run the backup command in tmux or screen so that if you lose ssh connecton the process will finish.
   b. Perform the backup:
   ```
   tar -c -I 'pixz -k -0' -f - /var/lib/docker | pv | ssh root@192.168.1.100 "cat > /mnt/backup/machine/docker.tar.pixz"
   ```
### Restoration:
6. **Restoring the Backup**:
   Make sure your new drive is mounted at `/var/lib/docker`.
   a. Switch to the root user:
   ```
   sudo su
   ```
   b. Restore from the backup:
   ```
   cd /
   ssh root@192.168.1.100 "cat /mnt/backup/machine/docker.tar.pixz" | pv | sudo tar -x -I 'pixz -d -k'
   ```
7. **Reactivate Services**:
   ```
   sudo systemctl enable vastai 
   sudo systemctl enable docker.socket 
   sudo systemctl enable docker
   sudo reboot
   ```
**Post-reboot**: Ensure your target drive is mounted to `/var/lib/docker` and that `vastai` is operational.

## Connecting to running instance with vnc to see applications gui 

Using a instance with open ports 
If display is color depth is 16 not 16bit try another vnc viewer. [TightVNC](https://www.tightvnc.com/download.php) worked for me on windows 

first tell vast to allow a port to be assinged. use the -p 8081:8081 and tick the direct command.

![image](https://user-images.githubusercontent.com/19214485/180969969-569add29-1d3b-4293-96a8-b808b5979987.png)

find a host with open ports and then rent it. preferbly on demand. go to the client instances page and wait for the connect button

![image](https://user-images.githubusercontent.com/19214485/180970637-b92743c1-8924-481a-92be-d5905c6baef8.png)

use ssh to connect to the instances. 
![image](https://user-images.githubusercontent.com/19214485/180970916-b04966ee-4b70-4d2d-beff-935245e3e094.png)

run the below commands. the second part can be placed in the onstart.sh to run on restart 

```
bash -c 'apt-get update; apt-get -y upgrade;  apt-get install -y x11vnc; apt-get install -y xvfb; apt-get install -y firefox;apt-get install -y xfce4;apt-get install -y  xfce4-goodies'


export DISPLAY=:20
Xvfb :20 -screen 0 1920x1080x16 &
x11vnc -passwd TestVNC -display :20 -N -forever -rfbport 8081 &
startxfce4
```
To connect use the ip of the host and the port that was provided. In this case  it is 400010
![image](https://user-images.githubusercontent.com/19214485/180971332-16962c8d-a655-44ec-a1a7-9e8308f5f9cd.png)

![image](https://user-images.githubusercontent.com/19214485/180971471-b18ef371-c508-4e35-b55e-07605bef29b5.png)

then enjoy the destkop. sadly this is not hardware accelarted. so no games will work 


## Setting up 3D accelerated Desktop in webbrowser on vastai
We will be using ghcr.io/ehfd/nvidia-glx-desktop:latest
![image](https://user-images.githubusercontent.com/19214485/203529896-d0e68c96-e2d5-4171-8a57-5ce1fefe3394.png)
use this env paramters

```
-e TZ=UTC -e SIZEW=1920 -e SIZEH=1080 -e REFRESH=60 -e DPI=96 -e CDEPTH=24 -e VIDEO_PORT=DFP -e PASSWD=mypasswd -e WEBRTC_ENCODER=nvh264enc -e BASIC_AUTH_PASSWORD=mypasswd -p 8080:8080

```
find a system that has open ports
![image](https://user-images.githubusercontent.com/19214485/203530107-67ac5b89-7014-4b37-b646-4a15fa9da6a1.png)

when done loading click open
![image](https://user-images.githubusercontent.com/19214485/203530801-a17b89c5-2fc1-4780-b262-77183918f8fe.png)

username is **user** and password is what you set **mypasswd** in this case
![image](https://user-images.githubusercontent.com/19214485/203530916-c655dd69-a0dc-4225-b0a0-fac5469cd44c.png)

hit start
![image](https://user-images.githubusercontent.com/19214485/203531080-cb475042-ebf9-45a4-8713-4ed618a7c16c.png)

3D accelerated desktop environment in a web browser
![image](https://user-images.githubusercontent.com/19214485/203531203-14415d38-1db2-43f8-9ec1-dfe68a61206b.png)

## How to set up a Docker Registry for the systems on your network. 
This will reduce the number of pull requests from your public IP. Docker is restricted to 100 pulls per 6h for unanonymous login, and it can speed up the startup time for your rentals.
This guide provides instructions on how to set up a Docker registry server using Docker Compose, as well as configuring Docker clients to use this registry.
Prerequisites
Docker and Docker Compose are installed on the server that has a lot of fast storage on your local LAN.
Docker is installed on all client machines.

Setting Up the Docker Registry Server
install docker-compose if you have not already. 

```
sudo su
curl -L "https://github.com/docker/compose/releases/download/v2.24.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
apt-get update && sudo apt-get install -y gettext-base
```
Create a docker-compose.yml file:
Create a file named docker-compose.yml on your server with the following content:
```
version: '3'
services:
  registry:
    restart: unless-stopped
    image: registry:2
    ports:
      - 5000:5000
    environment:
      - REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io
      - REGISTRY_STORAGE_DELETE_ENABLED="true"
    volumes:
      - data:/var/lib/registry
volumes:
  data:
```
This configuration sets up a Docker registry server running on port 5000 and uses a volume named data for storage.
Start the Docker Registry:

Run the following command in the directory where your docker-compose.yml file is located:
```
sudo docker-compose up -d
```
This command will start the Docker registry in detached mode.
## Configuring Docker Clients
To configure Docker clients to use the registry, follow these steps on each client machine:
Edit the Docker Daemon Configuration:
Run the following command to add your Docker registry as a mirror in the Docker daemon configuration:
```
echo '{
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "registry-mirrors": ["http://192.168.100.7:5000"]
}' | sudo tee /etc/docker/daemon.json
```
If space is limisted you can run this cleanup task as a cron job
```
wget https://github.com/jjziets/vasttools/raw/main/cleanup-registry.sh
chmod +x cleanup-registry.sh
```
add this like to your corntab -e 

```
0 * * * * /path/to/cleanup-registry.sh

```
replace /path/to/ with where the file is saved. 

Replace 192.168.100.7:5000 with the IP address and port of your Docker registry server.
Restart Docker Daemon:
```
sudo systemctl restart docker
```
Verifying the Setup
To verify that the Docker registry is set up correctly, you can try pulling an image from the registry:
```
docker pull 192.168.100.7:5000/your-image
```
Replace 192.168.100.7:5000/your-image with the appropriate registry URL and image name.



## Useful commands 
"If you set up the vast CLI, you can enter this
```
./vast show machines | grep "current_rentals_running_on_demand"
```
 if returns 0, then it's an interruptable rent.

Command on a host that provides logs of the deamon running 
```
tail /var/lib/vastai_kaalia/kaalia.log -f 
```
uninstall vast
```
wget https://s3.amazonaws.com/vast.ai/uninstall.py
sudo python uninstall.py
```
