### Single UE Single gnb, gnb and core and UE on the same node:
```
root@9eb4b2776f02:/tmp# iperf3 -c 12.1.1.130 -t 60
Connecting to host 12.1.1.130, port 5201
[  5] local 192.168.70.135 port 33538 connected to 12.1.1.130 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  1.83 MBytes  15.3 Mbits/sec    0    260 KBytes
[  5]   1.00-2.00   sec  1.86 MBytes  15.6 Mbits/sec    0    325 KBytes
[  5]   2.00-3.00   sec  1.55 MBytes  13.0 Mbits/sec    0    400 KBytes
[  5]   3.00-4.00   sec  1.80 MBytes  15.1 Mbits/sec    0    501 KBytes
[  5]   4.00-5.00   sec  3.29 MBytes  27.6 Mbits/sec    0    622 KBytes
[  5]   5.00-6.00   sec  2.50 MBytes  21.0 Mbits/sec    0    762 KBytes
[  5]   6.00-7.00   sec  3.75 MBytes  31.5 Mbits/sec    0    912 KBytes
[  5]   7.00-8.00   sec  2.50 MBytes  21.0 Mbits/sec    0   1.04 MBytes
[  5]   8.00-9.00   sec  2.50 MBytes  21.0 Mbits/sec    0   1.18 MBytes
[  5]   9.00-10.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.32 MBytes
[  5]  10.00-11.00  sec  3.75 MBytes  31.5 Mbits/sec    0   1.47 MBytes
[  5]  11.00-12.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.61 MBytes
[  5]  12.00-13.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.76 MBytes
[  5]  13.00-14.00  sec  3.75 MBytes  31.5 Mbits/sec    0   1.91 MBytes
[  5]  14.00-15.00  sec  2.50 MBytes  21.0 Mbits/sec    0   2.05 MBytes
[  5]  15.00-16.00  sec  2.47 MBytes  20.7 Mbits/sec    0   2.20 MBytes
[  5]  16.00-17.00  sec  3.51 MBytes  29.5 Mbits/sec    0   2.39 MBytes
[  5]  17.00-18.00  sec  3.26 MBytes  27.3 Mbits/sec    1   2.75 MBytes
[  5]  18.00-19.00  sec  2.27 MBytes  19.0 Mbits/sec    0   2.75 MBytes
[  5]  19.00-20.00  sec  3.19 MBytes  26.7 Mbits/sec    0   2.76 MBytes
[  5]  20.00-21.00  sec  3.46 MBytes  29.0 Mbits/sec    0   2.76 MBytes
[  5]  21.00-22.00  sec  2.03 MBytes  17.0 Mbits/sec    0   2.78 MBytes
[  5]  22.00-23.00  sec  3.43 MBytes  28.7 Mbits/sec    0   2.80 MBytes
[  5]  23.00-24.00  sec  2.50 MBytes  21.0 Mbits/sec   14   1.96 MBytes
[  5]  24.00-25.00  sec  2.48 MBytes  20.8 Mbits/sec  426   1.39 MBytes
[  5]  25.00-26.00  sec  3.75 MBytes  31.5 Mbits/sec    0   1.45 MBytes
[  5]  26.00-27.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.52 MBytes
[  5]  27.00-28.00  sec  3.75 MBytes  31.5 Mbits/sec    0   1.59 MBytes
[  5]  28.00-29.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.63 MBytes
[  5]  29.00-30.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.66 MBytes
[  5]  30.00-31.00  sec  3.75 MBytes  31.5 Mbits/sec    0   1.68 MBytes
[  5]  31.00-32.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.69 MBytes
[  5]  32.00-33.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.69 MBytes
[  5]  33.00-34.00  sec  3.75 MBytes  31.5 Mbits/sec    0   1.69 MBytes
[  5]  34.00-35.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.69 MBytes
[  5]  35.00-36.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.70 MBytes
[  5]  36.00-37.00  sec  2.50 MBytes  21.0 Mbits/sec    4   1.70 MBytes
[  5]  37.00-38.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.70 MBytes
[  5]  38.00-39.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.71 MBytes
[  5]  39.00-40.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.72 MBytes
[  5]  40.00-41.00  sec  3.75 MBytes  31.5 Mbits/sec    0   1.73 MBytes
[  5]  41.00-42.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.76 MBytes
[  5]  42.00-43.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.81 MBytes
[  5]  43.00-44.00  sec  3.75 MBytes  31.5 Mbits/sec    0   1.87 MBytes
[  5]  44.00-45.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.95 MBytes
[  5]  45.00-46.00  sec  2.50 MBytes  21.0 Mbits/sec    0   2.06 MBytes
[  5]  46.00-47.00  sec  3.72 MBytes  31.2 Mbits/sec    0   2.19 MBytes
[  5]  47.00-48.00  sec  2.35 MBytes  19.7 Mbits/sec    0   2.33 MBytes
[  5]  48.00-49.00  sec  3.28 MBytes  27.5 Mbits/sec    0   2.53 MBytes
[  5]  49.00-50.00  sec  3.40 MBytes  28.5 Mbits/sec    0   2.76 MBytes
[  5]  50.00-51.00  sec  1.14 MBytes  9.52 Mbits/sec   65   1.24 MBytes
[  5]  51.00-52.00  sec  3.69 MBytes  30.9 Mbits/sec    0   2.05 MBytes
[  5]  52.00-53.00  sec  2.50 MBytes  21.0 Mbits/sec  163   1.45 MBytes
[  5]  53.00-54.00  sec  3.75 MBytes  31.5 Mbits/sec    0   1.52 MBytes
[  5]  54.00-55.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.59 MBytes
[  5]  55.00-56.00  sec  3.75 MBytes  31.5 Mbits/sec    0   1.65 MBytes
[  5]  56.00-57.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.70 MBytes
[  5]  57.00-58.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.73 MBytes
[  5]  58.00-59.00  sec  2.50 MBytes  21.0 Mbits/sec    0   1.74 MBytes
[  5]  59.00-60.00  sec  3.75 MBytes  31.5 Mbits/sec    0   1.75 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-60.00  sec   169 MBytes  23.6 Mbits/sec  673
sender
[  5]   0.00-60.00  sec   168 MBytes  23.5 Mbits/sec
receiver

iperf Done.
```
Running the experiment for 60 seconds, the thp stablized to 23.5Mbits/sec.

### Core Separate from gnb and UE. 

Separating the core network from the gnb into different machines can be a minor challenge. 

Some resources that you may need:
+ https://www.powderwireless.net/show-profile.php?project=PowderTeam&profile=oai-indoor-ota
+ https://gitlab.flux.utah.edu/dmaas/oai-indoor-ota

This OTA experiment separate the core network from the gnb, so it contains some useful material. In the bin folder, the setup script is especially useful. We may also make use of the gnb.conf in the etc folder, to configure which address and socket we should bind to, because that may change as well. 

+ https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/NETWORK_CONSIDERATIONS.md 
This tutorial contains incomplete guide to setup core and gnb separately. 

+ https://github.com/PeterYaoNYU/core-network-5g
this is the profile to setup a POWDER/CLOUDLAB testbed with an extra link connecting 2 servers back to back. 

On the Core machine, do the following:
```bash
        sudo sysctl net.ipv4.conf.all.forwarding=1
        sudo iptables -P FORWARD ACCEPT
```
On the gnb machine, do the following:

```bash
LANIF=`ip r | awk '/10\.10\.1\.2/{print $3}'
sudo ip route add 192.168.70.128/26 via 192.168.1.1 dev $LANIF
```

You also need to chanhge the gnb configuration, perhaps the most important step that I was missing last night, resulting in gnb not attaching to the CN. 

```
    NETWORK_INTERFACES :
    {
        GNB_INTERFACE_NAME_FOR_NG_AMF            = "demo-oai";
        GNB_IPV4_ADDRESS_FOR_NG_AMF              = "10.10.1.2";
        GNB_INTERFACE_NAME_FOR_NGU               = "demo-oai";
        GNB_IPV4_ADDRESS_FOR_NGU                 = "10.10.1.2";
        GNB_PORT_FOR_S1U                         = 2152; # Spec 2152
    };
```
10.10.1.2 is the IP of the machine that hosts gnb. 

Pinging the UE, it seems that, delay-wise, it does not make a difference. 
```
root@29b9bec80e0f:/tmp# ping 12.1.1.130
PING 12.1.1.130 (12.1.1.130) 56(84) bytes of data.
64 bytes from 12.1.1.130: icmp_seq=1 ttl=63 time=82.8 ms
64 bytes from 12.1.1.130: icmp_seq=2 ttl=63 time=89.1 ms
64 bytes from 12.1.1.130: icmp_seq=3 ttl=63 time=92.2 ms
64 bytes from 12.1.1.130: icmp_seq=4 ttl=63 time=92.2 ms
64 bytes from 12.1.1.130: icmp_seq=5 ttl=63 time=81.0 ms
64 bytes from 12.1.1.130: icmp_seq=6 ttl=63 time=82.8 ms
64 bytes from 12.1.1.130: icmp_seq=7 ttl=63 time=79.7 ms
64 bytes from 12.1.1.130: icmp_seq=8 ttl=63 time=89.7 ms
64 bytes from 12.1.1.130: icmp_seq=9 ttl=63 time=90.3 ms
64 bytes from 12.1.1.130: icmp_seq=10 ttl=63 time=92.1 ms
64 bytes from 12.1.1.130: icmp_seq=11 ttl=63 time=79.0 ms
64 bytes from 12.1.1.130: icmp_seq=12 ttl=63 time=92.8 ms
64 bytes from 12.1.1.130: icmp_seq=13 ttl=63 time=78.4 ms
^C
--- 12.1.1.130 ping statistics ---
13 packets transmitted, 13 received, 0% packet loss, time 12017ms
rtt min/avg/max/mdev = 78.440/86.363/92.841/5.507 ms
```


Running the iperf server on one node:
```
iperf3 -s -B 12.1.1.131
```
Running the client on ext dn:
```
root@29b9bec80e0f:/tmp# iperf3 -c 12.1.1.131 -t 60
Connecting to host 12.1.1.131, port 5201
[  4] local 192.168.70.135 port 45418 connected to 12.1.1.131 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-1.00   sec  1.52 MBytes  12.7 Mbits/sec    0    164 KBytes
[  4]   1.00-2.00   sec  1.62 MBytes  13.5 Mbits/sec    0    228 KBytes
[  4]   2.00-3.00   sec  1.80 MBytes  15.1 Mbits/sec    0    301 KBytes
[  4]   3.00-4.00   sec  2.36 MBytes  19.8 Mbits/sec    0    395 KBytes
[  4]   4.00-5.00   sec  2.98 MBytes  25.0 Mbits/sec    0    515 KBytes
[  4]   5.00-6.00   sec  3.48 MBytes  29.2 Mbits/sec    0    655 KBytes
[  4]   6.00-7.00   sec  2.98 MBytes  25.0 Mbits/sec    0    802 KBytes
[  4]   7.00-8.00   sec  2.80 MBytes  23.5 Mbits/sec    0    950 KBytes
[  4]   8.00-9.00   sec  2.86 MBytes  24.0 Mbits/sec    0   1.07 MBytes
[  4]   9.00-10.00  sec  2.80 MBytes  23.5 Mbits/sec    0   1.22 MBytes
[  4]  10.00-11.00  sec  2.80 MBytes  23.5 Mbits/sec    0   1.36 MBytes
[  4]  11.00-12.00  sec  2.92 MBytes  24.5 Mbits/sec    0   1.51 MBytes
[  4]  12.00-13.00  sec  2.80 MBytes  23.5 Mbits/sec    0   1.65 MBytes
[  4]  13.00-14.00  sec  2.86 MBytes  24.0 Mbits/sec    0   1.80 MBytes
[  4]  14.00-15.00  sec  2.78 MBytes  23.3 Mbits/sec    0   1.94 MBytes
[  4]  15.00-16.00  sec  2.84 MBytes  23.8 Mbits/sec    0   2.09 MBytes
[  4]  16.00-17.00  sec  2.76 MBytes  23.1 Mbits/sec    0   2.36 MBytes
[  4]  17.00-18.00  sec  2.83 MBytes  23.7 Mbits/sec    0   2.68 MBytes
[  4]  18.00-19.00  sec  3.06 MBytes  25.6 Mbits/sec    0   3.03 MBytes
[  4]  19.00-20.00  sec  1.38 MBytes  11.6 Mbits/sec  284   1.96 MBytes
[  4]  20.00-21.00  sec  4.64 MBytes  38.9 Mbits/sec    0   2.22 MBytes
[  4]  21.00-22.00  sec  2.54 MBytes  21.3 Mbits/sec    0   2.38 MBytes
[  4]  22.00-23.00  sec  2.85 MBytes  23.9 Mbits/sec    0   2.53 MBytes
[  4]  23.00-24.00  sec  2.88 MBytes  24.1 Mbits/sec    0   2.62 MBytes
[  4]  24.00-25.00  sec  2.85 MBytes  23.9 Mbits/sec    0   2.73 MBytes
[  4]  25.00-26.00  sec  2.95 MBytes  24.7 Mbits/sec    0   2.82 MBytes
[  4]  26.00-27.00  sec  3.16 MBytes  26.6 Mbits/sec    0   2.87 MBytes
[  4]  27.00-28.00  sec  1.31 MBytes  11.0 Mbits/sec   13   1.01 MBytes
[  4]  28.00-29.00  sec  3.56 MBytes  29.8 Mbits/sec  334   1.22 MBytes
[  4]  29.00-30.00  sec  3.86 MBytes  32.4 Mbits/sec    0   1.47 MBytes
[  4]  30.00-31.00  sec  2.80 MBytes  23.5 Mbits/sec    0   1.60 MBytes
[  4]  31.00-32.00  sec  2.86 MBytes  24.0 Mbits/sec    0   1.72 MBytes
[  4]  32.00-33.00  sec  2.80 MBytes  23.5 Mbits/sec    0   1.82 MBytes
[  4]  33.00-34.00  sec  2.92 MBytes  24.5 Mbits/sec    0   1.90 MBytes
[  4]  34.00-35.00  sec  2.93 MBytes  24.6 Mbits/sec    0   1.95 MBytes
[  4]  35.00-36.00  sec  2.59 MBytes  21.7 Mbits/sec    0   1.99 MBytes
[  4]  36.00-37.00  sec  2.86 MBytes  24.0 Mbits/sec    0   2.01 MBytes
[  4]  37.00-38.00  sec  2.81 MBytes  23.5 Mbits/sec    0   2.03 MBytes
[  4]  38.00-39.00  sec  2.97 MBytes  24.9 Mbits/sec    0   2.04 MBytes
[  4]  39.00-40.00  sec  2.84 MBytes  23.9 Mbits/sec    0   2.04 MBytes
[  4]  40.00-41.00  sec  2.76 MBytes  23.1 Mbits/sec    0   2.04 MBytes
[  4]  41.00-42.00  sec  2.93 MBytes  24.6 Mbits/sec    0   2.04 MBytes
[  4]  42.00-43.00  sec  2.78 MBytes  23.3 Mbits/sec    0   2.05 MBytes
[  4]  43.00-44.00  sec  2.86 MBytes  24.0 Mbits/sec    0   2.07 MBytes
[  4]  44.00-45.00  sec  2.85 MBytes  23.9 Mbits/sec    0   2.09 MBytes
[  4]  45.00-46.00  sec  2.82 MBytes  23.6 Mbits/sec    0   2.14 MBytes
[  4]  46.00-47.00  sec  2.82 MBytes  23.6 Mbits/sec    0   2.20 MBytes
[  4]  47.00-48.00  sec  2.77 MBytes  23.2 Mbits/sec    0   2.28 MBytes
[  4]  48.00-49.00  sec  2.80 MBytes  23.5 Mbits/sec    0   2.39 MBytes
[  4]  49.00-50.00  sec  2.83 MBytes  23.7 Mbits/sec    0   2.52 MBytes
[  4]  50.00-51.00  sec  2.85 MBytes  23.9 Mbits/sec    0   2.65 MBytes
[  4]  51.00-52.00  sec  3.14 MBytes  26.4 Mbits/sec    0   2.86 MBytes
[  4]  52.00-53.00  sec  2.80 MBytes  23.4 Mbits/sec    0   2.98 MBytes
[  4]  53.00-54.00  sec  1.31 MBytes  11.0 Mbits/sec  157   1.87 MBytes
[  4]  54.00-55.00  sec  4.01 MBytes  33.6 Mbits/sec   92   1.94 MBytes
[  4]  55.00-56.00  sec  3.45 MBytes  28.9 Mbits/sec    0   1.57 MBytes
[  4]  56.00-57.00  sec  2.86 MBytes  24.0 Mbits/sec    0   1.65 MBytes
[  4]  57.00-58.00  sec  2.80 MBytes  23.5 Mbits/sec    0   1.73 MBytes
[  4]  58.00-59.00  sec  2.92 MBytes  24.5 Mbits/sec    0   1.79 MBytes
[  4]  59.00-60.00  sec  2.80 MBytes  23.5 Mbits/sec    0   1.83 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-60.00  sec   168 MBytes  23.5 Mbits/sec  880             sender
[  4]   0.00-60.00  sec   167 MBytes  23.3 Mbits/sec                  receiver

iperf Done.
```

It does not seem to make a difference. 