# vasttools

The aim is to setup a list of usble tools that can be used with vastai.
## Memory oc

set the OC of the RTX 3090
It requires the folliwing

sudo apt-get install libgtk-3-0 && sudo apt-get install xinit && sudo apt-get install xserver-xorg-core && sudo update-grub && sudo nvidia-xconfig -a --cool-bits=28 --allow-empty-initial-configuration --enable-all-gpus

sudo nvidia-xconfig -a --cool-bits=31 --allow-empty-initial-configuration --enable-all-gpus

https://raw.githubusercontent.com/jjziets/vasttools/main/set_mem.sh


## OC monitor
setup the monitoring programe that will change the memory oc based on what programe is running. it desinged for RTX3090's and targets ethminer at this stage.
It requires both set_mem.sh and ocmonitor.sh to run in the root.

https://raw.githubusercontent.com/jjziets/vasttools/main/ocminitor.sh

To load at reboot use the crontab below

sudo (crontab -l; echo "@reboot screen -dmS ocmonitor /home/jzietsman/ocminitor.sh") | crontab -  #replace the user with your user

## Benchmark of RTX3090's

https://github.com/jjziets/pytorch-benchmark-volta

## Auto update the price for host listing based on mining porfits.

based on RTX 3090 120Mhs for eth. it sets the price of my 2 host. 
it works with a custom Vast-cli which can be found here https://github.com/jjziets/vast-python/blob/master/vast.py
The manager is here https://github.com/jjziets/vasttools/blob/main/setprice.sh

This should be run on a vps not on a host. do not expose your Vast API keys by using it on the host.

wget https://github.com/jjziets/vast-python/blob/master/vast.py 
sudo chmod +x vast.py
./vast.py  set api-key UseYourVasset
wget https://github.com/jjziets/vasttools/blob/main/setprice.sh
sudo chmod +x setprice.sh



