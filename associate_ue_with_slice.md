Regarding the issue of logging level in RAN, I think there are multiple log level that we can choose, based on the definition in this file.

>common/utils/LOG/log.h

Based on the ioformaition provided, the logging level in OAI is a runtime feature. Rather than choosing it at compile time, you choose it at runtime with the config file. Take gnb.conf from /local/repository/etc/gnb.conf

```
     log_config :
     {
       global_log_level                      ="info";
       global_log_verbosity                  ="medium";
       hw_log_level                          ="info";
       hw_log_verbosity                      ="medium";
       phy_log_level                         ="info";
       phy_log_verbosity                     ="medium";
       mac_log_level                         ="info";
       mac_log_verbosity                     ="high";
       rlc_log_level                         ="info";
       rlc_log_verbosity                     ="medium";
       pdcp_log_level                        ="info";
       pdcp_log_verbosity                    ="medium";
       rrc_log_level                         ="info";
       rrc_log_verbosity                     ="medium";
       ngap_log_level                         ="debug";
       ngap_log_verbosity                     ="medium";
    }
```


specific instructions can be found here:
https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/develop/common/utils/LOG/DOC/rtusage.md 

Looking at the code, I am beginning to worry if slicing at MAC layer is indeed supported with the 5g base station, but only with the 4g lte base station eNB. 

Clue 1:
https://gitlab.eurecom.fr/oai/openairinterface5g/-/issues/607
But that was from one year ago. I can see there has been recent commit with slicing. 

Clue 2:
Slicing support for 5g is available in this request
https://gitlab.eurecom.fr/oai/openairinterface5g/-/merge_requests/2458

But it seems that it has not been merged to the latest version? 

Anyway, I decide to try before making further comment and/or changing the code. 

Start the core:

```
cd /opt/oai-cn5g-fed/docker-compose  
sudo python3 ./core-network.py --type start-basic --scenario 1   

sudo python3 ./core-network.py --type stop-basic --scenario 1
```

Weird thing today, I keep getting th enhealthy sign no matter how many times I start and stop the core network. Even after the restart the whole machine. 

I guess I can live with the fact that we use the latest 5g core. After all, we still need the latest version to support a slicing core network. The current version does not really have a NSSF included. 

Fine, I found the reason. The reason being that there is not enough storage on the device. I have got to figure out a way to enlarge the default directory someday. It feels like living in a small apartment. 

Monitor the AMF log:
```
sudo docker logs -f oai-amf  
```

Because I lost the gnb.conf for reasons I don't know, I put it somewhere else, and start the gnb. 

```
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /mydata/gnb.conf --sa --rfsim
```

Check that the flexric is running successfully, and that the address is 127.0.0.10 for easier logging purposes. 

```
PeterYao@node:/mydata/flexric$ ./build/examples/ric/nearRT-RIC
[UTIL]: Setting the config -c file to /usr/local/etc/flexric/flexric.conf
[UTIL]: Setting path -p for the shared libraries to /usr/local/lib/flexric/
[NEAR-RIC]: nearRT-RIC IP Address = 127.0.0.10, PORT = 36421
[NEAR-RIC]: Initializing
[NEAR-RIC]: Loading SM ID = 142 with def = MAC_STATS_V0
[NEAR-RIC]: Loading SM ID = 146 with def = TC_STATS_V0
[NEAR-RIC]: Loading SM ID = 148 with def = GTP_STATS_V0
[NEAR-RIC]: Loading SM ID = 2 with def = ORAN-E2SM-KPM
[NEAR-RIC]: Loading SM ID = 143 with def = RLC_STATS_V0
[NEAR-RIC]: Loading SM ID = 3 with def = ORAN-E2SM-RC
[NEAR-RIC]: Loading SM ID = 145 with def = SLICE_STATS_V0
[NEAR-RIC]: Loading SM ID = 144 with def = PDCP_STATS_V0
[iApp]: Initializing ...
[iApp]: nearRT-RIC IP Address = 127.0.0.10, PORT = 36422
[NEAR-RIC]: Initializing Task Manager with 2 threads
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

and that the base station is also running correctly. 

```
[2024-06-29T22:40:12.179058] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-29T22:40:12.179067] [AMF] [amf_app] [info ] |----------------------------------------------------gNBs' information-------------------------------------------|
[2024-06-29T22:40:12.179074] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2024-06-29T22:40:12.179088] [AMF] [amf_app] [info ] |      1      |    Connected     |         0xe000       |         gNB-Eurecom-5GNRBox        |            208, 95             |
[2024-06-29T22:40:12.179097] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-29T22:40:12.179103] [AMF] [amf_app] [info ]
[2024-06-29T22:40:12.179109] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-29T22:40:12.179116] [AMF] [amf_app] [info ] |----------------------------------------------------UEs' information--------------------------------------------|
[2024-06-29T22:40:12.179122] [AMF] [amf_app] [info ] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |Cell ID|
[2024-06-29T22:40:12.179129] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-29T22:40:12.179135] [AMF] [amf_app] [info ]
``` 

Start 1 UE. Actually I want to begin with something easier, so we will start 1 UE first, and then associate it with one slice with the flexric code. Then we will move on to the 2 UE case. 

Verify that the UE is indeed connected. 
```
[2024-06-29T22:43:32.180951] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-29T22:43:32.180960] [AMF] [amf_app] [info ] |----------------------------------------------------gNBs' information-------------------------------------------|
[2024-06-29T22:43:32.180994] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2024-06-29T22:43:32.181024] [AMF] [amf_app] [info ] |      1      |    Connected     |         0xe000       |         gNB-Eurecom-5GNRBox        |            208, 95             |
[2024-06-29T22:43:32.181042] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-29T22:43:32.181053] [AMF] [amf_app] [info ]
[2024-06-29T22:43:32.181062] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-29T22:43:32.181072] [AMF] [amf_app] [info ] |----------------------------------------------------UEs' information--------------------------------------------|
[2024-06-29T22:43:32.181082] [AMF] [amf_app] [info ] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |Cell ID|
[2024-06-29T22:43:32.181099] [AMF] [amf_app] [info ] |      1|    5GMM-REG-INITIATED|   001010000000001|               |               1|          1| 208, 95 |14680064|
[2024-06-29T22:43:32.181113] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-29T22:43:32.181123] [AMF] [amf_app] [info ]
```

Next, let's see how to associate that UE with a particular slice. 

I noticed one comment while looking at the code
```c 
static
void fill_add_mod_slice(slice_conf_t* add)
{
  assert(add != NULL);

  uint32_t set_len_slices = 0;
  uint32_t set_slice_id[] = {0, 2, 5};
  char* set_label[] = {"s1", "s2", "s3"};
  /// NVS/EDF slice are only supported by OAI eNB ///
  slice_algorithm_e set_type = SLICE_ALG_SM_V0_STATIC;
  //slice_algorithm_e set_type = SLICE_ALG_SM_V0_NVS;
  //slice_algorithm_e set_type = SLICE_ALG_SM_V0_EDF;
  //slice_algorithm_e set_type = SLICE_ALG_SM_V0_NONE;
```

It seems that NVS and EDF is only supported with 4G base stations. I am assuming that implementing it will not be too much trouble (because I did it before) but it might be time consuming because I need to get familiar with OAI MAC code. Let's demo with static slicing for now. 

One thing that I do not know how to solve is that the RNTI is changing all the time, making it really hard for me to associate a static UE with a slice, because even for that one UE, its RNTI is changing all the time?  

Okay, here is what I found out after digging into the log.

Be assured that right now there is no UE connected to the base station, here is the AMF log:

```
[2024-06-30T14:39:32.693310] [AMF] [amf_app] [info ]
[2024-06-30T14:39:32.693354] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-30T14:39:32.693364] [AMF] [amf_app] [info ] |----------------------------------------------------gNBs' information-------------------------------------------|
[2024-06-30T14:39:32.693371] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2024-06-30T14:39:32.693385] [AMF] [amf_app] [info ] |      1      |    Connected     |         0xe000       |         gNB-Eurecom-5GNRBox        |            208, 95             |
[2024-06-30T14:39:32.693393] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-30T14:39:32.693400] [AMF] [amf_app] [info ]
[2024-06-30T14:39:32.693406] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-30T14:39:32.693412] [AMF] [amf_app] [info ] |----------------------------------------------------UEs' information--------------------------------------------|
[2024-06-30T14:39:32.693418] [AMF] [amf_app] [info ] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |Cell ID|
[2024-06-30T14:39:32.693431] [AMF] [amf_app] [info ] |      1|     5GMM-DEREGISTERED|   001010000000001|               |               1|          3| 208, 95 |14680064|
[2024-06-30T14:39:32.693439] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-30T14:39:32.693445] [AMF] [amf_app] [info ]
```


One can verify that the gnb is connected, but the UE is disconnected. 

Then we run the slice ctrl xapp. To see what is going on, I remove all the control code, keeping only the indication messages, and then adding the printing module to log down the information of the indication messages. Here is the modified code:

```c
/*
 * Licensed to the OpenAirInterface (OAI) Software Alliance under one or more
 * contributor license agreements.  See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The OpenAirInterface Software Alliance licenses this file to You under
 * the OAI Public License, Version 1.1  (the "License"); you may not use this file
 * except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.openairinterface.org/?page_id=698
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *-------------------------------------------------------------------------------
 * For more information about the OpenAirInterface (OAI) Software Alliance:
 *      contact@openairinterface.org
 */

#include "../../../../src/xApp/e42_xapp_api.h"
#include "../../../../src/util/alg_ds/alg/defer.h"
#include "../../../../src/util/time_now_us.h"

#include "../../../../src/sm/slice_sm/slice_sm_id.h"

#include <stdatomic.h>
#include <stdlib.h>
#include <stdio.h>
#include <time.h>
#include <unistd.h>

_Atomic
uint16_t assoc_rnti = 0;

void to_string_slice(slice_ind_msg_t const* slice, int64_t tstamp, char* out, size_t out_len)
{
  assert(slice != NULL);
  assert(out != NULL);
  const size_t max = 2048;
  assert(out_len >= max);

  char temp[2048] = {0};
  size_t sz = 0;

  if (slice->slice_conf.dl.len_slices == 0) {
    int rc = snprintf(temp, out_len,  "slice_stats: "
                      "tstamp=%ld"
                      ",dl->sched_name=%s"
                      , tstamp
                      , slice->slice_conf.dl.sched_name
                      );
    assert(rc < (int)max && "Not enough space in the char array to write all the data");

    memcpy(out, temp, strlen(temp));
    sz += strlen(temp);
  }

  for(uint32_t i = 0; i < slice->slice_conf.dl.len_slices; ++i) {
    fr_slice_t* s = &slice->slice_conf.dl.slices[i];

    if (i == 0) {
      int rc = snprintf(temp, out_len, "slice_stats: tstamp=%ld,slice_conf,dl,len_slices=%u", tstamp, slice->slice_conf.dl.len_slices);
      assert(rc < (int)max && "Not enough space in the char array to write all the data");

      memcpy(out, temp, strlen(temp));
      sz += strlen(temp);
    }

    memset(temp, 0, sizeof(temp));
    // static
    if (s->params.type == SLICE_ALG_SM_V0_STATIC) {
      int rc = snprintf(temp, out_len,
                        ",slice[%u]"
                        ",id=%u"
                        ",label=%s"
                        ",type=%d,static"
                        ",sched=%s"
                        ",pos_high=%u"
                        ",pos_low=%u",
                        i,
                        s->id,
                        s->label,
                        s->params.type,
                        s->sched,
                        s->params.u.sta.pos_high,
                        s->params.u.sta.pos_low);
      assert(rc < (int)max && "Not enough space in the char array to write all the data");
    } else if (s->params.type == SLICE_ALG_SM_V0_NVS) {
      // nvs
      if (s->params.u.nvs.conf == SLICE_SM_NVS_V0_RATE) {
         int rc = snprintf(temp, out_len,
                        ",slice[%u]"
                        ",id=%u"
                        ",label=%s"
                        ",type=%d,nvs"
                        ",sched=%s"
                        ",conf=%d,rate"
                        ",mbps_required=%.2f"
                        ",mbps_reference=%.2f",
                        i,
                        s->id,
                        s->label,
                        s->params.type,
                        s->sched,
                        s->params.u.nvs.conf,
                        s->params.u.nvs.u.rate.u1.mbps_required,
                        s->params.u.nvs.u.rate.u2.mbps_reference);
        assert(rc < (int)max && "Not enough space in the char array to write all the data");
      } else if (s->params.u.nvs.conf == SLICE_SM_NVS_V0_CAPACITY) {
        int rc = snprintf(temp, out_len,
                          ",slice[%u]"
                          ",id=%u"
                          ",label=%s"
                          ",type=%d,nvs"
                          ",sched=%s"
                          ",conf=%d,capacity"
                          ",pct_reserved=%.2f",
                          i,
                          s->id,
                          s->label,
                          s->params.type,
                          s->sched,
                          s->params.u.nvs.conf,
                          s->params.u.nvs.u.capacity.u.pct_reserved);
        assert(rc < (int)max && "Not enough space in the char array to write all the data");
      }
    } else if (s->params.type == SLICE_ALG_SM_V0_EDF) {
      // edf
      int rc = snprintf(temp, out_len,
                        ",slice[%u]"
                        ",id=%u"
                        ",label=%s"
                        ",type=%d,edf"
                        ",sched=%s"
                        ",deadline=%u"
                        ",guaranteed_prbs=%u"
                        ",max_replenish=%u",
                        i,
                        s->id,
                        s->label,
                        s->params.type,
                        s->sched,
                        s->params.u.edf.deadline,
                        s->params.u.edf.guaranteed_prbs,
                        s->params.u.edf.max_replenish);
      // TODO: edf.len_over & edf.over[]
      assert(rc < (int)max && "Not enough space in the char array to write all the data");
    }
    memcpy(out + sz, temp, strlen(temp));
    sz += strlen(temp);
  }

  for(uint32_t i = 0; i < slice->ue_slice_conf.len_ue_slice; ++i) {
    ue_slice_assoc_t * u = &slice->ue_slice_conf.ues[i];

    if (i == 0) {
      memset(temp, 0, sizeof(temp));
      int rc = snprintf(temp, out_len, ",ue_slice_conf,len_ue_slice=%u", slice->ue_slice_conf.len_ue_slice);
      assert(rc < (int)max && "Not enough space in the char array to write all the data");

      memcpy(out + sz, temp, strlen(temp));
      sz += strlen(temp);
    }

    memset(temp, 0, sizeof(temp));
    int rc = snprintf(temp, out_len,
                      ",ues[%u]"
                      ",rnti=%x"
                      ",dl_id=%d",
                      i,
                      u->rnti,
                      u->dl_id);
    assert(rc < (int)max && "Not enough space in the char array to write all the data");

    memcpy(out + sz, temp, strlen(temp));
    sz += strlen(temp);
  }

  char end[] = "\n";
  memcpy(out + sz, end, strlen(end));
  sz += strlen(end);
  out[sz] = '\0';
  assert(strlen(out) < max && "Not enough space in the char array to write all the data");
}

static
void print_slice_indication_stats(slice_ind_msg_t const* slice)
{
  assert(slice != NULL);

  char stats[2048] = {0};
  to_string_slice(slice, slice->tstamp, stats, 2048);

  // Edit: The C99 standard §7.19.1.3 states:
  // The macros are [...]
  // EOF which expands to an integer constant expression, 
  // with type int and a negative value, that is returned by 
  // several functions to indicate end-of-ﬁle, that is, no more input from a stream;
  printf("[SLICE STATS]: %s\n", stats);
}

static
void sm_cb_slice(sm_ag_if_rd_t const* rd)
{
  assert(rd != NULL);
  assert(rd->type == INDICATION_MSG_AGENT_IF_ANS_V0);
  assert(rd->ind.type == SLICE_STATS_V0);

//   int64_t now = time_now_us();

//   printf("SLICE ind_msg latency = %ld μs\n", now - rd->ind.slice.msg.tstamp);
  if (rd->ind.slice.msg.ue_slice_conf.len_ue_slice > 0)
  {
    assoc_rnti = rd->ind.slice.msg.ue_slice_conf.ues->rnti; // TODO: assign the rnti after get the indication msg4
    print_slice_indication_stats(&rd->ind.slice.msg);
    // printf("The RNTI value is %u\n", assoc_rnti);
  }
}

static
void fill_add_mod_slice(slice_conf_t* add)
{
  assert(add != NULL);

  uint32_t set_len_slices = 0;
  uint32_t set_slice_id[] = {0, 2, 5};
  char* set_label[] = {"s1", "s2", "s3"};
  /// NVS/EDF slice are only supported by OAI eNB ///
  slice_algorithm_e set_type = SLICE_ALG_SM_V0_STATIC;
  //slice_algorithm_e set_type = SLICE_ALG_SM_V0_NVS;
  //slice_algorithm_e set_type = SLICE_ALG_SM_V0_EDF;
  //slice_algorithm_e set_type = SLICE_ALG_SM_V0_NONE;
  assert(set_type >= 0);
  if (set_type != 0)
    set_len_slices = 3;
  else
    printf("RESET DL SLICE, algo = NONE\n");
  /// SET DL STATIC SLICE PARAMETER ///
  uint32_t set_st_low_high_p[] = {0, 3, 4, 7, 8, 12};

  /// DL SLICE CONTROL INFO ///
  ul_dl_slice_conf_t* add_dl = &add->dl;
  char const* dlname = "PF";
  add_dl->len_sched_name = strlen(dlname);
  add_dl->sched_name = malloc(strlen(dlname));
  assert(add_dl->sched_name != NULL && "memory exhausted");
  memcpy(add_dl->sched_name, dlname, strlen(dlname));

  add_dl->len_slices = set_len_slices;
  if (add_dl->len_slices > 0) {
    add_dl->slices = calloc(add_dl->len_slices, sizeof(fr_slice_t));
    assert(add_dl->slices != NULL && "memory exhausted");
  }

  for (uint32_t i = 0; i < add_dl->len_slices; ++i) {
    fr_slice_t* s = &add_dl->slices[i];
    s->id = set_slice_id[i];

    const char* label = set_label[i];
    s->len_label = strlen(label);
    s->label = malloc(s->len_label);
    assert(s->label != NULL && "Memory exhausted");
    memcpy(s->label, label, s->len_label );

    const char* sched_str = "PF";
    s->len_sched = strlen(sched_str);
    s->sched = malloc(s->len_sched);
    assert(s->sched != NULL && "Memory exhausted");
    memcpy(s->sched, sched_str, s->len_sched);

    if (set_type == SLICE_ALG_SM_V0_STATIC) {
      s->params.type = SLICE_ALG_SM_V0_STATIC;
      s->params.u.sta.pos_high = set_st_low_high_p[i * 2 + 1];
      s->params.u.sta.pos_low = set_st_low_high_p[i * 2];
      printf("ADD STATIC DL SLICE: id %u, pos_low %u, pos_high %u\n", s->id, s->params.u.sta.pos_low, s->params.u.sta.pos_high);
    } else {
      assert(0 != 0 && "Unknown type encountered");
    }
  }


  /// UL SLICE CONTROL INFO ///
  ul_dl_slice_conf_t* add_ul = &add->ul;
  char const* ulname = "round_robin_ul";
  add_ul->len_sched_name = strlen(ulname);
  add_ul->sched_name = malloc(strlen(ulname));
  assert(add_ul->sched_name != NULL && "memory exhausted");
  memcpy(add_ul->sched_name, ulname, strlen(ulname));

  add_ul->len_slices = 0;
}

static
void fill_del_slice(del_slice_conf_t* del)
{
  assert(del != NULL);

  /// SET DL ID ///
  uint32_t dl_ids[] = {2};
  del->len_dl = sizeof(dl_ids)/sizeof(dl_ids[0]);
  if (del->len_dl > 0)
    del->dl = calloc(del->len_dl, sizeof(uint32_t));
  for (uint32_t i = 0; i < del->len_dl; i++) {
    del->dl[i] = dl_ids[i];
    printf("DEL DL SLICE: id %u\n", dl_ids[i]);
  }

  /*
  /// SET UL ID ///
  uint32_t ul_ids[] = {0};
  del->len_ul = sizeof(ul_ids)/sizeof(ul_ids[0]);
  if (del->len_ul > 0)
    del->ul = calloc(del->len_ul, sizeof(uint32_t));
  for (uint32_t i = 0; i < del->len_ul; i++)
    del->ul[i] = ul_ids[i];
  */

}

static
void fill_assoc_ue_slice(ue_slice_conf_t* assoc)
{
  assert(assoc != NULL);

  /// SET ASSOC UE NUMBER ///
  assoc->len_ue_slice = 1;
  if(assoc->len_ue_slice > 0){
    assoc->ues = calloc(assoc->len_ue_slice, sizeof(ue_slice_assoc_t));
    assert(assoc->ues);
  }

  for(uint32_t i = 0; i < assoc->len_ue_slice; ++i) {
    /// SET RNTI ///
    assoc->ues[i].rnti = assoc_rnti; // TODO: get rnti from sm_cb_slice()
    assoc->ues[i].rnti = assoc_rnti; // TODO: get rnti from sm_cb_slice()
    /// SET DL ID ///
    assoc->ues[i].dl_id = 5;
    printf("ASSOC DL SLICE: <rnti>, id %u\n", assoc->ues[i].dl_id);
    /*
    /// SET UL ID ///
    assoc->ues[i].ul_id = 0;
    */
  }
}

static
slice_ctrl_req_data_t fill_slice_sm_ctrl_req(uint16_t ran_func_id, slice_ctrl_msg_e type)
{
  assert(ran_func_id == 145);

  slice_ctrl_req_data_t dst = {0}; 
  if (type == SLICE_CTRL_SM_V0_ADD) {
    /// ADD MOD ///
    dst.msg.type = SLICE_CTRL_SM_V0_ADD;
    fill_add_mod_slice(&dst.msg.u.add_mod_slice);
  } else if (type == SLICE_CTRL_SM_V0_DEL) {
    /// DEL ///
    dst.msg.type = SLICE_CTRL_SM_V0_DEL;
    fill_del_slice(&dst.msg.u.del_slice);
  } else if (type == SLICE_CTRL_SM_V0_UE_SLICE_ASSOC) {
    /// ASSOC SLICE ///
    dst.msg.type = SLICE_CTRL_SM_V0_UE_SLICE_ASSOC;
    fill_assoc_ue_slice(&dst.msg.u.ue_slice);
  } else {
    assert(0 != 0 && "Unknown slice ctrl type");
  }
  return dst;
}

int main(int argc, char *argv[])
{
  fr_args_t args = init_fr_args(argc, argv);

  //Init the xApp
  init_xapp_api(&args);
  sleep(1);

  e2_node_arr_xapp_t nodes = e2_nodes_xapp_api();
  defer({ free_e2_node_arr_xapp(&nodes); });

  assert(nodes.len > 0);
  printf("Connected E2 nodes len = %d\n", nodes.len);

  // SLICE indication
  const char* inter_t = "10_ms";
  sm_ans_xapp_t* slice_handle = NULL;

  if(nodes.len > 0){
    slice_handle = calloc(nodes.len, sizeof(sm_ans_xapp_t) );
    assert(slice_handle != NULL);
  }

  assert(nodes.len == 1);

  for(size_t i = 0; i < nodes.len; ++i) {
    e2_node_connected_xapp_t *n = &nodes.n[i];
    for (size_t j = 0; j < n->len_rf; ++j)
      printf("Registered ran func id = %d \n ", n->rf[j].id);

    slice_handle[i] = report_sm_xapp_api(&nodes.n[i].id, SM_SLICE_ID, (void*)inter_t, sm_cb_slice);
    assert(slice_handle[i].success == true);
    sleep(2);
    
    // // Control ADD slice
    // slice_ctrl_req_data_t ctrl_msg_add = fill_slice_sm_ctrl_req(SM_SLICE_ID, SLICE_CTRL_SM_V0_ADD);
    // control_sm_xapp_api(&nodes.n[i].id, SM_SLICE_ID, &ctrl_msg_add);
    // free_slice_ctrl_msg(&ctrl_msg_add.msg);

    // sleep(1);

    // Control ASSOC slice
    // slice_ctrl_req_data_t  ctrl_msg_assoc = fill_slice_sm_ctrl_req(SM_SLICE_ID, SLICE_CTRL_SM_V0_UE_SLICE_ASSOC);
    // control_sm_xapp_api(&nodes.n[i].id, SM_SLICE_ID, &ctrl_msg_assoc);
    // free_slice_ctrl_msg(&ctrl_msg_assoc.msg);

    // sleep(1);
  }

  // Remove the handle previously returned
  sleep(100);

  for(int i = 0; i < nodes.len; ++i)
    rm_report_sm_xapp_api(slice_handle[i].u.handle);

  if(nodes.len > 0){
    free(slice_handle);
  }

  sleep(1);

  //Stop the xApp
  while(try_stop_xapp_api() == false)
    usleep(1000);

  printf("Test xApp run SUCCESSFULLY\n");
}
```

If you look at the main function, all I did in this code is to ask the gnb to report periodically to the RIC. There is no control messages, no adding/deleting slices. 

Here is what I get in the output:

```
[UTIL]: Setting the config -c file to /usr/local/etc/flexric/flexric.conf
[UTIL]: Setting path -p for the shared libraries to /usr/local/lib/flexric/
[xAapp]: Initializing ... 
[xApp]: nearRT-RIC IP Address = 127.0.0.10, PORT = 36422
[E2 AGENT]: Opening plugin from path = /usr/local/lib/flexric/libmac_sm.so 
[E2 AGENT]: Opening plugin from path = /usr/local/lib/flexric/libtc_sm.so 
[E2 AGENT]: Opening plugin from path = /usr/local/lib/flexric/libgtp_sm.so 
[E2 AGENT]: Opening plugin from path = /usr/local/lib/flexric/libkpm_sm.so 
[E2 AGENT]: Opening plugin from path = /usr/local/lib/flexric/librlc_sm.so 
[E2 AGENT]: Opening plugin from path = /usr/local/lib/flexric/librc_sm.so 
[E2 AGENT]: Opening plugin from path = /usr/local/lib/flexric/libslice_sm.so 
[E2 AGENT]: Opening plugin from path = /usr/local/lib/flexric/libpdcp_sm.so 
[NEAR-RIC]: Loading SM ID = 142 with def = MAC_STATS_V0 
[NEAR-RIC]: Loading SM ID = 146 with def = TC_STATS_V0 
[NEAR-RIC]: Loading SM ID = 148 with def = GTP_STATS_V0 
[NEAR-RIC]: Loading SM ID = 2 with def = ORAN-E2SM-KPM 
[NEAR-RIC]: Loading SM ID = 143 with def = RLC_STATS_V0 
[NEAR-RIC]: Loading SM ID = 3 with def = ORAN-E2SM-RC 
[NEAR-RIC]: Loading SM ID = 145 with def = SLICE_STATS_V0 
[NEAR-RIC]: Loading SM ID = 144 with def = PDCP_STATS_V0 
[xApp]: DB filename = /tmp/xapp_db_1719757287309164 
 [xApp]: E42 SETUP-REQUEST tx
[xApp]: E42 SETUP-RESPONSE rx 
[xApp]: xApp ID = 7 
[xApp]: Registered E2 Nodes = 1 
Connected E2 nodes len = 1
Registered ran func id = 2 
 Registered ran func id = 3 
 Registered ran func id = 142 
 Registered ran func id = 143 
 Registered ran func id = 144 
 Registered ran func id = 145 
 Registered ran func id = 146 
 Registered ran func id = 148 
 [xApp]: E42 RIC SUBSCRIPTION REQUEST tx RAN_FUNC_ID 145 RIC_REQ_ID 1 
[xApp]: SUBSCRIPTION RESPONSE rx
[xApp]: Successfully subscribed to RAN_FUNC_ID 145 
[SLICE STATS]: slice_stats: tstamp=1719757289344687,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289354731,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289364720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289374726,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289384727,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289394728,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289404728,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289414724,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289424722,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289434728,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289444727,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289454727,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289464727,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289474684,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289484679,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289494677,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289504722,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289514699,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289524727,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289534733,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289544727,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289554732,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289564728,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289574724,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289584720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289594726,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289604728,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289614726,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289624684,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289634680,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289644683,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289654724,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289664726,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289674724,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289684721,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289694732,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289704725,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289714728,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289724732,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289734730,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289744725,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289754723,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289764727,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289774734,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289784721,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289794719,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289804723,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289814720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289824726,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289834719,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289844722,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289854721,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289864721,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289874720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289884721,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289894720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289904720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289914721,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289924720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289934720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289944722,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289954720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289964720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289974720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289984722,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757289994720,slice_conf,dl,len_slices=2,slice[0],id=441,label=This is my label,type=2,nvs,sched=Scheduler string,conf=1,capacity,pct_reserved=15.00,slice[1],id=694,label=This is my label,type=1,static,sched=Scheduler string,pos_high=16,pos_low=13,ue_slice_conf,len_ue_slice=8,ues[0],rnti=240,dl_id=12,ues[1],rnti=3a3,dl_id=7,ues[2],rnti=3f9,dl_id=15,ues[3],rnti=2a3,dl_id=15,ues[4],rnti=3fe,dl_id=8,ues[5],rnti=105,dl_id=7,ues[6],rnti=100,dl_id=1,ues[7],rnti=3fa,dl_id=11

[SLICE STATS]: slice_stats: tstamp=1719757290004716,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290014716,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290024718,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290034715,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290044717,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290054701,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290064699,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290074676,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290084672,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290094700,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290104681,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290114725,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290124715,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290134715,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290144717,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

[SLICE STATS]: slice_stats: tstamp=1719757290154717,dl->sched_name=MY SLICE,ue_slice_conf,len_ue_slice=3,ues[0],rnti=3f,dl_id=10,ues[1],rnti=3c2,dl_id=8,ues[2],rnti=109,dl_id=4

```

Where are the 2 slices coming from? One is NVS and the other is static? Where are the 8 UEs coming from??? 


Note that the slice label is calle "this is my label". This has to come from somewhere in the codebase. So we do a global search, and found that it is in this file: /mydata/flexric/test/rnd/fill_rnd_data_slice.c 

Change and recompile to see if this makes a difference. 

```bash
make clean
make -j 8
```

It seems that the name of the label is still this is my label
```
[SLICE STATS]: slice_stats: tstamp=1719760124057503,slice_conf,dl,len_slices=3,slice[0],id=505,label=This is my label,type=1,static,sched=Scheduler string,pos_high=13,pos_low=5,slice[1],id=503,label=This is my label,type=1,static,sched=Scheduler string,pos_high=11,pos_low=11,slice[2],id=766,label=This is my label,type=1,static,sched=Scheduler string,pos_high=20,pos_low=24,ue_slice_conf,len_ue_slice=3,ues[0],rnti=5e,dl_id=10,ues[1],rnti=f2,dl_id=14,ues[2],rnti=263,dl_id=4

```

Even though I have changed the code to:
```c
    const char* label = "This is my favorite xbox game";
```

The only possibility is that it is not the flexric code, but the OAI code that is causing the trouble. 

Changing the code at the base station and recompile. 

```c
  for(uint32_t i = 0; i < slice->len_slices; ++i){
    slice->slices[i].id = abs(rand()%1024);
    fr_slice_t* s = &slice->slices[i];

    const char* label = "This is my favorite racing game";
    s->len_label = strlen(label);
    s->label = malloc(s->len_label);
    assert(s->label != NULL && "Memory exhausted");
    memcpy(s->label, label, s->len_label );
```
in the file: /mydata/openairinterface5g/openair2/E2AP/flexric/test/rnd/fill_rnd_data_slice.c 

Which is a git submodule of the flexric Repo. 

And we see that indeed the log changed to *"This is my favorite racing game"*

```
[SLICE STATS]: slice_stats: tstamp=1719760714112679,slice_conf,dl,len_slices=1,slice[0],id=139,label=This is my favorite racing game,type=1,static,sched=Scheduler string,pos_high=1,pos_low=21,ue_slice_conf,len_ue_slice=8,ues[0],rnti=24c,dl_id=3,ues[1],rnti=369,dl_id=15,ues[2],rnti=3ef,dl_id=10,ues[3],rnti=388,dl_id=9,ues[4],rnti=327,dl_id=9,ues[5],rnti=362,dl_id=7,ues[6],rnti=f,dl_id=6,ues[7],rnti=f,dl_id=0
```

So to really understand, we have no choice but to dig into the OAI code. How it handles a message. How it assign different slices, and simulate multiple UEs. I assume that this might be an error, where the programmer forgot to remove the test code.   

this is the entry function when a subscription is received. 

```c
e2ap_msg_t e2ap_handle_subscription_request_agent(e2_agent_t* ag, const e2ap_msg_t* msg)
{
  assert(ag != NULL);
  assert(msg != NULL);
  assert(msg->type == RIC_SUBSCRIPTION_REQUEST);

  ric_subscription_request_t const* sr = &msg->u_msgs.ric_sub_req;
  assert(supported_ric_subscription_request(sr) == true);

  printf("[E2 AGENT]: RIC_SUBSCRIPTION_REQUEST rx RAN_FUNC_ID %d RIC_REQ_ID %d\n", sr->ric_id.ran_func_id, sr->ric_id.ric_req_id);

  sm_subs_data_t data = generate_sm_subs_data(sr);
  uint16_t const ran_func_id = sr->ric_id.ran_func_id; 
  sm_agent_t* sm = sm_plugin_ag(&ag->plugin, ran_func_id);
  
  //subscribe_timer_t t = sm->proc.on_subscription(sm, &data);
  //assert(t.ms > -2 && "Bug? 0 = create pipe value"); 
  
  sm_ag_if_ans_subs_t const subs = sm->proc.on_subscription(sm, &data);

  // Register the indication event
  ind_event_t ev = {0};
  ev.action_id = sr->action[0].id;
  ev.ric_id = sr->ric_id;
  ev.sm = sm;
  ev.type = subs.type; 

  if(ev.type == PERIODIC_SUBSCRIPTION_FLRC){
    subscribe_timer_t const t = subs.per.t; 
    ev.act_def = t.act_def;
    // Periodic indication message generated i.e., every 5 ms
    assert(t.ms < 10001 && "Subscription for granularity larger than 10 seconds requested? ");
    int fd_timer = create_timer_ms_asio_agent(&ag->io, t.ms, t.ms); 
    lock_guard(&ag->mtx_ind_event);
    bi_map_insert(&ag->ind_event, &fd_timer, sizeof(fd_timer), &ev, sizeof(ev));
  } else if(ev.type == APERIODIC_SUBSCRIPTION_FLRC){
    ev.free_subs_aperiodic = subs.aper.free_aper_subs;
    // Aperiodic indication generated i.e., the RAN will generate it via 
    // void async_event_agent_api(uint32_t ric_req_id, void* ind_data);
    int fd = 0;
    lock_guard(&ag->mtx_ind_event);
    bi_map_insert(&ag->ind_event, &fd, sizeof(int), &ev, sizeof(ev));
  } else {
    assert(0!=0 && "Unknown subscritpion timer value");
  }

  printf("[E2-AGENT]: RIC_SUBSCRIPTION_REQUEST rx\n");

  uint8_t const ric_act_id = sr->action[0].id;
  e2ap_msg_t ans = {.type = RIC_SUBSCRIPTION_RESPONSE, 
                    .u_msgs.ric_sub_resp = generate_subscription_response(&sr->ric_id, ric_act_id) };
  return ans;
}
```

I was just looking at the mailing list, it seems that some scheduling algorithms is supported, but experimental: https://lists.eurecom.fr/sympa/arc/mosaic5g_techs/2024-05/msg00006.html


And I can salso see in the same file why we are having a variable number of UEs and the UE's RNTI seems completely random, but that does not explain why the number of UEs and RNTI are also changing from time to time: 

```c
static
void fill_ue_slice_conf(ue_slice_conf_t* conf)
{
  assert(conf != NULL);
  conf->len_ue_slice = abs(rand()%10);
  if(conf->len_ue_slice > 0){
    conf->ues = calloc(conf->len_ue_slice, sizeof(ue_slice_assoc_t));
    assert(conf->ues != NULL && "memory exhausted");
  }

  for(uint32_t i = 0; i < conf->len_ue_slice; ++i){
    conf->ues[i].rnti = abs(rand()%1024);  
    conf->ues[i].dl_id = abs(rand()%16); 
    conf->ues[i].ul_id = abs(rand()%16); 
  }

}
```

This is madness. 
All of these 2 functions are wrapped in a function called
```c
void fill_slice_ind_data(slice_ind_data_t* ind_msg)
{
  assert(ind_msg != NULL);

  srand(time(0));

  fill_slice_conf(&ind_msg->msg.slice_conf);
  fill_ue_slice_conf(&ind_msg->msg.ue_slice_conf);
  ind_msg->msg.tstamp = time_now_us();
}
```

This function is called at multiple locations, so I don't know what went wrong exaclty. 

I do think that this filie looks highly suspicious: /mydata/openairinterface5g/openair2/E2AP/flexric/test/sm/slice_sm/main.c
 
So I tweaked the main function of it a little:

```c
int main()
{

  printf("test slice sm main function is called\n");
  sm_io_ag_ran_t io_ag = {0}; //.read = read_RAN, .write = write_RAN};  
  io_ag.read_ind_tbl[SLICE_STATS_V0] = read_ind_slice;
  io_ag.write_ctrl_tbl[SLICE_CTRL_REQ_V0] = write_ctrl_slice;

  sm_agent_t* sm_ag = make_slice_sm_agent(io_ag);
  sm_ric_t* sm_ric = make_slice_sm_ric();

  printf("the sm agent and the ric is made with succ\n");

  for(int i = 0; i < 1024; ++i){
    check_eq_ran_function(sm_ag, sm_ric);
    check_subscription(sm_ag, sm_ric);
    check_indication(sm_ag, sm_ric);
    check_ctrl(sm_ag, sm_ric);
  }

  sm_ag->free_sm(sm_ag);
  sm_ric->free_sm(sm_ric);

  printf("Success\n");
  return EXIT_SUCCESS;
}
```
And then I recompile and run again. It is not found in the log. The function is triggered by something else. 

Further logging shows that this is actually triggered here:/mydata/openairinterface5g/openair2/E2AP/RAN_FUNCTION/CUSTOMIZED/ran_func_slice.c in the function 

```c
bool read_slice_sm(void* data)
{
  // printf("read_slice_sm at /mydata/openairinterface5g/openair2/E2AP/RAN_FUNCTION/CUSTOMIZED/ran_func_slice.c\n");
  assert(data != NULL);
//  assert(data->type == SLICE_STATS_V0);

  slice_ind_data_t* slice = (slice_ind_data_t*)data;
  fill_slice_ind_data(slice);

  return true;
}
```


Based on logging, it seems that this function is called once in the setup of the mono gnb (the first part):
```c
static
void init_read_ind_tbl(read_ind_fp (*read_ind_tbl)[SM_AGENT_IF_READ_V0_END])
{
  #if defined (NGRAN_GNB_DU)
  printf("init ran function with init_read_ind_tbl\n");
  (*read_ind_tbl)[MAC_STATS_V0] =  read_mac_sm;
  (*read_ind_tbl)[RLC_STATS_V0] =  read_rlc_sm ;
  (*read_ind_tbl)[SLICE_STATS_V0] = read_slice_sm ;
  #endif
  #if defined (NGRAN_GNB_CUUP)
  (*read_ind_tbl)[TC_STATS_V0] = read_tc_sm ;
  (*read_ind_tbl)[GTP_STATS_V0] = read_gtp_sm ; 
  (*read_ind_tbl)[PDCP_STATS_V0] = read_pdcp_sm ;
  #endif
  
  (*read_ind_tbl)[KPM_STATS_V3_0] = read_kpm_sm ; 
  (*read_ind_tbl)[RAN_CTRL_STATS_V1_03] = read_rc_sm;
}

```
The function above is assigning function to an array of function pointers. The read_slice_sm function is used nowhere else, so other call to this function must have been made via the array of this function pointers. 

And then the function at this is called: openair2/E2AP/RAN_FUNCTION/CUSTOMIZED/ran_func_slice.c
```c
bool read_slice_sm(void* data)
{
  // printf("read_slice_sm at /mydata/openairinterface5g/openair2/E2AP/RAN_FUNCTION/CUSTOMIZED/ran_func_slice.c\n");
  assert(data != NULL);
//  assert(data->type == SLICE_STATS_V0);

  slice_ind_data_t* slice = (slice_ind_data_t*)data;
  fill_slice_ind_data(slice);

  return true;
}
```

Which fills in random slice indication data (not real data). 

Using this information, I then found the beginning of everything: 

```c
#ifdef E2_AGENT
#include "openair2/LAYER2/NR_MAC_gNB/nr_mac_gNB.h" // need to get info from MAC
static void initialize_agent(ngran_node_t node_type, e2_agent_args_t oai_args)
{
  AssertFatal(oai_args.sm_dir != NULL , "Please, specify the directory where the SMs are located in the config file, i.e., add in config file the next line: e2_agent = {near_ric_ip_addr = \"127.0.0.1\"; sm_dir = \"/usr/local/lib/flexric/\");} ");
  AssertFatal(oai_args.ip != NULL , "Please, specify the IP address of the nearRT-RIC in the config file, i.e., e2_agent = {near_ric_ip_addr = \"127.0.0.1\"; sm_dir = \"/usr/local/lib/flexric/\"");

  printf("After RCconfig_NR_E2agent %s %s \n",oai_args.sm_dir, oai_args.ip  );

  fr_args_t args = { .ip = oai_args.ip }; // init_fr_args(0, NULL);
  memcpy(args.libs_dir, oai_args.sm_dir, 128);

  sleep(1);
  const gNB_RRC_INST* rrc = RC.nrrrc[0];
  assert(rrc != NULL && "rrc cannot be NULL");

  const int mcc = rrc->configuration.mcc[0];
  const int mnc = rrc->configuration.mnc[0];
  const int mnc_digit_len = rrc->configuration.mnc_digit_length[0];
  // const ngran_node_t node_type = rrc->node_type;
  int nb_id = 0;
  int cu_du_id = 0;
  if (node_type == ngran_gNB) {
    nb_id = rrc->node_id;
  } else if (node_type == ngran_gNB_DU) {
    const gNB_MAC_INST* mac = RC.nrmac[0];
    AssertFatal(mac, "MAC not initialized\n");
    cu_du_id = mac->f1_config.gnb_id;
    nb_id = mac->f1_config.setup_req->gNB_DU_id;
  } else if (node_type == ngran_gNB_CU || node_type == ngran_gNB_CUCP) {
    // agent buggy: the CU has no second ID, it is the CU-UP ID
    // however, that is not a problem her for us, so put the same ID twice
    nb_id = rrc->node_id;
    cu_du_id = rrc->node_id;
  } else {
    LOG_E(NR_RRC, "not supported ran type detect\n");
  }

  printf("[E2 NODE]: mcc = %d mnc = %d mnc_digit = %d nb_id = %d \n", mcc, mnc, mnc_digit_len, nb_id);

  printf("[E2 NODE]: Args %s %s \n", args.ip, args.libs_dir);

  sm_io_ag_ran_t io = init_ran_func_ag();
  init_agent_api(mcc, mnc, mnc_digit_len, nb_id, cu_du_id, node_type, io, &args);
}
#endif
```   

I really began to wonder if slicing is implemented at all in OAI 5G somtmodem. Apparently, it is not some test code that they accidentally mixed into the real production code: they did the random thing on purpose!


What compounded my suspiscion is this comment from their mailing list: https://lists.eurecom.fr/sympa/arc/mosaic5g_techs/2023-10/msg00008.html. But then they made a tentative promise to do that in 2024, and we do have a merge request on that in 2024 indeed. This is so different from what he claimeed in his disseration! I am gonna check that again. 

 I want to check the corresponding code in LTE to see if the 5G version is implemented or what. I also want to check the latest commit instead of just the latest release.  

My bad, the random code is in the flexric, and they do put that in a test folder? So what is the deal here? They implemented it or not??? So how they planned on filling in real data? 


