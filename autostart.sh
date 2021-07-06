#/bin/bash
#this script sets the pricing of listed host on vast to x1.8 mining of etherum
gpuhash=106
margin=1.05

get_json() {
    local response=$(curl --silent -H "accept: application/json" "$1" -w "\t\t%{http_code}")
    local body=$(echo "$response" | awk -F'\t\t' '{ print $1 }')
    local status_code=$(echo "$response" | awk -F'\t\t' '{ print $2 }' | xargs)

    if [[ "$status_code" != "200" ]]; then
        echo $RED "Failed: $status_code"
        return 2
    fi

    echo $body


}

start_instance() { # arg id id
#	echo "Starting instance $1"
	./vast start instance $1
	echo "return value = $?"
	sleep 1
	while [ $? -gt 1 ]
	do
		echo "Faild to  send command resend"
		sleep 1
		./vast start instance $1
	done
}
stop_instance() { # arg id
#       echo "stop instance $1"
        ./vast stop instance $1
        echo "return value = $?"
        sleep 1
	while [ $? -gt 1 ]
        do
                echo "Faild to  send command resend"
                sleep 1
                ./vast stop instance $1
        done
}


#start_instance 1015169

# get_json "https://whattomine.com/coins/151.json" # | jq .profit

while true
do
	now=$(date +"%T")
	echo "Update pricing : $now"

	rev=$(get_json "https://whattomine.com/coins/151.json?hr=$gpuhash&p=0&fee=0.0&cost=0.1&hcost=0.0&span_br=1h&span_d=24&commit=Calculate" | jq .revenue )

	if [ $? -eq 0 ];
	then
	        rev=$(echo $rev | sed  's/\$//g')
	        rev=$(echo $rev | sed  's/"//g')
		rev=$(bc <<< "scale=2; $rev/24")
	        up_rev=$(bc <<< "scale=2; $rev*1.05*1000") 
               	lo_rev=$(bc <<< "scale=2; $rev*1.2*1000") #when to stop limit. should  be higher as there is a 1.25 fee 
		up_rev=${up_rev%.*}
               	lo_rev=${lo_rev%.*}

		echo "New Price $rev $up_rev $lo_rev"
		if [ $up_rev -gt 400 ];
		then
			start_instance 1015169
			start_instance 1015168
			start_instance 1005154
			start_instance 1005100
			start_instance 995146
		fi

                if [ $lo_rev -lt 400 ];
                then
			echo "stop instnaces"
                        stop_instance 1015169
                        stop_instance 1015168
                        stop_instance 1005154
                        stop_instance 1005100
                        stop_instance 995146
                fi



	fi
	sleep 30
done
