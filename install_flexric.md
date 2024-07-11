building a new flexric on top of the original core network cloudlab profile

You would want to have at least GCC-9. The current version of GCC 7 on the cloudlab profile is just way too old to compile the flexric and OAI. Follow the instructions below:

```bash
# Add the ubuntu-toolchain-r PPA:
sudo add-apt-repository ppa:ubuntu-toolchain-r/test
sudo apt-get update
# install actually
sudo apt-get install gcc-9 g++-9
# set the new version as the default
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 60 --slave /usr/bin/g++ g++ /usr/bin/g++-9
sudo update-alternatives --config gcc
# verify the installation 
gcc --version
```


1. need to install the libpcre2-dev

```bash
sudo apt-get install libpcre2-dev
```

2. need to update the cmake to at least 3.15
```bash
sudo apt-get remove cmake
wget https://github.com/Kitware/CMake/releases/download/v3.15.7/cmake-3.15.7.tar.gz
tar -xzvf cmake-3.15.7.tar.gz
cd cmake-3.15.7
./bootstrap
# the make may take a while, accelerate that with multi threading with make -j 8, but I always forget to do that myself. O/W it is extremely slow.
make -j 8
sudo make install
# adding to the path
export PATH=/users/PeterYao/cmake-3.15.7/bin:$PATH

cmake --version

```

Probably we want newer cmake, since OAI is updating on a daily basis:
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

3. follow the commands at the flexric readme to install swig, checkout felxric, and build the file

4. run the local test suite to check if the installation is successful

```bash
ctest 
```

5. before starting the CU/DU, add the following lines to the CU configuration file at the location: /local/repository/etc/cu.conf

```
e2_agent = {
  near_ric_ip_addr = "127.0.0.1";
  sm_dir = "/usr/local/lib/flexric/"
}

```

in order to configure the E2 agent. 

6. Do the same thing for the DU, add the same block to the DU configuration file at location /local/repository/etc/du.conf

7. Because we follow a CU/DU split, bring up the CU/DU as follows:
```bash
cd /opt/openairinterface5g/cmake_targets/
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem --rfsim --sa -O /local/repository/etc/cu.conf

cd /opt/openairinterface5g/cmake_targets/
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem --rfsim --sa -O /local/repository/etc/du.conf
```

8. In another windows, Start the UE
```bash
cd /opt/openairinterface5g/cmake_targets
sudo RFSIMULATOR=127.0.0.1 ./ran_build/build/nr-uesoftmodem -O /local/repository/etc/ue.conf -r 106 -C 3619200000 --sa --nokrnmod --numerology 1 --band 78 --rfsim --rfsimulator.options chanmod
```

9. After running the RIC and the xApp with the following commands, an assertion failure occurs. 
```bash
cd flexric
./build/examples/ric/nearRT-RIC
./build/examples/xApp/c/monitor/xapp_kpm_moni
```

nearRT-RIC: /users/PeterYao/flexric/src/lib/e2ap/v2_03/enc/e2ap_msg_enc_asn.c:3165: e2ap_enc_e42_setup_response_asn_pdu: Assertion `sr->len_e2_nodes_conn > 0 && "No global node conected??"' failed.
Aborted

The RIC crashes after trying to start the Service Model. Based on the error message, suspect that the e2 nodes are not attached successfully. 

10. It turns out that the OAI RAN version is just too old to support E2 interface. We need to reinstall the latest version from source. 

```bash
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git

# install all dependencies
cd openairinterface5g/cmake_targets/

# but before that we want the UHD package to be of correct version. If we just pull the latest version, the build is not going to be successful
export BUILD_UHD_FROM_SOURCE=True
export UHD_VERSION=3.15.0.0
./build_oai -I -w USRP

# I did not install the new asn1c from source

# build the physical simulators (this part can be extremely lengthy)
cd openairinterface5g/cmake_targets/
./build_oai --phy_simulators

# we also need to build the base stations and the UEs
cd openairinterface5g/cmake_targets/
./build_oai -w USRP --eNB --UE --nrUE --gNB


```

It turns out that the d430 node on emulab does not have enough storage for compilation. I am now swithing to the d820 node. And Gosh, it is taking forever to boot that machine. We need to rebuild the cmake and the gcc after the new machine boots up. 

It turns out that event he d820 node does not have enough space.   
To turn around the situation, we should really allocate enough space at the beginning, and then compile and do everything in the newly mounted space  

```bash
# check how much space has been mounted
df -h
# allocate space during the experiment
cd /
sudo mkdir mydata
sudo /usr/local/etc/emulab/mkextrafs.pl /mydata
# check space usage again
df -h

# change the ownership of this new space
sudo chown PeterYao:nyunetworks mydata

chmod 775 mydata

# verify the result
ls -ld mydata
```

You should see something like this  

drwxrwxr-x 4 PeterYao nyunetworks 4096 Jun 18 14:55 mydata

Then redownload the OAI RAN repo, and recompile it again inside mydata.  

```bash
cd mydata
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git
```

My observation is that after starting the monolithic gnb using the command:

```bash
# from https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/NR_SA_Tutorial_OAI_nrUE.md
sudo ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.usrpb210.conf --gNBs.[0].min_rxtxtime 6 --rfsim --sa
# or this from https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/openair2/E2AP/README.md#223-installation-of-service-models-sms
sudo ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.usrpb210.conf --rfsim --sa -E
```
the core network does not seem to register this gNB, with output like this:

![屏幕截图 2024-06-19 084841](https://i.imgur.com/3uBNBaB.jpeg)

This is weird, because the core network should have registered the device. 

Try again by bringing up the core network according to the tutorial. 

https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/NR_SA_Tutorial_OAI_CN5G.md

Shut down the original core network with 

```bash
cd /opt/oai-cn5g-fed/docker-compose  

sudo python3 ./core-network.py --type stop-basic --scenario 1
```
check with sudo docker ps  

Alright, here is what I did:
1. Start the core network latest version following instructions from https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/NR_SA_Tutorial_OAI_CN5G.md#21-oai-cn5g-pre-requisites and brings up the dockerized core network containers. 

2. start the monolithic Gnb and UE following instructions from https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/doc/RUNMODEM.md#launch-gnb. Brings them up with RF simulators with the commands:
```bash
sudo ./nr-softmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/gnb.sa.band78.fr1.106PRB.usrpb210.conf --gNBs.[0].min_rxtxtime 6 --rfsim --sa
sudo ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --ssb 516 --rfsim --sa
```  

One can verify that the both the gnb and the UE have been connected to the core network from the AMF log:
![屏幕截图 2024-06-19 105542](/assets/屏幕截图%202024-06-19%20105542.png)

One can also check that in the configuration, the e2 agent information has already been incorporated into gnb configuration file. 

![屏幕截图 2024-06-19 110110](/assets/屏幕截图%202024-06-19%20110110.png)

3. Brings up the Flexric and xapp following the guide at https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/openair2/E2AP/README.md
with the commands:
```bash
# brings up flexric first 
cd flexric
./build/examples/xApp/c/monitor/xapp_kpm_moni
# brings up xapp
./build/examples/xApp/c/monitor/xapp_rc_moni
```
the flexric still crashed immediately
![屏幕截图 2024-06-19 110437](/assets/屏幕截图%202024-06-19%20110437.png)







