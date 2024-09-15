# Exploring the 5G Network Slicing

Yuncheng Yao (Peter) 

## Main Learning Objectives:
In this experiment, you will epxlore the 5G network slicing. You will learn:
1. How a 5G network can be sliced in both core and RAN, so that different service levels can be provided to different users, using the same physical wireless resources. 

## Background
To help you proceed with a good understanding of what you are doing, I will first wal you through several important concepts. 

### O-RAN
O-RAN is an initiative to standardize and open up the interfaces and architecture of the RAN component of mobile networks. Traditionally, RAN systems have been proprietary, meaning that equipment from one vendor often couldn’t interoperate with equipment from another. O-RAN seeks to change this by defining open and standardized interfaces. It is bringing the same revolution to RAN that SDN brings to data-ceneter netorking: interoperability between different vendor's products.

### RIC (RAN Intelligent Controller)
RIC stands for RAN Intelligent Controller. It is a key component in the Open RAN (O-RAN) architecture, aimed at enhancing the management and optimization of the Radio Access Network (RAN). It can give near real-time instructions and policy changes to the base station. [1]

### xAPP (external applications)
An xApp is an additional process that runs on the RAN Intelligent Controller (RIC) within an O-RAN architecture. xApps are designed to provide specific functionalities for managing and optimizing the Radio Access Network (RAN).

### RAN Slicing 
Slcing the RAN is about allocating physical resource blocks to different slices. Its aim is to provide divese service atop a single physical infrastructure. 

### NVS Inter-Slice Scheduling
The MAC level scheduler that we will use for RAN slicing is NVS [2]. It was proposed originally for Wifi scheduling, but is also applpicable to cellular network. The basic idea is to allocate different time slot completely to different users, as illustrated in the picture below. 

With NVS, we are using a 2-level scheduling. On the first slice level, we use NVS to decide which slice should get the PRB(physical resource blocks) at this time interval. And then specific enterprise algorithms is used to do the intra-slice scheduling. 

![屏幕截图 2024-07-21 175410](/assets/屏幕截图%202024-07-21%20175410.png)

Other MAC slice scheduling algorithms include: static slicing, which always allocate certain PRBs to a certain slice; EDF, which defines a deadline for all slices during which they need to be guaranteed a certain number of RBs.


### Core slicing
We extend the RAN slicing to core network. We focus on the case of 2 different UEs connected to the same gNB, and they go through different UPFs in the core network, which then go to different first hop interface. 

### Other Prerequisites


To understand the material comprehensively, before proceeding, you should read the [Explore RAN](https://witestlab.poly.edu/blog/exploring-the-5g-ran/) and [Explore Core](https://witestlab.poly.edu/blog/exploring-the-5g-core-network/) passages, and understand the functionality of different Network Functions(NFs) in the core, as well as some basic concepts in RAN (e.g. What is a gNB, UE...).

## Reserve a Bare Metal Server on POWDER


We run our experiemnts on POWDER Testbed. For this experiment, you will need one d430-type server on the Emulab cluster. Since you are reserving an entire bare-metal server, you should:

+ set aside time to work on this lab. You should reserve 6-12 hours (depending on how conservative you want to be) - the lab should not take that long, but this will give you some extra time in case you run into any issues.
+ reserve a d430 server for that time at least a few days in advance
+ and during your reserved time, complete the entire lab assignment in one sitting.

Please make the reservation [here on POWDER](https://www.powderwireless.net/resgroup.php). The cluster is Emulab, and you will need 1 d430 machine. Please leavel frequency blank, as that are for OTA experiemnts. 


## Instantiate a Profile


Instantiate this profile when the reservation time comes, as it has most of the software that we would probably need already installed. 

https://www.powderwireless.net/instantiate.php?profile=ffcb4ebd-47b1-11ef-9f39-e4434b2381fc

In the default setting, you will not have enough storage allocated on the Emulab cluster. The default 16G storage is not enoguh. You need to mount a new file system, and download and install everything in that folder.

```bash
cd /
sudo mkdir mydata
sudo /usr/local/etc/emulab/mkextrafs.pl /mydata

# change the ownership of this new space
username=$(whoami)
groupname=$(id -gn)

sudo chown $username:$groupname mydata
chmod 775 mydata
# verify the result
ls -ld mydata
```

You should see something like this  

```bash
drwxrwxr-x 4 PeterYao nyunetworks 4096 Jun 18 14:55 mydata
```

But with your own username and groupname.

### Install the build prerequisites
To compile the OAI RAN, we need newer versions of cmake and gcc. 

You would want to have at least GCC-9. The current version of GCC 7 on the cloudlab profile is just way too old to compile the flexric and OAI. Follow the instructions below:

```bash
# Add the ubuntu-toolchain-r PPA:
sudo add-apt-repository -y ppa:ubuntu-toolchain-r/test
sudo apt-get update
# install actually
sudo apt-get install -y gcc-9 g++-9
# set the new version as the default
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-9
sudo update-alternatives --config gcc
# verify the installation 
gcc --version
```

And you should see the following output:
```
PeterYao@node:~$ gcc --version
gcc (Ubuntu 9.4.0-1ubuntu1~18.04) 9.4.0
Copyright (C) 2019 Free Software Foundation, Inc.
This is free software; see the source for copying conditions.  There is NO
warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
```

You need newer cmake, since OAI is updating on a daily basis:
```bash
wget https://github.com/Kitware/CMake/releases/download/v3.27.0/cmake-3.27.0.tar.gz
tar -xzvf cmake-3.27.0.tar.gz
cd cmake-3.27.0
./bootstrap

make -j 8
sudo make install

export PATH=/users/PeterYao/cmake-3.27.0/bin:$PATH

cmake --version
```

You should expect the following output. 

You need to install the libpcre2-dev

```bash
sudo apt-get install libpcre2-dev
```

### Install OAI

Before we compile the OAI and flexric, first clone them, then checkout the right versions of it, so that they are at commit version where NVS and slicing are actually partially supported. 

```bash
# you are at /mydata
cd /mydata
git clone https://gitlab.eurecom.fr/mosaic5g/flexric.git
cd flexric/
git checkout rc_slice_xapp

# for oai, first git clone the latest version
cd /mydata
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git
cd openairinterface5g
git checkout rebased-5g-nvs-rc-rf
cd cmake_targets
```

Inside the OAI repo, We are changing a function. This function is invoked when a slice is added to the base station, and it is associating existing UEs with newly added slices. The general rule is that the first UE is associated with the first slice, while the second UE with the second slice. The OAI support for slicing is partial and not out-of-the-box, so we need to adapt it to our own needs, which is to associate two UEs at one gNB to 2 different slices. 

I have prepared the file in the folder upon instantiation of this experiment. You should copy to the folder path with the command. 

```bash
cp /local/repository/etc/modified_oai_code/rc_ctrl_service_style_2.c /mydata/openairinterface5g/openair2/E2AP/RAN_FUNCTION/O-RAN/
```


### Install FlexRIC
Compile the OAI Code:
```bash
cd /mydata/openairinterface5g
cd cmake_targets
./build_oai -c -C -I -w SIMU --gNB --nrUE --build-e2 --ninja
```

Compile the Flexric Code, we should follow the instructions at the [flexric's gitlab page](https://gitlab.eurecom.fr/mosaic5g/flexric). Please install the SWIG interface per instructions, and then compile the FlexRIC that we just checked out.

```bash

git clone https://github.com/swig/swig.git
cd swig
git checkout release-4.1
./autogen.sh
./configure --prefix=/usr/
make -j8
make install

cd /mydata/flexric && mkdir build && cd build && cmake .. && make -j8 
sudo make install

```

### Bring Up the Core Network
Clone the core network. 
```bash
cd /mydata
git clone https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed.git
cd /mydata/oai-cn5g-fed
```

First please bring up the core network. 

We aim to reproduce this core network:

![屏幕截图 2024-07-16 162905](/assets/屏幕截图%202024-07-16%20162905.png)

Copy these files into the respective folder. Replace the original files if necessary.

+ copy the docker compose file into /mydata/oai-cn5g-fed/docker-compose

+ copy the other configuration files into /mydata/oai-cn5g-fed/docker-compose/conf

```bash
cp /local/repository/etc/core-slice-conf/docker-compose-basic-nrf.yaml /mydata/oai-cn5g-fed/docker-compose

cp /local/repository/etc/core-slice-conf/basic* /mydata/oai-cn5g-fed/docker-compose/conf
```

Note that we do not use an NSSF here, as that is only necessary for the multiple NRF case. 

The slices that we are adding are sst 1 sd 1 and sst 1 sd 5. So we need to configure that in the gnb.conf at /local/repository/etc. This has already been done for you. But let me explain:

```
uicc0 = {
imsi = "208950000000031";
key = "0C0A34601D4F07677303652C0462535B";
opc= "63bfa50ee6523365ff14c1f45f88737d";
dnn= "oai";
nssai_sst=1;
nssai_sd=1;
}

@include "channelmod_rfsimu.conf"
```

The IMSI, key, opc are for user authentification. The dnn represents the data network that this UE should connect to. Slice information is represented with two numbers, sst and sd. One for slice category, and one for intra slice differentiation. Here we configure the UE to have sst 1 sd 1. This information will be included in the NAS packet that the UE send to the core network upon attachment. The core network will then assign UPF to the UE based on this slicing information.

The configuration file as usual is in the /local/repository/etc/ folder. Some general principles would be:

+ The SST SD is among those provided by the gNB ***AND*** the Core network AMF, otherwise the connection will berejected for sure

+ The UE imsi and keychain should match up with the user database, so that it can authenticate. 

Then we bring up the core network, and the gnb, and in the respective SSH sessions, we bring up the two UEs. You should also monitor the logs for AMF, two SMFs, and 2 UPFs. 

```bash
# core network
cd /mydata/oai-cn5g-fed/docker-compose  
sudo python3 ./core-network.py --type start-basic --scenario 1
```
> if the containers are not healthy, shut down and retry. It should ahppen very rarely. With the command:
sudo python3 ./core-network.py --type stop-basic --scenario 1

We will later verify that our core network is connected correctly, after we set up the UE and gNB. 

### Bring up the gNB and attach 2 UEs
Having brought up the core network, now we are ready to bring up the gnb. 

```bash
cd /mydata/openairinterface5g/cmake_targets
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /local/repository/etc/gnb.conf --sa --rfsim
```

You would also need to bring up the flexric. 

```bash
cd /mydata/flexric/
./build/examples/ric/nearRT-RIC
```

To attach two UEs to the same gnb, we will need some extra work to isolate them into 2 different subnets. This [tutorial](https://gitlab.eurecom.fr/oaiworkshop/summerworkshop2023/-/tree/main/ran#multiple-ues) provides a useful guide. But you do not need to read that. I have laid out the usage below. 

To attach the first UE. 
```bash
cd /mydata
git clone https://gitlab.eurecom.fr/oaiworkshop/summerworkshop2023.git
sudo /mydata/summerworkshop2023/ran/multi-ue.sh -c1 -e
sudo ip netns exec ue1 bash
#  go back to the oai cmake_targets folder. 
cd /mydata/openairinterface5g/cmake_targets
sudo RFSIMULATOR=10.201.1.100 ./ran_build/build/nr-uesoftmodem -O /local/repository/etc/ue.conf -r 106 -C 3619200000 --sa --nokrnmod --numerology 1 --band 78 --rfsim --rfsimulator.options chanmod
```

Then attach the second UE to the gnb:
```bash
sudo /mydata/summerworkshop2023/ran/multi-ue.sh -c3 -e
sudo ip netns exec ue3 bash
#  go back to the oai cmake_targets folder. 
cd /mydata/openairinterface5g/cmake_targets
sudo RFSIMULATOR=10.203.1.100 ./ran_build/build/nr-uesoftmodem -O /local/repository/etc/ue2.conf -r 106 -C 3619200000 --sa --nokrnmod --numerology 1 --band 78 --rfsim --rfsimulator.options chanmod
```

Checking the AMF log with the command:
```bash
sudo docker logs -f oai-amf
```
You should see something like this:

```
[2024-07-22 02:35:22.052] [amf_app] [info]
[2024-07-22 02:35:22.052] [amf_app] [info] |--------------------------------------------------------------------------------------------------------------------|
[2024-07-22 02:35:22.052] [amf_app] [info] |------------------------------------------------------gNBs' information---------------------------------------------|
[2024-07-22 02:35:22.052] [amf_app] [info] |    Index    |      Status      |       Global ID       |       gNB Name       |                 PLMN               |
[2024-07-22 02:35:22.052] [amf_app] [info] |      1      |    Connected     |        0xe000        |       gNB-Eurecom-5GNRBox           |               208, 95              |
[2024-07-22 02:35:22.052] [amf_app] [info] |--------------------------------------------------------------------------------------------------------------------|
[2024-07-22 02:35:22.052] [amf_app] [info]
[2024-07-22 02:35:22.052] [amf_app] [info] |--------------------------------------------------------------------------------------------------------------------|
[2024-07-22 02:35:22.052] [amf_app] [info] |----------------------------------------------------UEs' information------------------------------------------------|
[2024-07-22 02:35:22.052] [amf_app] [info] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |  Cell ID  |
[2024-07-22 02:35:22.052] [amf_app] [info] |      1|       5GMM-REGISTERED|   208950000000031|               |               1|          4| 208, 95 |0x   e00000|
[2024-07-22 02:35:22.052] [amf_app] [info] |      2|       5GMM-REGISTERED|   208950000000032|               |               2|          5| 208, 95 |0x   e00000|
[2024-07-22 02:35:22.052] [amf_app] [info] |--------------------------------------------------------------------------------------------------------------------|
```

With 1 gNB and 2 UEs connected. 

We can verify that both ue is connected to the gnb successfully and can be ping through normally in the gnb terminal session.

```
[NR_MAC]   Frame.Slot 128.0
UE RNTI 53e7 CU-UE-ID 1 in-sync PH 0 dB PCMAX 0 dBm, average RSRP -44 (16 meas)
UE 53e7: dlsch_rounds 3088/2/0/0, dlsch_errors 0, pucch0_DTX 0, BLER 0.00000 MCS (0) 9
UE 53e7: ulsch_rounds 3116/0/0/0, ulsch_errors 0, ulsch_DTX 0, BLER 0.00000 MCS (0) 9
UE 53e7: MAC:    TX         380016 RX         356230 bytes
UE 53e7: LCID 1: TX            863 RX            329 bytes
UE 53e7: LCID 2: TX              0 RX              0 bytes
UE 53e7: LCID 4: TX             24 RX            552 bytes
UE RNTI c084 CU-UE-ID 2 in-sync PH 0 dB PCMAX 0 dBm, average RSRP -44 (16 meas)
UE c084: dlsch_rounds 2414/2/0/0, dlsch_errors 0, pucch0_DTX 1, BLER 0.00000 MCS (0) 9
UE c084: ulsch_rounds 2437/0/0/0, ulsch_errors 0, ulsch_DTX 0, BLER 0.00000 MCS (0) 9
UE c084: MAC:    TX         297193 RX         278028 bytes
UE c084: LCID 1: TX            863 RX            329 bytes
UE c084: LCID 2: TX              0 RX              0 bytes
UE c084: LCID 4: TX             24 RX            532 bytes
```

Check that we are pining to the right interface, in different terminal sessions that we just started:
```bash
# UE 1 terminal session
sudo ip netns exec ue1 bash
ip addr list
[OIP]   Interface oaitun_ue1 successfully configured, ip address 12.1.1.130, mask 255.255.255.0 broadcast address 12.1.1.255


# UE2 terminal session
sudo ip netns exec ue3 bash
[OIP]   Interface oaitun_ue1 successfully configured, ip address 12.1.1.66, mask 255.255.255.0 broadcast address 12.1.1.255
```


Because of the way I set up the network, these two IP addresses should be static. Please feel to double check. But from now on, I will use these 2 IP addresses directly. 

Try pinging the two different UEs:
```
root@node:/mydata/flexric/build/examples/xApp/c/ctrl# sudo docker exec -it oai-ext-dn ping -c 10 12.1.1.130
sudo: unable to resolve host node.e2e.nyunetworks.emulab.net: Resource temporarily unavailable
PING 12.1.1.156 (12.1.1.156) 56(84) bytes of data.
64 bytes from 12.1.1.156: icmp_seq=1 ttl=63 time=90.1 ms
64 bytes from 12.1.1.156: icmp_seq=2 ttl=63 time=28.1 ms
64 bytes from 12.1.1.156: icmp_seq=3 ttl=63 time=87.3 ms
64 bytes from 12.1.1.156: icmp_seq=4 ttl=63 time=37.9 ms
64 bytes from 12.1.1.156: icmp_seq=5 ttl=63 time=91.6 ms
64 bytes from 12.1.1.156: icmp_seq=6 ttl=63 time=97.1 ms
64 bytes from 12.1.1.156: icmp_seq=7 ttl=63 time=23.1 ms
64 bytes from 12.1.1.156: icmp_seq=8 ttl=63 time=80.3 ms
64 bytes from 12.1.1.156: icmp_seq=9 ttl=63 time=83.8 ms
64 bytes from 12.1.1.156: icmp_seq=10 ttl=63 time=22.0 ms

--- 12.1.1.156 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9011ms
rtt min/avg/max/mdev = 22.076/64.180/97.149/30.242 ms
root@node:/mydata/flexric/build/examples/xApp/c/ctrl# sudo docker exec -it oai-ext-dn ping -c 10 12.1.1.66
sudo: unable to resolve host node.e2e.nyunetworks.emulab.net: Resource temporarily unavailable
PING 12.1.1.155 (12.1.1.155) 56(84) bytes of data.
64 bytes from 12.1.1.155: icmp_seq=1 ttl=63 time=91.4 ms
64 bytes from 12.1.1.155: icmp_seq=2 ttl=63 time=28.4 ms
64 bytes from 12.1.1.155: icmp_seq=3 ttl=63 time=96.8 ms
64 bytes from 12.1.1.155: icmp_seq=4 ttl=63 time=19.6 ms
64 bytes from 12.1.1.155: icmp_seq=5 ttl=63 time=55.5 ms
64 bytes from 12.1.1.155: icmp_seq=6 ttl=63 time=92.5 ms
64 bytes from 12.1.1.155: icmp_seq=7 ttl=63 time=85.2 ms
64 bytes from 12.1.1.155: icmp_seq=8 ttl=63 time=82.8 ms
64 bytes from 12.1.1.155: icmp_seq=9 ttl=63 time=86.8 ms
64 bytes from 12.1.1.155: icmp_seq=10 ttl=63 time=88.2 ms

--- 12.1.1.155 ping statistics ---
10 packets transmitted, 10 received, 0% packet loss, time 9014ms
rtt min/avg/max/mdev = 19.683/72.763/96.810/26.626 ms
```

If you observe delay on the sub millisecond scale, that means there is something wrong. This generally means that the UE is not connected to the gnb successfully. Either gnb or the core network does not have the slice information properly set up. Please redo each part, and find out where is the problem. 

Then we apply RAN Slicing. 

```bash
cd /mydata/flexric
./build/examples/xApp/c/ctrl/xapp_rc_slice_ctrl
```

> Question:
What outcome did you see in the gnb session when you run the slicing xapp? Please submit a screenshot, and explain the implications. 


### Verify RAN Slicing with iPerf
Get the IP address of the first UE, in my case it is 12.1.1.130. It should be the same on your machine. Please double check with the following command. Find the interface called oaitun_ue1:
```bash
sudo ip netns exec ue1 bash
ip addr list
```

You should see something similar to this:
```
55: oaitun_ue1: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none
    inet 12.1.1.130/24 brd 12.1.1.255 scope global oaitun_ue1
       valid_lft forever preferred_lft forever
    inet6 fe80::509c:4f08:8936:7761/64 scope link stable-privacy
       valid_lft forever preferred_lft forever
```
and 12.1.1.130 is our address. 


Then start the iperf server in the same session:
```bash
PeterYao@node:~$ sudo ip netns exec ue1 bash
root@node:~# iperf3 -s
-----------------------------------------------------------
Server listening on 5201
```

In another session, log into the ext-dn, and start iperf client:
```bash
PeterYao@node:~$ sudo ip netns exec ue1 bash
root@node:~# iperf3 -s
```

You should see something similar to this:
```bash
PeterYao@node:~$ sudo docker exec -it oai-ext-dn bash
root@581e40107528:/tmp# iperf3 -c 12.1.1.130
Connecting to host 12.1.1.155, port 5201
[  4] local 192.168.70.135 port 43686 connected to 12.1.1.155 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-1.00   sec  1.90 MBytes  15.9 Mbits/sec    0    255 KBytes
[  4]   1.00-2.00   sec  1.37 MBytes  11.5 Mbits/sec    0    310 KBytes
[  4]   2.00-3.00   sec  1.68 MBytes  14.1 Mbits/sec    0    376 KBytes
[  4]   3.00-4.00   sec  1.99 MBytes  16.7 Mbits/sec    0    457 KBytes
[  4]   4.00-5.00   sec  2.55 MBytes  21.4 Mbits/sec    0    557 KBytes
[  4]   5.00-6.00   sec  3.04 MBytes  25.5 Mbits/sec    0    680 KBytes
[  4]   6.00-7.00   sec  1.68 MBytes  14.1 Mbits/sec    0    768 KBytes
[  4]   7.00-8.00   sec  2.36 MBytes  19.8 Mbits/sec    0    889 KBytes
[  4]   8.00-9.00   sec  1.68 MBytes  14.1 Mbits/sec    0    979 KBytes
[  4]   9.00-10.00  sec  2.36 MBytes  19.8 Mbits/sec    0   1.08 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-10.00  sec  20.6 MBytes  17.3 Mbits/sec    0             sender
[  4]   0.00-10.00  sec  18.2 MBytes  15.2 Mbits/sec                  receiver

iperf Done.
```

>Question
Repeat this for the second UE. Submit screenshots. Explain the difference in the throughput (Explain how the RAN Slicing impact the throughput). Because of the way we assign NVS weight, the other slice's throughput should be roughly a half of the throughput you obtained from the procedure above. Because of the NVS , the second UE get roughly half the PRBs of the first slice above. 


### Core Slicing Verification

#### Verification Technique 1
You could watch the UPF and the SMF logs in realtime. You should first attach one UE to the base station, and then verify that only SMF1 and UPF1 got the registration request. Repeat similarly for UE2. 

#### Verification Technique 2
Ping from ext-dn to UE1 and UE2 in turn, and watch the datapath. You should see something similar to this:
```
PeterYao@node:~$ tshark -T fields -e frame.number -e _ws.col.Source -e _ws.col.Destination -e eth.src -e eth.dst -e _ws.col.Protocol -e ip.len  -e _ws.col.Info -r ~/ue1-ext-dn.pcap 'icmp'
630     192.168.70.135  12.1.1.130      02:42:c0:a8:46:87       02:42:c0:a8:46:86       ICMP    84       Echo (ping) request  id=0x6fba, seq=1/256, ttl=64
631     192.168.70.135  12.1.1.130      02:42:c0:a8:46:86       02:42:b2:72:b1:b7       GTP <ICMP>       128,84  Echo (ping) request  id=0x6fba, seq=1/256, ttl=63
632     12.1.1.130      192.168.70.135  02:42:b2:72:b1:b7       02:42:c0:a8:46:86       GTP <ICMP>       128,84  Echo (ping) reply    id=0x6fba, seq=1/256, ttl=64 (request in 631)
633     12.1.1.130      192.168.70.135  02:42:c0:a8:46:86       02:42:c0:a8:46:87       ICMP    84       Echo (ping) reply    id=0x6fba, seq=1/256, ttl=63 (request in 630)
PeterYao@node:~$ tshark -T fields -e frame.number -e _ws.col.Source -e _ws.col.Destination -e eth.src -e eth.dst -e _ws.col.Protocol -e ip.len  -e _ws.col.Info -r ~/ue2-ext-dn.pcap 'icmp'
126     192.168.70.135  12.1.1.66       02:42:c0:a8:46:87       02:42:c0:a8:46:8c       ICMP    84       Echo (ping) request  id=0x0d60, seq=1/256, ttl=64
127     192.168.70.135  12.1.1.66       02:42:c0:a8:46:8c       02:42:b2:72:b1:b7       GTP <ICMP>       128,84  Echo (ping) request  id=0x0d60, seq=1/256, ttl=63
128     12.1.1.66       192.168.70.135  02:42:b2:72:b1:b7       02:42:c0:a8:46:8c       GTP <ICMP>       128,84  Echo (ping) reply    id=0x0d60, seq=1/256, ttl=64 (request in 127)
129     12.1.1.66       192.168.70.135  02:42:c0:a8:46:8c       02:42:c0:a8:46:87       ICMP    84       Echo (ping) reply    id=0x0d60, seq=1/256, ttl=63 (request in 126)
```

You should grep the MAC Addresses of the ext-dn, UPF1, UPF2 and the oai gnb. 

```bash
# for extdn
sudo docker exec -it oai-ext-dn ip addr
# for UPF1, in the UE1 SSH session
sudo docker exec -it oai-upf-slice1 ip addr
# for UPF2, in the UE2 SSH session
sudo docker exec -it oai-upf-slice2 ip addr
# for the gnb
ip addr list demo-oai
```

And you should be able to verify that they go through different datapaths, accoding to how the slice is configured. 

For example, when you run the sudo docker exec -it oai-upf-slice1 ip addr  command, you should see something like this:
```
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 500
    link/none
    inet 12.1.1.129/25 scope global tun0
       valid_lft forever preferred_lft forever
1037: eth0@if1038: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:a8:46:86 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.70.134/26 brd 192.168.70.191 scope global eth0
       valid_lft forever preferred_lft forever

```

And here, 02:42:c0:a8:46:86 brd ff:ff:ff:ff:ff:ff is your MAC address. 


> Question
Look into the conf files and docker compose files that you copied into the core network folder, and explain how the core network is setup in the way as depicted in the picture? [This tutorial](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/CONFIGURATION.md) may help you understand the different parameters.

>Question 
Repeat those verification steps on your own machine (the second appraoch), and submit screenshots of ping path, and MAC addresses of different interfaces. Make sure that it is as you would expect. 

### Slice Setup Troubleshooting and Dimisyfied
I want to give you some important hints and troubleshooting guide of setting up this slicing in an end to end fashion. 

#### The slice information should really match up
That means the sst/sd number in UE and gnb and the core setup should match exaclty. If one of them does not match, then a PDU session setup request will be rejected. 

For example in the UE, we talked about having the right sst/sd in the configuration file:
```
uicc0 = {
imsi = "208950000000032";
key = "0C0A34601D4F07677303652C0462535B";
opc= "63bfa50ee6523365ff14c1f45f88737d";
dnn= "oai.ipv4";
nssai_sst=1;
nssai_sd=5;
}

@include "channelmod_rfsimu.conf"
```
Similarly in the gnb configraution, it is important that the slice info matches up. 

```
    plmn_list = ({
                  mcc = 208;
                  mnc = 95;
                  mnc_length = 2;
                  snssaiList = (
                    {
                      sst = 1;
                      sd  = 0x1; // 0 false, else true
                    },
                    {
                      sst = 1;
                      sd  = 0x112233; // 0 false, else true
                    },
                    {
                      sst = 1;
                      sd  = 0x5;                                                                                                         }
                  );

                  });
```

We can see in the PLMN list, it has sst1sd1 and sst1sd5 slices, which are the 2 slices that we use.  

Also in the core network, it should also have these slice information. 

For example, in the AMF config, we have all those slice info:
```
snssais:
  - &embb_slice1
    sst: 1
  - &embb_slice2
    sst: 1
    sd: 000001 # in hex
  - &custom_slice
    sst: 222
    sd: 00007B # in hex
  - &new_slice
    sst: 1
    sd: 000005 # in hex

############## NF-specific configuration
amf:
  amf_name: "OAI-AMF"
  # This really depends on if we want to keep the "mini" version or not
  support_features_options:
    enable_simple_scenario: no # "no" by default with the normal deployment scenarios with AMF/SMF/UPF/AUSF/UDM/UDR/NRF.
                               # set it to "yes" to use with the minimalist deployment scenario (including only AMF/SMF/UPF) by using the internal AUSF/UDM implemented inside AMF.
                               # There's no NRF in this scenario, SMF info is taken from "nfs" section.
    enable_nssf: no
    enable_smf_selection: yes
  relative_capacity: 30
  statistics_timer_interval: 20  # in seconds
  emergency_support: false
  served_guami_list:
    - mcc: 208
      mnc: 95
      amf_region_id: 01
      amf_set_id: 001
      amf_pointer: 01
    - mcc: 001
      mnc: 01
      amf_region_id: 01
      amf_set_id: 001
      amf_pointer: 01
  plmn_support_list:
    - mcc: 208
      mnc: 95
      tac: 0xa000
      nssai:
        - *embb_slice1
        - *embb_slice2
        - *custom_slice
        - *new_slice
  supported_integrity_algorithms:
    - "NIA0"
    - "NIA1"
    - "NIA2"
  supported_encryption_algorithms:
    - "NEA0"
    - "NEA1"
    - "NEA2"

```

You can see we use embb_slice1 and new_slice here. 
Otherwise, the UE will be rejected upon connecting to AMF, because AMF is not configured with the slice info. 

You should also see the slice info in the SMF, the SMF will tell the AMF which slice it can handle. We have 2 SMFs, so each one of them is responsible for one slice. 

```
smf:
  ue_mtu: 1500
  support_features:
    use_local_subscription_info: yes # Use infos from local_subscription_info or from UDM
    use_local_pcc_rules: yes # Use infos from local_pcc_rules or from PCF
  # we resolve from NRF, this is just to configure usage_reporting
  upfs:
    - host: oai-upf-slice1
      config:
        enable_usage_reporting: no
  ue_dns:
    primary_ipv4: "172.21.3.100"
    primary_ipv6: "2001:4860:4860::8888"
    secondary_ipv4: "8.8.8.8"
    secondary_ipv6: "2001:4860:4860::8888"
  ims:
    pcscf_ipv4: "127.0.0.1"
    pcscf_ipv6: "fe80::7915:f408:1787:db8b"
  # the DNN you configure here should be configured in "dnns"
  # follows the SmfInfo datatype from 3GPP TS 29.510
  smf_info:
    sNssaiSmfInfoList:
      - sNssai: *embb_slice2
        dnnSmfInfoList:
          - dnn: "oai"
  local_subscription_infos:
    - single_nssai: *embb_slice2
      dnn: "oai"
      qos_profile:
        5qi: 9
        session_ambr_ul: "100Mbps"
        session_ambr_dl: "200Mbps"
```
For example, this SMF is responsible for embb_slice2, and it also has a UPF under its control. 

#### Different DNNs
As we can see in the SMF setup above, and the UPF below, they are connected to the data network called oai. 

```
upf:
  support_features:
    enable_bpf_datapath: no    # If "on": BPF is used as datapath else simpleswitch is used, DEFAULT= off
    enable_snat: yes           # If "on": Source natting is done for UE, DEFAULT= off
  remote_n6_gw: localhost      # Dummy host since simple-switch does not use N6 GW
  smfs:
    - host: oai-smf-slice1            # To be used for PFCP association in case of no-NRF
  upf_info:
    sNssaiUpfInfoList:
      - sNssai: *embb_slice2
        dnnUpfInfoList:
          - dnn: "oai"
```

Meanwhile, the other slice is connected to another data network:
oai.ipv4. 
```
upf:
  support_features:
    enable_bpf_datapath: no    # If "on": BPF is used as datapath else simpleswitch is used, DEFAULT= off
    enable_snat: yes           # If "on": Source natting is done for UE, DEFAULT= off
  remote_n6_gw: localhost      # Dummy host since simple-switch does not use N6 GW
  smfs:
    - host: oai-smf-slice2            # To be used for PFCP association in case of no-NRF
  upf_info:
    sNssaiUpfInfoList:
      - sNssai: *new_slice
        dnnUpfInfoList:
          - dnn: "oai.ipv4"
```

Each of these dnn has a different subnet address range configured. 

```
dnns:
  - dnn: "oai"
    pdu_session_type: "IPV4"
    ipv4_subnet: "12.1.1.128/25"
  - dnn: "oai.ipv4"
    pdu_session_type: "IPV4"
    ipv4_subnet: "12.1.1.64/26"
  - dnn: "default"
    pdu_session_type: "IPV4"
    ipv4_subnet: "12.1.1.0/26"
  - dnn: "ims"
    pdu_session_type: "IPV4V6"
    ipv4_subnet: "14.1.1.2/24"
```

The UE is allocated IP according to the address range of this DNN. 

And if we ping from the ext-dn docker container to these UEs, we will use these rules to make sure that the packet go through the right UPFs. 
```
        entrypoint: /bin/bash -c \
              "ip route add 12.1.1.128/25 via 192.168.70.134 dev eth0;"\
              "ip route add 12.1.1.64/26 via 192.168.70.140 dev eth0; ip route; sleep infinity"
```

So traffic to DNN oai is going through ine UPF (the 192.168.70.134 is address for one UPF). And traffic to DNN oai.ipv4 is going through another UPF. 

#### AMF and SMF information exchange

Looking into the log help us have a deeper understanding of the UE setup process in a specific slice. 

Here the AMF first received a PDU setup request from UE with slice sst1sd1. 
```
[2024-07-22 04:56:27.260] [amf_n2] [info] Received PDU Session Resource Setup Request message, handling
[2024-07-22 04:56:27.260] [amf_n2] [debug] Handle PDU Session Resource Setup Request ...
[2024-07-22 04:56:27.260] [amf_n2] [debug] SUPI (imsi-208950000000031)
[2024-07-22 04:56:27.260] [amf_n2] [debug] S_NSSAI (SST, SD) 1, 1
InitiatingMessage ::= {
    procedureCode: 29
    criticality: 0 (reject)
    value: PDUSessionResourceSetupRequest ::= {
        protocolIEs: ProtocolIE-Container ::= {
            PDUSessionResourceSetupRequestIEs ::= {
                id: 10
                criticality: 0 (reject)
                value: 4
            }
            PDUSessionResourceSetupRequestIEs ::= {
                id: 85
                criticality: 0 (reject)
                value: 2
            }
            PDUSessionResourceSetupRequestIEs ::= {
                id: 74
                criticality: 0 (reject)
                value: PDUSessionResourceSetupListSUReq ::= {
                    PDUSessionResourceSetupItemSUReq ::= {
                        pDUSessionID: 10
                        pDUSessionNAS-PDU:
                            7E 02 4D 10 BE CF 02 7E 00 68 01 00 57 2E 0A 01
                            C2 11 00 09 01 00 06 31 21 01 01 01 09 06 06 00
                            C8 06 00 64 29 05 01 0C 01 01 82 22 04 01 00 00
                            01 81 79 00 06 09 20 41 01 01 09 7B 00 0D 80 00
                            0D 04 AC 15 03 64 00 10 02 05 DC 25 17 03 6F 61
                            69 06 6D 6E 63 30 39 35 06 6D 63 63 32 30 38 04
                            67 70 72 73 12 0A
                        s-NSSAI: S-NSSAI ::= {
                            sST: 01
                            sD: 00 00 01
                        }
                        pDUSessionResourceSetupRequestTransfer:
                            00 00 04 00 82 00 0A 0C 0B EB C2 00 30 05 F5 E1
                            00 00 8B 00 0A 01 F0 C0 A8 46 86 00 00 00 02 00
                            86 00 01 00 00 88 00 07 00 09 00 00 09 00 00
                    }
                }
            }
            PDUSessionResourceSetupRequestIEs ::= {
                id: 110
                criticality: 1 (ignore)
                value: UEAggregateMaximumBitRate ::= {
                    uEAggregateMaximumBitRateDL: 1000000000
                    uEAggregateMaximumBitRateUL: 1000000000
                }
            }
        }
    }
}
```

There is slicing information that it get from the UE. 

Then it relay the message to the corresponding SMF repsonsible for this slice:

```
[2024-07-22 04:56:27.382] [smf_app] [debug] Session procedure type: PDU_SESSION_ESTABLISHMENT_UE_REQUESTED
[2024-07-22 04:56:27.382] [smf_app] [debug] QoS Flow context to be modified QFI 9
[2024-07-22 04:56:27.382] [smf_app] [debug] AN F-TEID ID 0xd5fde091, IP Addr 192.168.70.129
[2024-07-22 04:56:27.382] [smf_app] [debug] QoS Flow, QFI 9
[2024-07-22 04:56:27.382] [smf_app] [warning] Could not get DL FTEID from PDR in DL
[2024-07-22 04:56:27.382] [smf_app] [debug] Could not get local_up_fteid from created_pdr
[2024-07-22 04:56:27.382] [smf_app] [debug] UPF graph in SMF finished
[2024-07-22 04:56:27.382] [smf_app] [info] PDU Session Establishment Request (UE-Initiated)
[2024-07-22 04:56:27.382] [smf_app] [info] Set PDU Session Status to PDU_SESSION_ACTIVE
[2024-07-22 04:56:27.382] [smf_app] [info] Set upCnxState to UPCNX_STATE_ACTIVATED
[2024-07-22 04:56:27.382] [smf_app] [info] SMF context:

SMF CONTEXT:
SUPI:                           208950000000031
PDU SESSION:
        PDU Session ID:                 10
        DNN:                    oai
        S-NSSAI:                        SST=1, SD=1
        PDN type:               IPV4
        PAA IPv4:               12.1.1.130
        Default QFI:            9
        SEID:                   5
        N3:
                QoS Flow:
                        QFI:            9
                        UL FTEID:       TEID=2, IPv4=192.168.70.134
                        DL FTEID:       TEID=3590185105, IPv4=192.168.70.129
                        PDR ID UL:      1
                        PDR ID DL:      2
                        Precedence:     0
                        FAR ID UL:      1
                        FAR ID DL:      2


[2024-07-22 04:56:27.382] [smf_app] [debug] Send request to N11 to triger FlexCN, SMF Context ID 0x2
[2024-07-22 04:56:27.382] [smf_app] [debug] Get PDU Session information related to SMF Context ID 0x2
[2024-07-22 04:56:27.382] [smf_app] [debug] Get PDU Session information related to SMF Context ID 0x2
[2024-07-22 04:56:27.382] [smf_app] [info] Find PDU Session with ID 10
[2024-07-22 04:56:27.382] [smf_app] [info] Find PDU Session with ID 10
[2024-07-22 04:56:27.382] [smf_app] [debug] Send request to N11 to triger FlexCN (Event Exposure), SUPI 208950000000031 , PDU Session ID 10, HTTP version 1
[2024-07-22 04:56:27.382] [smf_app] [debug] No subscription available for this event
[2024-07-22 04:56:27.382] [smf_app] [debug] Send request to N11 to triger FlexCN, SMF Context ID 0x2
[2024-07-22 04:56:27.382] [smf_app] [debug] Get PDU Session information related to SMF Context ID 0x2
[2024-07-22 04:56:27.382] [smf_app] [info] Find PDU Session with ID 10
```

Above is the log from SMF for sst1sd1 slice. It received the PDU request relayed by AMF, which also contians the slice info from UE, and a PDU session is created. 


### Final recap for end-to-end slicing
First we did the core slicing, then we brought up the gnb and attach 2 UEs to it. Then we bring in the xapp to enforce slicing. Finally you will have slicing at both the RAN MAC layer and the core layer. 

## References:
[1] Robert Schmidt, Mikel Irazabal, and Navid Nikaein. 2021. FlexRIC: an SDK for next-generation SD-RANs. In Proceedings of the 17th International Conference on emerging Networking EXperiments and Technologies (CoNEXT '21). Association for Computing Machinery, New York, NY, USA, 411–425. https://doi.org/10.1145/3485983.3494870

[2] R. Kokku, R. Mahindra, H. Zhang and S. Rangarajan, "NVS: A Substrate for Virtualizing Wireless Resources in Cellular Networks," in IEEE/ACM Transactions on Networking, vol. 20, no. 5, pp. 1333-1346, Oct. 2012, doi: 10.1109/TNET.2011.2179063. keywords: {Base stations;Resource management;Bandwidth;WiMAX;Quality of service;Downlink;Cellular networks;flow scheduling;network slicing;programmability;spectrum sharing;virtualization;wireless resource management},
