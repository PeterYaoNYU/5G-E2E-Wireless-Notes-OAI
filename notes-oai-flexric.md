***[NOTE]*** the latest OAI removes Ubuntu 18 from the supported list. To continue using Ubuntu18 for reprodcution pirposes:
```bash
git checkout c599e172
```
Checkout the last release. 


The error message

```
nearRT-RIC: /users/PeterYao/flexric/src/lib/e2ap/v2_03/enc/e2ap_msg_enc_asn.c:3165: e2ap_enc_e42_setup_response_asn_pdu: Assertion `sr->len_e2_nodes_conn > 0 && "No global node conected??"' failed.
```

seems clearly related to the E2 interface. I notice when playing with the "1.4 Test (optional step)" step [here](https://gitlab.eurecom.fr/mosaic5g/flexric), that the same error is raised if I start the nearRT RIC and then the xApp without starting the E2 Node Agent. 

This led me to check your notes and I see you previously had not built the RAN with the E2 agent (with `--build-e2`) as specified [here](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/openair2/E2AP/README.md#212-build-oai-with-e2-agent).)

So first,

```
cd /mydata/openairinterface5g
cd cmake_targets/
./build_oai -c -C --gNB --nrUE --build-e2 -w SIMU --build-lib all --ninja
```

(this is the same as in the "Exploring the 5G core", but with `--build-e2` as specified [here](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/openair2/E2AP/README.md#212-build-oai-with-e2-agent).)

This raises an error


```
--   No package 'libdpdk' found
```

so I did

```
sudo apt install libdpdk-dev
```

then did the build again.

```
./build_oai -c -C --gNB --nrUE --build-e2 -w SIMU --build-lib all --ninja
```

This raised

```
-- Checking for module 'libdpdk=20.11.9'
--   Requested 'libdpdk = 20.11.9' but version of dpdk is 17.11.10
```

I have a suspicion that I don't even really need this, so I did

```
./build_oai -c -C --gNB --nrUE --build-e2 -w SIMU --ninja
```

(without `--build-lib all`) and it finished with

```
BUILD SHOULD BE SUCCESSFUL
```

But **if** that hadn't worked, my next step would have been to follow the Debian instructions [here](https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/ORAN_FHI7.2_Tutorial.md#dpdk-data-plane-development-kit).

Since it did work...

Start core (following the original "Exploring the 5G core network")

```
cd /opt/oai-cn5g-fed/docker-compose  
sudo python3 ./core-network.py --type start-basic --scenario 1  
```

Watch AMF logs:

```
sudo docker logs -f oai-amf  
```

Add 

```
e2_agent = {
  near_ric_ip_addr = "127.0.0.1";
  sm_dir = "/usr/local/lib/flexric/";
}
```
to

```
/local/repository/etc/gnb.conf
```

Start gNB:

```
cd /mydata/openairinterface5g/cmake_targets
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /local/repository/etc/gnb.conf --sa --rfsim
```

Verify in AMF log that it is connected:

```
|----------------------------------------------------gNBs' information-------------------------------------------|
|    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
|      1      |    Connected     |         0xe000        |  gNB-Eurecom-5GNRBox |            208, 95             | 
|----------------------------------------------------------------------------------------------------------------|
```

In the gNB output I see


```
[E2 AGENT]: E2 SETUP REQUEST timeout. Resending again (tx) 
```

which is promising! It's running the E2 agent. 

Start near-RT RIC:

```
cd flexric
./build/examples/ric/nearRT-RIC
```

Now in the gNB output I can see

```
[E2-AGENT]: E2 SETUP RESPONSE rx
[E2-AGENT]: Transaction ID E2 SETUP-REQUEST 9 E2 SETUP-RESPONSE 9 
```

and in the near-RT RIC output I see


```
[E2AP]: E2 SETUP-REQUEST rx from PLMN 208.95 Node ID 3584 RAN type ngran_gNB
[NEAR-RIC]: Accepting RAN function ID 2 with def = ORAN-E2SM-KPM 
[NEAR-RIC]: Accepting RAN function ID 3 with def = ORAN-E2SM-RC 
[NEAR-RIC]: Accepting RAN function ID 142 with def = MAC_STATS_V0 
[NEAR-RIC]: Accepting RAN function ID 143 with def = RLC_STATS_V0 
[NEAR-RIC]: Accepting RAN function ID 144 with def = PDCP_STATS_V0 
[NEAR-RIC]: Accepting RAN function ID 145 with def = SLICE_STATS_V0 
[NEAR-RIC]: Accepting RAN function ID 146 with def = TC_STATS_V0 
[NEAR-RIC]: Accepting RAN function ID 148 with def = GTP_STATS_V0 
```

I can start an xApp:

```
./build/examples/xApp/c/monitor/xapp_kpm_moni
```

and it's running.