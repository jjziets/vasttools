#/bin/bash
#this script sets the pricing of listed host on vast to x1.8 mining of etherum

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

# get_json "https://whattomine.com/coins/151.json" # | jq .profit

while true
do
now=$(date +"%T")
echo "Update pricing : $now"

rev=$(get_json "https://whattomine.com/coins/151.json?hr=120&p=420.0&fee=0.0&cost=0.1&hcost=0.0&span_br=1h&span_d=24&commit=Calculate" | jq .revenue )

if [ $? -eq 0 ]
then 

        rev=$(echo $rev | sed  's/\$//g')
        rev=$(echo $rev | sed  's/"//g')
        rev=$(bc <<< "scale=2; $rev/24*2")
        echo "New Price $rev"

        ./vast list machine 3451 --price_gpu $rev --price_disk 2 --price_inetu 0.02 --price_inetd 0.02 --min_chunk 1

        sleep 1 

        ./vast list machine 2787 --price_gpu $rev --price_disk 2 --price_inetu 0.02 --price_inetd 0.02 --min_chunk 4

        sleep 1

        rev=$(bc <<< "scale=2; $rev*0.9")

        ./vast list machine 3129 --price_gpu $rev --price_disk 2 --price_inetu 0.02 --price_inetd 0.02 --min_chunk 4
        sleep 600 # sleep for 10 min
fi
sleep 1
done

