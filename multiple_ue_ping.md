#### Task:
Let multiple UEs ping through to an external data source. 

First start the gnb. 
```
cd /mydata/openairinterface5g/cmake_targets
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /local/repository/etc/gnb.conf --sa --rfsim
```

Start the flexric here (not necessary, I just hate to see the E2 timeout requests all the time)

Then start one UE:
```
cd /mydata/openairinterface5g/cmake_targets/ran_build/build/
sudo ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --rfsim --sa --uicc0.imsi 001010000000001 --rfsimulator.serveraddr 127.0.0.1
```

I first verify that the AMF log is showing correct result: one UE connected to a gNB
```
[2024-06-26T13:50:46.170337] [AMF] [amf_app] [info ]
[2024-06-26T13:50:46.170381] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T13:50:46.170389] [AMF] [amf_app] [info ] |----------------------------------------------------gNBs' information-------------------------------------------|
[2024-06-26T13:50:46.170396] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2024-06-26T13:50:46.170442] [AMF] [amf_app] [info ] |      1      |    Connected     |         0xe000       |         gNB-Eurecom-5GNRBox        |            208, 95             |
[2024-06-26T13:50:46.170455] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T13:50:46.170461] [AMF] [amf_app] [info ]
[2024-06-26T13:50:46.170467] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T13:50:46.170478] [AMF] [amf_app] [info ] |----------------------------------------------------UEs' information--------------------------------------------|
[2024-06-26T13:50:46.170485] [AMF] [amf_app] [info ] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |Cell ID|
[2024-06-26T13:50:46.170495] [AMF] [amf_app] [info ] |      1|    5GMM-REG-INITIATED|   001010000000001|               |               1|          1| 208, 95 |14680064|
[2024-06-26T13:50:46.170502] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T13:50:46.170508] [AMF] [amf_app] [info ]
```

Then it gives me something weird: the UE does not really have an IP address?

```
ip a
...
71: oaitun_ue1: <POINTOPOINT,MULTICAST,NOARP> mtu 1500 qdisc noop state DOWN group default qlen 500
    link/none
PeterYao@node:~$ ip -o -4 addr list oaitun_ue1
show nothing
```

It seems that the IP interface of UE is not assigned any address. 

Is this the problem of the flexric?

I do not think so, after stopping the flexric and starting the gnb and UE again, I can still see that the ip address of the UE is not available. 

Fine, this leaves me no choice but to manually assign an IP address to the UE:

```
sudo ip addr add 192.168.0.2/24 dev oaitun_ue1
```

and we can indeed verify that witt the ip a command:

```
72: oaitun_ue1: <POINTOPOINT,MULTICAST,NOARP> mtu 1500 qdisc noop state DOWN group default qlen 500
    link/none
    inet 192.168.0.2/24 scope global oaitun_ue1
       valid_lft forever preferred_lft forever
```

And ping from the external network to the UE is successful:

```
PeterYao@node:~$ sudo docker exec -it oai-ext-dn ping -c 10 192.168.0.2
PING 192.168.0.2 (192.168.0.2) 56(84) bytes of data.
64 bytes from 192.168.0.2: icmp_seq=1 ttl=64 time=0.077 ms
64 bytes from 192.168.0.2: icmp_seq=2 ttl=64 time=0.060 ms
64 bytes from 192.168.0.2: icmp_seq=3 ttl=64 time=0.066 ms
64 bytes from 192.168.0.2: icmp_seq=4 ttl=64 time=0.065 ms
64 bytes from 192.168.0.2: icmp_seq=5 ttl=64 time=0.057 ms
64 bytes from 192.168.0.2: icmp_seq=6 ttl=64 time=0.063 ms
64 bytes from 192.168.0.2: icmp_seq=7 ttl=64 time=0.058 ms
^C
--- 192.168.0.2 ping statistics ---
7 packets transmitted, 7 received, 0% packet loss, time 6138ms
rtt min/avg/max/mdev = 0.057/0.063/0.077/0.011 ms
```

Then we scale up the number of UE. In another terminal, bring up the second UE with the command:

```
sudo ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --rfsim --sa --uicc0.imsi 001010000000003 --rfsimulator.serveraddr 127.0.0.1
```

And we see some errors:
```
[PDCP]   pdcp init,usegtp usenetlink
[PDCP]   TUN: Error opening socket oaitun_ue1 (16:Device or resource busy)
[PDCP]   UE pdcp will use tun interface
[PDCP]   fcntl(F_SETFL) failed on fd -1: errno 9, Bad file descriptor
[NR_MAC]   [UE0] Initializing MAC
[PDCP]   error: cannot read() from fd -1: errno 9, Bad file descriptor
[NR_MAC]   Initializing dl and ul config_request. num_slots = 20
[RLC]   Activated srb0 for UE 0
```

It seems that the ip interface oaitun_ue1 is already in use by the previous UE. It needs to be changed to another interface. Checking the ip command, I also did not see any other UE interfaces. 

Before we attempt to fix it, let me put here some relevant links that might potentially be useful:

https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/master/ci-scripts/conf_files/nrue.uicc.conf

https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/master/doc/L2NFAPI_S1.md 

***Edit openair3/NAS/TOOLS/ue_eurecom_test_sfr.conf with your preferred editor***

Forgive me, I am stupid. This seems to be legacy from the LTE era. It is not working with the 5g anymore. There is no such command line option as num-ues in the 5g ue implementation (/mydata/openairinterface5g/executables/nr-softmodem.h)

The problem right now is the missing interfaces. Referring back to the tutorial for OAI workshop, it suddenly makes sense that they provide a script. 

https://gitlab.eurecom.fr/oaiworkshop/summerworkshop2023/-/blob/main/ran/multi-ue.sh?ref_type=heads  

Ok, it seems that the bash script that the workshop provides is not neccessari;y running perfectly. The problem that I keep getting is after creating a ue1 namespace, the v-eth0 interface cannot be found. 

```bash
# get into the oai folder
# create a namesapce called ue1
sudo bash ./multi-ue.sh -c1 -e
# verify that the namespace is created successfully. 
PeterYao@node:~$ ip netns list
ue1 (id: 9)

# get into that namespace:
ip netns exec ue1 bash
```

It seems that we are missing v-eth0 interface, and this will cause us problem when initiating the ue
```
PeterYao@node:~$ sudo !!
sudo ip netns exec ue1 bash
root@node:~# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
49: v-ue1@if50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 2a:75:5f:83:f5:71 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.201.1.1/24 scope global v-ue1
       valid_lft forever preferred_lft forever
    inet6 fe80::2875:5fff:fe83:f571/64 scope link
       valid_lft forever preferred_lft forever

```

Fine there seems to be no issue running the UE:
sudo -E LD_LIBRARY_PATH=. RFSIMULATOR=10.201.1.100 ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --rfsim --sa -O ./ue.conf

Output:
```
[2024-06-26T16:42:21.302150] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T16:42:21.302163] [AMF] [amf_app] [info ] |----------------------------------------------------gNBs' information-------------------------------------------|
[2024-06-26T16:42:21.302169] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2024-06-26T16:42:21.302181] [AMF] [amf_app] [info ] |      1      |    Connected     |         0xe000       |         gNB-Eurecom-5GNRBox        |            208, 95             |
[2024-06-26T16:42:21.302188] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T16:42:21.302195] [AMF] [amf_app] [info ]
[2024-06-26T16:42:21.302200] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T16:42:21.302206] [AMF] [amf_app] [info ] |----------------------------------------------------UEs' information--------------------------------------------|
[2024-06-26T16:42:21.302212] [AMF] [amf_app] [info ] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |Cell ID|
[2024-06-26T16:42:21.302228] [AMF] [amf_app] [info ] |      1|    5GMM-REG-INITIATED|   001010000000101|               |               1|          1| 208, 95 |14680064|
[2024-06-26T16:42:21.302235] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T16:42:21.302241] [AMF] [amf_app] [info ]
```

and the interface is brought up successfully:
```bash
root@node:/mydata/openairinterface5g# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
2: oaitun_ue1: <POINTOPOINT,MULTICAST,NOARP> mtu 1500 qdisc noop state DOWN group default qlen 500
    link/none
49: v-ue1@if50: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 2a:75:5f:83:f5:71 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.201.1.1/24 scope global v-ue1
       valid_lft forever preferred_lft forever
    inet6 fe80::2875:5fff:fe83:f571/64 scope link
       valid_lft forever preferred_lft forever
```

Now let us add the second ue

```bash 
PeterYao@node:/mydata/openairinterface5g$ sudo bash ./multi-ue.sh -c3
creating namespace for UE ID 3 name ue3
PeterYao@node:/mydata/openairinterface5g$ ip netns list
ue3 (id: 10)
ue1 (id: 9)
PeterYao@node:/mydata/openairinterface5g$ ip netns exec ue3 bash
setting the network namespace "ue3" failed: Operation not permitted
PeterYao@node:/mydata/openairinterface5g$ sudo !!
sudo ip netns exec ue3 bash
root@node:/mydata/openairinterface5g# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
51: v-ue3@if52: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether be:69:f9:23:0d:5c brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.203.1.3/24 scope global v-ue3
       valid_lft forever preferred_lft forever
    inet6 fe80::bc69:f9ff:fe23:d5c/64 scope link
       valid_lft forever preferred_lft forever
root@node:/mydata/openairinterface5g# cd ./cmake_targets/ran_build/build/
root@node:/mydata/openairinterface5g/cmake_targets/ran_build/build# ^C
root@node:/mydata/openairinterface5g/cmake_targets/ran_build/build# sudo -E LD_LIBRARY_PATH=. RFSIMULATOR=10.203.1.100 ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --rfsim --sa -O ./ue.conf --uicc0.imsi 001010000000103
```

And we check the amf log again:
```
[2024-06-26T16:48:21.304958] [AMF] [amf_app] [info ]
[2024-06-26T16:48:21.304993] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T16:48:21.305001] [AMF] [amf_app] [info ] |----------------------------------------------------gNBs' information-------------------------------------------|
[2024-06-26T16:48:21.305008] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2024-06-26T16:48:21.305021] [AMF] [amf_app] [info ] |      1      |    Connected     |         0xe000       |         gNB-Eurecom-5GNRBox        |            208, 95             |
[2024-06-26T16:48:21.305028] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T16:48:21.305034] [AMF] [amf_app] [info ]
[2024-06-26T16:48:21.305039] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T16:48:21.305045] [AMF] [amf_app] [info ] |----------------------------------------------------UEs' information--------------------------------------------|
[2024-06-26T16:48:21.305051] [AMF] [amf_app] [info ] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |Cell ID|
[2024-06-26T16:48:21.305062] [AMF] [amf_app] [info ] |      1|    5GMM-REG-INITIATED|   001010000000101|               |               1|          1| 208, 95 |14680064|
[2024-06-26T16:48:21.305071] [AMF] [amf_app] [info ] |      2|    5GMM-REG-INITIATED|   001010000000103|               |               2|          2| 208, 95 |14680064|
[2024-06-26T16:48:21.305077] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-26T16:48:21.305086] [AMF] [amf_app] [info ]
```

Note: if there is any trouble with the network interfaces, restart, though naive, will be the most effective way to reset anything related to ifconfig. 

Ping UE3 from external data network:
```bash
PeterYao@node:~$ sudo docker exec -it oai-ext-dn ping -c 10 10.203.1.3
PING 10.203.1.3 (10.203.1.3) 56(84) bytes of data.
64 bytes from 10.203.1.3: icmp_seq=1 ttl=63 time=0.127 ms
64 bytes from 10.203.1.3: icmp_seq=2 ttl=63 time=0.073 ms
64 bytes from 10.203.1.3: icmp_seq=3 ttl=63 time=0.073 ms
64 bytes from 10.203.1.3: icmp_seq=4 ttl=63 time=0.058 ms
64 bytes from 10.203.1.3: icmp_seq=5 ttl=63 time=0.056 ms
64 bytes from 10.203.1.3: icmp_seq=6 ttl=63 time=0.056 ms
64 bytes from 10.203.1.3: icmp_seq=7 ttl=63 time=0.072 ms
64 bytes from 10.203.1.3: icmp_seq=8 ttl=63 time=0.065 ms
64 bytes from 10.203.1.3: icmp_seq=9 ttl=63 time=0.064 ms
64 bytes from 10.203.1.3: icmp_seq=10 ttl=63 time=0.066 ms

--- 10.203.1.3 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9205ms
rtt min/avg/max/mdev = 0.056/0.071/0.127/0.019 ms
```

Ping UE1 from external data network:
```bash
PeterYao@node:~$ sudo docker exec -it oai-ext-dn ping -c 10 10.201.1.1
PING 10.201.1.1 (10.201.1.1) 56(84) bytes of data.
64 bytes from 10.201.1.1: icmp_seq=1 ttl=63 time=0.068 ms
64 bytes from 10.201.1.1: icmp_seq=2 ttl=63 time=0.080 ms
64 bytes from 10.201.1.1: icmp_seq=3 ttl=63 time=0.082 ms
64 bytes from 10.201.1.1: icmp_seq=4 ttl=63 time=0.081 ms
64 bytes from 10.201.1.1: icmp_seq=5 ttl=63 time=0.080 ms
64 bytes from 10.201.1.1: icmp_seq=6 ttl=63 time=0.080 ms
64 bytes from 10.201.1.1: icmp_seq=7 ttl=63 time=0.076 ms
64 bytes from 10.201.1.1: icmp_seq=8 ttl=63 time=0.083 ms
64 bytes from 10.201.1.1: icmp_seq=9 ttl=63 time=0.080 ms
64 bytes from 10.201.1.1: icmp_seq=10 ttl=63 time=0.080 ms

--- 10.201.1.1 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9222ms
rtt min/avg/max/mdev = 0.068/0.079/0.083/0.004 ms
```

Both are successful. 