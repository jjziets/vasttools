#/bin/bash
#this script sets the pricing of listed host on vast to x1.8 mining of etherum
gpuhash=120
OD_margin=1.9
BJ_margin=1.35
contract_lenght=20 # lenght of  days a contract 

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
set_bj_instance() { # arg id price
       echo "set instance $1 to $2"
        ./vast change bid $1 --price $2
#       echo "return value = $?"
        sleep 2
        while [ $? -gt 1 ]
        do
                echo "Faild to  send command resend"
                sleep 1
                       ./vast change bid $1 --price $2
        done
}


# get_json "https://whattomine.com/coins/151.json" # | jq .profit

while true
do
now=$(date +"%T")
echo "Update pricing : $now"

wtm_price=$(get_json "https://whattomine.com/coins/151.json?hr=$gpuhash&p=420.0&fee=0.0&cost=0.1&hcost=0.0&span_br=1h&span_d=24&commit=Calculate" | jq .revenue )


if [ $? -eq 0 ]
then 

        wtm_price=$(echo $wtm_price | sed  's/\$//g')
        wtm_price=$(echo $wtm_price | sed  's/"//g')


        rev=$(bc <<< "scale=2; $wtm_price/24*$OD_margin")
        echo "New On Demand Price $rev"

#        ./vast list machine 3451 --price_gpu $rev --price_disk 1 --price_inetu 0.02 --price_inetd 0.02 --min_chunk 6
#        sleep 1
#	enddate =$(date "+%s")
#	echo $enddate
	enddate=$(date +"%s")
	enddate=$(($enddate + $contract_lenght * 20 * 60 * 60)) # $contract_lenght
	echo "end date = $enddate"


        ./vast list machine 2787  --price_gpu $rev --price_disk 2 --price_inetu 0.02 --price_inetd 0.02 --min_chunk 4 --end_date $enddate 

        sleep 2

        ./vast list machine 3129  --price_gpu $rev --price_disk 2 --price_inetu 0.02 --price_inetd 0.02 --min_chunk 6  --end_date $enddate

        BJ_job_price=$(bc <<< "scale=2; $wtm_price/24*$BJ_margin")
	echo "New Background Job Price $BJ_job_price"

	set_bj_instance 1205426 $BJ_job_price
        set_bj_instance 1205427 $BJ_job_price
        set_bj_instance 1205428 $BJ_job_price
        set_bj_instance 1205429 $BJ_job_price

        set_bj_instance 1205500 $BJ_job_price
        set_bj_instance 1205501	 $BJ_job_price
        set_bj_instance 1205502  $BJ_job_price
        set_bj_instance 1205503  $BJ_job_price
        set_bj_instance 1205504  $BJ_job_price
        set_bj_instance 1205505  $BJ_job_price

	echo "Sleeping for 10min"
        sleep 600 # sleep for 10 min
fi
sleep 1
done
