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
RIC stands for RAN Intelligent Controller. It is a key component in the Open RAN (O-RAN) architecture, aimed at enhancing the management and optimization of the Radio Access Network (RAN). It can give near real-time instructions and policy changes to the base station.

### xAPP (external applications)
An xApp is an additional process that runs on the RAN Intelligent Controller (RIC) within an O-RAN architecture. xApps are designed to provide specific functionalities for managing and optimizing the Radio Access Network (RAN).

To understand, you should read the [Explore RAN](https://witestlab.poly.edu/blog/exploring-the-5g-ran/) and [Explore Core](https://witestlab.poly.edu/blog/exploring-the-5g-core-network/) passages, and understand the functionality of different Network Functions(NFs) in the core, as well as some basic concepts in RAN (e.g. What is a gNB, UE...). You willneed to have a basic understanding of O-RAN, esp the RIC part and xAPP. The original [FlexRIC paper](https://dl.acm.org/doi/10.1145/3485983.3494870) will be a good starting point. 


We run our experiemnts on POWDER Testbed. For this experiment, you will need one d430-type server on the Emulab cluster. Since you are reserving an entire bare-metal server, you should:

+ set aside time to work on this lab. You should reserve 6-12 hours (depending on how conservative you want to be) - the lab should not take that long, but this will give you some extra time in case you run into any issues.
+ reserve a d430 server for that time at least a few days in advance
+ and during your reserved time, complete the entire lab assignment in one sitting.


### Instantiate a Profile
Instantiate this profile, as it has most of the software that we would probably need already installed. 

https://www.powderwireless.net/p/244cecf4e88b119a16e5fb7d3fa5bf0a91a571a2

In the default setting, you will not have enough storage allocated on the Emulab cluster. The default 16G storage is not enoguh. You need to mount a new file system, and download and install everything in that folder.

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

```bash
drwxrwxr-x 4 PeterYao nyunetworks 4096 Jun 18 14:55 mydata
```

You will need to clone a more recent OpenAirInterface RAN reposotory, as the older version does not have support for E2AP interface, which is necessary for communication between the flexric and the gnb. 

### Install the prerequisites
To compile the OAI RAN, we need newer versions of cmake and gcc. 

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

You need to install the libpcre2-dev

```bash
sudo apt-get install libpcre2-dev
```

Add 
```
e2_agent = {
  near_ric_ip_addr = "127.0.0.1";
  sm_dir = "/usr/local/lib/flexric/";
}
```
to the end of this file
```
/local/repository/etc/gnb.conf
```

Before we compile the OAI and flexric, first clone them, then checkout the right versions of it, so that they are at commit version where NVS and slicing are actually partially supported. 

```bash
# you are at /mydata

git clone https://gitlab.eurecom.fr/mosaic5g/flexric.git
cd flexric/
git checkout rc_slice_xapp

# for oai, first git clone the latest version
git clone https://gitlab.eurecom.fr/oai/openairinterface5g.git
cd openairinterface5g
git checkout rebased-5g-nvs-rc-rf
cd cmake_targets
```

***Optional***  And if you want to capture E2AP packets, i.e. the communication between gnb and flexric, you would need a newer version of tshark to analyze these packets:

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
```
export PATH=/usr/local/bin:$PATH
tshark -v
```
```
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


### Compile the Code

Go inside the OAI repo, find the function with this name and replace it with the following code before compiling the whole OAI. This function is invoked when a slice is added to the base station, and it is associating existing UEs with newly added slices. The general rule is that the first UE is associated with the first slice, while the second UE with the second slice. The OAI support for slicing is partial and not out-of-the-box, so we need to adapt it to our own needs, which is to associate two UEs at one gNB to 2 different slices. 

```c
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

Compile the OAI Code:
```bash
cd cmake_targets
./build_oai -c -C -I -w SIMU --gNB --nrUE --build-e2 --ninja
```

Compile the Flexric Code, please follow the instructions at the [flexric's gitlab page](https://gitlab.eurecom.fr/mosaic5g/flexrichttps://gitlab.eurecom.fr/mosaic5g/flexric). Please install the SWIG interface per instructions, and then compile the FlexRIC that we just checked out.

### Initial RAN Slicing test
First please bring up the core network. And also bring up the gnb. 


```bash
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /local/repository/etc/gnb.conf --sa --rfsim
```

You would also need to bring up the flexric. 

```bash
cd /mydata/flexric/
./build/examples/ric/nearRT-RIC
```


To attach two UEs to the same gnb, we will need some extra work to isolate them into 2 different subnets. This [tutorial](https://gitlab.eurecom.fr/oaiworkshop/summerworkshop2023/-/tree/main/ran#multiple-ues) provides a useful guide. Pleas clone it. 

You would probably want two ue configuration file:
ue.conf
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

ue2.conf:
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


To attach the first UE. 
```bash
sudo ~/summerworkshop2023/ran/multi-ue.sh -c1 -e
sudo ip netns exec ue1 bash
#  go back to the oai cmake_targets folder. 
sudo RFSIMULATOR=10.201.1.100 ./ran_build/build/nr-uesoftmodem -O /local/repository/etc/ue.conf -r 106 -C 3619200000 --sa --nokrnmod --numerology 1 --band 78 --rfsim --rfsimulator.options chanmod
```
Check the AMF log that it is attached correctly. 

Then attach the second UE to the gnb:
```bash
sudo /mydata/summerworkshop2023/ran/multi-ue.sh -c3 -e
sudo ip netns exec ue3 bash
#  go back to the oai cmake_targets folder. 
sudo RFSIMULATOR=10.203.1.100 ./ran_build/build/nr-uesoftmodem -O /local/repository/etc/ue2.conf -r 106 -C 3619200000 --sa --nokrnmod --numerology 1 --band 78 --rfsim --rfsimulator.options chanmod
```

We can verify that both ue is connected to the gnb successfully and can be ping through normally.

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
ip addr list
[OIP]   Interface oaitun_ue1 successfully configured, ip address 12.1.1.156, mask 255.255.255.0 broadcast address 12.1.1.255

<!-- a different UE -->
# UE2 terminal session
[OIP]   Interface oaitun_ue1 successfully configured, ip address 12.1.1.155, mask 255.255.255.0 broadcast address 12.1.1.255
```

Try pinging the two different UEs:
```
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

Then we apply RAN Slicing. 

```bash
cd /mydata/flexric
./build/examples/xApp/c/ctrl/xapp_rc_slice_ctrl
```

> Question:
What outcome did you see in the gnb session when you run the slicing xapp? Please submit a screenshot, and explain the implications. 


### Verify RAN Slicing with iPerf
Get the IP address of the first UE, in my case it is 12.1.1.155
```bash
sudo ip netns exec ue1 bash
ip addr list
```
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

>Question
Repeat this for the second UE. Submit screenshots. Explain the difference in the throughput (Explain how the RAN Slicing impact the throughput). 





### Core Slicing
Having done the RAN Slicing successfully, we are now ready to do the Core slicing with OAI. We aim to reproduce this core network:

![屏幕截图 2024-07-16 162905](/assets/屏幕截图%202024-07-16%20162905.png)


Please download the following files from [this github repo](https://github.com/PeterYaoNYU/5G-E2E-Wireless-Notes-OAI/tree/main/core-slice-conf): 

- docker-compose-basic-nrf.yaml is a docker compose file that brings up all the network functions in one command. 
- basic_nrf_config.yaml is the configuration file for the AMF
- the other 2 conf files are for the configuration of the respective slices, the SMF and UPF. 

Copy these files into the respective folder. Replace the original files if necessary.

+ copy the docker compose file into /mydata/oai-cn5g-fed/docker-compose

+ copy the other configuration files into /mydata/oai-cn5g-fed/docker-compose/conf


Note that we do not use an NSSF here, as that is only necessary for the multiple NRF case. 

The slices that we are adding are sst 1 sd 1 and sst 1 sd 5. So we need to configure that in the gnb.conf at /local/repository/etc. 

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

Theoretically, you should configure the UE configurations as well, but we havealready done that in the RAN Slicing part. Some general principles would be:

+ The SST SD is among those provided by the gNB ***AND*** the Core network AMF, otherwise the connection will berejected for sure

+ The UE imsi and keychain should match up with the user database, so that it can authenticate. 

Then we bring up the core network, and the gnb, and in the respective SSH sessions, we bring up the two UEs. You should also monitor the logs for AMF, two SMFs, and 2 UPFs. 

```bash
# core network
cd /mydata/oai-cn5g-fed/docker-compose  
sudo python3 ./core-network.py --type start-basic --scenario 1

# if the containers are not healthy, shut down and retry. It should ahppen very rarely
sudo python3 ./core-network.py --type stop-basic --scenario 1

# base station
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /local/repository/etc/gnb.conf --sa --rfsim

# In another SSH session, start the first UE:

cd /mydata/openairinterface/cmake_targets
sudo ip netns exec ue1 bash
sudo RFSIMULATOR=10.201.1.100 ./ran_build/build/nr-uesoftmodem -O /local/repository/etc/ue.conf -r 106 -C 3619200000 --sa --nokrnmod --numerology 1 --band 78 --rfsim --rfsimulator.options chanmod

# in yet another session, start the second UE:
udo ip netns exec ue3 bash
sudo RFSIMULATOR=10.203.1.100 ./ran_build/build/nr-uesoftmodem -O /local/repository/etc/ue2.conf -r 106 -C 3619200000 --sa --nokrnmod --numerology 1 --band 78 --rfsim --rfsimulator.options chanmod

```

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
PeterYao@node:~$ sudo docker exec -it oai-ext-dn ip addr
# for UPF1, in the UE1 SSH session
PeterYao@node:~$ sudo docker exec -it oai-upf-slice1 ip addr
# for UPF2, in the UE2 SSH session
PeterYao@node:~$ sudo docker exec -it oai-upf-slice2 ip addr
# for the gnb
PeterYao@node:~$ ip addr list demo-oai
```

And you should be able to verify that they go through different datapaths, accoding to how the slice is configured. 

> Question
Look into the conf files and docker compose files that you copied into the core network folder, and explain how the core network is setup in the way as depicted in the picture? [This tutorial](https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/CONFIGURATION.md) may help you understand the different parameters.

>Question 
Repeat those verification steps on your own machine (the second appraoch), and submit screenshots of ping path, and MAC addresses of different interfaces. Make sure that it is as you would expect. 

### Final step for end-to-end slicing
First do the core slicing, then bring in the xapp to enforce slicing. Then you will have slicing at both the RAN MAC layer and the core layer. 

## References:
[1] Robert Schmidt, Mikel Irazabal, and Navid Nikaein. 2021. FlexRIC: an SDK for next-generation SD-RANs. In Proceedings of the 17th International Conference on emerging Networking EXperiments and Technologies (CoNEXT '21). Association for Computing Machinery, New York, NY, USA, 411–425. https://doi.org/10.1145/3485983.3494870


