# vasttools

The aim is to setup a list of usble tools that can be used with vastai.

*memory oc*
set the OC of the RTX 3090
It requires the folliwing

sudo apt-get install libgtk-3-0 && sudo apt-get install xinit && sudo apt-get install xserver-xorg-core && sudo update-grub && sudo nvidia-xconfig -a --cool-bits=28 --allow-empty-initial-configuration --enable-all-gpus

https://raw.githubusercontent.com/jjziets/vasttools/main/set_mem.sh


*OC monitor*
setup the monitoring programe that will change the memory oc based on what programe is running. it desinged for RTX3090's and targets ethminer at this stage.
It requires both set_mem.sh and ocmonitor.sh to run in the root.

https://raw.githubusercontent.com/jjziets/vasttools/main/ocminitor
https://raw.githubusercontent.com/jjziets/vasttools/main/set_mem.sh

(crontab -l; echo "@reboot screen -dmS ocmonitor /root/home/jzietsman/ocminitor.sh") | crontab -


