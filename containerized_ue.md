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

during the 