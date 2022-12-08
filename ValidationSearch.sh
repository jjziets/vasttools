#!/bin/bash
#to be used with vastcli in a shell. it will sreach for all the systems  unverified systems that meets the createare and starts 10 instances at a time.

pause () {
        echo "Press any key to continue"
        while [ true ] ; do
        read -t 1 -n 1
        if [ $? = 0 ] ; then
                return
        fi
        done
}

 Instances=($(./vast search offers 'verified=false  gpu_frac=1 reliability > 0.95 direct_port_count > 10 pcie_bw > 4 inet_down > 50 inet_up > 50 gpu_ram > 7'  -o 'dlperf-'  | sed 's/|/ /'  | awk '{print $1}' )) # ge$
 unset Instances[0] #delte the first index as it containe ID
        let "cnt=0"
        echo "There are ${#Instances[@]} systems to verify starting first 10"
        for i in "${Instances[@]}"; do
                printf "$i " #./vast change bid "$i" --price $1 #set the price for each
                ./vast create instance "$i"  --image pytorch/pytorch:1.9.0-cuda11.1-cudnn8-runtime --jupyter-lab --direct --disk 20
                sleep 1
                let "cnt=cnt+1"
                if [ $cnt -eq 10 ]; then
                        pause
                        let "cnt=0"
                fi
        done


