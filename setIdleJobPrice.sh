#!/bin/bash
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
