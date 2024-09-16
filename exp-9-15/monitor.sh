#!/bin/bash

if [ "$#" -ne 3 ]; then
    echo "Usage: $0 interface duration interval"
    echo "where 'interface' is the name of the interface on which the queue"
    echo "running (e.g., eth2), 'duration' is the total runtime (in seconds),"
    echo "and 'interval' is the time between measurements (in seconds)"
    exit 1
fi

interface=$1
duration=$2
interval=$3

# Run for the number of seconds specified by the "duration" argument
end=$((SECONDS+$duration))

while [ $SECONDS -lt $end ]
do
        # print timestamp at the beginning of each line;
        # useful for data analysis. (-n argument says not to
        # create a newline after printing timestamp.)
        echo -n "$(date +%s.%N) "
        # Show current queue information on the specified
        # interface, all on one line.
        echo $(tc -p -s -d qdisc show dev $interface)
        # sleep for the specified interval
        sleep $interval
done