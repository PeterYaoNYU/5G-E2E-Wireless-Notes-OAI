#### using tshark to capture E2 packets 

Running ip a before doing anything
```
PeterYao@node:/opt/oai-cn5g-fed/docker-compose$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 14:18:77:26:6a:50 brd ff:ff:ff:ff:ff:ff
    inet 155.98.36.82/22 brd 155.98.39.255 scope global eno1
       valid_lft forever preferred_lft forever
    inet6 fe80::1618:77ff:fe26:6a50/64 scope link
       valid_lft forever preferred_lft forever
3: eno2: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 14:18:77:26:6a:51 brd ff:ff:ff:ff:ff:ff
4: enp6s0f0: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a0 brd ff:ff:ff:ff:ff:ff
5: enp4s0f0: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether a0:36:9f:6b:fb:a2 brd ff:ff:ff:ff:ff:ff
6: enp4s0f1: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether a0:36:9f:6b:fb:a3 brd ff:ff:ff:ff:ff:ff
7: enp6s0f1: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a2 brd ff:ff:ff:ff:ff:ff
8: enp6s0f2: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a4 brd ff:ff:ff:ff:ff:ff
9: enp6s0f3: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a6 brd ff:ff:ff:ff:ff:ff
10: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:c9:3a:ea:b8 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
```

First we bring up the core network:
``` bash
cd /opt/oai-cn5g-fed/docker-compose  

sudo python3 ./core-network.py --type stop-basic --scenario 1

sudo python3 ./core-network.py --type start-mini --scenario 1

sudo docker ps
```

Then we check the available interfaces:
```
PeterYao@node:/opt/oai-cn5g-fed/docker-compose$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 14:18:77:26:6a:50 brd ff:ff:ff:ff:ff:ff
    inet 155.98.36.82/22 brd 155.98.39.255 scope global eno1
       valid_lft forever preferred_lft forever
    inet6 fe80::1618:77ff:fe26:6a50/64 scope link
       valid_lft forever preferred_lft forever
3: eno2: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 14:18:77:26:6a:51 brd ff:ff:ff:ff:ff:ff
4: enp6s0f0: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a0 brd ff:ff:ff:ff:ff:ff
5: enp4s0f0: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether a0:36:9f:6b:fb:a2 brd ff:ff:ff:ff:ff:ff
6: enp4s0f1: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether a0:36:9f:6b:fb:a3 brd ff:ff:ff:ff:ff:ff
7: enp6s0f1: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a2 brd ff:ff:ff:ff:ff:ff
8: enp6s0f2: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a4 brd ff:ff:ff:ff:ff:ff
9: enp6s0f3: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a6 brd ff:ff:ff:ff:ff:ff
10: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:c9:3a:ea:b8 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
58: demo-oai: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:a7:b9:b5:3c brd ff:ff:ff:ff:ff:ff
    inet 192.168.70.129/26 brd 192.168.70.191 scope global demo-oai
       valid_lft forever preferred_lft forever
    inet6 fe80::42:a7ff:feb9:b53c/64 scope link
       valid_lft forever preferred_lft forever
60: vetha14131f@if59: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether 66:6f:df:a8:3c:45 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::646f:dfff:fea8:3c45/64 scope link
       valid_lft forever preferred_lft forever
62: vethec411ba@if61: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether 9a:7c:22:f9:77:00 brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::987c:22ff:fef9:7700/64 scope link
       valid_lft forever preferred_lft forever
64: veth6cbc019@if63: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether 0a:dc:59:16:a7:7c brd ff:ff:ff:ff:ff:ff link-netnsid 2
    inet6 fe80::8dc:59ff:fe16:a77c/64 scope link
       valid_lft forever preferred_lft forever
66: vethb7a84c0@if65: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether 8e:a5:fc:16:9a:05 brd ff:ff:ff:ff:ff:ff link-netnsid 3
    inet6 fe80::8ca5:fcff:fe16:9a05/64 scope link
       valid_lft forever preferred_lft forever
68: vethbb99529@if67: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether de:ec:c6:0d:e2:ae brd ff:ff:ff:ff:ff:ff link-netnsid 4
    inet6 fe80::dcec:c6ff:fe0d:e2ae/64 scope link
       valid_lft forever preferred_lft forever
70: veth2787a66@if69: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether 6a:bd:26:f9:c4:08 brd ff:ff:ff:ff:ff:ff link-netnsid 5
    inet6 fe80::68bd:26ff:fef9:c408/64 scope link
       valid_lft forever preferred_lft foreve
```

We can see that there are a lot of new interfaces. 

Then we start the flexric:
```
cd /mydata/flexric
./build/examples/ric/nearRT-RIC
```

And the network interfaces are:
```
PeterYao@node:/opt/oai-cn5g-fed/docker-compose$ ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: eno1: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 14:18:77:26:6a:50 brd ff:ff:ff:ff:ff:ff
    inet 155.98.36.82/22 brd 155.98.39.255 scope global eno1
       valid_lft forever preferred_lft forever
    inet6 fe80::1618:77ff:fe26:6a50/64 scope link
       valid_lft forever preferred_lft forever
3: eno2: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 14:18:77:26:6a:51 brd ff:ff:ff:ff:ff:ff
4: enp6s0f0: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a0 brd ff:ff:ff:ff:ff:ff
5: enp4s0f0: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether a0:36:9f:6b:fb:a2 brd ff:ff:ff:ff:ff:ff
6: enp4s0f1: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether a0:36:9f:6b:fb:a3 brd ff:ff:ff:ff:ff:ff
7: enp6s0f1: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a2 brd ff:ff:ff:ff:ff:ff
8: enp6s0f2: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a4 brd ff:ff:ff:ff:ff:ff
9: enp6s0f3: <BROADCAST,MULTICAST> mtu 1500 qdisc mq state DOWN group default qlen 1000
    link/ether 3c:fd:fe:05:91:a6 brd ff:ff:ff:ff:ff:ff
10: docker0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default
    link/ether 02:42:c9:3a:ea:b8 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
58: demo-oai: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:a7:b9:b5:3c brd ff:ff:ff:ff:ff:ff
    inet 192.168.70.129/26 brd 192.168.70.191 scope global demo-oai
       valid_lft forever preferred_lft forever
    inet6 fe80::42:a7ff:feb9:b53c/64 scope link
       valid_lft forever preferred_lft forever
60: vetha14131f@if59: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether 66:6f:df:a8:3c:45 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet6 fe80::646f:dfff:fea8:3c45/64 scope link
       valid_lft forever preferred_lft forever
62: vethec411ba@if61: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether 9a:7c:22:f9:77:00 brd ff:ff:ff:ff:ff:ff link-netnsid 1
    inet6 fe80::987c:22ff:fef9:7700/64 scope link
       valid_lft forever preferred_lft forever
64: veth6cbc019@if63: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether 0a:dc:59:16:a7:7c brd ff:ff:ff:ff:ff:ff link-netnsid 2
    inet6 fe80::8dc:59ff:fe16:a77c/64 scope link
       valid_lft forever preferred_lft forever
66: vethb7a84c0@if65: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether 8e:a5:fc:16:9a:05 brd ff:ff:ff:ff:ff:ff link-netnsid 3
    inet6 fe80::8ca5:fcff:fe16:9a05/64 scope link
       valid_lft forever preferred_lft forever
68: vethbb99529@if67: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether de:ec:c6:0d:e2:ae brd ff:ff:ff:ff:ff:ff link-netnsid 4
    inet6 fe80::dcec:c6ff:fe0d:e2ae/64 scope link
       valid_lft forever preferred_lft forever
70: veth2787a66@if69: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue master demo-oai state UP group default
    link/ether 6a:bd:26:f9:c4:08 brd ff:ff:ff:ff:ff:ff link-netnsid 5
    inet6 fe80::68bd:26ff:fef9:c408/64 scope link
       valid_lft forever preferred_lft forever

```
the network interfaces do not change, and I assume that it is because that the flexric is just an application, not some contianers with virtualized network interfaces. 

Fine, I mean, there are two approaches when captureing traffic with tcpdump. We can capture the receiving interface or the sending interface. I think in this case, I am more inclined to capturing traffic from the base station interface. So here let us bring up one base station interface. 

```bash
cd /mydata/openairinterface5g/cmake_targets
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /local/repository/etc/gnb.conf --sa --rfsim
```

Damn, I forgot that the gNB is also just a single process, not a container with virtual interfaces. Let me thing how to capture. 

Fine I will just capture the 127.0.0.1 interface. 
First I shut down the flexric and the gnb, and start capturing on Loopback. 

```
sudo tcpdump -i lo -f "sctp" -w /mydata/e2traffic.pcap
```

Then I start the gnb, and then the flexric. 

After they are running for a while, stop the tcpdum process. 

Analyze the packet with tshark, first show which port they are coming from and going to, because this is important to different between E2 traffic and other loopback traffic. 

```
tshark -r /mydata/e2traffic.pcap -T fields -e frame.number -e ip.src -e tcp.srcport -e sctp.srcport -e ip.dst -e tcp.dstport -e sctp.dstport -e frame.time -e _ws.col.Info
```

The result is as follows:

```
PeterYao@node:~$ tshark -r /mydata/e2traffic.pcap -T fields -e frame.number -e ip.src -e tcp.srcport -e sctp.srcport -e ip.dst -e tcp.dstport -e sctp.dstport -e frame.time -e _ws.col.Info
1       127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:15:50.635203000 MDT INIT
2       127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:15:50.635267000 MDT INIT_ACK
3       127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:15:50.635301000 MDT COOKIE_ECHO DATA
4       127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:15:50.635365000 MDT COOKIE_ACK SACK
5       127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:15:50.635932000 MDT DATA
6       127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:15:50.635958000 MDT SACK
7       127.0.0.1               36421   155.98.36.82            32866   Jun 25, 2024 10:15:52.923596000 MDT HEARTBEAT
8       127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:15:52.923632000 MDT HEARTBEAT_ACK
9       127.0.0.1               36421   172.17.0.1              32866   Jun 25, 2024 10:15:53.179568000 MDT HEARTBEAT
10      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:15:53.179592000 MDT HEARTBEAT_ACK
11      127.0.0.1               36421   192.168.70.129          32866   Jun 25, 2024 10:15:53.435565000 MDT HEARTBEAT
12      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:15:53.435591000 MDT HEARTBEAT_ACK
13      127.0.0.1               36421   192.168.70.129          32866   Jun 25, 2024 10:16:24.411579000 MDT HEARTBEAT
14      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:16:24.411622000 MDT HEARTBEAT_ACK
15      127.0.0.1               36421   172.17.0.1              32866   Jun 25, 2024 10:16:24.411642000 MDT HEARTBEAT
16      127.0.0.1               36421   155.98.36.82            32866   Jun 25, 2024 10:16:24.411661000 MDT HEARTBEAT
17      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:16:24.411671000 MDT HEARTBEAT
18      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:16:24.411694000 MDT HEARTBEAT_ACK
19      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:16:24.411702000 MDT HEARTBEAT_ACK
20      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:16:24.411712000 MDT HEARTBEAT_ACK
21      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:16:26.459547000 MDT HEARTBEAT
22      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:16:26.459592000 MDT HEARTBEAT_ACK
23      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:16:55.131564000 MDT HEARTBEAT
24      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:16:55.131614000 MDT HEARTBEAT_ACK
25      127.0.0.1               36421   192.168.70.129          32866   Jun 25, 2024 10:16:57.179576000 MDT HEARTBEAT
26      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:16:57.179609000 MDT HEARTBEAT_ACK
27      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:16:57.179528000 MDT HEARTBEAT
28      127.0.0.1               36421   155.98.36.82            32866   Jun 25, 2024 10:16:57.179607000 MDT HEARTBEAT
29      127.0.0.1               36421   172.17.0.1              32866   Jun 25, 2024 10:16:57.179621000 MDT HEARTBEAT
30      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:16:57.179651000 MDT HEARTBEAT_ACK
31      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:16:57.179660000 MDT HEARTBEAT_ACK
32      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:16:57.179668000 MDT HEARTBEAT_ACK
33      127.0.0.1               36421   155.98.36.82            32866   Jun 25, 2024 10:17:27.899571000 MDT HEARTBEAT
34      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:27.899584000 MDT HEARTBEAT
35      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:27.899614000 MDT HEARTBEAT_ACK
36      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:17:27.899625000 MDT HEARTBEAT_ACK
37      127.0.0.1               36421   192.168.70.129          32866   Jun 25, 2024 10:17:29.947563000 MDT HEARTBEAT
38      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:29.947589000 MDT HEARTBEAT_ACK
39      127.0.0.1               36421   172.17.0.1              32866   Jun 25, 2024 10:17:29.947604000 MDT HEARTBEAT
40      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:17:29.947618000 MDT HEARTBEAT
41      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:29.947671000 MDT HEARTBEAT_ACK
42      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:29.947680000 MDT HEARTBEAT_ACK
43      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:17:43.200450000 MDT SHUTDOWN
44      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:43.200488000 MDT SHUTDOWN_ACK
45      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:17:43.200503000 MDT SHUTDOWN_COMPLETE
46      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:46.201086000 MDT INIT
47      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:17:46.201108000 MDT ABORT
48      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:49.200969000 MDT INIT
49      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:17:49.200990000 MDT ABORT
50      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:52.201020000 MDT INIT
51      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:17:52.201082000 MDT INIT_ACK
52      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:52.201118000 MDT COOKIE_ECHO DATA
53      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:17:52.201181000 MDT COOKIE_ACK SACK
54      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:17:52.201792000 MDT DATA
55      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:52.201818000 MDT SACK
56      127.0.0.1               36421   172.17.0.1              32866   Jun 25, 2024 10:17:54.783572000 MDT HEARTBEAT
57      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:54.783600000 MDT HEARTBEAT_ACK
58      127.0.0.1               36421   155.98.36.82            32866   Jun 25, 2024 10:17:56.059554000 MDT HEARTBEAT
59      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:56.059579000 MDT HEARTBEAT_ACK
60      127.0.0.1               36421   192.168.70.129          32866   Jun 25, 2024 10:17:56.571543000 MDT HEARTBEAT
61      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:17:56.571582000 MDT HEARTBEAT_ACK
62      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:18:25.243536000 MDT HEARTBEAT
63      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:18:25.243546000 MDT HEARTBEAT
64      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:18:25.243615000 MDT HEARTBEAT_ACK
65      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:18:25.243624000 MDT HEARTBEAT_ACK
66      127.0.0.1               36421   172.17.0.1              32866   Jun 25, 2024 10:18:27.291565000 MDT HEARTBEAT
67      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:18:27.291598000 MDT HEARTBEAT_ACK
68      127.0.0.1               36421   192.168.70.129          32866   Jun 25, 2024 10:18:29.339573000 MDT HEARTBEAT
69      127.0.0.1               36421   155.98.36.82            32866   Jun 25, 2024 10:18:29.339588000 MDT HEARTBEAT
70      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:18:29.339632000 MDT HEARTBEAT_ACK
71      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:18:29.339640000 MDT HEARTBEAT_ACK
72      127.0.0.1               36421   172.17.0.1              32866   Jun 25, 2024 10:18:58.011550000 MDT HEARTBEAT
73      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:18:58.011597000 MDT HEARTBEAT_ACK
74      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:18:58.011590000 MDT HEARTBEAT
75      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:18:58.011608000 MDT HEARTBEAT
76      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:18:58.011655000 MDT HEARTBEAT_ACK
77      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:18:58.011666000 MDT HEARTBEAT_ACK
78      127.0.0.1               36421   192.168.70.129          32866   Jun 25, 2024 10:19:00.059573000 MDT HEARTBEAT
79      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:19:00.059616000 MDT HEARTBEAT_ACK
80      127.0.0.1               36421   155.98.36.82            32866   Jun 25, 2024 10:19:02.107557000 MDT HEARTBEAT
81      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:19:02.107600000 MDT HEARTBEAT_ACK
82      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:19:02.240897000 MDT SHUTDOWN
83      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:19:02.240928000 MDT SHUTDOWN_ACK
84      127.0.0.1               36421   127.0.0.1               32866   Jun 25, 2024 10:19:02.240942000 MDT SHUTDOWN_COMPLETE
85      127.0.0.1               32866   127.0.0.1               36421   Jun 25, 2024 10:19:05.241737000 MDT INIT
```


Form the output of the flexric we know that the flexric port number is indeed 36421. 

```
PeterYao@node:/mydata/flexric$ ./build/examples/ric/nearRT-RIC
[UTIL]: Setting the config -c file to /usr/local/etc/flexric/flexric.conf
[UTIL]: Setting path -p for the shared libraries to /usr/local/lib/flexric/
[NEAR-RIC]: nearRT-RIC IP Address = 127.0.0.1, PORT = 36421
[NEAR-RIC]: Initializing
[NEAR-RIC]: Loading SM ID = 142 with def = MAC_STATS_V0
[NEAR-RIC]: Loading SM ID = 146 with def = TC_STATS_V0
[NEAR-RIC]: Loading SM ID = 148 with def = GTP_STATS_V0
[NEAR-RIC]: Loading SM ID = 2 with def = ORAN-E2SM-KPM
[NEAR-RIC]: Loading SM ID = 143 with def = RLC_STATS_V0
[NEAR-RIC]: Loading SM ID = 3 with def = ORAN-E2SM-RC
[NEAR-RIC]: Loading SM ID = 145 with def = SLICE_STATS_V0
[NEAR-RIC]: Loading SM ID = 144 with def = PDCP_STATS_V0
[iApp]: Initializing ...
[iApp]: nearRT-RIC IP Address = 127.0.0.1, PORT = 36422
[NEAR-RIC]: Initializing Task Manager with 2 threads
[E2AP]: E2 SETUP-REQUEST rx from PLMN 208.95 Node ID 3584 RAN type ngran_gNB
[NEAR-RIC]: Accepting RAN function ID 2 with def = ORAN-E2SM-KPM
[NEAR-RIC]: Accepting RAN function ID 3 with def = ORAN-E2SM-RC
[NEAR-RIC]: Accepting RAN function ID 142 with def = MAC_STATS_V0
[NEAR-RIC]: Accepting RAN function ID 143 with def = RLC_STATS_V0
[NEAR-RIC]: Accepting RAN function ID 144 with def = PDCP_STATS_V0
[NEAR-RIC]: Accepting RAN function ID 145 with def = SLICE_STATS_V0
[NEAR-RIC]: Accepting RAN function ID 146 with def = TC_STATS_V0
[NEAR-RIC]: Accepting RAN function ID 148 with def = GTP_STATS_V0
^C
[NEAR-RIC]: Abruptly ending with signal number = 2
```

I am not sure how to check the port number of the gNB, as it is not printed in its log, but I assume that the number should be 32866. 

Next I want to dig into those packets. Looking into the first packet:

```
PeterYao@node:~$ tshark -r /mydata/e2traffic.pcap -V -Y "frame.number == 1"
Frame 1: 114 bytes on wire (912 bits), 114 bytes captured (912 bits)
    Encapsulation type: Ethernet (1)
    Arrival Time: Jun 25, 2024 10:15:50.635203000 MDT
    [Time shift for this packet: 0.000000000 seconds]
    Epoch Time: 1719332150.635203000 seconds
    [Time delta from previous captured frame: 0.000000000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 0.000000000 seconds]
    Frame Number: 1
    Frame Length: 114 bytes (912 bits)
    Capture Length: 114 bytes (912 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:sctp]
Ethernet II, Src: 00:00:00_00:00:00 (00:00:00:00:00:00), Dst: 00:00:00_00:00:00 (00:00:00:00:00:00)
    Destination: 00:00:00_00:00:00 (00:00:00:00:00:00)
        Address: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: 00:00:00_00:00:00 (00:00:00:00:00:00)
        Address: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x02 (DSCP: CS0, ECN: ECT(0))
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..10 = Explicit Congestion Notification: ECN-Capable Transport codepoint '10' (2)
    Total Length: 100
    Identification: 0x0000 (0)
    Flags: 0x40, Don't fragment
        0... .... = Reserved bit: Not set
        .1.. .... = Don't fragment: Set
        ..0. .... = More fragments: Not set
    Fragment Offset: 0
    Time to Live: 64
    Protocol: SCTP (132)
    Header Checksum: 0x3c12 [validation disabled]
    [Header checksum status: Unverified]
    Source Address: 127.0.0.1
    Destination Address: 127.0.0.1
Stream Control Transmission Protocol, Src Port: 32866 (32866), Dst Port: 36421 (36421)
    Source port: 32866
    Destination port: 36421
    Verification tag: 0x00000000
    [Association index: 65535]
    Checksum: 0x00000000 [unverified]
    [Checksum Status: Unverified]
    INIT chunk (Outbound streams: 10, inbound streams: 65535)
        Chunk type: INIT (1)
            0... .... = Bit: Stop processing of the packet
            .0.. .... = Bit: Do not report
        Chunk flags: 0x00
        Chunk length: 68
        Initiate tag: 0xaa962225
        Advertised receiver window credit (a_rwnd): 106496
        Number of outbound streams: 10
        Number of inbound streams: 65535
        Initial TSN: 92860594
        IPv4 address parameter (Address: 127.0.0.1)
            Parameter type: IPv4 address (0x0005)
                0... .... .... .... = Bit: Stop processing of chunk
                .0.. .... .... .... = Bit: Do not report
            Parameter length: 8
            IP Version 4 address: 127.0.0.1
        IPv4 address parameter (Address: 155.98.36.82)
            Parameter type: IPv4 address (0x0005)
                0... .... .... .... = Bit: Stop processing of chunk
                .0.. .... .... .... = Bit: Do not report
            Parameter length: 8
            IP Version 4 address: 155.98.36.82
        IPv4 address parameter (Address: 172.17.0.1)
            Parameter type: IPv4 address (0x0005)
                0... .... .... .... = Bit: Stop processing of chunk
                .0.. .... .... .... = Bit: Do not report
            Parameter length: 8
            IP Version 4 address: 172.17.0.1
        IPv4 address parameter (Address: 192.168.70.129)
            Parameter type: IPv4 address (0x0005)
                0... .... .... .... = Bit: Stop processing of chunk
                .0.. .... .... .... = Bit: Do not report
            Parameter length: 8
            IP Version 4 address: 192.168.70.129
        Supported address types parameter (Supported types: IPv4)
            Parameter type: Supported address types (0x000c)
                0... .... .... .... = Bit: Stop processing of chunk
                .0.. .... .... .... = Bit: Do not report
            Parameter length: 6
            Supported address type: IPv4 address (5)
            Parameter padding: 0000
        ECN parameter
            Parameter type: ECN (0x8000)
                1... .... .... .... = Bit: Skip parameter and continue processing of the chunk
                .0.. .... .... .... = Bit: Do not report
            Parameter length: 4
        Forward TSN supported parameter
            Parameter type: Forward TSN supported (0xc000)
                1... .... .... .... = Bit: Skip parameter and continue processing of the chunk
                .1.. .... .... .... = Bit: Do report
            Parameter length: 4
```

My bad for not being familiar with the SCTP protocol, it is just a init packet in the SCTP init process. Maybe the real E2 init message is in frame 5 or 6.

###### Frame 5
```
PeterYao@node:~$ tshark -r /mydata/e2traffic.pcap -V -Y "frame.number == 5"
Frame 5: 190 bytes on wire (1520 bits), 190 bytes captured (1520 bits)
    Encapsulation type: Ethernet (1)
    Arrival Time: Jun 25, 2024 10:15:50.635932000 MDT
    [Time shift for this packet: 0.000000000 seconds]
    Epoch Time: 1719332150.635932000 seconds
    [Time delta from previous captured frame: 0.000567000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 0.000729000 seconds]
    Frame Number: 5
    Frame Length: 190 bytes (1520 bits)
    Capture Length: 190 bytes (1520 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:sctp:data]
Ethernet II, Src: 00:00:00_00:00:00 (00:00:00:00:00:00), Dst: 00:00:00_00:00:00 (00:00:00:00:00:00)
    Destination: 00:00:00_00:00:00 (00:00:00:00:00:00)
        Address: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: 00:00:00_00:00:00 (00:00:00:00:00:00)
        Address: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x02 (DSCP: CS0, ECN: ECT(0))
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..10 = Explicit Congestion Notification: ECN-Capable Transport codepoint '10' (2)
    Total Length: 176
    Identification: 0x0000 (0)
    Flags: 0x40, Don't fragment
        0... .... = Reserved bit: Not set
        .1.. .... = Don't fragment: Set
        ..0. .... = More fragments: Not set
    Fragment Offset: 0
    Time to Live: 64
    Protocol: SCTP (132)
    Header Checksum: 0x3bc6 [validation disabled]
    [Header checksum status: Unverified]
    Source Address: 127.0.0.1
    Destination Address: 127.0.0.1
Stream Control Transmission Protocol, Src Port: 36421 (36421), Dst Port: 32866 (32866)
    Source port: 36421
    Destination port: 32866
    Verification tag: 0xaa962225
    [Association index: 65535]
    Checksum: 0x00000000 [unverified]
    [Checksum Status: Unverified]
    DATA chunk(ordered, complete segment, TSN: 2057255573, SID: 0, SSN: 0, PPID: 0, payload length: 128 bytes)
        Chunk type: DATA (0)
            0... .... = Bit: Stop processing of the packet
            .0.. .... = Bit: Do not report
        Chunk flags: 0x03
            .... 0... = I-Bit: Possibly delay SACK
            .... .0.. = U-Bit: Ordered delivery
            .... ..1. = B-Bit: First segment
            .... ...1 = E-Bit: Last segment
        Chunk length: 144
        Transmission sequence number: 2057255573
        Stream identifier: 0x0000
        Stream sequence number: 0
        Payload protocol identifier: not specified (0)
Data (128 bytes)

0000  20 01 00 7c 00 00 04 00 31 00 02 00 00 00 04 00    ..|....1.......
0010  07 00 02 f8 59 00 01 90 00 09 00 49 07 00 06 40   ....Y......I...@
0020  05 00 00 02 00 00 00 06 40 05 00 00 03 00 00 00   ........@.......
0030  06 40 05 00 00 8e 00 00 00 06 40 05 00 00 8f 00   .@........@.....
0040  00 00 06 40 05 00 00 90 00 00 00 06 40 05 00 00   ...@........@...
0050  91 00 00 00 06 40 05 00 00 92 00 00 00 06 40 05   .....@........@.
0060  00 00 94 00 00 00 34 00 17 00 00 00 35 00 11 00   ......4.....5...
0070  01 80 44 75 6d 6d 79 20 6d 65 73 73 61 67 65 00   ..Dummy message.
    Data: 2001007c000004003100020000000400070002f859000190000900490700064005000002…
    [Length: 128]

```

This frame is from the RIC to the E2 node, and it is not showing much interesting content. The payload is not giving me any information. 

###### frame 6
```
PeterYao@node:~$ tshark -r /mydata/e2traffic.pcap -V -Y "frame.number == 6"
Frame 6: 62 bytes on wire (496 bits), 62 bytes captured (496 bits)
    Encapsulation type: Ethernet (1)
    Arrival Time: Jun 25, 2024 10:15:50.635958000 MDT
    [Time shift for this packet: 0.000000000 seconds]
    Epoch Time: 1719332150.635958000 seconds
    [Time delta from previous captured frame: 0.000026000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 0.000755000 seconds]
    Frame Number: 6
    Frame Length: 62 bytes (496 bits)
    Capture Length: 62 bytes (496 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:sctp]
Ethernet II, Src: 00:00:00_00:00:00 (00:00:00:00:00:00), Dst: 00:00:00_00:00:00 (00:00:00:00:00:00)
    Destination: 00:00:00_00:00:00 (00:00:00:00:00:00)
        Address: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: 00:00:00_00:00:00 (00:00:00:00:00:00)
        Address: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x02 (DSCP: CS0, ECN: ECT(0))
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..10 = Explicit Congestion Notification: ECN-Capable Transport codepoint '10' (2)
    Total Length: 48
    Identification: 0x0000 (0)
    Flags: 0x40, Don't fragment
        0... .... = Reserved bit: Not set
        .1.. .... = Don't fragment: Set
        ..0. .... = More fragments: Not set
    Fragment Offset: 0
    Time to Live: 64
    Protocol: SCTP (132)
    Header Checksum: 0x3c46 [validation disabled]
    [Header checksum status: Unverified]
    Source Address: 127.0.0.1
    Destination Address: 127.0.0.1
Stream Control Transmission Protocol, Src Port: 32866 (32866), Dst Port: 36421 (36421)
    Source port: 32866
    Destination port: 36421
    Verification tag: 0xc4ad7322
    [Association index: 65535]
    Checksum: 0x00000000 [unverified]
    [Checksum Status: Unverified]
    SACK chunk (Cumulative TSN: 2057255573, a_rwnd: 106368, gaps: 0, duplicate TSNs: 0)
        Chunk type: SACK (3)
            0... .... = Bit: Stop processing of the packet
            .0.. .... = Bit: Do not report
        Chunk flags: 0x00
            .... ...0 = Nounce sum: 0
        Chunk length: 16
        Cumulative TSN ACK: 2057255573
            [Acknowledges TSN: 2057255573]
                [Acknowledges TSN in frame: 5]
                [The RTT since DATA was: 0.000026000 seconds]
        Advertised receiver window credit (a_rwnd): 106368
        Number of gap acknowledgement blocks: 0
        Number of duplicated TSNs: 0

```
This SACK packet is not of much interest, it is just acknowledging the receipt of the previous DATA chunk.   

Fine, I am hoping that the hearbeat packet would show more information? 

```
PeterYao@node:~$ tshark -r /mydata/e2traffic.pcap -V -Y "frame.number == 7"
Frame 7: 98 bytes on wire (784 bits), 98 bytes captured (784 bits)
    Encapsulation type: Ethernet (1)
    Arrival Time: Jun 25, 2024 10:15:52.923596000 MDT
    [Time shift for this packet: 0.000000000 seconds]
    Epoch Time: 1719332152.923596000 seconds
    [Time delta from previous captured frame: 2.287638000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 2.288393000 seconds]
    Frame Number: 7
    Frame Length: 98 bytes (784 bits)
    Capture Length: 98 bytes (784 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:sctp]
Ethernet II, Src: 00:00:00_00:00:00 (00:00:00:00:00:00), Dst: 00:00:00_00:00:00 (00:00:00:00:00:00)
    Destination: 00:00:00_00:00:00 (00:00:00:00:00:00)
        Address: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: 00:00:00_00:00:00 (00:00:00:00:00:00)
        Address: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 155.98.36.82
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x02 (DSCP: CS0, ECN: ECT(0))
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..10 = Explicit Congestion Notification: ECN-Capable Transport codepoint '10' (2)
    Total Length: 84
    Identification: 0x0000 (0)
    Flags: 0x40, Don't fragment
        0... .... = Reserved bit: Not set
        .1.. .... = Don't fragment: Set
        ..0. .... = More fragments: Not set
    Fragment Offset: 0
    Time to Live: 64
    Protocol: SCTP (132)
    Header Checksum: 0xfb6e [validation disabled]
    [Header checksum status: Unverified]
    Source Address: 127.0.0.1
    Destination Address: 155.98.36.82
Stream Control Transmission Protocol, Src Port: 36421 (36421), Dst Port: 32866 (32866)
    Source port: 36421
    Destination port: 32866
    Verification tag: 0xaa962225
    [Association index: 65535]
    Checksum: 0x00000000 [unverified]
    [Checksum Status: Unverified]
    HEARTBEAT chunk (Information: 48 bytes)
        Chunk type: HEARTBEAT (4)
            0... .... = Bit: Stop processing of the packet
            .0.. .... = Bit: Do not report
        Chunk flags: 0x00
        Chunk length: 52
        Heartbeat info parameter (Information: 44 bytes)
            Parameter type: Heartbeat info (0x0001)
                0... .... .... .... = Bit: Stop processing of chunk
                .0.. .... .... .... = Bit: Do not report
            Parameter length: 48
            Heartbeat information: 020080629b622452000000000000000050394c5f038cffff607f8d41403f5d0201000000…

```
well, not really, it is really just heatbeat packets. 


I also want to see the E2 request packet, so I start the same data captrue, then start the e2 node gnb, but do not start the flexric. 


I see this, so I am hoping that it would give me something
```
[E2 AGENT]: E2 SETUP REQUEST timeout. Resending again (tx)
[NR_MAC]   Frame.Slot 128.0

[E2 AGENT]: E2 SETUP REQUEST timeout. Resending again (tx)
[NR_MAC]   Frame.Slot 256.0

[E2 AGENT]: E2 SETUP REQUEST timeout. Resending again (tx)
```


### Fine, I think it is because the tshark version that we are using is just too old. It does not have a E2AP dissector, so it only sees SCTP protol, and nothing more. 

according to the srsRAN tutorial: https://docs.srsran.com/projects/project/en/latest/tutorials/source/near-rt-ric/source/index.html, we want a version higher than 4.0.7, and right now our version is 
```
PeterYao@node:~$ tshark -v
TShark (Wireshark) 3.4.8 (Git v3.4.8 packaged as 3.4.8-1~ubuntu18.04.0+wiresharkdevstable1)
```

Installing the new version of the tshark is not a verys straightforward process. Using a package manager does not work, as with Ubuntu 18, the package manager only gives you as much as version 3.15, which is not enough.We need to build from source. 

first remove all previous installation of wireshark and tshark:

```
  300  sudo apt-get remove --purge wireshark wireshark-common wireshark-dev tshark
  301  sudo apt-get autoremove
  302  which wireshark
  303  which tshark
  304  sudo apt-get remove --purge tshark
  305  tshark -v
  306  which tshark
    313  sudo rm /usr/local/bin/tshark
  314  which tshark
``` 
verify with which tshark, remove until there is nothing left. 

Download the wireshark from gitlab, build with qt support (only install tshark then). 

```bash 
sudo apt-get install libc-ares-dev
sudo apt-get install libspeexdsp-dev
sudo apt-get install asciidoctor xsltproc
git clone https://gitlab.com/wireshark/wireshark.git
cd wireshark
git checkout master
mkdir build
cd build 
cmake.. -DBUILD_wireshark=OFF
make -j 8
sudo make install 
sudo ldconfig
```

verify the tshark version and the supported protocols:
```bash
export PATH=/usr/local/bin:$PATH
tshark -v
```
```bash
TShark (Wireshark) 4.3.0 (v4.3.0rc1-192-g3a00768fb421).

Copyright 1998-2024 Gerald Combs <gerald@wireshark.org> and contributors.
Licensed under the terms of the GNU General Public License (version 2 or later).
This is free software; see the file named COPYING in the distribution. There is
NO WARRANTY; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

Compiled (64-bit) using GCC 9.4.0, with GLib 2.56.4, with libpcap, with POSIX
capabilities (Linux), without libnl, with zlib 1.2.11, without zlib-ng, with
PCRE2, without Lua, with GnuTLS 3.5.18 and PKCS #11 support, with Gcrypt 1.8.1,
without Kerberos, without MaxMind, without nghttp2, without nghttp3, without
brotli, without LZ4, without Zstandard, without Snappy, with libxml2 2.9.4,
without libsmi, with binary plugins.

Running on Linux 4.15.0-159-generic, with Intel(R) Xeon(R) CPU E5-2630 v3 @
2.40GHz (with SSE4.2), with 64326 MB of physical memory, with GLib 2.56.4, with
libpcap 1.8.1, with zlib 1.2.11, with PCRE2 10.31 2018-02-12, with c-ares
1.14.0, with GnuTLS 3.5.18, with Gcrypt 1.8.1, with LC_TYPE=en_US.UTF-8, binary
plugins supported.
```

```
PeterYao@node:/mydata/wireshark/build$ tshark -G protocols | grep e2ap
E2 Application Protocol E2AP    e2ap    T       T       T
```

Using the new tshark to analyze, and we are finally getting something interesting. 

```
PeterYao@node:/mydata$ sudo tshark -r /mydata/e2ap_packets_all.pcap -d sctp.port==36421,e2apRunning as user "root" and group "root". This could be dangerous.
    1 0.000000000    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
    2 0.000021725    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
    3 3.000356597    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
    4 3.000379784    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
    5 6.000278315    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
    6 6.000296269    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
    7 9.000369478    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
    8 9.000394023    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
    9 12.000494380    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
   10 12.000513749    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
   11 15.000358993    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
   12 15.000382958    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
   13 18.000376213    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
   14 18.000403091    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
   15 21.000363258    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
   16 21.000397247    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
   17 24.000366964    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
   18 24.000390425    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
   19 27.000235090    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
   20 27.000253689    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
   21 30.000366217    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
   22 30.000390465    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
   23 33.000371595    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
   24 33.000396650    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
   25 36.000241138    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
   26 36.000259336    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
   27 39.000373305    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
   28 39.000440699    127.0.0.1 → 127.0.0.1    SCTP 338 INIT_ACK
   29 39.000474135    127.0.0.1 → 127.0.0.1    E2AP|NGAP 1374 COOKIE_ECHO , E2setupRequest
   30 39.000536156    127.0.0.1 → 127.0.0.1    SCTP 66 COOKIE_ACK SACK (Ack=0, Arwnd=105448)

   31 39.001161883    127.0.0.1 → 127.0.0.1    E2AP 190 E2setupResponse
   32 39.001189314    127.0.0.1 → 127.0.0.1    SCTP 62 SACK (Ack=0, Arwnd=106368)
   33 41.378029636    127.0.0.1 → 192.168.70.129 SCTP 98 HEARTBEAT
   34 41.378081670    127.0.0.1 → 127.0.0.1    SCTP 98 HEARTBEAT_ACK
   35 41.634038982    127.0.0.1 → 155.98.36.82 SCTP 98 HEARTBEAT
   36 41.634062432    127.0.0.1 → 127.0.0.1    SCTP 98 HEARTBEAT_ACK
   37 42.146011999    127.0.0.1 → 172.17.0.1   SCTP 98 HEARTBEAT
   38 42.146037468    127.0.0.1 → 127.0.0.1    SCTP 98 HEARTBEAT_ACK
   39 55.120521159    127.0.0.1 → 127.0.0.1    SCTP 54 SHUTDOWN
   40 55.120556193    127.0.0.1 → 127.0.0.1    SCTP 50 SHUTDOWN_ACK
   41 55.120571430    127.0.0.1 → 127.0.0.1    SCTP 50 SHUTDOWN_COMPLETE
   42 58.121100166    127.0.0.1 → 127.0.0.1    SCTP 114 INIT
   43 58.121120766    127.0.0.1 → 127.0.0.1    SCTP 50 ABORT
```

Two packets are reconginized as e2ap packets, specifically the setup request and response. 

zoom in a little. 
```
PeterYao@node:/mydata$ sudo tshark -r /mydata/e2ap_packets_all.pcap -d sctp.port==36421,e2ap -Y "e2ap"
Running as user "root" and group "root". This could be dangerous.
   29 39.000474135    127.0.0.1 → 127.0.0.1    E2AP|NGAP 1374 COOKIE_ECHO , E2setupRequest
   31 39.001161883    127.0.0.1 → 127.0.0.1    E2AP 190 E2setupResponse
```

The content of the packet, for the setup:
```
Frame 29: 1374 bytes on wire (10992 bits), 1374 bytes captured (10992 bits) on interface lo, id 0
    Section number: 1
    Interface id: 0 (lo)
        Interface name: lo
        Interface description: Loopback
    Encapsulation type: Ethernet (1)
    Arrival Time: Jun 25, 2024 12:02:04.177988332 MDT
    UTC Arrival Time: Jun 25, 2024 18:02:04.177988332 UTC
    Epoch Arrival Time: 1719338524.177988332
    [Time shift for this packet: 0.000000000 seconds]
    [Time delta from previous captured frame: 0.000033436 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 39.000474135 seconds]
    Frame Number: 29
    Frame Length: 1374 bytes (10992 bits)
    Capture Length: 1374 bytes (10992 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:sctp:e2ap:e2ap:ngap:ngap]
Ethernet II, Src: 00:00:00_00:00:00 (00:00:00:00:00:00), Dst: 00:00:00_00:00:00 (00:00:00:00:00:00)
    Destination: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
    [Stream index: 0]
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x02 (DSCP: CS0, ECN: ECT(0))
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..10 = Explicit Congestion Notification: ECN-Capable Transport codepoint '10' (2)
    Total Length: 1360
    Identification: 0x0000 (0)
    010. .... = Flags: 0x2, Don't fragment
        0... .... = Reserved bit: Not set
        .1.. .... = Don't fragment: Set
        ..0. .... = More fragments: Not set
    ...0 0000 0000 0000 = Fragment Offset: 0
    Time to Live: 64
    Protocol: SCTP (132)
    Header Checksum: 0x3726 [validation disabled]
    [Header checksum status: Unverified]
    Source Address: 127.0.0.1
    Destination Address: 127.0.0.1
    [Stream index: 0]
Stream Control Transmission Protocol, Src Port: 33932 (33932), Dst Port: 36421 (36421)
    Source port: 33932
    Destination port: 36421
    Verification tag: 0x28e59bf9
    [Association index: disabled (enable in preferences)]
    Checksum: 0x00000000 [unverified]
    [Checksum Status: Unverified]
    COOKIE_ECHO chunk (Cookie length: 260 bytes)
        Chunk type: COOKIE_ECHO (10)
            0... .... = Bit: Stop processing of the packet
            .0.. .... = Bit: Do not report
        Chunk flags: 0x00
        Chunk length: 264
        Cookie […]: 7bce9fc4e0b37e819017469e6c1b5a7c06cad9f300000000000000000000000000000000f99be528ae5f910a00000000000000002d828c365551dc170a000a003de7841e0200848c7f0000010000000000000000000000000000000000000000458e01000000000080020024665a6a307
    DATA chunk (ordered, complete segment, TSN: 0, SID: 0, SSN: 0, PPID: 0, payload length: 1048 bytes)
        Chunk type: DATA (0)
            0... .... = Bit: Stop processing of the packet
            .0.. .... = Bit: Do not report
        Chunk flags: 0x03
            .... 0... = I-Bit: Possibly delay SACK
            .... .0.. = U-Bit: Ordered delivery
            .... ..1. = B-Bit: First segment
            .... ...1 = E-Bit: Last segment
        Chunk length: 1064
        Transmission sequence number (relative): 0
        Transmission sequence number (absolute): 3883946270
        Stream identifier: 0x0000
        Stream sequence number: 0
        Payload protocol identifier: not specified (0)
E2 Application Protocol
    E2AP-PDU: initiatingMessage (0)
        initiatingMessage
            procedureCode: id-E2setup (1)
            criticality: reject (0)
            value
                E2setupRequest
                    protocolIEs: 4 items
                        Item 0: id-TransactionID
                            ProtocolIE-Field
                                id: id-TransactionID (49)
                                criticality: reject (0)
                                value
                                    TransactionID: 13
                        Item 1: id-GlobalE2node-ID
                            ProtocolIE-Field
                                id: id-GlobalE2node-ID (3)
                                criticality: reject (0)
                                value
                                    GlobalE2node-ID: gNB (0)
                                        gNB
                                            global-gNB-ID
                                                plmn-id: 02f859
                                                gnb-id: gnb-ID (0)
                                                    gnb-ID: 00000e00 [bit length 32, 0000 0000  0000 0000  0000 1110  0000 0000 decimal value 3584]
                        Item 2: id-RANfunctionsAdded
                            ProtocolIE-Field
                                id: id-RANfunctionsAdded (10)
                                criticality: reject (0)
                                value
                                    RANfunctions-List: 8 items
                                        Item 0: id-RANfunction-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunction-Item (8)
                                                criticality: reject (0)
                                                value
                                                    RANfunction-Item
                                                        ranFunctionID: 2
                                                        ranFunctionDefinition […]: 60304f52414e2d4532534d2d4b504d000018312e332e362e312e342e312e35333134382e312e322e322e3205004b504d204d6f6e69746f720001010700506572696f646963205265706f727401010001041580436f6d6d6f6e20436f6e646974696f6e2d6261736564
                                                        E2SM-KPM-RANfunction-Description
                                                            ranFunction-Name
                                                                ranFunction-ShortName: ORAN-E2SM-KPM
                                                                ranFunction-E2SM-OID: 1.3.6.1.4.1.53148.1.2.2.2
                                                                ranFunction-Description: KPM Monitor
                                                            ric-EventTriggerStyle-List: 1 item
                                                                Item 0
                                                                    RIC-EventTriggerStyle-Item
                                                                        ric-EventTriggerStyle-Type: 1
                                                                        ric-EventTriggerStyle-Name: Periodic Report
                                                                        ric-EventTriggerFormat-Type: 1
                                                            ric-ReportStyle-List: 1 item
                                                                Item 0
                                                                    RIC-ReportStyle-Item
                                                                        ric-ReportStyle-Type: 4
                                                                        ric-ReportStyle-Name: Common Condition-based, UE-level Measurement
                                                                        ric-ActionFormat-Type: 4
                                                                        measInfo-Action-List: 7 items
                                                                            Item 0
                                                                                MeasurementInfo-Action-Item
                                                                                    measName: DRB.PdcpSduVolumeDL
                                                                            Item 1
                                                                                MeasurementInfo-Action-Item
                                                                                    measName: DRB.PdcpSduVolumeUL
                                                                            Item 2
                                                                                MeasurementInfo-Action-Item
                                                                                    measName: DRB.RlcSduDelayDl
                                                                            Item 3
                                                                                MeasurementInfo-Action-Item
                                                                                    measName: DRB.UEThpDl
                                                                            Item 4
                                                                                MeasurementInfo-Action-Item
                                                                                    measName: DRB.UEThpUl
                                                                            Item 5
                                                                                MeasurementInfo-Action-Item
                                                                                    measName: RRU.PrbTotDl
                                                                            Item 6
                                                                                MeasurementInfo-Action-Item
                                                                                    measName: RRU.PrbTotUl
                                                                        ric-IndicationHeaderFormat-Type: 1
                                                                        ric-IndicationMessageFormat-Type: 3
                                                        ranFunctionRevision: 2
                                                        ranFunctionOID: 1.3.6.1.4.1.53148.1.2.2.2
                                                        [Version (frame): KPM v2]
                                        Item 1: id-RANfunction-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunction-Item (8)
                                                criticality: reject (0)
                                                value
                                                    RANfunction-Item
                                                        ranFunctionID: 3
                                                        ranFunctionDefinition […]: 6805804f52414e2d4532534d2d5243000018312e332e362e312e342e312e35333134382e312e312e322e33050052414e20436f6e74726f6c000001040a00554520496e666f726d6174696f6e204368616e67650103008001040680554520496e666f726d6174696f6e
                                                        E2SM-RC-RANFunctionDefinition
                                                            ranFunction-Name
                                                                ranFunction-ShortName: ORAN-E2SM-RC
                                                                ranFunction-E2SM-OID: 1.3.6.1.4.1.53148.1.1.2.3
                                                                ranFunction-Description: RAN Control
                                                            ranFunctionDefinition-EventTrigger
                                                                ric-EventTriggerStyle-List: 1 item
                                                                    Item 0
                                                                        RANFunctionDefinition-EventTrigger-Style-Item
                                                                            ric-EventTriggerStyle-Type: 4
                                                                            ric-EventTriggerStyle-Name: UE Information Change
                                                                            ric-EventTriggerFormat-Type: 3
                                                            ranFunctionDefinition-Report
                                                                ric-ReportStyle-List: 1 item
                                                                    Item 0
                                                                        RANFunctionDefinition-Report-Item
                                                                            ric-ReportStyle-Type: 4
                                                                            ric-ReportStyle-Name: UE Information
                                                                            ric-SupportedEventTriggerStyle-Type: 3
                                                                            ric-ReportActionFormat-Type: 0
                                                                            ric-IndicationHeaderFormat-Type: 0
                                                                            ric-IndicationMessageFormat-Type: 1
                                                                            ran-ReportParameters-List: 1 item
                                                                                Item 0
                                                                                    Report-RANParameter-Item
                                                                                        ranParameter-ID: 202
                                                                                        ranParameter-name: RRC State
                                                            ranFunctionDefinition-Control
                                                                ric-ControlStyle-List: 1 item
                                                                    Item 0
                                                                        RANFunctionDefinition-Control-Item
                                                                            ric-ControlStyle-Type: 1
                                                                            ric-ControlStyle-Name: Radio Bearer Control
                                                                            ric-ControlAction-List: 1 item
                                                                                Item 0
                                                                                    RANFunctionDefinition-Control-Action-Item
                                                                                        ric-ControlAction-ID: 2
                                                                                        ric-ControlAction-Name: QoS flow mapping configuration
                                                                                        ran-ControlActionParameters-List: 2 items
                                                                                            Item 0
                                                                                                ControlAction-RANParameter-Item
                                                                                                    ranParameter-ID: 1
                                                                                                    ranParameter-name: DRB ID
                                                                                            Item 1
                                                                                                ControlAction-RANParameter-Item
                                                                                                    ranParameter-ID: 2
                                                                                                    ranParameter-name: List of QoS Flows to be modified in DRB
                                                                                                    ranParameter-Definition
                                                                                                        ranParameter-Definition-Choice: choiceLIST (0)
                                                                                                            choiceLIST
                                                                                                                ranParameter-List: 2 items

 Item 0

     RANParameter-Definition-Choice-LIST-Item

         ranParameter-ID: 4

         ranParameter-name: QoS Flow Identifier

 Item 1

     RANParameter-Definition-Choice-LIST-Item

         ranParameter-ID: 5

         ranParameter-name: QoS Flow Mapping Indication
                                                                            ric-ControlHeaderFormat-Type: 0
                                                                            ric-ControlMessageFormat-Type: 0
                                                                            ric-ControlOutcomeFormat-Type: 0
                                                        ranFunctionRevision: 1
                                                        ranFunctionOID: 1.3.6.1.4.1.53148.1.1.2.3
                                                        [Version (frame): RC  v1]
                                        Item 2: id-RANfunction-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunction-Item (8)
                                                criticality: reject (0)
                                                value
                                                    RANfunction-Item
                                                        ranFunctionID: 142
                                                        ranFunctionDefinition: 4d41435f53544154535f5630
                                                        RANfunction name not recognised
                                                            [Expert Info (Warning/Protocol): ShortName does not match any known Service Model]
                                                                [ShortName does not match any known Service Model]
                                                                [Severity level: Warning]
                                                                [Group: Protocol]
                                                        ranFunctionRevision: 1
                                                        ranFunctionOID: 0.0.0.0.0.0.0.0.1.142.0
                                                        [Version (frame): itu-t.0.0.0.0.0.0.0.1.142.0]
                                        Item 3: id-RANfunction-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunction-Item (8)
                                                criticality: reject (0)
                                                value
                                                    RANfunction-Item
                                                        ranFunctionID: 143
                                                        ranFunctionDefinition: 524c435f53544154535f5630
                                                        RANfunction name not recognised
                                                            [Expert Info (Warning/Protocol): ShortName does not match any known Service Model]
                                                                [ShortName does not match any known Service Model]
                                                                [Severity level: Warning]
                                                                [Group: Protocol]
                                                        ranFunctionRevision: 1
                                                        ranFunctionOID: 0.0.0.0.0.0.0.0.1.143.0
                                                        [Version (frame): itu-t.0.0.0.0.0.0.0.1.143.0]
                                        Item 4: id-RANfunction-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunction-Item (8)
                                                criticality: reject (0)
                                                value
                                                    RANfunction-Item
                                                        ranFunctionID: 144
                                                        ranFunctionDefinition: 504443505f53544154535f5630
                                                        RANfunction name not recognised
                                                            [Expert Info (Warning/Protocol): ShortName does not match any known Service Model]
                                                                [ShortName does not match any known Service Model]
                                                                [Severity level: Warning]
                                                                [Group: Protocol]
                                                        ranFunctionRevision: 1
                                                        ranFunctionOID: 0.0.0.0.0.0.0.0.1.144.0
                                                        [Version (frame): itu-t.0.0.0.0.0.0.0.1.144.0]
                                        Item 5: id-RANfunction-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunction-Item (8)
                                                criticality: reject (0)
                                                value
                                                    RANfunction-Item
                                                        ranFunctionID: 145
                                                        ranFunctionDefinition: 534c4943455f53544154535f5630
                                                        RANfunction name not recognised
                                                            [Expert Info (Warning/Protocol): ShortName does not match any known Service Model]
                                                                [ShortName does not match any known Service Model]
                                                                [Severity level: Warning]
                                                                [Group: Protocol]
                                                        ranFunctionRevision: 1
                                                        ranFunctionOID: 0.0.0.0.0.0.0.0.1.145.0
                                                        [Version (frame): itu-t.0.0.0.0.0.0.0.1.145.0]
                                        Item 6: id-RANfunction-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunction-Item (8)
                                                criticality: reject (0)
                                                value
                                                    RANfunction-Item
                                                        ranFunctionID: 146
                                                        ranFunctionDefinition: 54435f53544154535f5630
                                                        RANfunction name not recognised
                                                            [Expert Info (Warning/Protocol): ShortName does not match any known Service Model]
                                                                [ShortName does not match any known Service Model]
                                                                [Severity level: Warning]
                                                                [Group: Protocol]
                                                        ranFunctionRevision: 1
                                                        ranFunctionOID: 0.0.0.0.0.0.0.0.1.146.0
                                                        [Version (frame): itu-t.0.0.0.0.0.0.0.1.146.0]
                                        Item 7: id-RANfunction-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunction-Item (8)
                                                criticality: reject (0)
                                                value
                                                    RANfunction-Item
                                                        ranFunctionID: 148
                                                        ranFunctionDefinition: 4754505f53544154535f5630
                                                        RANfunction name not recognised
                                                            [Expert Info (Warning/Protocol): ShortName does not match any known Service Model]
                                                                [ShortName does not match any known Service Model]
                                                                [Severity level: Warning]
                                                                [Group: Protocol]
                                                        ranFunctionRevision: 1
                                                        ranFunctionOID: 0.0.0.0.0.0.0.0.1.148.0
                                                        [Version (frame): itu-t.0.0.0.0.0.0.0.1.148.0]
                        Item 3: id-E2nodeComponentConfigAddition
                            ProtocolIE-Field
                                id: id-E2nodeComponentConfigAddition (50)
                                criticality: reject (0)
                                value
                                    E2nodeComponentConfigAddition-List: 1 item
                                        Item 0: id-E2nodeComponentConfigAddition-Item
                                            ProtocolIE-SingleContainer
                                                id: id-E2nodeComponentConfigAddition-Item (51)
                                                criticality: reject (0)
                                                value
                                                    E2nodeComponentConfigAddition-Item
                                                        e2nodeComponentInterfaceType: ng (0)
                                                        e2nodeComponentID: e2nodeComponentInterfaceTypeNG (0)
                                                            e2nodeComponentInterfaceTypeNG
                                                                amf-name: Dummy message
                                                        e2nodeComponentConfiguration
                                                            e2nodeComponentRequestPart: 4e4741502052657175657374204d6573736167652073656e74
                                                            NG Application Protocol (MulticastSessionActivationFailure)
                                                                NGAP-PDU: unsuccessfulOutcome (2)
                                                                    unsuccessfulOutcome
                                                                        procedureCode: id-MulticastSessionActivation (71)
                                                                        criticality: ignore (1)
                                                                        Open type length(80) > available data(21)
                                                                            [Expert Info (Error/Protocol): Open type length(80) > available data(21)]
                                                                                [Open type length(80) > available data(21)]
                                                                                [Severity level: Error]
                                                                                [Group: Protocol]
                                                                        value
                                                                            MulticastSessionActivationFailure
                                                                                protocolIEs: 21093 items
                                                                                    Item 0: unknown (29045)
                                                                                        ProtocolIE-Field
                                                                                            id: Unknown (29045)
                                                                                            criticality: ignore (1)
                                                                                            Open type length(115) > available data(14)
                                                                                                [Expert Info (Error/Protocol): Open type length(115) > available data(14)]
                                                                                                    [Open type length(115) > available data(14)]
                                                                                                    [Severity level: Error]
                                                                                                    [Group: Protocol]
                                                                                            value
                                                                                    Item 1
[Malformed Packet: NGAP]
    [Expert Info (Error/Malformed): Malformed Packet (Exception occurred)]
        [Malformed Packet (Exception occurred)]
        [Severity level: Error]
        [Group: Malformed]
```

That us a lot of information. I think the primary information is 
1. the basic info of this gnb
2. the RAN functions supported by this gnb (may be different if we split into DU and CU)
3. the control actions supported by this gnb. 

By the way, it seems that the E2 request sent form the base stations to the RIC is not recognized as E2AP, but just sctp. I do not think that there might be anything interesting in that, so I will not look into it. 

This is the e2 setup response message
```
PeterYao@node:/mydata$ sudo tshark -r /mydata/e2ap_packets_all.pcap -d sctp.port==36421,e2ap -Y "frame.number == 31" -V
Running as user "root" and group "root". This could be dangerous.
Frame 31: 190 bytes on wire (1520 bits), 190 bytes captured (1520 bits) on interface lo, id 0
    Section number: 1
    Interface id: 0 (lo)
        Interface name: lo
        Interface description: Loopback
    Encapsulation type: Ethernet (1)
    Arrival Time: Jun 25, 2024 12:02:04.178676080 MDT
    UTC Arrival Time: Jun 25, 2024 18:02:04.178676080 UTC
    Epoch Arrival Time: 1719338524.178676080
    [Time shift for this packet: 0.000000000 seconds]
    [Time delta from previous captured frame: 0.000625727 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 39.001161883 seconds]
    Frame Number: 31
    Frame Length: 190 bytes (1520 bits)
    Capture Length: 190 bytes (1520 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:sctp:e2ap:e2ap]
Ethernet II, Src: 00:00:00_00:00:00 (00:00:00:00:00:00), Dst: 00:00:00_00:00:00 (00:00:00:00:00:00)
    Destination: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
    [Stream index: 0]
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x02 (DSCP: CS0, ECN: ECT(0))
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..10 = Explicit Congestion Notification: ECN-Capable Transport codepoint '10' (2)
    Total Length: 176
    Identification: 0x0000 (0)
    010. .... = Flags: 0x2, Don't fragment
        0... .... = Reserved bit: Not set
        .1.. .... = Don't fragment: Set
        ..0. .... = More fragments: Not set
    ...0 0000 0000 0000 = Fragment Offset: 0
    Time to Live: 64
    Protocol: SCTP (132)
    Header Checksum: 0x3bc6 [validation disabled]
    [Header checksum status: Unverified]
    Source Address: 127.0.0.1
    Destination Address: 127.0.0.1
    [Stream index: 0]
Stream Control Transmission Protocol, Src Port: 36421 (36421), Dst Port: 33932 (33932)
    Source port: 36421
    Destination port: 33932
    Verification tag: 0x0a915fae
    [Association index: disabled (enable in preferences)]
    Checksum: 0x00000000 [unverified]
    [Checksum Status: Unverified]
    DATA chunk (ordered, complete segment, TSN: 0, SID: 0, SSN: 0, PPID: 0, payload length: 128 bytes)
        Chunk type: DATA (0)
            0... .... = Bit: Stop processing of the packet
            .0.. .... = Bit: Do not report
        Chunk flags: 0x03
            .... 0... = I-Bit: Possibly delay SACK
            .... .0.. = U-Bit: Ordered delivery
            .... ..1. = B-Bit: First segment
            .... ...1 = E-Bit: Last segment
        Chunk length: 144
        Transmission sequence number (relative): 0
        Transmission sequence number (absolute): 512026429
        Stream identifier: 0x0000
        Stream sequence number: 0
        Payload protocol identifier: not specified (0)
E2 Application Protocol
    E2AP-PDU: successfulOutcome (1)
        successfulOutcome
            procedureCode: id-E2setup (1)
            criticality: reject (0)
            value
                E2setupResponse
                    protocolIEs: 4 items
                        Item 0: id-TransactionID
                            ProtocolIE-Field
                                id: id-TransactionID (49)
                                criticality: reject (0)
                                value
                                    TransactionID: 13
                        Item 1: id-GlobalRIC-ID
                            ProtocolIE-Field
                                id: id-GlobalRIC-ID (4)
                                criticality: reject (0)
                                value
                                    GlobalRIC-ID
                                        pLMN-Identity: 02f859
                                        ric-ID: 000190 [bit length 20, 4 LSB pad bits, 0000 0000  0000 0001  1001 .... decimal value 25]
                        Item 2: id-RANfunctionsAccepted
                            ProtocolIE-Field
                                id: id-RANfunctionsAccepted (9)
                                criticality: reject (0)
                                value
                                    RANfunctionsID-List: 8 items
                                        Item 0: id-RANfunctionID-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunctionID-Item (6)
                                                criticality: ignore (1)
                                                value
                                                    RANfunctionID-Item
                                                        ranFunctionID: 2
                                                        ranFunctionRevision: 0
                                        Item 1: id-RANfunctionID-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunctionID-Item (6)
                                                criticality: ignore (1)
                                                value
                                                    RANfunctionID-Item
                                                        ranFunctionID: 3
                                                        ranFunctionRevision: 0
                                        Item 2: id-RANfunctionID-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunctionID-Item (6)
                                                criticality: ignore (1)
                                                value
                                                    RANfunctionID-Item
                                                        ranFunctionID: 142
                                                        ranFunctionRevision: 0
                                        Item 3: id-RANfunctionID-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunctionID-Item (6)
                                                criticality: ignore (1)
                                                value
                                                    RANfunctionID-Item
                                                        ranFunctionID: 143
                                                        ranFunctionRevision: 0
                                        Item 4: id-RANfunctionID-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunctionID-Item (6)
                                                criticality: ignore (1)
                                                value
                                                    RANfunctionID-Item
                                                        ranFunctionID: 144
                                                        ranFunctionRevision: 0
                                        Item 5: id-RANfunctionID-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunctionID-Item (6)
                                                criticality: ignore (1)
                                                value
                                                    RANfunctionID-Item
                                                        ranFunctionID: 145
                                                        ranFunctionRevision: 0
                                        Item 6: id-RANfunctionID-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunctionID-Item (6)
                                                criticality: ignore (1)
                                                value
                                                    RANfunctionID-Item
                                                        ranFunctionID: 146
                                                        ranFunctionRevision: 0
                                        Item 7: id-RANfunctionID-Item
                                            ProtocolIE-SingleContainer
                                                id: id-RANfunctionID-Item (6)
                                                criticality: ignore (1)
                                                value
                                                    RANfunctionID-Item
                                                        ranFunctionID: 148
                                                        ranFunctionRevision: 0
                        Item 3: id-E2nodeComponentConfigAdditionAck
                            ProtocolIE-Field
                                id: id-E2nodeComponentConfigAdditionAck (52)
                                criticality: reject (0)
                                value
                                    E2nodeComponentConfigAdditionAck-List: 1 item
                                        Item 0: id-E2nodeComponentConfigAdditionAck-Item
                                            ProtocolIE-SingleContainer
                                                id: id-E2nodeComponentConfigAdditionAck-Item (53)
                                                criticality: reject (0)
                                                value
                                                    E2nodeComponentConfigAdditionAck-Item
                                                        e2nodeComponentInterfaceType: ng (0)
                                                        e2nodeComponentID: e2nodeComponentInterfaceTypeNG (0)
                                                            e2nodeComponentInterfaceTypeNG
                                                                amf-name: Dummy message
                                                        e2nodeComponentConfigurationAck
                                                            updateOutcome: success (0)
```
It tells the base station which are accepted as valid. 


Next, I want to investigate xAPP messages and their content. I will just start the tcpdump, then the flexric, then gnb, and finally, an xapp:slicing. We will hopefully see the subscription, indication and control messages. 

Now there seems to be many more packets captured. 
```bash
PeterYao@node:~$ sudo tcpdump -i lo -f "sctp" -w /mydata/e2traffic.pcap
tcpdump: listening on lo, link-type EN10MB (Ethernet), capture size 262144 bytes

^C3081 packets captured
6162 packets received by filter
0 packets dropped by kernel
```

Investigating these packets, filter out those SCTP control messages, and only keep the E2AP messages. 

```
PeterYao@node:~$ sudo tshark -r /mydata/e2traffic.pcap -d sctp.port==36421,e2ap -Y "e2ap"
Running as user "root" and group "root". This could be dangerous.
   25  33.000487    127.0.0.1 → 127.0.0.1    E2AP|NGAP 1374 COOKIE_ECHO , E2setupRequest
   27  33.001250    127.0.0.1 → 127.0.0.1    E2AP 190 E2setupResponse
   54  80.190963    127.0.0.1 → 127.0.0.1    E2AP 102 RICsubscriptionRequest
   55  80.191229    127.0.0.1 → 127.0.0.1    E2AP 118 SACK (Ack=1, Arwnd=106496) , RICsubscriptionResponse
   57  80.196259    127.0.0.1 → 127.0.0.1    E2AP 450 RICindication
   61  80.201228    127.0.0.1 → 127.0.0.1    E2AP 450 RICindication
...
  117  80.291224    127.0.0.1 → 127.0.0.1    E2AP 450 RICindication
  119  80.296243    127.0.0.1 → 127.0.0.1    E2AP 450 RICindication
  123  80.301225    127.0.0.1 → 127.0.0.1    E2AP 450 RICindication
  125  80.306242    127.0.0.1 → 127.0.0.1    E2AP 430 RICindication
  129  80.311225    127.0.0.1 → 127.0.0.1    E2AP 430 RICindication
...
  723  81.301246    127.0.0.1 → 127.0.0.1    E2AP 430 RICindication
  725  81.306238    127.0.0.1 → 127.0.0.1    E2AP 346 RICindication
  729  81.311241    127.0.0.1 → 127.0.0.1    E2AP 346 RICindication
...
 1245  82.171244    127.0.0.1 → 127.0.0.1    E2AP 346 RICindication
 1247  82.176237    127.0.0.1 → 127.0.0.1    E2AP 346 RICindication
 1251  82.181240    127.0.0.1 → 127.0.0.1    E2AP 346 RICindication
 1253  82.186239    127.0.0.1 → 127.0.0.1    E2AP 346 RICindication
 1257  82.191240    127.0.0.1 → 127.0.0.1    E2AP 346 RICindication
 1260  82.192226    127.0.0.1 → 127.0.0.1    E2AP 242 SACK (Ack=401, Arwnd=106496) , RICcontrolRequest
 1261  82.192390    127.0.0.1 → 127.0.0.1    E2AP 110 SACK (Ack=2, Arwnd=106496) , RICcontrolAcknowledge
 1263  82.196238    127.0.0.1 → 127.0.0.1    E2AP 346 RICindication
...
 1321  82.291248    127.0.0.1 → 127.0.0.1    E2AP 346 RICindication
 1323  82.296239    127.0.0.1 → 127.0.0.1    E2AP 346 RICindication
 1327  82.301238    127.0.0.1 → 127.0.0.1    E2AP 346 RICindication
 1329  82.306250    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
 1333  82.311236    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
 1335  82.316246    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
...
 1679  82.886235    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
 1683  82.891236    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
 1685  82.896235    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
 1689  82.901235    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
 1691  82.906237    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
...
 1866  83.193154    127.0.0.1 → 127.0.0.1    E2AP 138 SACK (Ack=602, Arwnd=106496) , RICcontrolRequest
 1867  83.193308    127.0.0.1 → 127.0.0.1    E2AP 110 SACK (Ack=3, Arwnd=106496) , RICcontrolAcknowledge
 1869  83.196237    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
 1873  83.201248    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
 1875  83.206245    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
...
 1929  83.296237    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
 1933  83.301242    127.0.0.1 → 127.0.0.1    E2AP 254 RICindication
 1935  83.306258    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
 1939  83.311250    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
 1941  83.316254    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
 1959  83.346248    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
...
 2041  83.481253    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
 2043  83.486247    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
...
 2283  83.886249    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
 2287  83.891249    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
 2289  83.896247    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication

 2467  84.191248    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
 2470  84.194059    127.0.0.1 → 127.0.0.1    E2AP 138 SACK (Ack=803, Arwnd=106496) , RICcontrolRequest
 2471  84.194246    127.0.0.1 → 127.0.0.1    E2AP 110 SACK (Ack=4, Arwnd=106496) , RICcontrolAcknowledge
 2473  84.196245    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
 2477  84.201249    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
 2479  84.206247    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
 ...
 2537  84.301254    127.0.0.1 → 127.0.0.1    E2AP 530 RICindication
 2539  84.306249    127.0.0.1 → 127.0.0.1    E2AP 542 RICindication
 2543  84.311246    127.0.0.1 → 127.0.0.1    E2AP 542 RICindication
 2545  84.316249    127.0.0.1 → 127.0.0.1    E2AP 542 RICindication
 ...
 2549  84.321250    127.0.0.1 → 127.0.0.1    E2AP 542 RICindication
 2551  84.326249    127.0.0.1 → 127.0.0.1    E2AP 542 RICindication

 3074  85.194980    127.0.0.1 → 127.0.0.1    E2AP 102 SACK (Ack=1004, Arwnd=106496) , RICsubscriptionDeleteRequest
 3075  85.195122    127.0.0.1 → 127.0.0.1    E2AP 102 SACK (Ack=5, Arwnd=106496) , RICsubscriptionDeleteResponse
 ```

Some comments on the log:
1. I deleted a lot of redundant RICindication messages, as there are just the reports. 
2. I don't know why the number before the RIC indication messages are changing all the time. 

Let us go through the content of eack kind of packets one by one:

### RICsubscriptionRequest
```
PeterYao@node:~$ sudo tshark -r /mydata/e2traffic.pcap -d sctp.port==36421,e2ap -Y "frame.number == 54" -V
Running as user "root" and group "root". This could be dangerous.
Frame 54: 102 bytes on wire (816 bits), 102 bytes captured (816 bits)
    Encapsulation type: Ethernet (1)
    Arrival Time: Jun 25, 2024 13:31:30.892021000 MDT
    UTC Arrival Time: Jun 25, 2024 19:31:30.892021000 UTC
    Epoch Arrival Time: 1719343890.892021000
    [Time shift for this packet: 0.000000000 seconds]
    [Time delta from previous captured frame: 0.000263000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 80.190963000 seconds]
    Frame Number: 54
    Frame Length: 102 bytes (816 bits)
    Capture Length: 102 bytes (816 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:sctp:e2ap:e2ap]
Ethernet II, Src: 00:00:00_00:00:00 (00:00:00:00:00:00), Dst: 00:00:00_00:00:00 (00:00:00:00:00:00)
    Destination: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
    [Stream index: 0]
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x02 (DSCP: CS0, ECN: ECT(0))
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..10 = Explicit Congestion Notification: ECN-Capable Transport codepoint '10' (2)
    Total Length: 88
    Identification: 0x0000 (0)
    010. .... = Flags: 0x2, Don't fragment
        0... .... = Reserved bit: Not set
        .1.. .... = Don't fragment: Set
        ..0. .... = More fragments: Not set
    ...0 0000 0000 0000 = Fragment Offset: 0
    Time to Live: 64
    Protocol: SCTP (132)
    Header Checksum: 0x3c1e [validation disabled]
    [Header checksum status: Unverified]
    Source Address: 127.0.0.1
    Destination Address: 127.0.0.1
    [Stream index: 0]
Stream Control Transmission Protocol, Src Port: 36421 (36421), Dst Port: 38363 (38363)
    Source port: 36421
    Destination port: 38363
    Verification tag: 0xe12e762d
    [Association index: disabled (enable in preferences)]
    Checksum: 0x00000000 [unverified]
    [Checksum Status: Unverified]
    DATA chunk (ordered, complete segment, TSN: 1, SID: 0, SSN: 1, PPID: 0, payload length: 40 bytes)
        Chunk type: DATA (0)
            0... .... = Bit: Stop processing of the packet
            .0.. .... = Bit: Do not report
        Chunk flags: 0x03
            .... 0... = I-Bit: Possibly delay SACK
            .... .0.. = U-Bit: Ordered delivery
            .... ..1. = B-Bit: First segment
            .... ...1 = E-Bit: Last segment
        Chunk length: 56
        Transmission sequence number (relative): 1
        Transmission sequence number (absolute): 2128841583
        Stream identifier: 0x0000
        Stream sequence number: 1
        Payload protocol identifier: not specified (0)
E2 Application Protocol
    E2AP-PDU: initiatingMessage (0)
        initiatingMessage
            procedureCode: id-RICsubscription (8)
            criticality: reject (0)
            value
                RICsubscriptionRequest
                    protocolIEs: 3 items
                        Item 0: id-RICrequestID
                            ProtocolIE-Field
                                id: id-RICrequestID (29)
                                criticality: reject (0)
                                value
                                    RICrequestID
                                        ricRequestorID: 1021
                                        ricInstanceID: 0
                        Item 1: id-RANfunctionID
                            ProtocolIE-Field
                                id: id-RANfunctionID (5)
                                criticality: reject (0)
                                value
                                    RANfunctionID: 145
                        Item 2: id-RICsubscriptionDetails
                            ProtocolIE-Field
                                id: id-RICsubscriptionDetails (30)
                                criticality: reject (0)
                                value
                                    RICsubscriptionDetails
                                        ricEventTriggerDefinition: 05000000
                                        Unmapped RANfunctionID
                                            [Expert Info (Warning/Protocol): Service Model not mapped for FunctionID 145]
                                                [Service Model not mapped for FunctionID 145]
                                                [Severity level: Warning]
                                                [Group: Protocol]
                                        ricAction-ToBeSetup-List: 1 item
                                            Item 0: id-RICaction-ToBeSetup-Item
                                                ProtocolIE-SingleContainer
                                                    id: id-RICaction-ToBeSetup-Item (19)
                                                    criticality: reject (0)
                                                    value
                                                        RICaction-ToBeSetup-Item
                                                            ricActionID: 0
                                                            ricActionType: report (0)
```

The important information would be the RAN function that the RIC is subscribing to: 145
```
RANfunctionID: 145
```

### E2AP RIC Indication Message 
```
PeterYao@node:~$ sudo tshark -r /mydata/e2traffic.pcap -d sctp.port==36421,e2ap -Y "frame.number == 729" -V
Running as user "root" and group "root". This could be dangerous.
Frame 729: 346 bytes on wire (2768 bits), 346 bytes captured (2768 bits)
    Encapsulation type: Ethernet (1)
    Arrival Time: Jun 25, 2024 13:31:32.012299000 MDT
    UTC Arrival Time: Jun 25, 2024 19:31:32.012299000 UTC
    Epoch Arrival Time: 1719343892.012299000
    [Time shift for this packet: 0.000000000 seconds]
    [Time delta from previous captured frame: 0.004670000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 81.311241000 seconds]
    Frame Number: 729
    Frame Length: 346 bytes (2768 bits)
    Capture Length: 346 bytes (2768 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:sctp:e2ap:e2ap]
Ethernet II, Src: 00:00:00_00:00:00 (00:00:00:00:00:00), Dst: 00:00:00_00:00:00 (00:00:00:00:00:00)
    Destination: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
    [Stream index: 0]
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x02 (DSCP: CS0, ECN: ECT(0))
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..10 = Explicit Congestion Notification: ECN-Capable Transport codepoint '10' (2)
    Total Length: 332
    Identification: 0x0000 (0)
    010. .... = Flags: 0x2, Don't fragment
        0... .... = Reserved bit: Not set
        .1.. .... = Don't fragment: Set
        ..0. .... = More fragments: Not set
    ...0 0000 0000 0000 = Fragment Offset: 0
    Time to Live: 64
    Protocol: SCTP (132)
    Header Checksum: 0x3b2a [validation disabled]
    [Header checksum status: Unverified]
    Source Address: 127.0.0.1
    Destination Address: 127.0.0.1
    [Stream index: 0]
Stream Control Transmission Protocol, Src Port: 38363 (38363), Dst Port: 36421 (36421)
    Source port: 38363
    Destination port: 36421
    Verification tag: 0x0a7e0b6c
    [Association index: disabled (enable in preferences)]
    Checksum: 0x00000000 [unverified]
    [Checksum Status: Unverified]
    DATA chunk (ordered, complete segment, TSN: 225, SID: 0, SSN: 225, PPID: 0, payload length: 281 bytes)
        Chunk type: DATA (0)
            0... .... = Bit: Stop processing of the packet
            .0.. .... = Bit: Do not report
        Chunk flags: 0x03
            .... 0... = I-Bit: Possibly delay SACK
            .... .0.. = U-Bit: Ordered delivery
            .... ..1. = B-Bit: First segment
            .... ...1 = E-Bit: Last segment
        Chunk length: 297
        Transmission sequence number (relative): 225
        Transmission sequence number (absolute): 769355475
        Stream identifier: 0x0000
        Stream sequence number: 225
        Payload protocol identifier: not specified (0)
        Chunk padding: 000000
E2 Application Protocol
    E2AP-PDU: initiatingMessage (0)
        initiatingMessage
            procedureCode: id-RICindication (5)
            criticality: ignore (1)
            value
                RICindication
                    protocolIEs: 6 items
                        Item 0: id-RICrequestID
                            ProtocolIE-Field
                                id: id-RICrequestID (29)
                                criticality: reject (0)
                                value
                                    RICrequestID
                                        ricRequestorID: 1021
                                        ricInstanceID: 0
                        Item 1: id-RANfunctionID
                            ProtocolIE-Field
                                id: id-RANfunctionID (5)
                                criticality: reject (0)
                                value
                                    RANfunctionID: 145
                        Item 2: id-RICactionID
                            ProtocolIE-Field
                                id: id-RICactionID (15)
                                criticality: reject (0)
                                value
                                    RICactionID: 0
                        Item 3: id-RICindicationType
                            ProtocolIE-Field
                                id: id-RICindicationType (28)
                                criticality: reject (0)
                                value
                                    RICindicationType: report (0)
                        Item 4: id-RICindicationHeader
                            ProtocolIE-Field
                                id: id-RICindicationHeader (25)
                                criticality: reject (0)
                                value
                                    RICindicationHeader: 00000000
                                    Unmapped RANfunctionID
                                        [Expert Info (Warning/Protocol): Service Model not mapped for FunctionID 145]
                                            [Service Model not mapped for FunctionID 145]
                                            [Severity level: Warning]
                                            [Group: Protocol]
                        Item 5: id-RICindicationMessage
                            ProtocolIE-Field
                                id: id-RICindicationMessage (26)
                                criticality: reject (0)
                                value
                                    RICindicationMessage […]: 080000004d5920534c49434503000000830100001000000054686973206973206d79206c6162656c100000005363686564756c657220737472696e67010000000a00000014000000150200001000000054686973206973206d79206c6162656c1000000053636865647
                                    Unmapped RANfunctionID
                                        [Expert Info (Warning/Protocol): Service Model not mapped for FunctionID 145]
                                            [Service Model not mapped for FunctionID 145]
                                            [Severity level: Warning]
                                            [Group: Protocol]
```
Comment on the message:
1. 
```
    Frame Length: 530 bytes (4240 bits)
    Capture Length: 530 bytes (4240 bits)
```
this is from some packet whose number before RICindication is 530, and as we can see from the lengthy packet above, the frame length in that pakcet is 346, corresponding to that number as well. 

2. The RIC indication Message, as I said yesterday, is not in plaintext. O-RAN specificaiton makes it encoded in ANS1. 

### RIC Control Message
```
PeterYao@node:~$ sudo tshark -r /mydata/e2traffic.pcap -d sctp.port==36421,e2ap -Y "frame.number == 2470" -V
Running as user "root" and group "root". This could be dangerous.
Frame 2470: 138 bytes on wire (1104 bits), 138 bytes captured (1104 bits)
    Encapsulation type: Ethernet (1)
    Arrival Time: Jun 25, 2024 13:31:34.895117000 MDT
    UTC Arrival Time: Jun 25, 2024 19:31:34.895117000 UTC
    Epoch Arrival Time: 1719343894.895117000
    [Time shift for this packet: 0.000000000 seconds]
    [Time delta from previous captured frame: 0.000268000 seconds]
    [Time delta from previous displayed frame: 0.000000000 seconds]
    [Time since reference or first frame: 84.194059000 seconds]
    Frame Number: 2470
    Frame Length: 138 bytes (1104 bits)
    Capture Length: 138 bytes (1104 bits)
    [Frame is marked: False]
    [Frame is ignored: False]
    [Protocols in frame: eth:ethertype:ip:sctp:e2ap:e2ap]
Ethernet II, Src: 00:00:00_00:00:00 (00:00:00:00:00:00), Dst: 00:00:00_00:00:00 (00:00:00:00:00:00)
    Destination: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Source: 00:00:00_00:00:00 (00:00:00:00:00:00)
        .... ..0. .... .... .... .... = LG bit: Globally unique address (factory default)
        .... ...0 .... .... .... .... = IG bit: Individual address (unicast)
    Type: IPv4 (0x0800)
    [Stream index: 0]
Internet Protocol Version 4, Src: 127.0.0.1, Dst: 127.0.0.1
    0100 .... = Version: 4
    .... 0101 = Header Length: 20 bytes (5)
    Differentiated Services Field: 0x02 (DSCP: CS0, ECN: ECT(0))
        0000 00.. = Differentiated Services Codepoint: Default (0)
        .... ..10 = Explicit Congestion Notification: ECN-Capable Transport codepoint '10' (2)
    Total Length: 124
    Identification: 0x0000 (0)
    010. .... = Flags: 0x2, Don't fragment
        0... .... = Reserved bit: Not set
        .1.. .... = Don't fragment: Set
        ..0. .... = More fragments: Not set
    ...0 0000 0000 0000 = Fragment Offset: 0
    Time to Live: 64
    Protocol: SCTP (132)
    Header Checksum: 0x3bfa [validation disabled]
    [Header checksum status: Unverified]
    Source Address: 127.0.0.1
    Destination Address: 127.0.0.1
    [Stream index: 0]
Stream Control Transmission Protocol, Src Port: 36421 (36421), Dst Port: 38363 (38363)
    Source port: 36421
    Destination port: 38363
    Verification tag: 0xe12e762d
    [Association index: disabled (enable in preferences)]
    Checksum: 0x00000000 [unverified]
    [Checksum Status: Unverified]
    SACK chunk (Cumulative TSN: 769356053, a_rwnd: 106496, gaps: 0, duplicate TSNs: 0)
        Chunk type: SACK (3)
            0... .... = Bit: Stop processing of the packet
            .0.. .... = Bit: Do not report
        Chunk flags: 0x00
            .... ...0 = Nonce sum: 0
        Chunk length: 16
        Cumulative TSN ACK (relative): 803
        Cumulative TSN ACK (absolute): 769356053
        Advertised receiver window credit (a_rwnd): 106496
        Number of gap acknowledgement blocks: 0
        Number of duplicated TSNs: 0
    DATA chunk (ordered, complete segment, TSN: 4, SID: 0, SSN: 4, PPID: 0, payload length: 59 bytes)
        Chunk type: DATA (0)
            0... .... = Bit: Stop processing of the packet
            .0.. .... = Bit: Do not report
        Chunk flags: 0x03
            .... 0... = I-Bit: Possibly delay SACK
            .... .0.. = U-Bit: Ordered delivery
            .... ..1. = B-Bit: First segment
            .... ...1 = E-Bit: Last segment
        Chunk length: 75
        Transmission sequence number (relative): 4
        Transmission sequence number (absolute): 2128841586
        Stream identifier: 0x0000
        Stream sequence number: 4
        Payload protocol identifier: not specified (0)
        Chunk padding: 00
E2 Application Protocol
    E2AP-PDU: initiatingMessage (0)
        initiatingMessage
            procedureCode: id-RICcontrol (4)
            criticality: reject (0)
            value
                RICcontrolRequest
                    protocolIEs: 5 items
                        Item 0: id-RICrequestID
                            ProtocolIE-Field
                                id: id-RICrequestID (29)
                                criticality: reject (0)
                                value
                                    RICrequestID
                                        ricRequestorID: 1024
                                        ricInstanceID: 0
                        Item 1: id-RANfunctionID
                            ProtocolIE-Field
                                id: id-RANfunctionID (5)
                                criticality: reject (0)
                                value
                                    RANfunctionID: 145
                        Item 2: id-RICcontrolHeader
                            ProtocolIE-Field
                                id: id-RICcontrolHeader (22)
                                criticality: reject (0)
                                value
                                    RICcontrolHeader: 00000000
                                    Unmapped RANfunctionID
                                        [Expert Info (Warning/Protocol): Service Model not mapped for FunctionID 145]
                                            [Service Model not mapped for FunctionID 145]
                                            [Severity level: Warning]
                                            [Group: Protocol]
                        Item 3: id-RICcontrolMessage
                            ProtocolIE-Field
                                id: id-RICcontrolMessage (23)
                                criticality: reject (0)
                                value
                                    RICcontrolMessage: 02000000010000000500000000000000d700
                                    Unmapped RANfunctionID
                                        [Expert Info (Warning/Protocol): Service Model not mapped for FunctionID 145]
                                            [Service Model not mapped for FunctionID 145]
                                            [Severity level: Warning]
                                            [Group: Protocol]
                        Item 4: id-RICcontrolAckRequest
                            ProtocolIE-Field
                                id: id-RICcontrolAckRequest (21)
                                criticality: reject (0)
                                value
                                    RICcontrolAckRequest: ack (1)
```
General Comment:
1. I do not see much, again, the content is encoded. with 
```
RICcontrolMessage: 02000000010000000500000000000000d700
```