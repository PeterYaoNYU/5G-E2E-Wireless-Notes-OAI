#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 {prague|cubic-ecn1|cubic-ecn-none|cubic-ecn-20}"
    exit 1
fi

# Variables
duration=60  # Replace with your desired duration
flows=1      # Replace with your desired number of flows
iperf_server_1="12.1.1.130"
iperf_server_2="12.1.1.66"  # Add the second iperf server

# Determine the flow variable and congestion control based on the argument
case "$1" in
    prague)
        flow="prague"
        cc="prague"
        ;;
    cubic-ecn-1)
        flow="cubic_ecn_1"
        cc="cubic"
        ;;
    cubic-ecn-none)
        flow="cubic_ecn_none"
        cc="cubic"
        ;;
    cubic-ecn-20)
        flow="cubic_ecn_20"
        cc="cubic"
        ;;
    *)
        echo "Invalid argument: $1"
        echo "Usage: $0 {prague|cubic-ecn1|cubic-ecn-none|cubic-ecn-20}"
        exit 1
        ;;
esac

# Start ss monitoring for the first UE in the background
rm -f ${flow}-ss-ue1.txt
start_time=$(date +%s)
while true; do
    ss --no-header -eipn dst $iperf_server_1 | ts '%.s' | tee -a ${flow}-ss-ue1.txt
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    if [ $elapsed_time -ge $duration ]; then
        break
    fi
    sleep 0.1
done &

# Start ss monitoring for the second UE in the background
rm -f ${flow}-ss-ue2.txt
start_time=$(date +%s)
while true; do
    ss --no-header -eipn dst $iperf_server_2 | ts '%.s' | tee -a ${flow}-ss-ue2.txt
    current_time=$(date +%s)
    elapsed_time=$((current_time - start_time))
    if [ $elapsed_time -ge $duration ]; then
        break
    fi
    sleep 0.1
done &

# Give some time for ss monitoring to start
sleep 1

# Start iperf3 for the first UE
iperf3 -c $iperf_server_1 -t $duration -P $flows -C $cc -p 4000 -J > ${flow}-result-ue1.json &

# Start iperf3 for the second UE
iperf3 -c $iperf_server_2 -t $duration -P $flows -C $cc -p 4000 -J > ${flow}-result-ue2.json &

# Wait for background processes to complete
wait

echo "Iperf tests completed."

