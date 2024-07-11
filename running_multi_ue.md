### Running multiple UEs

This is a note on how to run multiple UE within a single RAN. We want to do the same for the FlexRIC as well. 

Assume that the core network is already up and you are watching the AMF log with the command

```
sudo docker logs -f oai-amf  
```


first start a gNB
```
cd /mydata/openairinterface5g/cmake_targets
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /local/repository/etc/gnb.conf --sa --rfsim
```

Then start one UE:
```
sudo ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --rfsim --sa --uicc0.imsi 001010000000001 --rfsimulator.serveraddr 127.0.0.1
```

Then start another UE. Keep everything else the same, but vary the IMSI number

```
sudo ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --rfsim --sa --uicc0.imsi 001010000000003 --rfsimulator.serveraddr 127.0.0.1
```

And then we can verify from the AMF log that indeed 2 UEs are running 

```
[2024-06-23T16:25:40.335688] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-23T16:25:40.335696] [AMF] [amf_app] [info ] |----------------------------------------------------gNBs' information-------------------------------------------|
[2024-06-23T16:25:40.335703] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2024-06-23T16:25:40.335714] [AMF] [amf_app] [info ] |      1      |    Connected     |         0xe000       |         gNB-Eurecom-5GNRBox        |            208, 95             | 
[2024-06-23T16:25:40.335722] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-23T16:25:40.335728] [AMF] [amf_app] [info ] 
[2024-06-23T16:25:40.335733] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-23T16:25:40.335739] [AMF] [amf_app] [info ] |----------------------------------------------------UEs' information--------------------------------------------|
[2024-06-23T16:25:40.335745] [AMF] [amf_app] [info ] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |Cell ID|
[2024-06-23T16:25:40.335755] [AMF] [amf_app] [info ] |      1|    5GMM-REG-INITIATED|   001010000000001|               |               1|          8| 208, 95 |14680064|
[2024-06-23T16:25:40.335764] [AMF] [amf_app] [info ] |      2|    5GMM-REG-INITIATED|   001010000000003|               |               2|          9| 208, 95 |14680064|
[2024-06-23T16:25:40.335773] [AMF] [amf_app] [info ] |      3|     5GMM-DEREGISTERED|     2089900007487|               |               1|          1| 208, 95 |14680064|
[2024-06-23T16:25:40.335780] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-23T16:25:40.335786] [AMF] [amf_app] [info ] 
```

Then we start the flexric:
```
./build/examples/ric/nearRT-RIC
```

And no bug is reported. 

I want to tweak the order of starting. First gNB, then flexRIC, then 2 UEs. And it still works fine. 

### Accidentally deleting the docker images when clearing away space, had to start anew. Problems with building phy simulator. 

I guess another question that needs to be answered is whether we can run multiple gNB on the same core network. This afternoon, before I accidently delete the docker images in order to clear some space, and have to start a new instance, I had managed to run 2 gnb on a single core net. The problem seems to be that they share the same cell ID. I need to reproduce that problem. 

Further, I am having some trouble builidng the phy simualtor on the new instance. I am thinking that this might not be relevant to what we are interested in. 


```
PeterYao@node:/mydata/openairinterface5g/cmake_targets$ ./build_oai --phy_simulators
..
--
collect2: error: ld returned 1 exit status
ninja: build stopped: subcommand failed.
ERROR: 3 error. See /mydata/openairinterface5g/cmake_targets/log/all.txt
compilation of dlsim ulsim ldpctest polartest smallblocktest nr_pbchsim nr_dlschsim nr_ulschsim nr_dlsim nr_ulsim nr_pucchsim nr_prachsim nr_psbchsim params_libconfig coding rfsimulator dfts failed
build have failed
```

Fine, I know that this is a linker problem. But I am not sure which part is missing from the log. I hope this does not matter, because I didn't see the phy simualtor built in the tutorial. I do not know what it is. But I do think that on the last instance, the build process was successful. 

### running multiple gnb cells. 

Let me get back to the issue of running multiple gnb in a core. So far I did not see a use case, but it needs to be handled eventually I assume. 

I tweak the conf file a little. The way I tweak it will be shown later. But for now there are 2 problems:

1. On the second gNB I see this:
```
got sync (ru_thread)
[HW]   bind() failed, errno(98)
[HW]   Could not start the RF device
[PHY]   RU 0 RF started opp_enabled 0
[HW]   No connected device, generating void samples...
[PHY]   Command line parameters for the UE: -C 3619200000 -r 106 --numerology 1 --ssb 516
```

the two lines of HW were in red, indicating an error that does not exist when starting the first gnb:

```
<!-- from first gnb -->
waiting for sync (L1_stats_thread,0/0x558fa75370ac,0x558fa8e7c760,0x558fa8e7ba60)
got sync (L1_stats_thread)
got sync (ru_thread)
[PHY]   RU 0 rf device ready
[PHY]   RU 0 RF started opp_enabled 0
[HW]   No connected device, generating void samples...
```

But it seems that the core network at least got the message that there are 2 gnbs attached

```
[2024-06-24T01:20:16.744976] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-24T01:20:16.744985] [AMF] [amf_app] [info ] |----------------------------------------------------gNBs' information-------------------------------------------|
[2024-06-24T01:20:16.744992] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2024-06-24T01:20:16.745005] [AMF] [amf_app] [info ] |      1      |    Connected     |         0xe000       |         gNB-Eurecom-5GNRBox        |            208, 95             |
[2024-06-24T01:20:16.745014] [AMF] [amf_app] [info ] |      2      |    Connected     |         0xe010       |         gNB-Eurecom-5GNRBox        |            208, 95             |
[2024-06-24T01:20:16.745021] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-24T01:20:16.745027] [AMF] [amf_app] [info ]
[2024-06-24T01:20:16.745033] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-24T01:20:16.745039] [AMF] [amf_app] [info ] |----------------------------------------------------UEs' information--------------------------------------------|
[2024-06-24T01:20:16.745046] [AMF] [amf_app] [info ] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |Cell ID|
[2024-06-24T01:20:16.745052] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-24T01:20:16.745059] [AMF] [amf_app] [info ]
```

This is how I tweak the gnb conf.

```bash
# gnode id is changed 
    ////////// Identification parameters:
    gNB_ID    =  0xe01;
    gNB_name  =  "gNB-Eurecom-5GNRBox";

# physical cell id is changed
# though I think that it will still work without changing this 
# I just think that different gnb should be in difference cells. 
      physCellId                                                    = 1;

# the ru band is changed from 78 to 80, though it will work without changing that

RUs = (
    {
       local_rf       = "yes"
         nb_tx          = 1
         nb_rx          = 1
         att_tx         = 0
         att_rx         = 0;
         bands          = [80];
         max_pdschReferenceSignalPower = -27;
         max_rxgain                    = 114;
         eNB_instances  = [0];
         #beamforming 1x4 matrix:
         bf_weights = [0x00007fff, 0x0000, 0x0000, 0x0000];
         clock_src = "internal";
    }
);

# the probably most relevant part, rfsim conf, is not changed at all
rfsimulator :
{
    serveraddr = "server";
    serverport = "4043";
    options = (); #("saviq"); or/and "chanmod"
    modelname = "AWGN";
    IQfile = "/tmp/rfsimulator.iqs";
};

# though I do not understand why an address of "server" could provide any meaningful inforomation:q
```

2. I really don't know how to configure which gnb a UE should attach to. It just attaches to the first gnb when I run the command

```bash
sudo ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --ssb 516 --rfsim --sa
```

But I mean, the second gnb also tells me to run with the arguments: 

```
[PHY]   Command line parameters for the UE: -C 3619200000 -r 106 --numerology 1 --ssb 516
```
which is the same. 

### Reproducing the TC example that might be of interest

2 difficulties to reproduce. We need to actually generate traffic. I also need one of them to be backlogged using iperf, according to the paper, so that the pacer and the queue split can actually be triggered. 

