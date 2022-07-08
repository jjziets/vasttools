#!/bin/bash
#to be used with vastcli in a shell. It will set the price of all the instnases listed in your account to the arg past. 0.3 is $0.3/h/instance. In this case as there is only one gpu per instces.
# Parse and Execute Arguments passed to script                           {{{1
 if (( $(echo "$1 > 0" |bc -l) )); then
        Instances=($(./vast show instances  | sed 's/|/ /'  | awk '{print $1}' )) # get all the instanses number from vast
        unset Instances[0] #delte the first index as it containe ID
        for i in "${Instances[@]}"; do
                ./vast change bid "$i" --price $1 #set the price for each
        done
  else
  echo "usage sudo  ./setIdleJobPrice.sh 0.3"
 fi
