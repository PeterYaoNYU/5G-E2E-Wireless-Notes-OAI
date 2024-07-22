I am investigating how to imporce the e2e latency here. 
We have verified that separating the core from the gnb and the UE does not help with the throughput. 

TODO:
- [x] paired radio cable
- [x] OTA experiment
- [ ] use VNC to verify modulation and noise. 
- [ ] docker container. 

### Docker container. 
It has been observed previously that running the docker container's version of gnb and UE results in much lower latency. 

It remains to be verified what is the cause:
- [x] We could run an iperf test and check if the throughput shows the same thing. 

- [ ] We could investigate whether the gnb script is the same for the container version and the non-docker version

- [ ] though very unlikely, we can investigate the docker network setup and see if it is the cause. One appraoch might be moving to an ordinary docker network instead of using the slicing configuration. 

- [ ] We could also build the image ourselves, and see if we can reproduce the latency. 

- [x] Does it actually go through the UPF?

- [ ] Or maybe it is because of the UE configuration?


#### We could run an iperf test and check if the throughput shows the same thing. 

I can see that the thp is also very high for the docker setup. I really begin to wonder whether it really go through the UPF.
```
root@4984842df64f:/tmp# iperf3 -c 12.1.1.130
Connecting to host 12.1.1.130, port 5201
[  5] local 192.168.70.145 port 53554 connected to 12.1.1.130 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec  4.23 MBytes  35.4 Mbits/sec    0    230 KBytes
[  5]   1.00-2.00   sec  7.64 MBytes  64.1 Mbits/sec    0    539 KBytes
[  5]   2.00-3.00   sec  8.61 MBytes  72.2 Mbits/sec    0    952 KBytes
[  5]   3.00-4.00   sec  7.50 MBytes  62.9 Mbits/sec    2   1012 KBytes
[  5]   4.00-5.00   sec  8.75 MBytes  73.4 Mbits/sec    4   1018 KBytes
[  5]   5.00-6.00   sec  7.50 MBytes  62.9 Mbits/sec    0   1024 KBytes
[  5]   6.00-7.00   sec  8.75 MBytes  73.4 Mbits/sec    0   1.01 MBytes
[  5]   7.00-8.00   sec  8.75 MBytes  73.3 Mbits/sec    0   1.02 MBytes
[  5]   8.00-9.00   sec  7.50 MBytes  63.0 Mbits/sec    0   1.05 MBytes
[  5]   9.00-10.00  sec  7.50 MBytes  62.9 Mbits/sec    0   1.09 MBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  76.7 MBytes  64.4 Mbits/sec    6
sender
[  5]   0.00-10.15  sec  75.2 MBytes  62.1 Mbits/sec
receiver

iperf Done.

```

I begin to wonder if it really goes through the UPF. The latency seems longer than not going through the UPF, but a magnitude smaller than actually going through the UPF and RF sim.  I want to verify with the wireshark.

#### Does it actually go through the UPF/gNB?

The high thp and low latency makes me wonder if the UPF is really a part of the process. Did we go through the gnb, or are we just pinging?

The result shows that indeed, gnb and UPF is on the route. 

I ping from the bash window of the ext-dn container, and I observe the following:

***Note*** I am running the docker compose at this [link](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/DEPLOY_SA5G_SLICING.md), which is the original slicing one. 

```bash
# from the ext dn container
root@4984842df64f:/tmp# ping 12.1.1.130 -c 1
PING 12.1.1.130 (12.1.1.130) 56(84) bytes of data.
64 bytes from 12.1.1.130: icmp_seq=1 ttl=63 time=9.67 ms

--- 12.1.1.130 ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 9.673/9.673/9.673/0.000 ms

# capture with the command:
 sudo tcpdump -i demo-oai -f "not arp and not port 53 and not host archive.ubuntu.com and not host security.ubuntu.com" -w ~/docker-verify.pcap

# tshark the captured packets:
PeterYao@node:~$ tshark -T fields -e frame.number -e _ws.col.Source -e _ws.col.Destination -e eth.src -e eth.dst -e _ws.col.Protocol -e ip.len  -e _ws.col.Info -r ~/docker-verify.pcap 'icmp'
20376   192.168.70.145  12.1.1.130      02:42:c0:a8:46:91       02:42:c0:a8:46:8f       ICMP    84      Echo (ping) request  id=0x5c57, seq=1/256, ttl=64
20377   192.168.70.145  12.1.1.130      02:42:c0:a8:46:8f       02:42:c0:a8:46:99       GTP <ICMP>      128,84  Echo (ping) request  id=0x5c57, seq=1/256, ttl=63
20607   12.1.1.130      192.168.70.145  02:42:c0:a8:46:99       02:42:c0:a8:46:8f       GTP <ICMP>      128,84  Echo (ping) reply    id=0x5c57, seq=1/256, ttl=64 (request in 20377)
20608   12.1.1.130      192.168.70.145  02:42:c0:a8:46:8f       02:42:c0:a8:46:91       ICMP    84      Echo (ping) reply    id=0x5c57, seq=1/256, ttl=63 (request in 20376)
```

And you can verify that it went through the correct NFs and everything.

```
PeterYao@node:~/.cache$ sudo docker network inspect demo-oai-public-net
[
    {
        "Name": "demo-oai-public-net",
        "Id": "c2f316707e7f02218f7df3bb6d2e5ec0cd98fac80abc8208c10a47354559caf0",
        "Created": "2024-07-19T11:55:56.771853088-06:00",
        "Scope": "local",
        "Driver": "bridge",
        "EnableIPv6": false,
        "IPAM": {
            "Driver": "default",
            "Options": null,
            "Config": [
                {
                    "Subnet": "192.168.70.0/24"
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
            "10240115b27e5014504637140b01ceb116b12cbafa1bdcc83df55d38af88cc25": {
                "Name": "oai-upf-slice1",
                "EndpointID": "2b25c9a9c76ff88bc05e7dc5fdf7aceeb02f446814f3182438f57be94c103045",
                "MacAddress": "02:42:c0:a8:46:8e",
                "IPv4Address": "192.168.70.142/24",
                "IPv6Address": ""
            },
            "455ca8356dbf85a8a7f6a7eba5711c2b0d4869a77a268bc5f5efead83864f246": {
                "Name": "oai-upf-slice2",
                "EndpointID": "6a151e490da4037e48a88e8d87090c676962a29ed22a5388316a59f881926c51",
                "MacAddress": "02:42:c0:a8:46:8f",
                "IPv4Address": "192.168.70.143/24",
                "IPv6Address": ""
            },
            "4984842df64f9e9f8c507e834b965c592b88fc8ef77074faa5262bd75a439915": {
                "Name": "oai-ext-dn",
                "EndpointID": "104d6c94427fc378d70bab9900aa129fb670b2aa43daf1f1f7a8ac383f5735b8",
                "MacAddress": "02:42:c0:a8:46:91",
                "IPv4Address": "192.168.70.145/24",
                "IPv6Address": ""
            },
            "545cea33372ff1e84285b27ce13354a4944874222a2ca4e933f05457180515de": {
                "Name": "oai-smf-slice2",
                "EndpointID": "3c8b3b3936694f2a666a94bb516ebc9d68074a3601fce8b022e050c4c63826dc",
                "MacAddress": "02:42:c0:a8:46:8c",
                "IPv4Address": "192.168.70.140/24",
                "IPv6Address": ""
            },
            "581faa85085ebe9e3b1b19de257cd2311376ca639def22a657ee946b52573d7e": {
                "Name": "vpp-upf-slice3",
                "EndpointID": "f73c2cb55322a2884e16f0bd1760f0177eb74f964107ee144bedb09f5eb0f019",
                "MacAddress": "02:42:c0:a8:46:90",
                "IPv4Address": "192.168.70.144/24",
                "IPv6Address": ""
            },
            "7f300e8042bca511bbf241f2ecb15e9f47dad39a21c2ae34405291c3cd506fa3": {
                "Name": "oai-amf",
                "EndpointID": "1c9e1ddae8fd155190315722f854021538234e80a5355f1be7ecbebafd17831a",
                "MacAddress": "02:42:c0:a8:46:8a",
                "IPv4Address": "192.168.70.138/24",
                "IPv6Address": ""
            },
            "87b4457c3eb188346f42522c772e2023949af9b181e996655a7c35f216368aa7": {
                "Name": "rfsim5g-oai-gnb",
                "EndpointID": "891bad0c7712d8799e9e33ec3885358abdb457d82c462aec47e0fc5b53fe7765",
                "MacAddress": "02:42:c0:a8:46:99",
                "IPv4Address": "192.168.70.153/24",
                "IPv6Address": ""
            },
            "a9fa966cb6cb15e9358419413e7100bc0964bf7c9de3a1146f38156c381bdf58": {
                "Name": "oai-smf-slice1",
                "EndpointID": "aebd2a6325b3a1a163227bdfda69fcade34702b693b634bc771e6cb403f9e033",
                "MacAddress": "02:42:c0:a8:46:8b",
                "IPv4Address": "192.168.70.139/24",
                "IPv6Address": ""
            },
            "ae1a076d0314d135ce95def8e2f66121fea106fc32dc2e099be9d305480ddd98": {
                "Name": "mysql",
                "EndpointID": "b8acc6ee782391d3250cd57450275241fa77a809a16eedecf140b2c194ff82f1",
                "MacAddress": "02:42:c0:a8:46:83",
                "IPv4Address": "192.168.70.131/24",
                "IPv6Address": ""
            },
            "ba3527ab9da84148ea627e994634cade55f55d0a938e2618236e84ea17cce2ee": {
                "Name": "oai-ausf",
                "EndpointID": "f276cceed0a42584131a2971bec28ed6b0d5b9d26bea6d7a8f045952944ba6cd",
                "MacAddress": "02:42:c0:a8:46:87",
                "IPv4Address": "192.168.70.135/24",
                "IPv6Address": ""
            },
            "c05c1e283ddc2c1c1f90e9ad4753f700f9851e00bf9295169506026fd38ef3b9": {
                "Name": "oai-udm",
                "EndpointID": "6f1f4d438d8fbf7f59fcc721f7acd96f7d5430d8cd0c0d1ac82795414de428fb",
                "MacAddress": "02:42:c0:a8:46:86",
                "IPv4Address": "192.168.70.134/24",
                "IPv6Address": ""
            },
            "c3f2b66687642e8d63023fc95f484b65258643d2ae8c3f0efab1c7e605f8f684": {
                "Name": "oai-nrf-slice3",
                "EndpointID": "ce2df9da8b38ac65b1bbf8c60e4173f753ce628fa918c07903e5f1f6ce249749",
                "MacAddress": "02:42:c0:a8:46:89",
                "IPv4Address": "192.168.70.137/24",
                "IPv6Address": ""
            },
            "cfa594c304d20ddd1cb322970016fcf1043e11786bb3929ad68417e899a79c89": {
                "Name": "rfsim5g-oai-nr-ue1",
                "EndpointID": "ae7689bf147ebbf687a1f286110f15d0ab70aa1e0a73c5650f525aebdd609f24",
                "MacAddress": "02:42:c0:a8:46:9a",
                "IPv4Address": "192.168.70.154/24",
                "IPv6Address": ""
            },
            "d3c68b81a03cae7ed7b934fa17a3e721b35259288f84c5a056f85aea30f92e2e": {
                "Name": "oai-nrf-slice12",
                "EndpointID": "569864ed406409ad1ad7782750fc8a0b77334a2dfe02414b58e3d824dde8c378",
                "MacAddress": "02:42:c0:a8:46:88",
                "IPv4Address": "192.168.70.136/24",
                "IPv6Address": ""
            },
            "db0df10662803141bee07611cf0d517ecbb18916213c9caf5e873219ffaf1cf4": {
                "Name": "oai-smf-slice3",
                "EndpointID": "5343ff078a83c07531ca3b7482787a413e01671562d33b3f15f404ea73af4a44",
                "MacAddress": "02:42:c0:a8:46:8d",
                "IPv4Address": "192.168.70.141/24",
                "IPv6Address": ""
            },
            "dca5bae6ddae3ac3f2ae80d3aed461ad9772550ca379df9e472402957ee0336b": {
                "Name": "oai-nssf",
                "EndpointID": "9bbb2ed7828b3fb5e35c22240ddf94967f04d7fe8370d76d81b0958bfa366674",
                "MacAddress": "02:42:c0:a8:46:84",
                "IPv4Address": "192.168.70.132/24",
                "IPv6Address": ""
            },
            "fde8fe510ae84785db48a6122b89bbd11189150e26257c554940466ee6434bac": {
                "Name": "oai-udr",
                "EndpointID": "235858c7ff359f958eee8605345207ddacfe7cd67cfb82bec7e3fab77c92c94b",
                "MacAddress": "02:42:c0:a8:46:85",
                "IPv4Address": "192.168.70.133/24",
                "IPv6Address": ""
            }
        },
        "Options": {
            "com.docker.network.bridge.name": "demo-oai"
        },
        "Labels": {
            "com.docker.compose.network": "demo-oai-public-net",
            "com.docker.compose.project": "docker-compose",
            "com.docker.compose.version": "1.29.2"
        }
    }
]
```


### Is it because of the gnb configuration and/or the UE configuration. 

I first copy down the gnbconfiguration from the docker container to the host, and then change the necessary info like slicing, amf address, and network binding. 

Then I get the following latency data with the original nondocker UE with old UE conf and the non docker gnb with the docker gnb conf. 

```
PeterYao@node:~$ sudo docker exec -it oai-ext-dn ping -c 20 12.1.1.130
PING 12.1.1.130 (12.1.1.130) 56(84) bytes of data.
64 bytes from 12.1.1.130: icmp_seq=1 ttl=63 time=36.5 ms
64 bytes from 12.1.1.130: icmp_seq=2 ttl=63 time=24.9 ms
64 bytes from 12.1.1.130: icmp_seq=3 ttl=63 time=18.9 ms
64 bytes from 12.1.1.130: icmp_seq=4 ttl=63 time=45.9 ms
64 bytes from 12.1.1.130: icmp_seq=5 ttl=63 time=32.2 ms
64 bytes from 12.1.1.130: icmp_seq=6 ttl=63 time=23.0 ms
64 bytes from 12.1.1.130: icmp_seq=7 ttl=63 time=19.2 ms
64 bytes from 12.1.1.130: icmp_seq=8 ttl=63 time=34.5 ms
64 bytes from 12.1.1.130: icmp_seq=9 ttl=63 time=23.3 ms
64 bytes from 12.1.1.130: icmp_seq=10 ttl=63 time=43.4 ms
64 bytes from 12.1.1.130: icmp_seq=11 ttl=63 time=33.7 ms
64 bytes from 12.1.1.130: icmp_seq=12 ttl=63 time=30.6 ms
64 bytes from 12.1.1.130: icmp_seq=13 ttl=63 time=21.9 ms
64 bytes from 12.1.1.130: icmp_seq=14 ttl=63 time=42.2 ms
64 bytes from 12.1.1.130: icmp_seq=15 ttl=63 time=26.7 ms
64 bytes from 12.1.1.130: icmp_seq=16 ttl=63 time=43.6 ms
64 bytes from 12.1.1.130: icmp_seq=17 ttl=63 time=39.5 ms
64 bytes from 12.1.1.130: icmp_seq=18 ttl=63 time=22.7 ms
64 bytes from 12.1.1.130: icmp_seq=19 ttl=63 time=46.2 ms
64 bytes from 12.1.1.130: icmp_seq=20 ttl=63 time=34.9 ms

--- 12.1.1.130 ping statistics ---
20 packets transmitted, 20 received, 0% packet loss, time 19029ms
rtt min/avg/max/mdev = 18.855/32.187/46.157/8.997 ms
```

The average latency used to be 86ms, and now it is 32 ms!

I need to compare the 2 conf to figure out the cause of this drop in latency. But this is a magical configuration. 

In terms of thp, I did not see much of an imporve:
```
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-120.00 sec   337 MBytes  23.6 Mbits/sec  4462
 sender
[  5]   0.00-120.00 sec   336 MBytes  23.5 Mbits/sec
receiver

iperf Done.
```
I ran for 2 minutes with rfsimulation. 

### Change the UE configuration. 




## OTA Test
I test the latency and thp with an OTA setting. To see if the Thp is low because of the rf simulation. 

When running the gnb, the following error occurs:
```
[LIBCONFIG] loader.oai_device: 2/2 parameters successfully set, (1 to default value)
shlib_path liboai_device.so
[LOADER] library liboai_device.so successfully loaded
[HW]   openair0_cfg[0].sdr_addrs == 'type=x300'
[HW]   openair0_cfg[0].clock_source == '0' (internal = 0, external = 1)
[HW]   UHD version 4.7.0.0-0ubuntu1~jammy1 (4.7.0)
[HW]   Checking for USRP with args type=x300
[INFO] [UHD] linux; GNU C++ version 11.4.0; Boost_107400; UHD_4.7.0.0-0ubuntu1~jammy1
[HW]   Found USRP x300
Found USRP x300
net.core.rmem_max = 33554432
net.core.wmem_max = 33554432
[INFO] [X300] X300 initialization sequence...
terminate called after throwing an instance of 'uhd::runtime_error'
  what():  RuntimeError: Expected FPGA compatibility number 39.0, but got 38.0:
The FPGA image on your device is not compatible with this host code build.
Download the appropriate FPGA images for this version of UHD.
Please run:

 "/lib/x86_64-linux-gnu/uhd/utils/uhd_images_downloader.py"

Then burn a new image to the on-board flash storage of your
USRP X3xx device using the image loader utility. Use this command:

"/lib/bin/uhd_image_loader" --args="type=x300,addr=192.168.40.2"

For more information, refer to the UHD manual:

 http://files.ettus.com/manual/page_usrp_x3x0.html#x3x0_flash
Aborted
```

But the /lib/x86_64-linux-gnu/uhd/utils/uhd_images_downloader.py file does not exist. 

Per the instructions here: https://files.ettus.com/manual/page_usrp_x3x0.html#x3x0_load_fpga_imgs
```
PeterYao@ota-x310-2-gnb-comp:~$ sudo !!
sudo uhd_images_downloader
[INFO] Using base URL: https://files.ettus.com/binaries/cache/
[INFO] Images destination: /usr/share/uhd/images
[INFO] No inventory file found at /usr/share/uhd/images/inventory.json. Creating an empty one.
32160 kB / 32160 kB (100%) x4xx_x410_fpga_default-gc37b318.zip
53718 kB / 53718 kB (100%) x4xx_x440_fpga_default-g7acd179.zip
19672 kB / 19672 kB (100%) x3xx_x300_fpga_default-gc37b318.zip
21624 kB / 21624 kB (100%) x3xx_x310_fpga_default-gc37b318.zip
01123 kB / 01123 kB (100%) e3xx_e310_sg1_fpga_default-gc37b318.zip
01115 kB / 01115 kB (100%) e3xx_e310_sg3_fpga_default-gc37b318.zip
10212 kB / 10212 kB (100%) e3xx_e320_fpga_default-gc37b318.zip
14224 kB / 14224 kB (100%) n3xx_n300_fpga_default-gc37b318.zip
20864 kB / 20864 kB (100%) n3xx_n310_fpga_default-gc37b318.zip
27183 kB / 27183 kB (100%) n3xx_n320_fpga_default-gc37b318.zip
00479 kB / 00479 kB (100%) b2xx_b200_fpga_default-gc37b318.zip
00485 kB / 00485 kB (100%) b2xx_b200mini_fpga_default-gc37b318.zip
00870 kB / 00870 kB (100%) b2xx_b210_fpga_default-gc37b318.zip
00507 kB / 00507 kB (100%) b2xx_b205mini_fpga_default-gc37b318.zip
00167 kB / 00167 kB (100%) b2xx_common_fw_default-g7f7d016.zip
00007 kB / 00007 kB (100%) usrp2_usrp2_fw_default-g6bea23d.zip
00450 kB / 00450 kB (100%) usrp2_usrp2_fpga_default-g6bea23d.zip
02415 kB / 02415 kB (100%) usrp2_n200_fpga_default-g6bea23d.zip
00009 kB / 00009 kB (100%) usrp2_n200_fw_default-g6bea23d.zip
02757 kB / 02757 kB (100%) usrp2_n210_fpga_default-g6bea23d.zip
00009 kB / 00009 kB (100%) usrp2_n210_fw_default-g6bea23d.zip
00319 kB / 00319 kB (100%) usrp1_usrp1_fpga_default-g6bea23d.zip
00522 kB / 00522 kB (100%) usrp1_b100_fpga_default-g6bea23d.zip
00006 kB / 00006 kB (100%) usrp1_b100_fw_default-g6bea23d.zip
00009 kB / 00017 kB (050%) octoclock_octoclock_fw_default-g14000041.zi00017 kB / 00017 kB (100%) octoclock_octoclock_fw_default-g14000041.zip
04839 kB / 04839 kB (100%) usb_common_windrv_default-g14000041.zip
[INFO] Images download complete.
```

After burning the image to the USRP and reboot the antenna with:
```
 uhd_image_loader --args="type=x300,addr=192.168.40.2"
```
It can now be connected to the core network. 

It is amazing, we can now connect the UE to the core network and the gnb:

```

[2024-07-20T08:10:40.543591] [AMF] [amf_sbi] [info ] Get response with HTTP code (200)
[2024-07-20T08:10:40.543609] [AMF] [amf_sbi] [info ] Response body {"cause":255}
[2024-07-20T08:10:40.543615] [AMF] [amf_app] [debug] Parsing the message with Simple Parser
[2024-07-20T08:10:40.543622] [AMF] [amf_sbi] [info ] JSON part {"cause":255}
[2024-07-20T08:10:51.409319] [AMF] [amf_app] [info ]
[2024-07-20T08:10:51.409349] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-07-20T08:10:51.409355] [AMF] [amf_app] [info ] |----------------------------------------------------gNBs' information-------------------------------------------|
[2024-07-20T08:10:51.409361] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2024-07-20T08:10:51.409371] [AMF] [amf_app] [info ] |      1      |    Connected     |         0xe000       |         gNB-OAI        |            999, 99             |
[2024-07-20T08:10:51.409377] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-07-20T08:10:51.409382] [AMF] [amf_app] [info ]
[2024-07-20T08:10:51.409387] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-07-20T08:10:51.409391] [AMF] [amf_app] [info ] |----------------------------------------------------UEs' information--------------------------------------------|
[2024-07-20T08:10:51.409396] [AMF] [amf_app] [info ] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |Cell ID|
[2024-07-20T08:10:51.409406] [AMF] [amf_app] [info ] |      1|       5GMM-REGISTERED|   999990000000003|               |
    0|          8| 999, 99 |14680064|
[2024-07-20T08:10:51.409411] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-07-20T08:10:51.409415] [AMF] [amf_app] [info ]
```


### OTA Delay

It seems that with OTA, the delay is indeed smaller, pinging from UE to ext-dn
```
PeterYao@ota-nuc4-cots-ue:~$ ping 192.168.70.135 -c 60
PING 192.168.70.135 (192.168.70.135) 56(84) bytes of data.
64 bytes from 192.168.70.135: icmp_seq=1 ttl=63 time=11.7 ms
64 bytes from 192.168.70.135: icmp_seq=2 ttl=63 time=19.6 ms
64 bytes from 192.168.70.135: icmp_seq=3 ttl=63 time=17.6 ms
64 bytes from 192.168.70.135: icmp_seq=4 ttl=63 time=15.1 ms
64 bytes from 192.168.70.135: icmp_seq=5 ttl=63 time=12.7 ms
64 bytes from 192.168.70.135: icmp_seq=6 ttl=63 time=10.7 ms
64 bytes from 192.168.70.135: icmp_seq=7 ttl=63 time=18.1 ms
64 bytes from 192.168.70.135: icmp_seq=8 ttl=63 time=16.1 ms
64 bytes from 192.168.70.135: icmp_seq=9 ttl=63 time=14.6 ms
64 bytes from 192.168.70.135: icmp_seq=10 ttl=63 time=15.1 ms
64 bytes from 192.168.70.135: icmp_seq=11 ttl=63 time=20.2 ms
64 bytes from 192.168.70.135: icmp_seq=12 ttl=63 time=18.1 ms
64 bytes from 192.168.70.135: icmp_seq=13 ttl=63 time=16.2 ms
64 bytes from 192.168.70.135: icmp_seq=14 ttl=63 time=14.1 ms
64 bytes from 192.168.70.135: icmp_seq=15 ttl=63 time=12.6 ms
64 bytes from 192.168.70.135: icmp_seq=16 ttl=63 time=20.2 ms
64 bytes from 192.168.70.135: icmp_seq=17 ttl=63 time=18.1 ms
64 bytes from 192.168.70.135: icmp_seq=18 ttl=63 time=16.1 ms
64 bytes from 192.168.70.135: icmp_seq=19 ttl=63 time=14.1 ms
64 bytes from 192.168.70.135: icmp_seq=20 ttl=63 time=12.2 ms
64 bytes from 192.168.70.135: icmp_seq=22 ttl=63 time=13.6 ms
64 bytes from 192.168.70.135: icmp_seq=23 ttl=63 time=11.2 ms
64 bytes from 192.168.70.135: icmp_seq=24 ttl=63 time=19.2 ms
64 bytes from 192.168.70.135: icmp_seq=25 ttl=63 time=17.1 ms
64 bytes from 192.168.70.135: icmp_seq=26 ttl=63 time=15.1 ms
64 bytes from 192.168.70.135: icmp_seq=27 ttl=63 time=13.1 ms
64 bytes from 192.168.70.135: icmp_seq=28 ttl=63 time=11.6 ms
64 bytes from 192.168.70.135: icmp_seq=29 ttl=63 time=19.2 ms
64 bytes from 192.168.70.135: icmp_seq=30 ttl=63 time=17.1 ms
64 bytes from 192.168.70.135: icmp_seq=31 ttl=63 time=15.2 ms
64 bytes from 192.168.70.135: icmp_seq=32 ttl=63 time=13.1 ms
64 bytes from 192.168.70.135: icmp_seq=33 ttl=63 time=11.1 ms
64 bytes from 192.168.70.135: icmp_seq=34 ttl=63 time=19.7 ms
64 bytes from 192.168.70.135: icmp_seq=35 ttl=63 time=17.1 ms
64 bytes from 192.168.70.135: icmp_seq=36 ttl=63 time=15.1 ms
64 bytes from 192.168.70.135: icmp_seq=37 ttl=63 time=13.1 ms
64 bytes from 192.168.70.135: icmp_seq=38 ttl=63 time=11.1 ms
64 bytes from 192.168.70.135: icmp_seq=39 ttl=63 time=19.1 ms
64 bytes from 192.168.70.135: icmp_seq=40 ttl=63 time=17.2 ms
64 bytes from 192.168.70.135: icmp_seq=41 ttl=63 time=15.6 ms
64 bytes from 192.168.70.135: icmp_seq=43 ttl=63 time=17.4 ms
64 bytes from 192.168.70.135: icmp_seq=44 ttl=63 time=15.1 ms
64 bytes from 192.168.70.135: icmp_seq=45 ttl=63 time=13.2 ms
64 bytes from 192.168.70.135: icmp_seq=46 ttl=63 time=11.2 ms
64 bytes from 192.168.70.135: icmp_seq=47 ttl=63 time=19.7 ms
64 bytes from 192.168.70.135: icmp_seq=48 ttl=63 time=17.1 ms
64 bytes from 192.168.70.135: icmp_seq=49 ttl=63 time=15.1 ms
64 bytes from 192.168.70.135: icmp_seq=50 ttl=63 time=13.1 ms
64 bytes from 192.168.70.135: icmp_seq=51 ttl=63 time=10.8 ms
64 bytes from 192.168.70.135: icmp_seq=52 ttl=63 time=18.5 ms
64 bytes from 192.168.70.135: icmp_seq=53 ttl=63 time=16.2 ms
64 bytes from 192.168.70.135: icmp_seq=54 ttl=63 time=14.6 ms
64 bytes from 192.168.70.135: icmp_seq=55 ttl=63 time=12.1 ms
64 bytes from 192.168.70.135: icmp_seq=56 ttl=63 time=20.1 ms
64 bytes from 192.168.70.135: icmp_seq=57 ttl=63 time=18.2 ms
64 bytes from 192.168.70.135: icmp_seq=58 ttl=63 time=16.1 ms
64 bytes from 192.168.70.135: icmp_seq=59 ttl=63 time=14.1 ms
64 bytes from 192.168.70.135: icmp_seq=60 ttl=63 time=12.6 ms

--- 192.168.70.135 ping statistics ---
60 packets transmitted, 58 received, 3.33333% packet loss, time 59149ms
rtt min/avg/max/mdev = 10.666/15.400/20.228/2.807 ms
```


And I see similar delay from the ext-dn to the UE. 

```
PeterYao@cn5g-docker-host:~$ sudo docker exec -it oai-ext-dn ping 12.1.1.51 -c 50
PING 12.1.1.51 (12.1.1.51) 56(84) bytes of data.
64 bytes from 12.1.1.51: icmp_seq=1 ttl=63 time=17.4 ms
64 bytes from 12.1.1.51: icmp_seq=2 ttl=63 time=15.7 ms
64 bytes from 12.1.1.51: icmp_seq=3 ttl=63 time=13.9 ms
64 bytes from 12.1.1.51: icmp_seq=4 ttl=63 time=12.0 ms
64 bytes from 12.1.1.51: icmp_seq=5 ttl=63 time=10.8 ms
64 bytes from 12.1.1.51: icmp_seq=6 ttl=63 time=18.9 ms
64 bytes from 12.1.1.51: icmp_seq=7 ttl=63 time=18.0 ms
64 bytes from 12.1.1.51: icmp_seq=8 ttl=63 time=17.2 ms
64 bytes from 12.1.1.51: icmp_seq=9 ttl=63 time=15.8 ms
64 bytes from 12.1.1.51: icmp_seq=10 ttl=63 time=13.9 ms
64 bytes from 12.1.1.51: icmp_seq=11 ttl=63 time=11.8 ms
64 bytes from 12.1.1.51: icmp_seq=12 ttl=63 time=19.8 ms
64 bytes from 12.1.1.51: icmp_seq=15 ttl=63 time=19.1 ms
64 bytes from 12.1.1.51: icmp_seq=16 ttl=63 time=17.8 ms
64 bytes from 12.1.1.51: icmp_seq=17 ttl=63 time=15.9 ms
64 bytes from 12.1.1.51: icmp_seq=18 ttl=63 time=14.8 ms
64 bytes from 12.1.1.51: icmp_seq=19 ttl=63 time=13.0 ms
64 bytes from 12.1.1.51: icmp_seq=20 ttl=63 time=11.7 ms
64 bytes from 12.1.1.51: icmp_seq=21 ttl=63 time=20.0 ms
64 bytes from 12.1.1.51: icmp_seq=22 ttl=63 time=18.9 ms
64 bytes from 12.1.1.51: icmp_seq=23 ttl=63 time=16.9 ms
64 bytes from 12.1.1.51: icmp_seq=24 ttl=63 time=19.4 ms
64 bytes from 12.1.1.51: icmp_seq=25 ttl=63 time=13.4 ms
64 bytes from 12.1.1.51: icmp_seq=26 ttl=63 time=11.9 ms
64 bytes from 12.1.1.51: icmp_seq=27 ttl=63 time=19.7 ms
64 bytes from 12.1.1.51: icmp_seq=28 ttl=63 time=17.9 ms
64 bytes from 12.1.1.51: icmp_seq=29 ttl=63 time=15.9 ms
64 bytes from 12.1.1.51: icmp_seq=30 ttl=63 time=13.9 ms
64 bytes from 12.1.1.51: icmp_seq=31 ttl=63 time=12.8 ms
64 bytes from 12.1.1.51: icmp_seq=32 ttl=63 time=10.9 ms
64 bytes from 12.1.1.51: icmp_seq=33 ttl=63 time=18.9 ms
64 bytes from 12.1.1.51: icmp_seq=34 ttl=63 time=16.8 ms
64 bytes from 12.1.1.51: icmp_seq=35 ttl=63 time=14.9 ms
64 bytes from 12.1.1.51: icmp_seq=36 ttl=63 time=13.9 ms
64 bytes from 12.1.1.51: icmp_seq=37 ttl=63 time=11.9 ms
64 bytes from 12.1.1.51: icmp_seq=38 ttl=63 time=19.7 ms
64 bytes from 12.1.1.51: icmp_seq=39 ttl=63 time=17.9 ms
64 bytes from 12.1.1.51: icmp_seq=40 ttl=63 time=16.9 ms
64 bytes from 12.1.1.51: icmp_seq=41 ttl=63 time=14.9 ms
64 bytes from 12.1.1.51: icmp_seq=42 ttl=63 time=12.9 ms
64 bytes from 12.1.1.51: icmp_seq=43 ttl=63 time=11.0 ms
64 bytes from 12.1.1.51: icmp_seq=44 ttl=63 time=19.8 ms
64 bytes from 12.1.1.51: icmp_seq=45 ttl=63 time=17.9 ms
64 bytes from 12.1.1.51: icmp_seq=46 ttl=63 time=15.9 ms
64 bytes from 12.1.1.51: icmp_seq=47 ttl=63 time=15.0 ms
64 bytes from 12.1.1.51: icmp_seq=48 ttl=63 time=13.8 ms
64 bytes from 12.1.1.51: icmp_seq=49 ttl=63 time=11.9 ms
64 bytes from 12.1.1.51: icmp_seq=50 ttl=63 time=24.4 ms

--- 12.1.1.51 ping statistics ---
50 packets transmitted, 48 received, 4% packet loss, time 49108ms
rtt min/avg/max/mdev = 10.754/15.777/24.388/3.080 ms
```

### OAI Throughput
But the thp is small:
```
PeterYao@cn5g-docker-host:~$ sudo docker exec -it oai-ext-dn bash
root@80ebe4113592:/tmp# iperf3 -c 12.1.1.51
Connecting to host 12.1.1.51, port 5201
[  5] local 192.168.70.135 port 41318 connected to 12.1.1.51 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec   324 KBytes  2.65 Mbits/sec   16   5.66 KBytes
[  5]   1.00-2.00   sec   120 KBytes   984 Kbits/sec   14   2.83 KBytes
[  5]   2.00-3.00   sec   124 KBytes  1.02 Mbits/sec   13   2.83 KBytes
[  5]   3.00-4.00   sec   246 KBytes  2.02 Mbits/sec   11   5.66 KBytes
[  5]   4.00-5.00   sec   189 KBytes  1.55 Mbits/sec   14   1.41 KBytes
[  5]   5.00-6.00   sec   189 KBytes  1.55 Mbits/sec   11   4.24 KBytes
[  5]   6.00-7.00   sec   189 KBytes  1.55 Mbits/sec   10   8.48 KBytes
[  5]   7.00-8.00   sec   259 KBytes  2.12 Mbits/sec   10   9.90 KBytes
[  5]   8.00-9.00   sec   260 KBytes  2.13 Mbits/sec   16   7.07 KBytes
[  5]   9.00-10.00  sec   122 KBytes   996 Kbits/sec   11   1.41 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  1.98 MBytes  1.66 Mbits/sec  126             sender
[  5]   0.00-10.05  sec  1.89 MBytes  1.58 Mbits/sec                  receiver

iperf Done.
```


It looks weird, so I confirmed it again. It seems that the OTA has some bug, and iperf3 can only be run once before the UE need to be restarted. So I am not totally sure that this test makes sense:

```
root@e58920558c3b:/tmp# iperf3 -c 12.1.1.51
Connecting to host 12.1.1.51, port 5201
[  5] local 192.168.70.135 port 34758 connected to 12.1.1.51 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec   362 KBytes  2.96 Mbits/sec   16   4.24 KBytes
[  5]   1.00-2.00   sec   257 KBytes  2.11 Mbits/sec   11   4.24 KBytes
[  5]   2.00-3.00   sec   130 KBytes  1.07 Mbits/sec   11   4.24 KBytes
[  5]   3.00-4.00   sec   256 KBytes  2.10 Mbits/sec   11   4.24 KBytes
[  5]   4.00-5.00   sec   194 KBytes  1.59 Mbits/sec   10   7.07 KBytes
[  5]   5.00-6.00   sec   269 KBytes  2.20 Mbits/sec   10   4.24 KBytes
[  5]   6.00-7.00   sec   255 KBytes  2.09 Mbits/sec   11   4.24 KBytes
[  5]   7.00-8.00   sec   191 KBytes  1.56 Mbits/sec   15   4.24 KBytes
[  5]   8.00-9.00   sec   257 KBytes  2.11 Mbits/sec   13   7.07 KBytes
[  5]   9.00-10.00  sec   127 KBytes  1.04 Mbits/sec   14   2.83 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  2.24 MBytes  1.88 Mbits/sec  122             sender
[  5]   0.00-10.05  sec  2.16 MBytes  1.80 Mbits/sec                  receiver

iperf Done.
```

### Paired Radio Workbench Delay

ping from the UE to the external data network.
```
PeterYao@nrue-comp:~$ ping 192.168.70.135 -c 40
PING 192.168.70.135 (192.168.70.135) 56(84) bytes of data.
64 bytes from 192.168.70.135: icmp_seq=1 ttl=63 time=16.5 ms
64 bytes from 192.168.70.135: icmp_seq=2 ttl=63 time=15.0 ms
64 bytes from 192.168.70.135: icmp_seq=3 ttl=63 time=13.9 ms
64 bytes from 192.168.70.135: icmp_seq=4 ttl=63 time=12.0 ms
64 bytes from 192.168.70.135: icmp_seq=5 ttl=63 time=11.0 ms
64 bytes from 192.168.70.135: icmp_seq=6 ttl=63 time=9.90 ms
64 bytes from 192.168.70.135: icmp_seq=7 ttl=63 time=7.99 ms
64 bytes from 192.168.70.135: icmp_seq=8 ttl=63 time=16.9 ms
64 bytes from 192.168.70.135: icmp_seq=10 ttl=63 time=8.94 ms
64 bytes from 192.168.70.135: icmp_seq=11 ttl=63 time=17.0 ms
64 bytes from 192.168.70.135: icmp_seq=12 ttl=63 time=15.9 ms
64 bytes from 192.168.70.135: icmp_seq=13 ttl=63 time=14.9 ms
64 bytes from 192.168.70.135: icmp_seq=14 ttl=63 time=13.0 ms
64 bytes from 192.168.70.135: icmp_seq=15 ttl=63 time=11.9 ms
64 bytes from 192.168.70.135: icmp_seq=16 ttl=63 time=11.0 ms
64 bytes from 192.168.70.135: icmp_seq=17 ttl=63 time=8.99 ms
64 bytes from 192.168.70.135: icmp_seq=18 ttl=63 time=7.93 ms
64 bytes from 192.168.70.135: icmp_seq=19 ttl=63 time=17.0 ms
64 bytes from 192.168.70.135: icmp_seq=20 ttl=63 time=15.0 ms
64 bytes from 192.168.70.135: icmp_seq=21 ttl=63 time=13.9 ms
64 bytes from 192.168.70.135: icmp_seq=22 ttl=63 time=13.0 ms
64 bytes from 192.168.70.135: icmp_seq=23 ttl=63 time=11.0 ms
64 bytes from 192.168.70.135: icmp_seq=24 ttl=63 time=9.92 ms
64 bytes from 192.168.70.135: icmp_seq=25 ttl=63 time=8.98 ms
64 bytes from 192.168.70.135: icmp_seq=26 ttl=63 time=8.02 ms
64 bytes from 192.168.70.135: icmp_seq=27 ttl=63 time=16.9 ms
64 bytes from 192.168.70.135: icmp_seq=28 ttl=63 time=15.0 ms
64 bytes from 192.168.70.135: icmp_seq=29 ttl=63 time=14.0 ms
64 bytes from 192.168.70.135: icmp_seq=30 ttl=63 time=12.9 ms
64 bytes from 192.168.70.135: icmp_seq=31 ttl=63 time=11.0 ms
64 bytes from 192.168.70.135: icmp_seq=32 ttl=63 time=10.0 ms
64 bytes from 192.168.70.135: icmp_seq=33 ttl=63 time=8.93 ms
64 bytes from 192.168.70.135: icmp_seq=34 ttl=63 time=17.0 ms
64 bytes from 192.168.70.135: icmp_seq=35 ttl=63 time=16.0 ms
64 bytes from 192.168.70.135: icmp_seq=36 ttl=63 time=14.9 ms
64 bytes from 192.168.70.135: icmp_seq=37 ttl=63 time=13.0 ms
64 bytes from 192.168.70.135: icmp_seq=38 ttl=63 time=12.0 ms
64 bytes from 192.168.70.135: icmp_seq=39 ttl=63 time=10.9 ms
64 bytes from 192.168.70.135: icmp_seq=40 ttl=63 time=9.01 ms

--- 192.168.70.135 ping statistics ---
40 packets transmitted, 39 received, 2.5% packet loss, time 39056ms
rtt min/avg/max/mdev = 7.928/12.592/16.992/2.916 ms
```

Ping from the extdn to the UE. 

```
PeterYao@cn5g-docker-host:~$ sudo docker exec -it oai-ext-dn ping -c 10 12.1.1.151 -c 40
PING 12.1.1.151 (12.1.1.151) 56(84) bytes of data.
64 bytes from 12.1.1.151: icmp_seq=1 ttl=63 time=15.3 ms
64 bytes from 12.1.1.151: icmp_seq=2 ttl=63 time=13.9 ms
64 bytes from 12.1.1.151: icmp_seq=3 ttl=63 time=11.9 ms
64 bytes from 12.1.1.151: icmp_seq=4 ttl=63 time=9.82 ms
64 bytes from 12.1.1.151: icmp_seq=5 ttl=63 time=7.95 ms
64 bytes from 12.1.1.151: icmp_seq=6 ttl=63 time=6.88 ms
64 bytes from 12.1.1.151: icmp_seq=7 ttl=63 time=14.9 ms
64 bytes from 12.1.1.151: icmp_seq=8 ttl=63 time=12.8 ms
64 bytes from 12.1.1.151: icmp_seq=9 ttl=63 time=11.0 ms
64 bytes from 12.1.1.151: icmp_seq=10 ttl=63 time=9.91 ms
64 bytes from 12.1.1.151: icmp_seq=11 ttl=63 time=7.87 ms
64 bytes from 12.1.1.151: icmp_seq=12 ttl=63 time=15.9 ms
64 bytes from 12.1.1.151: icmp_seq=13 ttl=63 time=13.9 ms
64 bytes from 12.1.1.151: icmp_seq=14 ttl=63 time=11.9 ms
64 bytes from 12.1.1.151: icmp_seq=15 ttl=63 time=10.8 ms
64 bytes from 12.1.1.151: icmp_seq=16 ttl=63 time=8.92 ms
64 bytes from 12.1.1.151: icmp_seq=17 ttl=63 time=6.88 ms
64 bytes from 12.1.1.151: icmp_seq=18 ttl=63 time=14.9 ms
64 bytes from 12.1.1.151: icmp_seq=19 ttl=63 time=12.8 ms
64 bytes from 12.1.1.151: icmp_seq=20 ttl=63 time=11.0 ms
64 bytes from 12.1.1.151: icmp_seq=21 ttl=63 time=9.89 ms
64 bytes from 12.1.1.151: icmp_seq=22 ttl=63 time=7.84 ms
64 bytes from 12.1.1.151: icmp_seq=24 ttl=63 time=13.9 ms
64 bytes from 12.1.1.151: icmp_seq=25 ttl=63 time=11.9 ms
64 bytes from 12.1.1.151: icmp_seq=26 ttl=63 time=9.82 ms
64 bytes from 12.1.1.151: icmp_seq=27 ttl=63 time=7.99 ms
64 bytes from 12.1.1.151: icmp_seq=28 ttl=63 time=6.87 ms
64 bytes from 12.1.1.151: icmp_seq=29 ttl=63 time=14.8 ms
64 bytes from 12.1.1.151: icmp_seq=30 ttl=63 time=12.8 ms
64 bytes from 12.1.1.151: icmp_seq=31 ttl=63 time=11.0 ms
64 bytes from 12.1.1.151: icmp_seq=32 ttl=63 time=9.90 ms
64 bytes from 12.1.1.151: icmp_seq=33 ttl=63 time=7.74 ms
64 bytes from 12.1.1.151: icmp_seq=34 ttl=63 time=16.0 ms
64 bytes from 12.1.1.151: icmp_seq=35 ttl=63 time=14.9 ms
64 bytes from 12.1.1.151: icmp_seq=36 ttl=63 time=13.0 ms
64 bytes from 12.1.1.151: icmp_seq=37 ttl=63 time=11.8 ms
64 bytes from 12.1.1.151: icmp_seq=38 ttl=63 time=9.93 ms
64 bytes from 12.1.1.151: icmp_seq=39 ttl=63 time=8.84 ms
64 bytes from 12.1.1.151: icmp_seq=40 ttl=63 time=6.96 ms

--- 12.1.1.151 ping statistics ---
40 packets transmitted, 39 received, 2.5% packet loss, time 39069ms
rtt min/avg/max/mdev = 6.872/11.156/15.996/2.778 ms
```
Which is similar. 

### Paired Radio Workbench Delay
```
PeterYao@cn5g-docker-host:~$ sudo docker exec -it oai-ext-dn bash
root@05794244a25c:/tmp# iperf3 -c 12.1.1.151
Connecting to host 12.1.1.151, port 5201
[  5] local 192.168.70.135 port 33294 connected to 12.1.1.151 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec   619 KBytes  5.07 Mbits/sec   23   2.83 KBytes
[  5]   1.00-2.00   sec   413 KBytes  3.38 Mbits/sec   21   5.66 KBytes
[  5]   2.00-3.00   sec   249 KBytes  2.04 Mbits/sec   17   2.83 KBytes
[  5]   3.00-4.00   sec  86.3 KBytes   706 Kbits/sec    9   4.24 KBytes
[  5]   4.00-5.00   sec   436 KBytes  3.57 Mbits/sec   12   8.48 KBytes
[  5]   5.00-6.00   sec   684 KBytes  5.61 Mbits/sec   21   2.83 KBytes
[  5]   6.00-7.00   sec   368 KBytes  3.01 Mbits/sec   23   2.83 KBytes
[  5]   7.00-8.00   sec   434 KBytes  3.56 Mbits/sec   20   4.24 KBytes
[  5]   8.00-9.00   sec   215 KBytes  1.76 Mbits/sec   15   9.90 KBytes
[  5]   9.00-10.00  sec   366 KBytes  3.00 Mbits/sec   20   4.24 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  3.78 MBytes  3.17 Mbits/sec  181
sender
[  5]   0.00-10.04  sec  3.72 MBytes  3.11 Mbits/sec
receiver

iperf Done.
root@05794244a25c:/tmp# iperf3 -c 12.1.1.151
Connecting to host 12.1.1.151, port 5201
[  5] local 192.168.70.135 port 52978 connected to 12.1.1.151 port 5201
[ ID] Interval           Transfer     Bitrate         Retr  Cwnd
[  5]   0.00-1.00   sec   574 KBytes  4.70 Mbits/sec   27   7.07 KBytes
[  5]   1.00-2.00   sec   462 KBytes  3.79 Mbits/sec   22   2.83 KBytes
[  5]   2.00-3.00   sec   399 KBytes  3.27 Mbits/sec   17   7.07 KBytes
[  5]   3.00-4.00   sec   396 KBytes  3.24 Mbits/sec   18   2.83 KBytes
[  5]   4.00-5.00   sec   305 KBytes  2.50 Mbits/sec   21   5.66 KBytes
[  5]   5.00-6.00   sec   573 KBytes  4.69 Mbits/sec   20   5.66 KBytes
[  5]   6.00-7.00   sec   397 KBytes  3.25 Mbits/sec   15   9.90 KBytes
[  5]   7.00-8.00   sec   452 KBytes  3.71 Mbits/sec   23   2.83 KBytes
[  5]   8.00-9.00   sec   400 KBytes  3.28 Mbits/sec   21   1.41 KBytes
[  5]   9.00-10.00  sec   317 KBytes  2.59 Mbits/sec   15   7.07 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bitrate         Retr
[  5]   0.00-10.00  sec  4.18 MBytes  3.50 Mbits/sec  199
sender
[  5]   0.00-10.04  sec  4.05 MBytes  3.39 Mbits/sec
receiver

iperf Done.
```

thp slightly better than OTA, but worse than RF simulation. 

Makes me wonder what is the cause?

## Analysis

It seems that it is hardly a flaw on the CPU side. 

```
PeterYao@gnb-comp:~$ sudo numactl --membind=0 --cpubind=0   /var/tmp/oairan/cmake_targets/ran_build/build/nr-softmodem -E   -O /var/tmp/etc/oai/gnb.sa.band78.fr1.106PRB.usrpx310.conf --sa   --MACRLCs.[0].dl_max_mcs 28 --tune-offset 23040000
```

The dl_max_mcs parameter 28 caught my attention. Can we use that for the rfsim mode?
