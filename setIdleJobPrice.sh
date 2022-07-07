
#!/bin/bash

Instances=($(./vast show instances  | sed 's/|/ /'  | awk '{print $1}' )) # get all the instanses number from vast

unset Instances[0] #delte the first index as it containe ID

for i in "${Instances[@]}"; do
    echo "$i"
        ./vast change bid "$i" --price 0.3 #set the price for each
done




