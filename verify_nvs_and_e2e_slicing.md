first question that I am epxloring today is the latency issue. Apparently, it is not taking into account the RF simulation process in the latency calculation, so I start a new experiment, and here is what I found.

```
[NR_MAC]   Frame.Slot 768.0
UE RNTI a713 (1) PH 0 dB PCMAX 0 dBm, average RSRP -44 (16 meas)
UE a713: CQI 0, RI 1, PMI (0,0)
UE a713: dlsch_rounds 126/2/0/0, dlsch_errors 0, pucch0_DTX 2, BLER 0.00000 MCS 9
UE a713: dlsch_total_bytes 15674
UE a713: ulsch_rounds 128/0/0/0, ulsch_DTX 0, ulsch_errors 0, BLER 0.00000 MCS 9
UE a713: ulsch_total_bytes_scheduled 14848, ulsch_total_bytes_received 14848
UE a713: LCID 1: 513 bytes TX
UE a713: LCID 4: 12 bytes TX
UE a713: LCID 4: 216 bytes RX
```
This is a relatively weird thing. When I attached the UE to the RAN, I see 2 different logical channels, while previously I only see one in my nvs experiment. I am just taking a note of it in case it is sth of importance. 



Doing the experiment on the original old server that has a problem of too short a latency.
```
tshark -T fields -e frame.number -e _ws.col.Source -e _ws.col.Destination -e eth.src -e eth.dst -e _ws.col.Protocol -e ip.len  -e _ws.col.Info -r ~/ue-ext-dn.pcap 'icmp'
1568    192.168.70.135  192.168.72.79   02:42:c0:a8:46:87       02:42:b6:e4:db:c9       ICMP  84       Echo (ping) request  id=0xf94c, seq=1/256, ttl=64
1569    192.168.72.79   192.168.70.135  02:42:b6:e4:db:c9       02:42:c0:a8:46:87       ICMP  84       Echo (ping) reply    id=0xf94c, seq=1/256, ttl=64 (request in 1568)
```

This is the mac address of the external data network:
```
PeterYao@node:~$ sudo docker exec -it oai-ext-dn ip addr
...
301: eth0@if302: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:a8:46:87 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.70.135/26 brd 192.168.70.191 scope global eth0
       valid_lft forever preferred_lft forever
```

This is the mac address of the gnb: 
```
PeterYao@node:~$ ip addr list demo-oai
196: demo-oai: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:b6:e4:db:c9 brd ff:ff:ff:ff:ff:ff
    inet 192.168.70.129/26 brd 192.168.70.191 scope global demo-oai
       valid_lft forever preferred_lft forever
    inet6 fe80::42:b6ff:fee4:dbc9/64 scope link
       valid_lft forever preferred_lft forever
```

And then this is the address of the upf: 
```
317: eth0@if318: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:a8:46:86 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.70.134/26 brd 192.168.70.191 scope global eth0
       valid_lft forever preferred_lft forever
```
The ping goes directly from the external data network to the gnb without going through the UPF, which is problematic. 

Now let's compare with the normal case  

```
PeterYao@node:~$ tshark -T fields -e frame.number -e _ws.col.Source -e _ws.col.Destination -e eth.src -e eth.dst -e _ws.col.Protocol -e ip.len  -e _ws.col.Info -r ~/ue-ext-dn.pcap 'icmp'
55      192.168.70.135  12.1.1.151      02:42:c0:a8:46:87     02:42:c0:a8:46:86       ICMP    84      Echo (ping) request  id=0x0015, seq=1/256, ttl=64
56      192.168.70.135  12.1.1.151      02:42:c0:a8:46:86     02:42:4b:57:0c:77       GTP <ICMP>      128,84Echo (ping) request  id=0x0015, seq=1/256, ttl=63
57      12.1.1.151      192.168.70.135  02:42:4b:57:0c:77     02:42:c0:a8:46:86       GTP <ICMP>      128,84Echo (ping) reply    id=0x0015, seq=1/256, ttl=64 (request in 56)
58      12.1.1.151      192.168.70.135  02:42:c0:a8:46:86     02:42:c0:a8:46:87       ICMP    84      Echo (ping) reply    id=0x0015, seq=1/256, ttl=63 (request in 55)
```

the mac of the external data network being:
```
PeterYao@node:~$ sudo docker exec -it oai-ext-dn ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
28: eth0@if29: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:a8:46:87 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.70.135/26 brd 192.168.70.191 scope global eth0
       valid_lft forever preferred_lft forever
```
and the upf address being: 
```
PeterYao@node:~$ sudo docker exec -it oai-spgwu ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 500
    link/none
    inet 12.1.1.1/24 scope global tun0
       valid_lft forever preferred_lft forever
26: eth0@if27: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:a8:46:86 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.70.134/26 brd 192.168.70.191 scope global eth0
       valid_lft forever preferred_lft forever
```

and the gnb address being: 
```
11: demo-oai: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:4b:57:0c:77 brd ff:ff:ff:ff:ff:ff
    inet 192.168.70.129/26 brd 192.168.70.191 scope global demo-oai
       valid_lft forever preferred_lft forever
    inet6 fe80::42:4bff:fe57:c77/64 scope link
       valid_lft forever preferred_lft forever
```

That looks normal, from the ext to upf to gnb and the same way back. But does that mean the latency is primarily in the UPF? that does not seem right. So the problem should be that we are skipping the hop of gnb RF. But it seems that we are really skipping UPF. Or are we skipping both somehow. 


---
I have given up trying to make the orig ./build_oai -Iinal work. It is not worth the effort, and I have no idea where it could have gone wrong. So I am starting a new one. 

```bash
cd flexric/
git checkout rc_slice_xapp

# for oai, first git clone the latest version
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git
cd openairinterface5g
git checkout rebased-5g-nvs-rc-rf
cd cmake_targets
./build_oai -c -C -I -w SIMU --gNB --nrUE --build-e2 --ninja
```
add 
```
e2_agent = {
  near_ric_ip_addr = "127.0.0.1";
  sm_dir = "/usr/local/lib/flexric/"
}

```

adding the flexric to the loop, now the latency still seems okay. 
```
PeterYao@node:~$ sudo docker exec -it oai-ext-dn ping -c 20 $UEIP
PING 12.1.1.152 (12.1.1.152) 56(84) bytes of data.
64 bytes from 12.1.1.152: icmp_seq=1 ttl=63 time=92.6 ms
64 bytes from 12.1.1.152: icmp_seq=2 ttl=63 time=91.9 ms
64 bytes from 12.1.1.152: icmp_seq=3 ttl=63 time=77.6 ms
64 bytes from 12.1.1.152: icmp_seq=4 ttl=63 time=79.4 ms
64 bytes from 12.1.1.152: icmp_seq=5 ttl=63 time=78.0 ms
64 bytes from 12.1.1.152: icmp_seq=6 ttl=63 time=93.6 ms
64 bytes from 12.1.1.152: icmp_seq=7 ttl=63 time=80.5 ms
64 bytes from 12.1.1.152: icmp_seq=8 ttl=63 time=82.2 ms
64 bytes from 12.1.1.152: icmp_seq=9 ttl=63 time=82.4 ms
64 bytes from 12.1.1.152: icmp_seq=10 ttl=63 time=82.5 ms
64 bytes from 12.1.1.152: icmp_seq=11 ttl=63 time=85.1 ms
64 bytes from 12.1.1.152: icmp_seq=12 ttl=63 time=83.5 ms
64 bytes from 12.1.1.152: icmp_seq=13 ttl=63 time=83.2 ms
64 bytes from 12.1.1.152: icmp_seq=14 ttl=63 time=88.2 ms
64 bytes from 12.1.1.152: icmp_seq=15 ttl=63 time=84.1 ms
64 bytes from 12.1.1.152: icmp_seq=16 ttl=63 time=90.0 ms
64 bytes from 12.1.1.152: icmp_seq=17 ttl=63 time=89.7 ms
64 bytes from 12.1.1.152: icmp_seq=18 ttl=63 time=85.9 ms
64 bytes from 12.1.1.152: icmp_seq=19 ttl=63 time=84.3 ms
64 bytes from 12.1.1.152: icmp_seq=20 ttl=63 time=82.7 ms

--- 12.1.1.152 ping statistics ---
20 packets transmitted, 20 received, 0% packet loss, time 19025ms
rtt min/avg/max/mdev = 77.629/84.926/93.652/4.628 ms
```
I have to admit that the latency looks longer than in the morningi, proobably a different OAI version's fault. 

---

Now I need to test e2e, once we get one UE in the proper slice, can we ping from the external data network to that ue in the slice, and whether the latency looks normal. 

That is a question. 
First, I need to change the code as last time to bind the UE to the correct slice. 

And then we recompile the code and everything. I think we only need to recompile the gNB part of it. 

```bash
./build_oai --gNB --build-e2 -w SIMU --ninja
```


I want to know at which step the IP address to the UE is not assigned automatically, hence a problem.

I reboot and verify that when it is just the RIC and the gnb and ue (all at the correct branch, unmodified), the ping is normal. 


I found the problem! The UE ip address goes away when I changed the gnb.conf's mcc and mnc. I have the doubt that when I changed that, the core network cannot recognize the new mcc and mnc id for the plmn identifier. 


Undo the changes to verify, yes indeed the ping is back to normal. 

---

Changing the code at gnb. Forget about the flxric mcc and mnc. 

```bash
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /local/repository/etc/gnb.conf --sa --rfsim

sudo RFSIMULATOR=127.0.0.1 ./ran_build/build/nr-uesoftmodem -O /local/repository/etc/ue.conf -r 106 -C 3619200000 --sa --nokrnmod --numerology 1 --band 78 --rfsim --rfsimulator.options chanmod
```

First step is to create and connect 2 UEs, and assign them to different slices, and then we will talk about how to configure the core network to make it work. 

---
### Multiple UE at different slices.

The tutorial at this website: https://gitlab.eurecom.fr/oaiworkshop/summerworkshop2023/-/tree/main/ran#multiple-ues 
is only partially correct. It changes the imsi, but not the corresponding authentication information like key and opc. Hence it will not pass the test of AUSF, and hence it will be rejected.  We will see again the familiar dreadful scenario of almost zero latency, becuase it has never been properly attached to the base station. 

To attach the first UE. 
```bash
sudo ~/summerworkshop2023/ran/multi-ue.sh -c1 -e
sudo ip netns exec ue1 bash
sudo RFSIMULATOR=10.201.1.100 ./ran_build/build/nr-uesoftmodem -O /local/repository/etc/ue.conf -r 106 -C 3619200000 --sa --nokrnmod --numerology 1 --band 78 --rfsim --rfsimulator.options chanmod
```
this works and is accepted by ausf. 

We need to delve into the database to get the configuration for the second UE. 

database file where the ue information is stored: ***/opt/oai-cn5g-fed/docker-compose/database***

Write to this new ue conf the new imsi and key according to the database sql instructions. 

```
uicc0 = {
imsi = "208950000000032";
key = "0C0A34601D4F07677303652C0462535B";
opc= "63bfa50ee6523365ff14c1f45f88737d";
dnn= "oai";
nssai_sst=1;
nssai_sd=1;
}

@include "channelmod_rfsimu.conf"
```

run the UE. 

```bash
sudo /mydata/summerworkshop2023/ran/multi-ue.sh -c3 -e
sudo ip netns exec ue3 bash
sudo RFSIMULATOR=10.203.1.100 ./ran_build/build/nr-uesoftmodem -O /local/repository/etc/ue2.conf -r 106 -C 3619200000 --sa --nokrnmod --numerology 1 --band 78 --rfsim --rfsimulator.options chanmod
```

We can verify that both ue is connected to the gnb successfully and can be ping through normally. 

```bash
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

Adding RAN slices to a gnb with xaapp and 2 UEs. 

```

[NR_MAC]   [E2-Agent]: RC CONTROL rx, RIC Style Type 2, Action ID 6
[NR_MAC]   Add default DL slice id 99, label default, sst 0, sd 0, slice sched algo NVS_CAPACITY, pct_reserved 0.05, ue sched algo nr_proportional_fair_wbcqi_dl
[NR_MAC]   configure slice 0, label SST1SD1, Dedicated_PRB_Policy_Ratio 70
[NR_MAC]   add DL slice id 1, label SST1SD1, slice sched algo NVS_CAPACITY, pct_reserved 0.66, ue sched algo nr_proportional_fair_wbcqi_dl
[NR_MAC]   UE: mcc 208 mnc 95, sst 0 sd 0, RC: mcc 505 mnc 1, sst 1 sd 1
[NR_MAC]   Matched slice, Add UE rnti 0xc172 to slice idx 0, sst 0, sd 0
[NR_MAC]   Matched slice, Add UE rnti 0xc172 to slice idx 1, sst 1, sd 1
[NR_MAC]   Failed matching UE rnti 6c4d with current slice (sst 1, sd 1), might lost user plane data
[NR_MAC]   configure slice 1, label SST1SD5, Dedicated_PRB_Policy_Ratio 30
[NR_MAC]   add DL slice id 2, label SST1SD5, slice sched algo NVS_CAPACITY, pct_reserved 0.28, ue sched algo nr_proportional_fair_wbcqi_dl
[NR_MAC]   Failed matching UE rnti c172 with current slice (sst 1, sd 5), might lost user plane data
[NR_MAC]   Failed matching UE rnti 6c4d with current slice (sst 1, sd 5), might lost user plane data
[E2-AGENT]: CONTROL ACKNOWLEDGE tx
```


It seems that code is still a bit wrong. 

Looking at the UE that does not get any slice:

```
[NR_PHY]   ============================================
[NR_PHY]   Harq round stats for Downlink: 158/2/0
[NR_PHY]   ============================================
[RLC]   max RETX reached on DRB 1
[RLC]   max RETX reached on DRB 1
[RLC]   max RETX reached on DRB 1
[RLC]   max RETX reached on DRB 1
[RLC]   max RETX reached on DRB 1
[RLC]   max RETX reached on DRB 1
[RLC]   max RETX reached on DRB 1
[RLC]   max RETX reached on DRB 1
[RLC]   max RETX reached on DRB 1
```

It cannot get any resources. 

Turns out that the previous code modification contains mistakes. 

Copy and paste this function instead. 

```c++
bool add_mod_rc_slice(int mod_id, size_t slices_len, ran_param_list_t* lst)
{
  gNB_MAC_INST *nrmac = RC.nrmac[mod_id];
  assert(nrmac);

  int current_algo = nrmac->pre_processor_dl.algorithm;
  // use NVS algorithm by default
  int new_algo = NVS_SLICING;

  pthread_mutex_lock(&nrmac->UE_info.mutex);
  if (current_algo != new_algo) {
    set_new_dl_slice_algo(mod_id, new_algo);
    current_algo = new_algo;
    if (new_algo > 0)
      LOG_D(NR_MAC, "set new algorithm %d\n", current_algo);
    else
      LOG_W(NR_MAC, "reset slicing algorithm as NONE\n");
  }

  for (size_t i = 0; i < slices_len; ++i) {
    lst_ran_param_t* RRM_Policy_Ratio_Group = &lst->lst_ran_param[i];
    //Bug in rc_enc_asn.c:1003, asn didn't define ran_param_id for lst_ran_param_t...
    //assert(RRM_Policy_Ratio_Group->ran_param_id == RRM_Policy_Ratio_Group_8_4_3_6 && "wrong RRM_Policy_Ratio_Group id");
    assert(RRM_Policy_Ratio_Group->ran_param_struct.sz_ran_param_struct == 4 && "wrong RRM_Policy_Ratio_Group->ran_param_struct.sz_ran_param_struct");
    assert(RRM_Policy_Ratio_Group->ran_param_struct.ran_param_struct != NULL && "NULL RRM_Policy_Ratio_Group->ran_param_struct.ran_param_struct");

    seq_ran_param_t* RRM_Policy = &RRM_Policy_Ratio_Group->ran_param_struct.ran_param_struct[0];
    assert(RRM_Policy->ran_param_id == RRM_Policy_8_4_3_6 && "wrong RRM_Policy id");
    assert(RRM_Policy->ran_param_val.type == STRUCTURE_RAN_PARAMETER_VAL_TYPE && "wrong RRM_Policy type");
    assert(RRM_Policy->ran_param_val.strct != NULL && "NULL RRM_Policy->ran_param_val.strct");
    assert(RRM_Policy->ran_param_val.strct->sz_ran_param_struct == 1 && "wrong RRM_Policy->ran_param_val.strct->sz_ran_param_struct");
    assert(RRM_Policy->ran_param_val.strct->ran_param_struct != NULL && "NULL RRM_Policy->ran_param_val.strct->ran_param_struct");

    seq_ran_param_t* RRM_Policy_Member_List = &RRM_Policy->ran_param_val.strct->ran_param_struct[0];
    assert(RRM_Policy_Member_List->ran_param_id == RRM_Policy_Member_List_8_4_3_6 && "wrong RRM_Policy_Member_List id");
    assert(RRM_Policy_Member_List->ran_param_val.type == LIST_RAN_PARAMETER_VAL_TYPE && "wrong RRM_Policy_Member_List type");
    assert(RRM_Policy_Member_List->ran_param_val.lst != NULL && "NULL RRM_Policy_Member_List->ran_param_val.lst");
    assert(RRM_Policy_Member_List->ran_param_val.lst->sz_lst_ran_param == 1 && "wrong RRM_Policy_Member_List->ran_param_val.lst->sz_lst_ran_param");
    assert(RRM_Policy_Member_List->ran_param_val.lst->lst_ran_param != NULL && "NULL RRM_Policy_Member_List->ran_param_val.lst->lst_ran_param");

    lst_ran_param_t* RRM_Policy_Member = &RRM_Policy_Member_List->ran_param_val.lst->lst_ran_param[0];
    //Bug in rc_enc_asn.c:1003, asn didn't define ran_param_id for lst_ran_param_t ...
    //assert(RRM_Policy_Member->ran_param_id == RRM_Policy_Member_8_4_3_6 && "wrong RRM_Policy_Member id");
    assert(RRM_Policy_Member->ran_param_struct.sz_ran_param_struct == 2 && "wrong RRM_Policy_Member->ran_param_struct.sz_ran_param_struct");
    assert(RRM_Policy_Member->ran_param_struct.ran_param_struct != NULL && "NULL RRM_Policy_Member->ran_param_struct.ran_param_struct");

    seq_ran_param_t* PLMN_Identity = &RRM_Policy_Member->ran_param_struct.ran_param_struct[0];
    assert(PLMN_Identity->ran_param_id == PLMN_Identity_8_4_3_6 && "wrong PLMN_Identity id");
    assert(PLMN_Identity->ran_param_val.type == ELEMENT_KEY_FLAG_FALSE_RAN_PARAMETER_VAL_TYPE && "wrong PLMN_Identity type");
    assert(PLMN_Identity->ran_param_val.flag_false != NULL && "NULL PLMN_Identity->ran_param_val.flag_false");
    assert(PLMN_Identity->ran_param_val.flag_false->type == OCTET_STRING_RAN_PARAMETER_VALUE && "wrong PLMN_Identity->ran_param_val.flag_false->type");
    ///// GET RC PLMN ////
    char* plmn_str = cp_ba_to_str(PLMN_Identity->ran_param_val.flag_false->octet_str_ran);
    int RC_mnc, RC_mcc = 0;
    if (strlen(plmn_str) == 6)
      sscanf(plmn_str, "%3d%2d", &RC_mcc, &RC_mnc);
    else
      sscanf(plmn_str, "%3d%3d", &RC_mcc, &RC_mnc);
    LOG_D(NR_MAC, "RC PLMN %s, MCC %d, MNC %d\n", plmn_str, RC_mcc, RC_mnc);
    free(plmn_str);

    seq_ran_param_t* S_NSSAI = &RRM_Policy_Member->ran_param_struct.ran_param_struct[1];
    assert(S_NSSAI->ran_param_id == S_NSSAI_8_4_3_6 && "wrong S_NSSAI id");
    assert(S_NSSAI->ran_param_val.type == STRUCTURE_RAN_PARAMETER_VAL_TYPE && "wrong S_NSSAI type");
    assert(S_NSSAI->ran_param_val.strct != NULL && "NULL S_NSSAI->ran_param_val.strct");
    assert(S_NSSAI->ran_param_val.strct->sz_ran_param_struct == 2 && "wrong S_NSSAI->ran_param_val.strct->sz_ran_param_struct");
    assert(S_NSSAI->ran_param_val.strct->ran_param_struct != NULL && "NULL S_NSSAI->ran_param_val.strct->ran_param_struct");

    seq_ran_param_t* SST = &S_NSSAI->ran_param_val.strct->ran_param_struct[0];
    assert(SST->ran_param_id == SST_8_4_3_6 && "wrong SST id");
    assert(SST->ran_param_val.type == ELEMENT_KEY_FLAG_FALSE_RAN_PARAMETER_VAL_TYPE && "wrong SST type");
    assert(SST->ran_param_val.flag_false != NULL && "NULL SST->ran_param_val.flag_false");
    assert(SST->ran_param_val.flag_false->type == OCTET_STRING_RAN_PARAMETER_VALUE && "wrong SST->ran_param_val.flag_false type");
    seq_ran_param_t* SD = &S_NSSAI->ran_param_val.strct->ran_param_struct[1];
    assert(SD->ran_param_id == SD_8_4_3_6 && "wrong SD id");
    assert(SD->ran_param_val.type == ELEMENT_KEY_FLAG_FALSE_RAN_PARAMETER_VAL_TYPE && "wrong SD type");
    assert(SD->ran_param_val.flag_false != NULL && "NULL SD->ran_param_val.flag_false");
    assert(SD->ran_param_val.flag_false->type == OCTET_STRING_RAN_PARAMETER_VALUE && "wrong SD->ran_param_val.flag_false type");
    ///// GET RC NSSAI ////
    char* rc_sst_str = cp_ba_to_str(SST->ran_param_val.flag_false->octet_str_ran);
    char* rc_sd_str = cp_ba_to_str(SD->ran_param_val.flag_false->octet_str_ran);
    nssai_t RC_nssai = {.sst = atoi(rc_sst_str), .sd = atoi(rc_sd_str)};
    LOG_D(NR_MAC, "RC (oct) SST %s, SD %s -> (uint) SST %d, SD %d\n", rc_sst_str, rc_sd_str, RC_nssai.sst, RC_nssai.sd);
    ///// SLICE LABEL NAME /////
    char* sst_str = "SST";
    char* sd_str = "SD";
    size_t label_nssai_len = strlen(sst_str) + strlen(rc_sst_str) + strlen(sd_str) + strlen(rc_sd_str) + 1;
    char* label_nssai = (char*)malloc(label_nssai_len);
    assert(label_nssai != NULL && "Memory exhausted");
    sprintf(label_nssai, "%s%s%s%s", sst_str, rc_sst_str, sd_str, rc_sd_str);
    free(rc_sst_str);
    free(rc_sd_str);

    ///// SLICE NVS CAP /////
    seq_ran_param_t* Min_PRB_Policy_Ratio = &RRM_Policy_Ratio_Group->ran_param_struct.ran_param_struct[1];
    assert(Min_PRB_Policy_Ratio->ran_param_id == Min_PRB_Policy_Ratio_8_4_3_6 && "wrong Min_PRB_Policy_Ratio id");
    assert(Min_PRB_Policy_Ratio->ran_param_val.type == ELEMENT_KEY_FLAG_FALSE_RAN_PARAMETER_VAL_TYPE && "wrong Min_PRB_Policy_Ratio type");
    assert(Min_PRB_Policy_Ratio->ran_param_val.flag_false != NULL && "NULL Min_PRB_Policy_Ratio->ran_param_val.flag_false");
    assert(Min_PRB_Policy_Ratio->ran_param_val.flag_false->type == INTEGER_RAN_PARAMETER_VALUE && "wrong Min_PRB_Policy_Ratio->ran_param_val.flag_false type");
    int64_t min_prb_ratio = Min_PRB_Policy_Ratio->ran_param_val.flag_false->int_ran;
    LOG_D(NR_MAC, "configure slice %ld, label %s, Min_PRB_Policy_Ratio %ld\n", i, label_nssai, min_prb_ratio);

    seq_ran_param_t* Dedicated_PRB_Policy_Ratio = &RRM_Policy_Ratio_Group->ran_param_struct.ran_param_struct[3];
    assert(Dedicated_PRB_Policy_Ratio->ran_param_id == Dedicated_PRB_Policy_Ratio_8_4_3_6 && "wrong Dedicated_PRB_Policy_Ratio id");
    assert(Dedicated_PRB_Policy_Ratio->ran_param_val.type == ELEMENT_KEY_FLAG_FALSE_RAN_PARAMETER_VAL_TYPE && "wrong Dedicated_PRB_Policy_Ratio type");
    assert(Dedicated_PRB_Policy_Ratio->ran_param_val.flag_false != NULL && "NULL Dedicated_PRB_Policy_Ratio->ran_param_val.flag_false");
    assert(Dedicated_PRB_Policy_Ratio->ran_param_val.flag_false->type == INTEGER_RAN_PARAMETER_VALUE && "wrong Dedicated_PRB_Policy_Ratio->ran_param_val.flag_false type");
    int64_t dedicated_prb_ratio = Dedicated_PRB_Policy_Ratio->ran_param_val.flag_false->int_ran;
    LOG_I(NR_MAC, "configure slice %ld, label %s, Dedicated_PRB_Policy_Ratio %ld\n", i, label_nssai, dedicated_prb_ratio);
    // TODO: could be extended to support max prb ratio in the MAC scheduling algorithm
    //seq_ran_param_t* Max_PRB_Policy_Ratio = &RRM_Policy_Ratio_Group->ran_param_struct.ran_param_struct[2];
    //assert(Max_PRB_Policy_Ratio->ran_param_id == Max_PRB_Policy_Ratio_8_4_3_6 && "wrong Max_PRB_Policy_Ratio id");
    //assert(Max_PRB_Policy_Ratio->ran_param_val.type == ELEMENT_KEY_FLAG_FALSE_RAN_PARAMETER_VAL_TYPE && "wrong Max_PRB_Policy_Ratio type");
    //assert(Max_PRB_Policy_Ratio->ran_param_val.flag_false != NULL && "NULL Max_PRB_Policy_Ratio->ran_param_val.flag_false");
    //assert(Max_PRB_Policy_Ratio->ran_param_val.flag_false->type == INTEGER_RAN_PARAMETER_VALUE && "wrong Max_PRB_Policy_Ratio->ran_param_val.flag_false type");
    //int64_t max_prb_ratio = Max_PRB_Policy_Ratio->ran_param_val.flag_false->int_ran;
    //LOG_I(NR_MAC, "configure slice %ld, label %s, Max_PRB_Policy_Ratio %ld\n", i, label_nssai, max_prb_ratio);

    ///// ADD SLICE /////
    /* Resource-based */
    void *params = malloc(sizeof(nvs_nr_slice_param_t));
    ((nvs_nr_slice_param_t *)params)->type = NVS_RES;
    ((nvs_nr_slice_param_t *)params)->pct_reserved = dedicated_prb_ratio;
    const int rc = add_mod_dl_slice(mod_id, current_algo, i+1, RC_nssai, label_nssai, params);
    free(label_nssai);
    if (rc < 0) {
      pthread_mutex_unlock(&nrmac->UE_info.mutex);
      LOG_E(NR_MAC, "error code %d while updating slices\n", rc);
      return false;
    }
    /* TODO: Bandwidth-based */

    /// ASSOC SLICE ///
    if (nrmac->pre_processor_dl.algorithm <= 0)
      LOG_E(NR_MAC, "current slice algo is NONE, no UE can be associated\n");

    if (nrmac->UE_info.list[0] == NULL)
      LOG_E(NR_MAC, "no UE connected\n");


    nr_pp_impl_param_dl_t *dl = &RC.nrmac[mod_id]->pre_processor_dl;
    NR_UEs_t *UE_info = &RC.nrmac[mod_id]->UE_info;
    int ue_idx = 0;
    UE_iterator(UE_info->list, UE) {
      rnti_t rnti = UE->rnti;
      NR_UE_sched_ctrl_t *sched_ctrl = &UE->UE_sched_ctrl;
      bool assoc_ue = 0;
      long lcid = 0;
      for (int l = 0; l < sched_ctrl->dl_lc_num; ++l) {
        lcid = sched_ctrl->dl_lc_ids[l];
        LOG_W(NR_MAC, "looking at slice idx: %d, and ue idx: %d, rnti: %x, l %d, lcid %ld, sst %d, sd %d\n", i, ue_idx, rnti,l, lcid, sched_ctrl->dl_lc_nssai[lcid].sst, sched_ctrl->dl_lc_nssai[lcid].sd);
        // if (nssai_matches(sched_ctrl->dl_lc_nssai[lcid], RC_nssai.sst, &RC_nssai.sd)) {
        if (i % 2 == ue_idx % 2) {
          rrc_gNB_ue_context_t* rrc_ue_context_list = rrc_gNB_get_ue_context_by_rnti_any_du(RC.nrrrc[mod_id], rnti);
          uint16_t UE_mcc = rrc_ue_context_list->ue_context.ue_guami.mcc;
          uint16_t UE_mnc = rrc_ue_context_list->ue_context.ue_guami.mnc;

          uint8_t UE_sst = sched_ctrl->dl_lc_nssai[lcid].sst;
          uint32_t UE_sd = sched_ctrl->dl_lc_nssai[lcid].sd;
          // LOG_I(NR_MAC, "UE: mcc %d mnc %d, sst %d sd %d, RC: mcc %d mnc %d, sst %d sd %d\n",
          //       UE_mcc, UE_mnc, UE_sst, UE_sd, RC_mcc, RC_mnc, RC_nssai.sst, RC_nssai.sd);

          // if (UE_mcc == RC_mcc && UE_mnc == RC_mnc && UE_sst == RC_nssai.sst && UE_sd == RC_nssai.sd) {
          dl->add_UE(dl->slices, UE);
          LOG_I(NR_MAC, "adding UE with RNTI%x to slice with sst: %d, sd: %d \n", rnti, RC_nssai.sst, RC_nssai.sd);

	        assoc_ue = true;

          // } else {
            // LOG_E(NR_MAC, "Failed adding UE (PLMN: mcc %d mnc %d, NSSAI: sst %d sd %d) to slice (PLMN: mcc %d mnc %d, NSSAI: sst %d sd %d)\n",
                  // UE_mcc, UE_mnc, UE_sst, UE_sd, RC_mcc, RC_mnc, RC_nssai.sst, RC_nssai.sd);
          // }
        }
      }
      ue_idx++;
      if (!assoc_ue)
        LOG_E(NR_MAC, "Failed matching UE rnti %x with current slice (sst %d, sd %d), might lost user plane data\n", rnti, RC_nssai.sst, RC_nssai.sd);
    }

  }

  pthread_mutex_unlock(&nrmac->UE_info.mutex);
  LOG_D(NR_MAC, "All slices add/mod successfully!\n");
  return true;
}

```


It might take me a while to figure out how to ping through to the 2 UEs, as they are in different subnets now. 

Actually, quite easy, just ping directly:
```bash
root@node:/mydata/flexric/build/examples/xApp/c/ctrl# sudo docker exec -it oai-ext-dn ping -c 10 12.1.1.156
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
root@node:/mydata/flexric/build/examples/xApp/c/ctrl# sudo docker exec -it oai-ext-dn ping -c 10 12.1.1.155
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

Be assured that we are pinging to the right interfaces:
```
[OIP]   Interface oaitun_ue1 successfully configured, ip address 12.1.1.156, mask 255.255.255.0 broadcast address 12.1.1.255

<!-- a different UE -->

[OIP]   Interface oaitun_ue1 successfully configured, ip address 12.1.1.155, mask 255.255.255.0 broadcast address 12.1.1.255
```
```
root@node:/mydata/flexric/build/examples/xApp/c/ctrl# ip addr list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
5: oaitun_ue1: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none
    inet 12.1.1.156/24 brd 12.1.1.255 scope global oaitun_ue1
       valid_lft forever preferred_lft forever
    inet6 fe80::3ffc:ef4a:cb43:ade3/64 scope link stable-privacy
       valid_lft forever preferred_lft forever
32: v-ue3@if33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether ea:7a:6a:81:3e:4a brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.203.1.3/24 scope global v-ue3
       valid_lft forever preferred_lft forever
    inet6 fe80::e87a:6aff:fe81:3e4a/64 scope link
       valid_lft forever preferred_lft forever
root@node:/mydata/flexric/build/examples/xApp/c/ctrl# exit
PeterYao@node:/mydata/flexric/build/examples/xApp/c/ctrl$ sudo ip netns exec ue1 bash
root@node:/mydata/flexric/build/examples/xApp/c/ctrl# ip addr list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host
       valid_lft forever preferred_lft forever
6: oaitun_ue1: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 500
    link/none
    inet 12.1.1.155/24 brd 12.1.1.255 scope global oaitun_ue1
       valid_lft forever preferred_lft forever
    inet6 fe80::cb5d:2bfb:8933:145a/64 scope link stable-privacy
       valid_lft forever preferred_lft forever
30: v-ue1@if31: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 06:2b:77:5d:32:c8 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 10.201.1.1/24 scope global v-ue1
       valid_lft forever preferred_lft forever
    inet6 fe80::42b:77ff:fe5d:32c8/64 scope link
       valid_lft forever preferred_lft forever
```

---
To test with iperf, first get the address of the external net:
```bash
PeterYao@node:~$ docker exec -it oai-ext-dn bash
Got permission denied while trying to connect to the Docker daemon socket at unix:///var/run/docker.sock: Get "http://%2Fvar%2Frun%2Fdocker.sock/v1.24/containers/oai-ext-dn/json": dial unix /var/run/docker.sock: connect: permission denied
PeterYao@node:~$ sudo !!
sudo docker exec -it oai-ext-dn bash
root@581e40107528:/tmp# ip addr list
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
28: eth0@if29: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:a8:46:87 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.70.135/26 brd 192.168.70.191 scope global eth0
       valid_lft forever preferred_lft forever
```

Then run iperf:

for the ue in the first slice:
```
PeterYao@node:~$ sudo ip netns exec ue1 bash
root@node:~# iperf3 -s
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 192.168.70.135, port 43684
[  5] local 12.1.1.155 port 5201 connected to 192.168.70.135 port 43686
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-1.00   sec   499 KBytes  4.09 Mbits/sec
[  5]   1.00-2.00   sec  1.07 MBytes  8.99 Mbits/sec
[  5]   2.00-3.00   sec  1.28 MBytes  10.7 Mbits/sec
[  5]   3.00-4.00   sec  1.58 MBytes  13.3 Mbits/sec
[  5]   4.00-5.00   sec  1.93 MBytes  16.2 Mbits/sec
[  5]   5.00-6.00   sec  2.37 MBytes  19.9 Mbits/sec
[  5]   6.00-7.00   sec  1.76 MBytes  14.8 Mbits/sec
[  5]   7.00-8.00   sec  2.36 MBytes  19.8 Mbits/sec
[  5]   8.00-9.00   sec  1.73 MBytes  14.5 Mbits/sec
[  5]   9.00-10.00  sec  2.39 MBytes  20.1 Mbits/sec
[  5]  10.00-10.47  sec  1.18 MBytes  21.0 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-10.47  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-10.47  sec  18.2 MBytes  14.5 Mbits/sec
receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
```

And the iperf client on the external data network shows this:
```
PeterYao@node:~$ sudo docker exec -it oai-ext-dn bash
root@581e40107528:/tmp# iperf3 -c 12.1.1.155
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

***I do not understand why the two sides might be different??***

For the second slice:

On the UE side,  running iperf server:
```
PeterYao@node:~$ sudo ip netns exec ue3 bash
root@node:~# iperf3 -s
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------
Accepted connection from 192.168.70.135, port 49306
[  5] local 12.1.1.156 port 5201 connected to 192.168.70.135 port 49308
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-1.00   sec   296 KBytes  2.42 Mbits/sec
[  5]   1.00-2.00   sec   696 KBytes  5.70 Mbits/sec
[  5]   2.00-3.00   sec   848 KBytes  6.95 Mbits/sec
[  5]   3.00-4.00   sec   638 KBytes  5.22 Mbits/sec
[  5]   4.00-5.00   sec   773 KBytes  6.34 Mbits/sec
[  5]   5.00-6.00   sec  1.03 MBytes  8.68 Mbits/sec
[  5]   6.00-7.00   sec  1.07 MBytes  8.98 Mbits/sec
[  5]   7.00-8.00   sec  1.11 MBytes  9.30 Mbits/sec
[  5]   8.00-9.00   sec  1.20 MBytes  10.0 Mbits/sec
[  5]   9.00-10.00  sec  1.45 MBytes  12.2 Mbits/sec
[  5]  10.00-10.44  sec   690 KBytes  12.7 Mbits/sec
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth
[  5]   0.00-10.44  sec  0.00 Bytes  0.00 bits/sec                  sender
[  5]   0.00-10.44  sec  9.71 MBytes  7.80 Mbits/sec
receiver
-----------------------------------------------------------
Server listening on 5201
-----------------------------------------------------------

```

For the ext-dn:
```bash
root@581e40107528:/tmp# iperf3 -c 12.1.1.156
Connecting to host 12.1.1.156, port 5201
[  4] local 192.168.70.135 port 49308 connected to 12.1.1.156 port 5201
[ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
[  4]   0.00-1.00   sec  1.18 MBytes  9.87 Mbits/sec    0    144 KBytes
[  4]   1.00-2.00   sec   827 KBytes  6.78 Mbits/sec    0    177 KBytes
[  4]   2.00-3.00   sec  1.06 MBytes  8.86 Mbits/sec    0    219 KBytes
[  4]   3.00-4.00   sec   827 KBytes  6.78 Mbits/sec    0    252 KBytes
[  4]   4.00-5.00   sec   954 KBytes  7.82 Mbits/sec    0    290 KBytes
[  4]   5.00-6.00   sec  1.37 MBytes  11.5 Mbits/sec    0    345 KBytes
[  4]   6.00-7.00   sec  1.43 MBytes  12.0 Mbits/sec    0    400 KBytes
[  4]   7.00-8.00   sec  1.30 MBytes  11.0 Mbits/sec    0    455 KBytes
[  4]   8.00-9.00   sec  1.62 MBytes  13.5 Mbits/sec    0    520 KBytes
[  4]   9.00-10.00  sec  1.80 MBytes  15.1 Mbits/sec    0    592 KBytes
- - - - - - - - - - - - - - - - - - - - - - - - -
[ ID] Interval           Transfer     Bandwidth       Retr
[  4]   0.00-10.00  sec  12.3 MBytes  10.3 Mbits/sec    0             sender
[  4]   0.00-10.00  sec  9.71 MBytes  8.15 Mbits/sec                  receiver

iperf Done.
```

Ths NVS share of the first slice is 66% of the dl:
```
[NR_MAC]   add DL slice id 1, label SST1SD1, slice sched algo NVS_CAPACITY, pct_reserved 0.66, ue sched algo nr_proportional_fair_wbcqi_dl
```
While the second slice nvs share is: 28%
```
[NR_MAC]   add DL slice id 2, label SST1SD5, slice sched algo NVS_CAPACITY, pct_reserved 0.28, ue sched algo nr_proportional_fair_wbcqi_dl
```

---

Configuring the core slices. 
I don't know, but it seems that the tutorial for core slicing is seriously wrong. The gnb is not even attached to the core network. 

additionally, if you look at the traffic test section, the icmp latency is abusrdly low. There is clearly something wrong. Very likely the core network configuration is simply wrong. 

Let's deal with these problems one at a time. First of all, let's solve the problem that the gnb is not attached properly to the core network. 

Update: the gnb is not attached to the core when it is not in a container. However, if you follow the slicing tutorial and do the container gnb, it is properly attached and exchanging traffic with the core correctly. (I am not sure if the UE is properly attached, I have not run the ping test)

the ip of the containerized UJE1: 12.1.1.130

The traffic test:

```
PeterYao@node:/mydata/oai-cn5g-fed/docker-compose$ sudo docker exec oai-ext-dn ping -c 10 12.1.1.130
PING 12.1.1.130 (12.1.1.130) 56(84) bytes of data.
64 bytes from 12.1.1.130: icmp_seq=1 ttl=63 time=13.3 ms
64 bytes from 12.1.1.130: icmp_seq=2 ttl=63 time=6.03 ms
64 bytes from 12.1.1.130: icmp_seq=3 ttl=63 time=4.68 ms
64 bytes from 12.1.1.130: icmp_seq=4 ttl=63 time=5.64 ms
64 bytes from 12.1.1.130: icmp_seq=5 ttl=63 time=7.44 ms
64 bytes from 12.1.1.130: icmp_seq=6 ttl=63 time=6.88 ms
64 bytes from 12.1.1.130: icmp_seq=7 ttl=63 time=8.39 ms
64 bytes from 12.1.1.130: icmp_seq=8 ttl=63 time=5.96 ms
64 bytes from 12.1.1.130: icmp_seq=9 ttl=63 time=4.28 ms
64 bytes from 12.1.1.130: icmp_seq=10 ttl=63 time=8.67 ms
```
It agrees with the tutorial, but the latency is still low. But not too slow. I am not sure if it goes through the gnb properly. 


Apparently, there is something going on in the containerized version that running gnb directly as a process does not have. It could be 2 ways: the way the process is run, and/or the docker network setup. If we fail to find a reason, we have to fall back to the 


### the way the process is run

Looking into the entrypoint shell script of the gnb container. 

```
== Starting gNB soft modem
Additional option(s): --sa -E --rfsim --log_config.global_log_options level,nocolor,time
/opt/oai-gnb/bin/nr-softmodem -O /opt/oai-gnb/etc/gnb.conf --sa -E --rfsim --log_config.global_log_options level,nocolor,time
```
We can try that to see if it makes a difference. 


Running this command, it does not work:
```
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /mydata/oai-cn5g-fed/docker-compose/ran-conf/gnb.conf --sa -E --rfsim --log_config.global_log_options level,nocolor,time
```
I was using the same configuration and everything. 

And if we remove RFSIMULATOR=server, the 2 commands is completely the same. but we cannot remove that. I thus dedeuce that it has to do with the docker network configuration and everything. Ifit works in the basic docker compose, and not in the slicing one, we can try to find the difference. 

---
## Roadmap

1. working setup with the core, and the gnb and two ues, based closely  to ran slicing. The same network as exploring, config as similar as possible. 
2. In that working setup, deploy more upf smf nrf combinations. and also an nssf. Want to see that the AMD can connect to all of them. 
3. configure the ue and gnb to connect to slice 1. Validate that we connect too extdn through slice 1 UPF. 
4. Validate that can connect to slice 2, thorugh that UPF to the extdn. 
5. See if can get gnb to connect gnb1 /2 and ue to respective slices. and validate traffic flow. 

---
I am now doing this core setup thing really incrementally, I first want to setup the nssf. Just add the nssf to the existing network, and nothing else. I want to see when the amf and the nssf talks. 

So here is the docker compose: 
```
version: '3.8'
services:
    mysql:
        container_name: "mysql"
        image: mysql:8.0
        volumes:
            - ./database/oai_db2.sql:/docker-entrypoint-initdb.d/oai_db.sql
            - ./healthscripts/mysql-healthcheck2.sh:/tmp/mysql-healthcheck.sh
        environment:
            - TZ=Europe/Paris
            - MYSQL_DATABASE=oai_db
            - MYSQL_USER=test
            - MYSQL_PASSWORD=test
            - MYSQL_ROOT_PASSWORD=linux
        healthcheck:
            test: /bin/bash -c "/tmp/mysql-healthcheck.sh"
            interval: 10s
            timeout: 5s
            retries: 30
        networks:
            public_net:
                ipv4_address: 192.168.70.131
    oai-nssf:
        container_name: "oai-nssf"
        image: oaisoftwarealliance/oai-nssf:v2.0.1
        expose:
            - 80/tcp
            - 8080/tcp
        volumes:
            - ./conf/slicing_base_config.yaml:/openair-nssf/etc/config.yaml
            - ./conf/nssf_slice_config.yaml:/openair-nssf/etc/nssf_slice_config.yaml
        cap_add:
            - NET_ADMIN
            - SYS_ADMIN
        cap_drop:
            - ALL
        privileged: true
        networks:
            public_net:
                ipv4_address: 192.168.70.139
    oai-udr:
        container_name: "oai-udr"
        image: oaisoftwarealliance/oai-udr:v2.0.1
        expose:
            - 80/tcp
            - 8080/tcp
        volumes:
            - ./conf/basic_nrf_config.yaml:/openair-udr/etc/config.yaml
        environment:
            - TZ=Europe/Paris
        depends_on:
            - mysql
            - oai-nrf
        networks:
            public_net:
                ipv4_address: 192.168.70.136
    oai-udm:
        container_name: "oai-udm"
        image: oaisoftwarealliance/oai-udm:v2.0.1
        expose:
            - 80/tcp
            - 8080/tcp
        volumes:
            - ./conf/basic_nrf_config.yaml:/openair-udm/etc/config.yaml
        environment:
            - TZ=Europe/Paris
        depends_on:
            - oai-udr
        networks:
            public_net:
                ipv4_address: 192.168.70.137
    oai-ausf:
        container_name: "oai-ausf"
        image: oaisoftwarealliance/oai-ausf:v2.0.1
        expose:
            - 80/tcp
            - 8080/tcp
        volumes:
            - ./conf/basic_nrf_config.yaml:/openair-ausf/etc/config.yaml
        environment:
            - TZ=Europe/Paris
        depends_on:
            - oai-udm
        networks:
            public_net:
                ipv4_address: 192.168.70.138
    oai-nrf:
        container_name: "oai-nrf"
        image: oaisoftwarealliance/oai-nrf:v2.0.1
        expose:
            - 80/tcp
            - 8080/tcp
        volumes:
            - ./conf/basic_nrf_config.yaml:/openair-nrf/etc/config.yaml
        environment:
            - TZ=Europe/Paris
        networks:
            public_net:
                ipv4_address: 192.168.70.130
    oai-amf:
        container_name: "oai-amf"
        image: oaisoftwarealliance/oai-amf:v2.0.1
        expose:
            - 80/tcp
            - 8080/tcp
            - 38412/sctp
        volumes:
            - ./conf/basic_nrf_config.yaml:/openair-amf/etc/config.yaml
        environment:
            - TZ=Europe/Paris
        depends_on:
            - mysql
            - oai-nrf
            - oai-ausf
        networks:
            public_net:
                ipv4_address: 192.168.70.132
    oai-smf:
        container_name: "oai-smf"
        image: oaisoftwarealliance/oai-smf:v2.0.1
        expose:
            - 80/tcp
            - 8080/tcp
            - 8805/udp
        volumes:
            - ./conf/basic_nrf_config.yaml:/openair-smf/etc/config.yaml
        environment:
            - TZ=Europe/Paris
        depends_on:
            - oai-nrf
            - oai-amf
        networks:
            public_net:
                ipv4_address: 192.168.70.133
    oai-upf:
        container_name: "oai-upf"
        image: oaisoftwarealliance/oai-upf:v2.0.1
        expose:
            - 2152/udp
            - 8805/udp
        volumes:
            - ./conf/basic_nrf_config.yaml:/openair-upf/etc/config.yaml
        environment:
            - TZ=Europe/Paris
        depends_on:
            - oai-nrf
            - oai-smf
        cap_add:
            - NET_ADMIN
            - SYS_ADMIN
        cap_drop:
            - ALL
        privileged: true
        networks:
            public_net:
                ipv4_address: 192.168.70.134
    oai-ext-dn:
        privileged: true
        init: true
        container_name: oai-ext-dn
        image: oaisoftwarealliance/trf-gen-cn5g:latest
        entrypoint: /bin/bash -c \
              "ip route add 12.1.1.0/24 via 192.168.70.134 dev eth0; ip route; sleep infinity"
        command: ["/bin/bash", "-c", "trap : SIGTERM SIGINT; sleep infinity & wait"]
        healthcheck:
            test: /bin/bash -c "ip r | grep 12.1.1"
            interval: 10s
            timeout: 5s
            retries: 5
        networks:
            public_net:
                ipv4_address: 192.168.70.135
networks:
    public_net:
        driver: bridge
        name: demo-oai-public-net
        ipam:
            config:
                - subnet: 192.168.70.128/26
        driver_opts:
            com.docker.network.bridge.name: "demo-oai"

```

Just add the nssf and assign it an address. When I attach the gnb and the UE, it can connect successfully to the AMF. But I fail to see ANY communication between the AMF and the NSSF when I attach the UE. Is it because that there is only one smf, and there is really no choice? Or is it because that the nssf is not correctly configured? 

I am very excited. Several things are apparently going on, in my direction. Pretty exciting progress.  

First of all, let's talk about what we have changed so far about the configuration. 

1. Previously, I forgot to configure the SBI interfaces of the nssf nf. So now I add the following to basic_nrf_config.yaml. This is a huge mistake, because the nssf will not know about which port to use for its REST interface. So now I add the following lines to the file /mydata/oai-cn5g-fed/docker-compose/conf/basic_nrf_config.yaml, in the SBI section. 
```
  nssf:
    host: oai-nssf
    sbi:
      port: 8080
      api_version: v1
      interface_name: eth0
```

2. in the AMF section, we need to enable nssf NF. Otherwise, AMF will not make an attempt to connect to it. (in the same file)
```
############## NF-specific configuration
amf:
  amf_name: "OAI-AMF"
  # This really depends on if we want to keep the "mini" version or not
  support_features_options:
    enable_simple_scenario: no # "no" by default with the normal deployment scenarios with AMF/SMF/UPF/AUSF/UDM/UDR/NRF.
                               # set it to "yes" to use with the minimalist deployment scenario (including only AMF/SMF/UPF) by using the internal AUSF/UDM implemented inside AMF.
                               # There's no NRF in this scenario, SMF info is taken from "nfs" section.
    enable_nssf: yes
    enable_smf_selection: yes
```
Now I can see the amf and nssf communicate when a new UE is being attached to the network. 

3. We also want to add nssf connfiguration to the same file, so that nssf knows where to look for NSSF specific configurations. 

```
nssf:
  slice_config_path: /openair-nssf/etc/nssf_slice_config.yaml
```

4. I tweak the nssai information at the same file basic_nrf_config.yaml, and found that only when the nssai of this configuration and the nssai of the plmn in the gnb.conf matches up can the gnb connect to the core network. otherwise, the amf will not allow the connection of the gnb:

When I first change to the following (from sst 1 sd 1 to sst 1 sd 5):
```
## general single_nssai configuration
## Defines YAML anchors, which are reused in the config file
snssais:
  - &embb_slice1
    sst: 1
  - &embb_slice2
    sst: 1
    sd: 000005 # in hex
  - &custom_slice
    sst: 222
    sd: 00007B # in hex
```
the gnb cannot connect to the core network. However, when I changed the gnb conf as well to the following, the gnb can again successfully connect to the core. Basically I just add the sst 1 sd 5 to the file. 

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
                      sd  = 0x5;
                    }
                  );

                  });
```

4. I also found that the sst and sd information in the ue configutaiton of uicc0 is not completely useless. It is provided to the nssf nf for slice selection. But right now, I assume that because the nssf has not been configured correctly, the NAS message returned to the UE says that the slice 

Now the nssf is configured correctly, but the UE never received the NAS response. 

```
[NAS]   [UE 0] Received NAS_CONN_ESTABLI_CNF: errCode 1, length 102
```

My suspicion is that the smf does not get the message. Because the last NAS message was related to pdu session establishment:


```
[NAS]   Send NAS_UPLINK_DATA_REQ message(RegistrationComplete)
mac e9 39 67 db
[NAS]   Send NAS_UPLINK_DATA_REQ message(PduSessionEstablishRequest)
```

So I set the use nssf to No, and I can now correctly connect to the SMF. I think that we do not need the nssf. Just put the smf and the corresponding upf in the same configuration file, and the amd should be able to tell which smf to send to (I hope), and I can already see from the log of UPF that SMF is a peering NF with UPF, so it should not need to go through to NRF to fetch. And SMF is a peering NF for UPF (seen from the log), and SMF also has s UPF list configured. And we see such examples of 1 NRF and 2 SMF for 2 slices. 

I cannot wait to try it out. 

Setting nrf registration to no to try, because each smf is getting the right PDU request from the right UE, but a single UPF is handling all connections. Might be NRF's fault 

changing the SBI name in the conf file seems to result in unhealthy containers. 

Solution: separating config into 3 files: 1 just for amf and ausf and all the shared stuff, 1 for the common nrf and the specific SMF and UPF, and another again the NRF, UPF and SMF, for a different slice (the nrf is shared, we do not need a second nrf, as I omit the nssf here, there is no need for a nssf, and adding nssf somehow leads to errors, but that may also because of the fact that I did not spend much time on nssf)

### Problem:
why when connected to the same extdn, they began to share the same ip address the 2 UEs. 

One approach might to tweak the database file to add subscription data for PDU and to add to those entries a static ip address.

Change oai_db2.sql: 
```sql
INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES 
('208950000000031', '20895', '{\"sst\": 1, \"sd\": \"1\"}','{\"default\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"100Mbps\", \"downlink\":\"100Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.70\"}]}}');

INSERT INTO `SessionManagementSubscriptionData` (`ueid`, `servingPlmnid`, `singleNssai`, `dnnConfigurations`) VALUES 
('208950000000032', '20895', '{\"sst\": 1, \"sd\": \"5\"}','{\"default\":{\"pduSessionTypes\":{ \"defaultSessionType\": \"IPV4\"},\"sscModes\": {\"defaultSscMode\": \"SSC_MODE_1\"},\"5gQosProfile\": {\"5qi\": 6,\"arp\":{\"priorityLevel\": 1,\"preemptCap\": \"NOT_PREEMPT\",\"preemptVuln\":\"NOT_PREEMPTABLE\"},\"priorityLevel\":1},\"sessionAmbr\":{\"uplink\":\"100Mbps\", \"downlink\":\"100Mbps\"},\"staticIpAddress\":[{\"ipv4Addr\": \"12.1.1.71\"}]}}');
```

This does not seem to be working. The address is not allocated as statically as I wished. 

---
### NAT translation issue:
Be aware of this configuration of the ext dn. This may have an impact on the later parts of this experiment: 

```
 "iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE;"\
```

We do not want all packets going out of this interface to be masked with the same IP address. We then cannot differentiate and isolate them apart. So be aware. 

---

back to the same ip issue: 
change the routing of extdn:
```
        entrypoint: /bin/bash -c \
              "ip route add 12.1.1.128/25 via 192.168.70.134 dev eth0;"\
              "ip route add 12.1.1.64/26 via 192.168.70.140 dev eth0; ip route; sleep infinity"
```
UE1 will use slice 1 upf and network oai: 12.1.1.128/25
ue 2 will ues slice2 upf and network oai.ipv4: 12.1.1.64/26

These are separate network IP ranges. 
COnfig the UE uicc0 info accordingly, and run experiment: 


---
I want to furtheer verify that they go through different UPFs, with wireshark. 

I ping the first UE and UE2 in turn. And capture the ICMP packets:

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


The MAC of the ext-dn is:
```
PeterYao@node:~$ sudo docker exec -it oai-ext-dn ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
737: eth0@if738: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:a8:46:87 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.70.135/26 brd 192.168.70.191 scope global eth0
       valid_lft forever preferred_lft forever
```

MAC of UPF slice 1 is :
```
PeterYao@node:~$ sudo docker exec -it oai-upf-slice1 ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 500
    link/none
    inet 12.1.1.129/25 scope global tun0
       valid_lft forever preferred_lft forever
759: eth0@if760: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:a8:46:86 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.70.134/26 brd 192.168.70.191 scope global eth0
       valid_lft forever preferred_lft forever
```

MAC of UPF slice 2 is:
```
PeterYao@node:~$ sudo docker exec -it oai-upf-slice2 ip addr
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
2: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 500
    link/none
    inet 12.1.1.129/25 scope global tun0
       valid_lft forever preferred_lft forever
757: eth0@if758: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:c0:a8:46:8c brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.70.140/26 brd 192.168.70.191 scope global eth0
       valid_lft forever preferred_lft forever
```
MAC of GNB is:
```
PeterYao@node:~$ ip addr list demo-oai
736: demo-oai: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:b2:72:b1:b7 brd ff:ff:ff:ff:ff:ff
    inet 192.168.70.129/26 brd 192.168.70.191 scope global demo-oai
       valid_lft forever preferred_lft forever
    inet6 fe80::42:b2ff:fe72:b1b7/64 scope link
       valid_lft forever preferred_lft forever
```


Traffic path verified!
