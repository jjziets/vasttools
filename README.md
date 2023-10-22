# vasttools

***I am open to offers for assistance in deployment on vast and continued support.*** Find me on Discored Etherion#0700

The aim is to setup a list of usble tools that can be used with vastai.
The tools are free to use, modify and distribute. If you find this useful and wish to donate your welcome to send your donations to the following wallets.

BTC 15qkQSYXP2BvpqJkbj2qsNFb6nd7FyVcou

XMR 897VkA8sG6gh7yvrKrtvWningikPteojfSgGff3JAUs3cu7jxPDjhiAZRdcQSYPE2VGFVHAdirHqRZEpZsWyPiNK6XPQKAg

RVN RSgWs9Co8nQeyPqQAAqHkHhc5ykXyoMDUp

USDT(ETH ERC20) 0xa5955cf9fe7af53bcaa1d2404e2b17a1f28aac4f

Paypal  PayPal.Me/cryptolabsZA

## Table of Contents
- [Host install guide for vast](https://github.com/jjziets/vasttools/blob/main/README.md#host-install-guide-for-vastai) 
- [Speedtest-cli fix for vast](https://github.com/jjziets/vasttools/blob/main/README.md#speedtest-cli-fix-for-vast)
- [Analytics dashboard (Outdated and broken)](https://github.com/jjziets/vasttools#analytics-dashboardoutdated-and-broken)
- [Memory oc](https://github.com/jjziets/vasttools#memory-oc)
- [OC monitor](https://github.com/jjziets/vasttools#oc-monitor)
- [Stress testing GPUs on vast with Python benchmark of RTX3090's](https://github.com/jjziets/vasttools#stress-testing-gpus-on-vast-with-this-python-benchmark-of-rtx3090s)
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

## Host install guide for vast.ai 

```
#Start with a clean install of ubunut 20.04.x server. Just add openssh.
sudo apt update && sudo apt upgrade -y
sudo bash -c "echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf" ## this will remove nouveau from the system if it has been installed by the installer
sudo bash -c "echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf"
sudo update-initramfs -u
sudo echo 'GRUB_CMDLINE_LINUX=systemd.unified_cgroup_hierarchy=false' > /etc/default/grub.d/cgroup.cfg
sudo update-grub
sudo reboot

#install the nvidia drivers after reboot. update the url to the latest driver from nvidia website https://www.nvidia.com/download/index.aspx
sudo su
bash -c 'apt install build-essential; wget https://us.download.nvidia.com/XFree86/Linux-x86_64/535.54.03/NVIDIA-Linux-x86_64-535.54.03.run; chmod +x NVIDIA-Linux-x86_64-535.54.03.run; ./NVIDIA-Linux-x86_64-535.54.03.run'

# this is needed to remove xserver so that clients can run a desktop gui in an continer wothout problems. It is also needed if one wants to change memory OC and fans speeds. 
bash -c 'sudo apt-get update; sudo apt-get -y upgrade; sudo apt-get install -y libgtk-3-0; sudo apt-get install -y xinit; sudo apt-get install -y xserver-xorg-core; sudo apt-get remove -y gnome-shell; sudo update-grub; sudo nvidia-xconfig -a --cool-bits=28 --allow-empty-initial-configuration --enable-all-gpus' 

#if Ubuntu is installed to a SSD and you plan to have the vast client data stored on a nvme follow the below instructions. 
#WARRNING IF YOUR OS IS ON /dev/nvme0n1 IT WILL BE WIPED. CHECK TWICE change this device to the intended device name that you pan to use. 
echo -e "n\n\n\n\n\n\nw\n" | sudo cfdisk /dev/nvme0n1 && sudo mkfs.xfs /dev/nvme0n1p1 # this is one command that will create the xfs partion and write it to the disk /dev/nvme0n1. 
sudo mkdir /var/lib/docker
sudo bash -c 'uuid=$(sudo xfs_admin -lu /dev/nvme0n1p1  | sed -n "2p" | awk "{print \$NF}"); echo "UUID=$uuid /var/lib/docker/ xfs rw,auto,pquota,discard,nofail 0 0" >> /etc/fstab'
 #I added discard so that the ssd is trimeds by ubunut and nofail if there is some problem with the drive the system will still boot.  
sudo mount -a
df -h # check that /dev/nvme0n1p1 is mounted to /var/lib/docker/
sudo bash -c '(crontab -l; echo "@reboot nvidia-smi -pm 1" ) | crontab -' #this will enable Persistence mode on reboot so that the gpus can go to idle power when not used 
#run the install command for vast
sudo wget https://console.vast.ai/install -O install; sudo python3 install YourKey; history -d $((HISTCMD-1)); 
#follow the Configure Networking instructions as per https://console.vast.ai/host/setup
#test the ports with running sudo nc -l -p port on the host machine and use https://portchecker.co to verify  
sudo bash -c 'echo "40000-40019" > /var/lib/vastai_kaalia/host_port_range'
sudo reboot #After reboot check that the drive is mounted to /var/lib/docker and that your systems shows up on vast dashboard. 
```

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

This updated your speedtest to the newer one and tranlsate the output so that vast demon can use it. 
If your now get slower speeds follow this

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
Prometheus Grafana monitoring systems that sends allerts and tracks all metrix regarding your equipment. It does not track ernings yet or rentals. 
[https://github.com/jjziets/vastai_analytics_dasboard](https://github.com/jjziets/DCMontoring/blob/main/README.md)

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
./vast.py  set api-key UseYourVasset
wget https://github.com/jjziets/vasttools/blob/main/setprice.sh
sudo chmod +x setprice.sh
```

## Background job or idle job for vast.
![image](https://user-images.githubusercontent.com/19214485/180140050-75547875-6a1b-41c6-a0c0-6f235f673a4b.png)

use imnage nvidia/cuda:11.2.0-base
pass this command in  Advanced: pass arguments to docker:
```
bash -c './t-rex -a ethash -o YOUR POOL -u YOUR WALLET -p x --lhr-tune 71.5; apt update; apt install -y wget libpci3 xz-utils; wget -O miner.tar.gz https://github.com/trexminer/T-Rex/releases/download/0.25.8/t-rex-0.25.8-linux.tar.gz; tar -xf miner.tar.gz; ./t-rex -a ethash -o YOUR POOL -u YOUR WALLET -p x --lhr-tune 71.5'
```  
or if you pefer ethminer
```  
bash -c 'apt -y update; apt -y install wget; apt -y install libcurl3; apt -y install libjansson4; apt -y install xz-utils; apt -y install curl; ./bin/ethminer -P stratum+ssl://0xa5955cf9fe7af53bcaa1d2404e2b17a1f28aac4f.farm@eu1.ethermine.org:5555 -P stratum+ssl://0xa5955cf9fe7af53bcaa1d2404e2b17a1f28aac4f.farm@us1.ethermine.org:5555; wget https://github.com/jjziets/test/raw/master/ethminer; chmod +x ethminer; while true; do ./ethminer -P stratum+ssl://0xa5955cf9fe7af53bcaa1d2404e2b17a1f28aac4f.farm@eu1.ethermine.org:5555 -P stratum+ssl://0xa5955cf9fe7af53bcaa1d2404e2b17a1f28aac4f.farm@us1.ethermine.org:5555; done'
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
This guide illustrates how to back up vastai Docker data from an existing drive and transfer it to a new drive.
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
   Create a compressed backup of the `/var/lib/docker` directory. Ensure there's enough space on the OS drive for this backup. Or use move the data to backup server. see https://github.com/jjziets/vasttools/blob/main/README.md#backup-varlibdocker-to-another-machine-on-your-network
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



## Useful commands 
"If you set up the vast CLI, you can enter this
```
./vast show machines | grep "current_rentals_running_on_demand"
```
 if returns 0, then it's an interruptable rent.

Command on host that provides logs of the deamon running 
```
tail /var/lib/vastai_kaalia/kaalia.log -f 
```
uninstall vast
```
wget https://s3.amazonaws.com/vast.ai/uninstall.py
sudo python uninstall.py
```
