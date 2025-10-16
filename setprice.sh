#!/bin/bash
# This script sets the pricing of listed hosts on Vast.ai to 1.8x the mining revenue of Ethereum.

gpuhash=120  # Hashrate of the GPU that you intend to base your scaling on. This is for an RTX 3090.
OD_margin=3
BJ_margin=1.3
contract_length=25 # Length of the contract in days. A value of 25 here gives 20 days runtime.

get_json() {
    local response=$(curl --silent -H "accept: application/json" "$1" -w "\t\t%{http_code}")
    local body=$(echo "$response" | awk -F'\t\t' '{ print $1 }')
    local status_code=$(echo "$response" | awk -F'\t\t' '{ print $2 }' | xargs)

    if [[ "$status_code" != "200" ]]; then
        echo $RED "Failed: $status_code"
        return 2
    fi

    echo "$body"
}

set_bj_instance() { # arg id price
    local instance_id="$1"
    local price="$2"

    echo "Setting instance $instance_id to $price"

    while true; do
        ./vast change bid "$instance_id" --price "$price"
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            break
        fi

        echo "Failed to send command. Resending."
        sleep 2
    done
}

list_machine() { # arg id price_gpu price_disk min_chunk end_date
    local machine_id="$1"
    local price_gpu="$2"
    local price_disk="$3"
    local min_chunk="$4"
    local end_date="$5"

    echo "vast list machine $machine_id --price_gpu $price_gpu --price_disk $price_disk --price_inetu 0.02 --price_inetd 0.02 --min_chunk $min_chunk --end_date $end_date"

    while true; do
        ./vast list machine "$machine_id" \
            --price_gpu "$price_gpu" \
            --price_disk "$price_disk" \
            --price_inetu 0.02 \
            --price_inetd 0.02 \
            --min_chunk "$min_chunk" \
            --end_date "$end_date"
        local exit_code=$?
        if [ $exit_code -eq 0 ]; then
            break
        fi

        echo "Failed to send command. Resending."
        sleep 1
    done
}

# get_json "https://whattomine.com/coins/151.json" # | jq .profit

while true
do
    now=$(date +"%T")
    echo "Update pricing : $now"

    wtm_price=$(get_json "https://whattomine.com/coins/151.json?hr=$gpuhash&p=420.0&fee=0.0&cost=0.1&hcost=0.0&span_br=1h&span_d=24&commit=Calculate" | jq .revenue)

    if [ $? -eq 0 ]; then
        wtm_price=$(echo "$wtm_price" | sed 's/\$//g' | sed 's/"//g')

        rev=$(bc <<< "scale=2; $wtm_price/24*$OD_margin")
        echo "New On Demand Price $rev"

        enddate=$(date +"%s")
        enddate=$((enddate + contract_length * 20 * 60 * 60))
        echo "End date = $enddate"

        list_machine 2787 "$rev" 2 6 "$enddate"
        sleep 2
        list_machine 3129 "$rev" 2 6 "$enddate"

        BJ_job_price=$(bc <<< "scale=2; $wtm_price/24*$BJ_margin")
        echo "New Background Job Price $BJ_job_price"

        set_bj_instance 1212222 "$BJ_job_price"
        set_bj_instance 1212223 "$BJ_job_price"
        set_bj_instance 1212224 "$BJ_job_price"
        set_bj_instance 1212225 "$BJ_job_price"
        set_bj_instance 1212226 "$BJ_job_price"
        set_bj_instance 1212227 "$BJ_job_price"

        set_bj_instance 1205500 "$BJ_job_price"
        set_bj_instance 1205501 "$BJ_job_price"
        set_bj_instance 1205502 "$BJ_job_price"
        set_bj_instance 1205503 "$BJ_job_price"
        set_bj_instance 1205504 "$BJ_job_price"
        set_bj_instance 1205505 "$BJ_job_price"

        echo "Sleeping for 10min"
        sleep 600 # sleep for 10 min
    fi

    sleep 1
done
