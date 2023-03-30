#!/bin/bash
#to be used with vastcli in a shell. it will sreach for all the systems  unverified systems that meets the createare and starts 10 instances at a time. 
# Parse and Execute Arguments passed to script                           {{{1
# if (( $(echo "$1 > 0" |bc -l) )); then
#        Instances=($(./vast show instances  | sed 's/|/ /'  | awk '{print $1}' )) # get all the instanses number from vast
#        unset Instances[0] #delte the first index as it containe ID
#        for i in "${Instances[@]}"; do
#                ./vast change bid "$i" --price $1 #set the price for each
#        done
#  else
#  echo "usage sudo  ./setIdleJobPrice.sh 0.3"
# fi

pause () {
	echo "Press any key to continue"
	while [ true ] ; do
	read -t 1 -n 1
	if [ $? = 0 ] ; then
		return
	fi
	done
}

 Instances=($(./vast search offers 'verified=false cuda_vers>=12.0  gpu_frac=1 reliability>0.90 direct_port_count>3 pcie_bw>3 inet_down>30 inet_up>30 gpu_ram>7'  -o 'dlperf-'  | sed 's/|/ /'  | awk '{print $1}' )) # get all the instanses number from vast
 unset Instances[0] #delte the first index as it containe ID
	let "cnt=0"
	echo "There are ${#Instances[@]} systems to verify starting first 10"
	pause
        for i in "${Instances[@]}"; do
		printf "$i " #./vast change bid "$i" --price $1 #set the price for each
		./vast create instance "$i"  --image pytorch/pytorch:1.9.0-cuda11.1-cudnn8-runtime --jupyter --direct --disk 20 
		sleep 1
		let "cnt=cnt+1"
		if [ $cnt -eq 10 ]; then 
                        let "remaining_instances=${#Instances[@]}-cnt"
                        printf "\nRemaning instances: $remaining_instances\n"
			pause
			let "cnt=0"
		fi
        done
