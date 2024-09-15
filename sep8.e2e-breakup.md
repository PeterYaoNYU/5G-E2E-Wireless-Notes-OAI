I am thinking that looking end to end does not provide me with enough information, so I am breaking each part up and looking at the cause of the problem specifically. 

Because of the previous issue we have with the emulab router, I have kept only the rx node as physical machine (I cannot do it as a VM, because the VM does not seem to be able to compile the OAI base statation. Either it is too low or the Xen architecture just does not support the OAI). So now I have 1 physical machine, and the rest is just VM. Using virtual switch might be easier to avoud the emulab router issue. 

### 2 UEs without any slicing or router configuration. 
Pinging directly from the local machine. The route taken is from the extdn to the gnb to the UE and back. (I am running on a 820 node because there was a d430 shortage over the weekend)


Measuring the latency over 60 seconds separately. 

```
--- 12.1.1.131 ping statistics ---
60 packets transmitted, 60 received, 0% packet loss, time 59075ms
rtt min/avg/max/mdev = 125.268/141.511/175.640/10.643 ms

--- 12.1.1.66 ping statistics ---
60 packets transmitted, 60 received, 0% packet loss, time 59078ms
rtt min/avg/max/mdev = 126.598/144.460/179.442/14.865 ms
```

Measuring the thp separately over 60 seconds:

the UE1 131 node:
```
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec   111 MBytes  15.6 Mbits/sec  753             sender
[  4]   0.00-60.00  sec   111 MBytes  15.5 Mbits/sec                  receiver
```

The UE3 66 node over 60 seconds:

```
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec   107 MBytes  15.0 Mbits/sec  928             sender
[  4]   0.00-60.00  sec   106 MBytes  14.8 Mbits/sec                  receiver
```

Running at the same time over 60 seconds:
```
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec  64.9 MBytes  9.08 Mbits/sec  694             sender
[  4]   0.00-60.00  sec  63.6 MBytes  8.89 Mbits/sec                  receiver

- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec  65.0 MBytes  9.08 Mbits/sec  851             sender
[  4]   0.00-60.00  sec  63.3 MBytes  8.85 Mbits/sec                  receiver
```

### add slicing, but still on the same machine:

```
rtt min/avg/max/mdev = 136.749/175.300/266.635/34.391 ms
rtt min/avg/max/mdev = 133.799/174.351/283.876/34.287 ms
```

It does not made a difference, my suspicion is that the network is not saturated, hence the difference is salient. Might consider running jointly iperf and ping to saturate the network. 

Running iperf3 gives us more result.

```
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec  80.2 MBytes  11.2 Mbits/sec  755             sender
[  4]   0.00-60.00  sec  77.3 MBytes  10.8 Mbits/sec                  receiver

iperf Done.
[  4]  59.00-60.00  sec   699 KBytes  5.73 Mbits/sec    0   3.13 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec  37.9 MBytes  5.29 Mbits/sec    4             sender
[  4]   0.00-60.00  sec  37.8 MBytes  5.28 Mbits/sec                  receiver

iperf Done.
```

So yes, I think we should run iperf and ping jointly. 

```
--- 12.1.1.131 ping statistics ---
60 packets transmitted, 60 received, 0% packet loss, time 59132ms
rtt min/avg/max/mdev = 147.650/1069.770/2363.682/558.733 ms, pipe 3


- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec  83.3 MBytes  11.6 Mbits/sec  793             sender
[  4]   0.00-60.00  sec  82.4 MBytes  11.5 Mbits/sec                  receiver



--- 12.1.1.66 ping statistics ---
60 packets transmitted, 60 received, 0% packet loss, time 59173ms
rtt min/avg/max/mdev = 147.755/3017.266/5166.684/1951.293 ms, pipe 6

- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.01  sec  39.2 MBytes  5.48 Mbits/sec    8             sender
[  4]   0.00-60.01  sec  39.1 MBytes  5.47 Mbits/sec                  receiver

iperf Done.
```

So yes, the latency is of course better when slicing is in place. 

But the latency that we get from this maybe too extreme, given that the queueing delay is now on the magnitude of seconds. This is clearly not what we want. So I want to limit the rate of the first UE iperf to 10Mbps and the seconds to 5 Mbps, to create moderate queueing but not making the queue indefintely long. 


```
--- 12.1.1.131 ping statistics ---
60 packets transmitted, 60 received, 0% packet loss, time 59079ms
rtt min/avg/max/mdev = 73.934/116.464/238.176/31.748 ms
64 bytes from 12.1.1.66: icmp_seq=60 ttl=63 time=100 ms


- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec  68.9 MBytes  9.63 Mbits/sec    0             sender
[  4]   0.00-60.00  sec  67.4 MBytes  9.42 Mbits/sec                  receiver


--- 12.1.1.66 ping statistics ---
60 packets transmitted, 60 received, 0% packet loss, time 59077ms
rtt min/avg/max/mdev = 76.510/138.107/301.731/43.547 ms

iperf Done.
[  4]   0.00-60.00  sec  34.7 MBytes  4.85 Mbits/sec    0             sender
[  4]   0.00-60.00  sec  33.6 MBytes  4.69 Mbits/sec                  receiver

iperf Done.

```

the difference is not too much, to be honest. And I tried to raise the bar to 11 and 6 mbps to see if the difference is bigger. 

```
--- 12.1.1.131 ping statistics ---
60 packets transmitted, 60 received, 0% packet loss, time 59046ms
rtt min/avg/max/mdev = 77.741/117.298/241.146/33.511 ms
64 bytes from 12.1.1.66: icmp_seq=60 ttl=63 time=1567 ms

--- 12.1.1.66 ping statistics ---
60 packets transmitted, 60 received, 0% packet loss, time 59032ms
rtt min/avg/max/mdev = 136.465/858.466/1602.920/440.227 ms, pipe 2
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec  75.0 MBytes  10.5 Mbits/sec    0             sender
[  4]   0.00-60.00  sec  73.7 MBytes  10.3 Mbits/sec                  receiver

- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec  42.1 MBytes  5.89 Mbits/sec    0             sender
[  4]   0.00-60.00  sec  39.7 MBytes  5.56 Mbits/sec                  receiver

iperf Done.
```

This is more or less what I would expect to see, that slicing makes a huge difference when the network is saturated just a bit, and the latency makes a huge difference. (not just x2)

### Adding queueing bottleneck to the picture, but no UE. 

I want to for now isolate the queueing transport from the UE. And I want to see just the l4s and bottleneck. what is the latency and thp interplay. 

For verifying latency in this setting, ICMP message does not work anymore, because they are not TCP controlled. I have to use ss to analyze. 

```
sudo modprobe sch_dualpi2
sudo modprobe tcp_prague
```
these 2 steps are essential for setting up endhost CC algo. 

I honestly began to wonder if the tcp prgaue is fair even under dual queue. It should, but still there is a persistent thp difference that 

two separate network namespace on the same host:
UE1 namespace with tcpecn=3 and prague. 

UE3 namespace with tcpecn = 0 and cubic. 

And run a test as in the to switch or not to switch paper. 

Only 2 nodes, the other one is a VM. The TX port of the VM is configured with a bottleneck of 25mbit. Dualqueue. The sender is configured with 

```
PeterYao@router1:~$ sysctl net.ipv4.tcp_congestion_control
net.ipv4.tcp_congestion_control = prague
PeterYao@router1:~$ sysctl net.ipv4.tcp_ecn
net.ipv4.tcp_ecn = 3
```

The test script that I run is: Simple enough, just one running cubic, and the other running prague. 


```shell

#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 {prague|cubic-ecn1|cubic-ecn-none|cubic-ecn-20}"
    exit 1
fi

# Variables
duration=20  # Replace with your desired duration
flows=1      # Replace with your desired number of flows
iperf_server_1="10.201.1.1"
iperf_server_2="10.203.1.3"  # Add the second iperf server

# Determine the flow variable and congestion control based on the argument
case "$1" in
    prague)
        flow="prague_2.0_100_25_single_queue_FQ_1_2_1"
        cc="prague"
        ;;
    cubic-ecn1)
        flow="cubic_2.0_100_25_single_queue_FQ_1_1_1"
        cc="cubic"
        ;;
    cubic-ecn-none)
        flow="cubic_2.0_100_25_single_queue_FQ_none_0_1"
        cc="cubic"
        ;;
    cubic-ecn-20)
        flow="cubic_2.0_100_25_single_queue_FQ_20_1_1"
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
iperf3 -c $iperf_server_1 -t $duration -P $flows -C $cc > prague-result-ue1.json &

# Start iperf3 for the second UE
iperf3 -c $iperf_server_2 -t $duration -P $flows -C cubic > cubic-result-ue2.json &

# Wait for background processes to complete
wait

echo "Iperf tests completed."


```

Running the script, here is the iperf result:

For the prague flow:

```
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-20.00  sec  9.38 MBytes  3.94 Mbits/sec   17             sender
[  5]   0.00-20.00  sec  9.26 MBytes  3.88 Mbits/sec                  receiver

iperf Done.
```

For the cubic flow:
```
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-20.00  sec  47.8 MBytes  20.0 Mbits/sec  736             sender
[  5]   0.00-20.00  sec  47.6 MBytes  20.0 Mbits/sec                  receiver
```

The distinction is shocking. And I do not know why. 

And here is the traffic shaping in the router, I followed that part pretty strictly the original paper method:

```
PeterYao@router1:~$ sudo tc qdisc show dev eth2
qdisc htb 1: root refcnt 2 r2q 10 default 0x3 direct_packets_stat 0 direct_qlen 1000
qdisc dualpi2 3: parent 1:3 limit 10000p target 1ms tupdate 16ms alpha 0.156250 beta 3.195312 l4s_ect coupling_factor 2 drop_on_overload step_thresh 1ms drop_dequeue split_gso classic_protection 10%
```

And then I analyze the latency from the ss data. 

Most notabily, the ss data is of this format:

```
1725877589.814789 tcp ESTAB 0      0      10.0.5.1:55026 10.201.1.1:5201 users:(("iperf3",pid=16828,fd=4)) uid:39791 ino:126633 sk:a3 cgroup:unreachable:2010c00000052 <->
1725877589.819042 	 ts sack ecnseen prague wscale:8,7 rto:204 rtt:0.542/0.213 ato:40 mss:1448 pmtu:1500 rcvmss:536 advmss:1448 cwnd:10 bytes_sent:163 bytes_acked:164 bytes_received:4 segs_out:9 segs_in:8 data_segs_out:3 data_segs_in:4 send 213726937bps lastsnd:6316 lastrcv:6308 lastack:6308 pacing_rate 442804400bps delivery_rate 40645608bps delivered:4 app_limited rcv_space:14480 rcv_ssthresh:64088 minrtt:0.285
1725877589.825149 tcp ESTAB 0      90468  10.0.5.1:55042 10.201.1.1:5201 users:(("iperf3",pid=16828,fd=5)) timer:(persist,200ms,0) uid:39791 ino:126634 sk:a4 cgroup:unreachable:2010c00000052 <->
1725877589.827549 	 ts sack ecnseen prague wscale:8,7 rto:204 rtt:0.62/0.082 mss:1448 pmtu:1500 rcvmss:536 advmss:1448 cwnd:2 ssthresh:2 bytes_sent:5400833 bytes_retrans:11488 bytes_acked:5389346 segs_out:3764 segs_in:3657 data_segs_out:3762 send 37367742bps lastsnd:4 lastrcv:6316 lastack:4 pacing_rate 3408752bps delivery_rate 16088888bps delivered:3755 delivered_ce:562 busy:6308ms retrans:0/8 rcv_space:14480 rcv_ssthresh:64088 notsent:90468 minrtt:0.212
1725877590.257834 tcp ESTAB 0      0      10.0.5.1:55026 10.201.1.1:5201 users:(("iperf3",pid=16828,fd=4)) uid:39791 ino:126633 sk:a3 cgroup:unreachable:2010c00000052 <->
1725877590.267962 	 ts sack ecnseen prague wscale:8,7 rto:204 rtt:0.542/0.213 ato:40 mss:1448 pmtu:1500 rcvmss:536 advmss:1448 cwnd:10 bytes_sent:163 bytes_acked:164 bytes_received:4 segs_out:9 segs_in:8 data_segs_out:3 data_segs_in:4 send 213726937bps lastsnd:6816 lastrcv:6808 lastack:6808 pacing_rate 442804400bps delivery_rate 40645608bps delivered:4 app_limited rcv_space:14480 rcv_ssthresh:64088 minrtt:0.285
```
The ecmsee prague cc mentioned is different from what I will try to differentiate later. 


While the other UE file is of the format:

```
1725877584.662746 	 ts sack cubic wscale:8,7 rto:208 rtt:4.104/0.255 mss:1448 pmtu:1500 rcvmss:536 advmss:1448 cwnd:10 ssthresh:7 bytes_sent:2613677 bytes_retrans:5792 bytes_acked:2602094 segs_out:1808 segs_in:949 data_segs_out:1806 send 28226121bps lastrcv:1288 pacing_rate 33866184bps delivery_rate 13008416bps delivered:1799 busy:1248ms unacked:4 retrans:0/4 rcv_space:14480 rcv_ssthresh:64088 notsent:140456 minrtt:0.352
1725877584.937347 tcp ESTAB 0      0      10.0.5.1:35782 10.203.1.3:5201 users:(("iperf3",pid=16829,fd=4)) uid:39791 ino:126632 sk:a5 cgroup:unreachable:2010c00000052 <->
1725877584.943406 	 ts sack prague-reno wscale:8,7 rto:208 rtt:5.524/9.131 ato:40 mss:1448 pmtu:1500 rcvmss:536 advmss:1448 cwnd:10 bytes_sent:162 bytes_acked:163 bytes_received:4 segs_out:8 segs_in:7 data_segs_out:3 data_segs_in:3 send 20970311bps lastsnd:1568 lastrcv:1524 lastack:1524 pacing_rate 41939672bps delivery_rate 31824168bps delivered:4 app_limited busy:44ms rcv_space:14480 rcv_ssthresh:64088 minrtt:0.364
1725877584.944263 tcp ESTAB 0      147696 10.0.5.1:35788 10.203.1.3:5201 users:(("iperf3",pid=16829,fd=5)) timer:(on,016ms,0) uid:39791 ino:126647 sk:a6 cgroup:unreachable:2010c00000052 <->
1725877584.945001 	 ts sack cubic wscale:8,7 rto:208 rtt:5.62/0.359 mss:1448 pmtu:1500 rcvmss:536 advmss:1448 cwnd:10 ssthresh:7 bytes_sent:3071245 bytes_retrans:7240 bytes_acked:3056766 segs_out:2124 segs_in:1110 data_segs_out:2122 send 20612100bps lastsnd:4 lastrcv:1568 lastack:4 pacing_rate 24734512bps delivery_rate 11925872bps delivered:2113 busy:1528ms unacked:5 retrans:0/5 rcv_space:14480 rcv_ssthresh:64088 notsent:140456 minrtt:0.352
1725877585.468447 tcp ESTAB 0      0      10.0.5.1:35782 10.203.1.3:5201 users:(("iperf3",pid=16829,fd=4)) uid:39791 ino:126632 sk:a5 cgroup:unreachable:2010c00000052 <->
1725877585.472022 	 ts sack prague-reno wscale:8,7 rto:208 rtt:5.524/9.131 ato:40 mss:1448 pmtu:1500 rcvmss:536 advmss:1448 cwnd:10 bytes_sent:162 bytes_acked:163 bytes_received:4 segs_out:8 segs_in:7 data_segs_out:3 data_segs_in:3 send 20970311bps lastsnd:1908 lastrcv:1864 lastack:1864 pacing_rate 41939672bps delivery_rate 31824168bps delivered:4 app_limited busy:44ms rcv_space:14480 rcv_ssthresh:64088 minrtt:0.364
1725877585.473618 tcp ESTAB 0      123080 10.0.5.1:35788 10.203.1.3:5201 users:(("iperf3",pid=16829,fd=5)) timer:(on,016ms,0) uid:39791 ino:126647 sk:a6 cgroup:unreachable:2010c00000052 <->
```
What is cubic and prague-reno. It should be simply just cubic. 

But at the same time, using faith's script to do the analysis of the srtt shows that the l4s flow is indeed exhibiting shorter latency: 0.546, while the cubic flow has a latency as high as: 4.285. And I think the unit is in millisecond. 

I think the problem might be that the threshold is too small. And I think that I am right. Let me try to set the ecn threshold higher to 5ms. 
the prague flow:
```
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-20.00  sec  0.00 Bytes  0.00 bits/sec
  sender
[  5]   0.00-20.00  sec  33.2 MBytes  13.9 Mbits/sec
    receiver

```
and the cubic flow:
```
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-20.04  sec  0.00 Bytes  0.00 bits/sec
  sender
[  5]   0.00-20.04  sec  23.7 MBytes  9.94 Mbits/sec
    receiver
```

I can see that it is turned around a little. This is probably because 5ms is pretty long. 

The latency slightly increases: 0.7095 for the LL flow, and the srtt is 6.27 for the NLL flow. 







