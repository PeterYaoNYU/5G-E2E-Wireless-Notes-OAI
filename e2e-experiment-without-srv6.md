> do not ever forget to configure the iptable in the namespace leaving the namesapce. Something like the following is needed:


```
 ip route add default via 192.168.100.1 dev veth-namespace
```


I am setting up an e2e experiment, with 2 l4s enabled routers, one delay node, one server, one base station, 2 UEs. 

This section in the docker compose file inspire me to think about how to route oncoming traffic to the right UPF:

```
    oai-ext-dn:
        privileged: true
        init: true
        container_name: oai-ext-dn
        image: oaisoftwarealliance/trf-gen-cn5g:latest
        entrypoint: /bin/bash -c \
              "ip route add 12.1.1.128/25 via 192.168.70.134 dev eth0;"\
              "ip route add 12.1.1.64/26 via 192.168.70.140 dev eth0; ip route; sleep infinity"
        command: ["/bin/bash", "-c", "trap : SIGTERM SIGINT; sleep infinity & wait"]
        healthcheck:
            test: /bin/bash -c "ip r | grep 12.1.1"
            interval: 10s
            timeout: 5s
            retries: 5
        networks:
            public_net:
                ipv4_address: 192.168.70.135
```

I think this can be configured correctly on the base station node. I just need to make sure that the server can indeed send traffic to the UPF docker container with that address. 

I begin to see that OAI latest version does not seem to be compatible with ubuntu 22. 
It will result in installation error. 

```
WARNING: 7 warnings. See /mydata/openairinterface5g/cmake_targets/log/all.txt
ERROR: 3 error. See /mydata/openairinterface5g/cmake_targets/log/all.txt
compilation of rfsimulator nr-softmodem nr-cuup nr-uesoftmodem params_libconfig coding rfsimulator dfts failed
build have failed
```
This is not very ideal. I will have to tweak the profile to adapt to this. 


When installing packages on the rx node, may encounter apt issue because of the ubuntu version being 18, can easily resolve with:
```
sudo apt --fix-broken install
sudo apt -y install iperf3 net-tools moreutils
```


At the rx0 node. 
```
sudo ip route add 12.1.1.64/26 via 192.168.70.140

sudo ip route add 12.1.1.128/25 via 192.168.70.134
```


At the router1, adding routing rule as well. 

```
sudo ip route add 12.1.1.64/26 via 10.0.5.100
sudo ip route add 12.1.1.128/25 via 10.0.5.100

```

router0:
```
sudo ip route add 12.1.1.64/26 via 10.0.2.1
sudo ip route add 12.1.1.128/25 via 10.0.2.1
```

tx0:
```
sudo ip route add 12.1.1.64/26 via 10.0.0.2
sudo ip route add 12.1.1.128/25 via 10.0.0.2
```

pinging okay. 

Configuring the network to have non l4s. (Scenario 1)

On all 4 nodes:

make sure that unmae -r  gives the kernel version: 5.15.72-56eae305c-prague-91
```
sudo sysctl -w net.ipv4.tcp_congestion_control=cubic  
sudo sysctl -w net.ipv4.tcp_ecn=0
```

Turn off all segmentatation offload on all 4 machines. 

router1:
```
sudo tc qdisc del dev enp4s0f0 root
sudo tc qdisc replace dev enp4s0f0 root handle 1: htb default 3
sudo tc class add dev enp4s0f0 parent 1: classid 1:3 htb rate 25mbit

sudo tc qdisc add dev enp4s0f0 parent 1:3 handle 3: bfifo limit 625000
```

so the dl egress of router1 is configured as
```
PeterYao@router1:~$ sudo tc qdisc show dev enp6s0f2
qdisc htb 1: root refcnt 9 r2q 10 default 0x3 direct_packets_stat 0 direct_qlen 1000
qdisc bfifo 3: parent 1:3 limit 625000b
```

router0
```
sudo tc qdisc del dev enp6s0f2 root
sudo tc qdisc replace dev enp6s0f2 root handle 1: htb default 3
sudo tc class add dev enp6s0f2 parent 1: classid 1:3 htb rate 1000mbit

sudo tc qdisc del dev enp6s0f1 root
sudo tc qdisc replace dev enp6s0f1 root handle 1: htb default 3
sudo tc class add dev enp6s0f1 parent 1: classid 1:3 htb rate 1000mbit

sudo tc qdisc add dev enp6s0f2 parent 1:3 handle 3: bfifo limit 625000
sudo tc qdisc add dev enp6s0f1 parent 1:3 handle 3: bfifo limit 625000

```

so router 0 shows the following configuration. 

```
PeterYao@router0:~$ sudo tc qdisc show dev enp6s0f1
qdisc htb 1: root refcnt 9 r2q 10 default 0x3 direct_packets_stat 0 direct_qlen 1000
qdisc bfifo 3: parent 1:3 limit 625000b
PeterYao@router0:~$ sudo tc qdisc show dev enp6s0f2
qdisc htb 1: root refcnt 9 r2q 10 default 0x3 direct_packets_stat 0 direct_qlen 1000
qdisc bfifo 3: parent 1:3 limit 625000b
```
All just simple deep fifo queues. 

actually later I decided to not use simple fifo queues on router0. I keep the original codel default queue that is the same up every boot. So the queue should look something like this:

```
PeterYao@router0:~$ sudo tc qdisc show dev enp4s0f1
qdisc mq 0: root
qdisc fq_codel 0: parent :8 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :7 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :6 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :5 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :4 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :3 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :2 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :1 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64

PeterYao@router0:~$ sudo tc qdisc show dev enp4s0f0
qdisc mq 0: root
qdisc fq_codel 0: parent :8 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :7 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :6 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :5 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :4 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :3 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :2 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
qdisc fq_codel 0: parent :1 limit 10240p flows 1024 quantum 1514 target 5ms interval 100ms memory_limit 32Mb ecn drop_batch 64
```

they are kept as the default. 

Running iperf for the 2 UEs one by one:
UE1:
```
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-60.61  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-60.61  sec   158 MBytes  21.9 Mbits/sec                  receiver
```

UE2:
```
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-60.67  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-60.67  sec   158 MBytes  21.8 Mbits/sec                  receiver
```

So I guess setting the btl to 25mbps is too high to form a queue. Let me set it to 15 mbps instead:

router1:
```
sudo tc qdisc del dev enp6s0f2 root
sudo tc qdisc replace dev enp6s0f2 root handle 1: htb default 3
sudo tc class add dev enp6s0f2 parent 1: classid 1:3 htb rate 15mbit

sudo tc qdisc add dev enp6s0f2 parent 1:3 handle 3: bfifo limit 625000
```

Now I am seeing the thp that I expect to see:

UE1:
```
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-60.32  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-60.32  sec   101 MBytes  14.1 Mbits/sec                  receiver
```

UE2 is the same. 

running iperf for 2 UEs simultaneously:
```
iperf3 -c 12.1.1.130 -p 5001 -t 60 -i 1 &
iperf3 -c 12.1.1.66 -p 5002 -t 60 -i 1 &
```

UE1:
```
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-60.32  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-60.32  sec  57.0 MBytes  7.92 Mbits/sec                  receiver
```

UE2:
```
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-60.33  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-60.33  sec  45.3 MBytes  6.30 Mbits/sec                  receiver
```
They are sharing the link more or less equally?

Running for the third time:
```bash
# ue1
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-60.49  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-60.49  sec  50.7 MBytes  7.03 Mbits/sec                  receiver
# ue2
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-60.39  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-60.39  sec  50.2 MBytes  6.97 Mbits/sec                  receiver
```

maybe we want to run the ss+iperf experiment as well, to collect some result. 

the test script is:
```bash
#!/bin/bash

# Check if an argument is provided
if [ -z "$1" ]; then
    echo "Usage: $0 {prague|cubic-ecn1|cubic-ecn-none|cubic-ecn-20}"
    exit 1
fi

# Variables
duration=20  # Replace with your desired duration
flows=1      # Replace with your desired number of flows
iperf_server_1="10.0.5.100"
iperf_server_2="10.0.5.101"  # Add the second iperf server

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
iperf3 -c $iperf_server_1 -t $duration -P $flows -C $cc -p 4000 -J > ${flow}-result-ue1.json &

# Start iperf3 for the second UE
iperf3 -c $iperf_server_2 -t $duration -P $flows -C $cc -p 4000 -J > ${flow}-result-ue2.json &

# Wait for background processes to complete
wait

echo "Iperf tests completed."

```


After adding slicing:

I repeat serveral times:
```
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-60.35  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-60.35  sec  55.9 MBytes  7.77 Mbits/sec                  receiver

- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-60.39  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-60.39  sec  45.9 MBytes  6.37 Mbits/sec                  receiver
```

Does it have to do with the fact that we have routing in place? The result is not shoing much disparity. 

It seems that the slicing fails apart. 
```
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-60.29  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-60.29  sec  52.5 MBytes  7.31 Mbits/sec                  receiver


[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-60.52  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-60.52  sec  49.5 MBytes  6.86 Mbits/sec                  receiver
```

Weird thing is that if I limit the iperf time to 20 seconds, I can still somehow see the effect of slicing in place. 

Is this because of the queueing policy? Will the problem persist if there is no restriction on btl links? Power cycle to see


This problem goes away when the queue and bottleneck links are rest. 


```
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-61.42  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-61.42  sec  92.7 MBytes  12.7 Mbits/sec                  receiver

[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-62.21  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-62.21  sec  40.9 MBytes  5.51 Mbits/sec                  receiver

```
Apparently the problem is that, since queue is building up, it cause ran slicing to  lose effect. This phenomenom is interesting. 

> if the ip routing does not work, it is probably that the firwall drops it. Change by this commnad: sudo iptables -P FORWARD ACCEPT   on the rx machine. 

after the automation, change the ownership of the mydata partition. 

the ownership needs to be chanegd recursively. 

```bash
username=$(whoami)
groupname=$(id -gn)
sudo chown -R $username:$groupname /mydata
chmod 775 /mydata
```

Actually, I have updated the test script, the latest one should always be at this link:

https://github.com/PeterYaoNYU/core-network-5g/blob/main/etc/experiment.sh

running the exepriment, start the iperf server process at the two UEs:

```
sudo ip netns exec ue1 bash 
iperf3 -s -p 4000


sudo ip netns exec ue3 bash 
iperf3 -s -p 4000
```

then run the experiment script on the tx0 node:
```
bash experiment.sh cubic-ecn-none


```


### Second experiment (with Slicing only)

```bash
sudo sysctl -w net.ipv4.tcp_congestion_control=cubic

sudo sysctl -w net.ipv4.tcp_ecn=0
```

at the endpoint (the 2 namespaces and the sender). 


```bash

sudo sysctl -w net.ipv4.tcp_ecn=0
```

at every intermediate node


Check with:
```bash
sysctl net.ipv4.tcp_ecn
sysctl net.ipv4.tcp_congestion_control
```

check the btl link queueing discipline:
```bash
sudo tc qdisc show dev enp4s0f0
```

I set it to the following:
```bash
PeterYao@router1:~$ sudo tc qdisc show dev enp4s0f0
qdisc htb 1: root refcnt 9 r2q 10 default 0x3 direct_packets_stat 0 direct_qlen 1000
qdisc bfifo 3: parent 1:3 limit 625000b
```

> use the python notebook to turn off all offloads

Then run the experiment.

```bash
sudo ip netns exec ue1 bash 
iperf3 -s -p 4000
```

```bash
sudo ip netns exec ue3 bash 
iperf3 -s -p 4000
```

```bash
bash ./experiment.sh cubic-ecn-none-slicing
```


### experiment3 (dualqueue l4s + slicing)

```bash
#configuration for DUALPI2 bottleneck
sudo apt-get update
sudo apt -y install git gcc make bison flex libdb-dev libelf-dev pkg-config libbpf-dev libmnl-dev libcap-dev libatm1-dev selinux-utils libselinux1-dev
sudo git clone https://github.com/L4STeam/iproute2.git
cd iproute2
sudo chmod +x configure
sudo ./configure
sudo make
sudo make install
sudo modprobe sch_dualpi2
```

> sudo modprobe sch_dualpi2 should not have any output 


at the bottleneck link (router1): (interface name subject to change for different cloudlab instance)

```bash
sudo tc qdisc del dev enp4s0f0 root
sudo tc qdisc replace dev enp4s0f0 root handle 1: htb default 3 
sudo tc class add dev enp4s0f0 parent 1: classid 1:3 htb rate 25mbit 

sudo tc qdisc add dev enp4s0f0 parent 1:3 handle 3: dualpi2 target 1ms
```

check with 
```bash
sudo tc qdisc show dev enp4s0f0
```

I see the following output
```bash
PeterYao@router1:~$ sudo tc qdisc show dev enp4s0f0
qdisc htb 1: root refcnt 9 r2q 10 default 0x3 direct_packets_stat 0 direct_qlen 1000
qdisc dualpi2 3: parent 1:3 limit 10000p target 1ms tupdate 16ms alpha 0.156250 beta 3.195312 l4s_ect coupling_factor 2 drop_on_overload step_thresh 1ms drop_dequeue split_gso classic_protection 10%
```

in ue1 terminal (the l4s low latency UE), enable l4s and accurate ecn and tcp prague
```bash
sudo sysctl -w net.ipv4.tcp_congestion_control=prague  
sudo sysctl -w net.ipv4.tcp_ecn=3
```

do the same in the tx node, othwewise the iperf3 will not have prague cc to choose. 

check with 
```bash
sysctl net.ipv4.tcp_congestion_control
sysctl net.ipv4.tcp_ecn
```

run the experiment
```bash
bash experiment.sh prague
```

### verfiy TCP prague
check what is causing the TCP prague to function abnormally. First we need to set up routing correctly. 

at tx0:

```
sudo ip route add 10.201.1.0/24 via 10.0.0.2
sudo ip route add 10.203.1.0/24 via 10.0.0.2
```

at router0:
```
sudo ip route add 10.201.1.0/24 via 10.0.2.1
sudo ip route add 10.203.1.0/24 via 10.0.2.1
```

at router1:

```
sudo ip route add 10.201.1.0/24 via 10.0.5.100
sudo ip route add 10.203.1.0/24 via 10.0.5.100
```
## Very important and easy to forget. 
> very important
at the ue1 namespace:
```
sudo ip netns exec ue1 bash
sudo ip route add default via 10.201.1.100
```
so that the icmp messages can be routed back to the sender. 


at the ue3 namesapce:
```
sudo ip netns exec ue3 bash
sudo ip route add default via 10.203.1.100
```

Then we enable tcp prague at ue1 namesapce and tcp cubic and ue3 namespace. 

UE1:
```bash
sudo ip netns exec ue1 bash
sudo sysctl -w net.ipv4.tcp_congestion_control=prague  
sudo sysctl -w net.ipv4.tcp_ecn=3
```

UE3:
```bash
sudo ip netns exec ue3 bash
sudo sysctl -w net.ipv4.tcp_congestion_control=cubic  
sudo sysctl -w net.ipv4.tcp_ecn=0
```

then start iperf server sessions at both namespaces:

```bash
iperf3 -s -p 4000
```

running iperf for 2 UE namespaces simultaneously:
```
iperf3 -c 10.201.1.1 -C prague -p 4000 -t 60 -i 1 &
iperf3 -c 10.203.1.3 -C cubic -p 4000 -t 60 -i 1 &
```









```
PeterYao@rx0:/mydata/oai-cn5g-fed/docker-compose$ sudo  docker network inspect docker-compose_ue1_net
[
    {
        "Name": "docker-compose_ue1_net",
        "Id": "04e8003791329a994c704a36316e341f6d190d48db2da5ce9067685cec41257a",
        "Created": "2024-09-23T08:48:26.965724652-06:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "172.18.0.0/16",
                    "Gateway": "172.18.0.1"
                }
            ]
        },
        "Internal": false,
        "Attachable": true,
        "Ingress": false,
        "ConfigFrom": {
            "Network": ""
        },
        "ConfigOnly": false,
        "Containers": {
            "62a8c9fb2c4f45a2c084fe6522a6ea42c744f40eeae640d7bf3615bc8d3f2d58": {
                "Name": "rfsim5g-oai-nr-ue2",
                "EndpointID": "e762eb1161284368e33f04b0f899a57736d5aacbff35d4c4e86bb73caddb572c",
                "MacAddress": "02:42:ac:12:00:03",
                "IPv4Address": "172.18.0.3/16",
                "IPv6Address": ""
            },
            "e44fcea8f267469e0c020230a377b1a5ee1da49dc7624aaab69acefeccd78c8f": {
                "Name": "rfsim5g-oai-nr-ue1",
                "EndpointID": "e288236bc058499928edd33381da17f5026cedd418fb8ebd7a9b5e4f35997e66",
                "MacAddress": "02:42:ac:12:00:02",
                "IPv4Address": "172.18.0.2/16",
                "IPv6Address": ""
            }
        },
        "Options": {},
        "Labels": {
            "com.docker.compose.network": "ue1_net",
            "com.docker.compose.project": "docker-compose",
            "com.docker.compose.version": "1.29.2"
        }
    }
]

```

each container has a net. 

go inside the container. 
```
PeterYao@rx0:/mydata/oai-cn5g-fed/docker-compose$ sudo docker exec -it 62a8c9fb2c4f /bin/bash
root@62a8c9fb2c4f:/opt/oai-nr-ue# ip addr list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: oaitun_ue1: <POINTOPOINT,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none
    inet 12.1.1.66/24 scope global oaitun_ue1
       valid_lft forever preferred_lft forever
241: eth0@if242: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:ac:12:00:03 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 172.18.0.3/16 brd 172.18.255.255 scope global eth0
       valid_lft forever preferred_lft forever
root@62a8c9fb2c4f:/opt/oai-nr-ue#
```

Each container itself is like a separate namespace, so there is no need to create namespace separately. 

the interesting thing is that the RF simulator address is not set correctly:

```yaml
version: '3.8'
services:
    oai-nr-ue1:
        image: oaisoftwarealliance/oai-nr-ue:2024.w30
        privileged: true
        container_name: rfsim5g-oai-nr-ue1
        environment: 
            RFSIMULATOR: 10.201.1.100
            USE_ADDITIONAL_OPTIONS: --sa --rfsim -r 106 --numerology 1 -C 3619200000 
        volumes:
            - ./ran-conf/ue1.conf:/opt/oai-nr-ue/etc/nr-ue.conf
        networks:
            - ue1_net
        healthcheck:
            test: /bin/bash -c "pgrep nr-uesoftmodem"
            interval: 10s
            timeout: 5s
            retries: 5

    oai-nr-ue2:
        image: oaisoftwarealliance/oai-nr-ue:2024.w30
        privileged: true
        container_name: rfsim5g-oai-nr-ue2
        environment: 
            RFSIMULATOR: 10.203.1.100
            USE_ADDITIONAL_OPTIONS: --sa --rfsim -r 106 --numerology 1 -C 3619200000 
        volumes:
            - ./ran-conf/ue2.conf:/opt/oai-nr-ue/etc/nr-ue.conf
        networks:
            - ue1_net
        healthcheck:
            test: /bin/bash -c "pgrep nr-uesoftmodem"
            interval: 10s
            timeout: 5s
            retries: 5
networks:
    ue1_net:
        driver: bridge

```

but when the RF simulator address is set to 127.0.0.1, it will not work. I suppose that 127.0.0.1 is local to the docker network. But still the purpose of rf simulator is not totally clear to me. 


Note that you should not use the latest version of the docker container: namely with the develop tag. It has some serious issues / totally different ways of loading the configuration files for the RAN. 

```
cd /mydata/oai-cn5g-fed/docker-compose/
sudo docker-compose -f docker-compose-ue-slice1.yaml up oai-nr-ue1


cd /mydata/oai-cn5g-fed/docker-compose/
sudo docker-compose -f docker-compose-ue-slice1.yaml up oai-nr-ue2
```


to monitor with xapp the RLC buffer size:
```bash
/mydata/flexric/build/examples/xApp/c/monitor/xapp_gtp_mac_rlc_pdcp_moni
```
```
cp /mydata/core-network-5g/etc/core-slice-conf/docker-compose-basic-nrf.yaml /mydata/oai-cn5g-fed/docker-compose

cp /mydata/core-network-5g/etc/core-slice-conf/basic* /mydata/oai-cn5g-fed/docker-compose/conf

cp /mydata/core-network-5g/etc/new_core_network.py /mydata/oai-cn5g-fed/docker-compose  
```

Configure differen cca and ecn inside the container. Check on the 5G node. 
```python
rx.sudo("docker exec rfsim5g-oai-nr-ue1 sysctl -w net.ipv4.tcp_congestion_control=prague")
rx.sudo("docker exec rfsim5g-oai-nr-ue1 sysctl -w net.ipv4.tcp_ecn=3")
rx.sudo("docker exec rfsim5g-oai-nr-ue1 sysctl net.ipv4.tcp_ecn")
rx.sudo("docker exec rfsim5g-oai-nr-ue1 sysctl net.ipv4.tcp_congestion_control")



rx.sudo("docker exec rfsim5g-oai-nr-ue2 sysctl -w net.ipv4.tcp_congestion_control=cubic")
rx.sudo("docker exec rfsim5g-oai-nr-ue2 sysctl -w net.ipv4.tcp_ecn=0")
rx.sudo("docker exec rfsim5g-oai-nr-ue2 sysctl net.ipv4.tcp_ecn")
rx.sudo("docker exec rfsim5g-oai-nr-ue2 sysctl net.ipv4.tcp_congestion_control")
```


At the rx0 node. 
```
sudo ip route add 12.1.1.64/26 via 192.168.70.140

sudo ip route add 12.1.1.128/25 via 192.168.70.134

sudo iptables -P FORWARD ACCEPT
```

> very important
at the ue1 namespace:
```
sudo ip netns exec ue1 bash
sudo /mydata/summerworkshop2023/ran/multi-ue.sh -c1 -e 
sudo ip route add default via 10.201.1.100
```
so that the icmp messages can be routed back to the sender. 


at the ue3 namesapce:
```
sudo ip netns exec ue3 bash
sudo /mydata/summerworkshop2023/ran/multi-ue.sh -c3 -e 

sudo ip route add default via 10.203.1.100
```




