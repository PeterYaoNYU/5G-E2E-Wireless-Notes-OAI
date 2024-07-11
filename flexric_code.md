Problems encountered when running multiple gNbs. The flexric will break down since they all look the same to it. May need to resolve it in the long run. 

Starting one gnb:
```
[2024-06-20T14:22:35.714498] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2024-06-20T14:22:35.714511] [AMF] [amf_app] [info ] |      1      |    Connected     |         0xe000       |         gNB-Eurecom-5GNRBox        |            208, 95             | 
[2024-06-20T14:22:35.714518] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
```

Then starting the flexric:
```
PeterYao@node:~/flexric$ ./build/examples/ric/nearRT-RIC
[UTIL]: Setting the config -c file to /usr/local/etc/flexric/flexric.conf
[UTIL]: Setting path -p for the shared libraries to /usr/local/lib/flexric/
[NEAR-RIC]: nearRT-RIC IP Address = 127.0.0.1, PORT = 36421
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
[iApp]: nearRT-RIC IP Address = 127.0.0.1, PORT = 36422
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

We may also start a UE so that we can have more fun with the xapp:
```
sudo ./nr-uesoftmodem -r 106 --numerology 1 --band 78 -C 3619200000 --rfsim --sa --uicc0.imsi 001010000000001 --rfsimulator.serveraddr 127.0.0.1
```
```
[2024-06-20T14:30:35.722060] [AMF] [amf_app] [info ] |----------------------------------------------------gNBs' information-------------------------------------------|
[2024-06-20T14:30:35.722066] [AMF] [amf_app] [info ] |    Index    |      Status      |       Global ID       |       gNB Name       |               PLMN             |
[2024-06-20T14:30:35.722077] [AMF] [amf_app] [info ] |      1      |    Connected     |         0xe000       |         gNB-Eurecom-5GNRBox        |            208, 95             | 
[2024-06-20T14:30:35.722085] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-20T14:30:35.722091] [AMF] [amf_app] [info ] 
[2024-06-20T14:30:35.722097] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
[2024-06-20T14:30:35.722103] [AMF] [amf_app] [info ] |----------------------------------------------------UEs' information--------------------------------------------|
[2024-06-20T14:30:35.722109] [AMF] [amf_app] [info ] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |Cell ID|
[2024-06-20T14:30:35.722119] [AMF] [amf_app] [info ] |      1|    5GMM-REG-INITIATED|   001010000000001|               |               1|          5| 208, 95 |14680064|
[2024-06-20T14:30:35.722128] [AMF] [amf_app] [info ] |      2|     5GMM-DEREGISTERED|     2089900007487|               |               1|          1| 208, 95 |14680064|
[2024-06-20T14:30:35.722134] [AMF] [amf_app] [info ] |----------------------------------------------------------------------------------------------------------------|
```

One can verify that up till now, everthing is okay. 

Then we start a new gnb with the command
```
PeterYao@node:~/flexric$ cd /mydata/openairinterface5g/cmake_targets/
PeterYao@node:/mydata/openairinterface5g/cmake_targets$ sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /local/repository/etc/gnb.conf --sa --rfsim
...
[HW]   The RFSIMULATOR environment variable is deprecated and support will be removed in the future. Instead, add parameter --rfsimulator.serveraddr server to set the server address. Note: the default is "server"; for the gNB/eNB, you don't have to set any configuration.
[HW]   Remove RFSIMULATOR environment variable to get rid of this message and the sleep.
nr-softmodem: ../../../openair2/E2AP/flexric/src/agent/e2_agent.c:242: pend_event: Assertion `bi_map_size(&ag->pending) == 1' failed.
Aborted
```

Above shows that the second gnb crashed. One can also see that the flexric crashed.

```
[E2AP]: E2 SETUP-REQUEST rx from PLMN 208.95 Node ID 3584 RAN type ngran_gNB
nearRT-RIC: /users/PeterYao/flexric/src/lib/msg_hand/reg_e2_nodes.c:174: add_reg_e2_node: Assertion `it_node == end_node && "Trying to add an already existing E2 Node"' failed.
Aborted
```

Maybe because the config file has the same e2 node name. Tweak to see if the problem lingers. 
Change the gnb id to 
```
gNBs =
(
 {
    ////////// Identification parameters:
    gNB_ID    =  0xe01;
```
The flexric and the gnb does not crash anymore. But the amf log is not showing the recognition of the new gnb. But the flexric get the connection and is fine with it. Here is what came from the new gnb
```
TYPE <CTRL-C> TO TERMINATE
got sync (L1_stats_thread)
got sync (ru_thread)
[HW]   bind() failed, errno(98)
[HW]   Could not start the RF device
[PHY]   RU 0 RF started opp_enabled 0
[HW]   No connected device, generating void samples...
[PHY]   Command line parameters for the UE: -C 3619200000 -r 106 --numerology 1 --ssb 516
```

I assume that the software simulation env limits the number of monolithic gnb that one can start. 

I want to put this problem aside for now, since it does not impact the overall problem that we are trying to solve. 

What I want to do is to go through the xapp coding examples provided and see if there is anything we can learn or reuse. 

A tutorial that is not particularly useful:
https://gitlab.eurecom.fr/mosaic5g/flexric/-/wikis/Create-a-xApp

We may want to check the slice model to see what information is actually available (especially the indication message provided by the ran elements), at this address under the flexric worksapce 
```
src/sm/slice_sm/ie/slice_data_ie.h
```

Creating a SM seems complicated. We need to provide the message type definitions, as well as the encoding and deconding procedures. Try to avoid. 

https://gitlab.eurecom.fr/mosaic5g/flexric/-/wikis/uploads/f87434f11e0036bf7286bd9a5e86e37d/2022.10.04_flexric-main_v1.03-RELEASED.pdf 
The link above provides a cute introduction to the internals of the flexric architecture. 

In the slide, it mentions that the slice SM provides the following:

E2 Control Procedure
 Add operation: Add a slice in
the MAC scheduler
 Modify operation: Associate a
UE with a slice
 Delete operation: Delete an
existing slice
E2 Report Procedure
 Slice Statistics for RAN:
number of slices, slicing/UE
scheduling algorithm,
parameters for each slice
 Slice statistics for UE: number
of connected UEs, associated
slice for each UE

Which I can also see in the slice monitoring xapp. But that xapp does not provide things as interesting as mentioned in the paper. 

***What is missing is how to report the arrival of a new UE, and how to tell which slice the UE should belong to***
One can do the UE new arrival check by checking the indication message, to see if the number of UE changed in the last 5ms or so. But that is risky, maybe one left and one joined. If the interval is small enough, I guess ok. More effective would be to check if there is a way to get the list of UE identifiers. In that case the SM (the message that the SM sends) may need to be modified 

#### mac_ctrl.c
this code snippet shows how to send control message to the MAC layer of a base station. Key API:

```c
// get all the nodes and its length
e2_node_arr_xapp_t nodes = e2_nodes_xapp_api();
  assert(nodes.len > 0);

// free all nodes at the release of the xapp
  defer({ free_e2_node_arr_xapp(&nodes); });

// send a control message of actioni 42 to the mac layer via the server API if the node is indeed a gnb or a DU
if(n->id.type == ngran_gNB || n->id.type == ngran_gNB_DU){
    mac_ctrl_req_data_t wr = {.hdr.dummy = 1, .msg.action = 42 };
    sm_ans_xapp_t const a = control_sm_xapp_api(&nodes.n[i].id, 142, &wr);
    assert(a.success == true);
}
```

#### helloworld hw.c
```c
// check node types
#define NODE_IS_MONOLITHIC(nOdE_TyPe) ((nOdE_TyPe) == ngran_eNB    || (nOdE_TyPe) == ngran_ng_eNB    || (nOdE_TyPe) == ngran_gNB)
#define NODE_IS_CU(nOdE_TyPe)         ((nOdE_TyPe) == ngran_eNB_CU || (nOdE_TyPe) == ngran_ng_eNB_CU || (nOdE_TyPe) == ngran_gNB_CU || (nOdE_TyPe) == ngran_gNB_CUCP || (nOdE_TyPe) == ngran_gNB_CUUP)
#define NODE_IS_DU(nOdE_TyPe)         ((nOdE_TyPe) == ngran_eNB_DU || (nOdE_TyPe) == ngran_gNB_DU)
#define NODE_IS_MBMS(nOdE_TyPe)       ((nOdE_TyPe) == ngran_eNB_MBMS_STA)
#define NODE_IS_CUUP(nOdE_TyPe) ((nOdE_TyPe) == ngran_gNB_CUUP)
#define GTPV1_U_PORT_NUMBER (2152)

// the things that you can get from a node type
typedef struct global_e2_node_id {
  ngran_node_t type;
  e2ap_plmn_t plmn;
  e2ap_gnb_id_t nb_id;
  uint64_t *cu_du_id;
} global_e2_node_id_t;

// usage:
  e2_node_arr_xapp_t nodes = e2_nodes_xapp_api();

    printf("E2 node %ld info: nb_id %d, mcc %d, mnc %d, mnc_digit_len %d, ran_type %s, cu_du_id %lu\n",
            i,
            nodes.n[i].id.nb_id.nb_id,
            nodes.n[i].id.plmn.mcc,
            nodes.n[i].id.plmn.mnc,
            nodes.n[i].id.plmn.mnc_digit_len,
            get_ngran_name(ran_type),
            *nodes.n[i].id.cu_du_id);
```

#### xapp_keysight_kpm_rc.c
My assumption for the meaning of RC is RAN control. 

This is a relatively larger example, with more than 1k lines of code. I hope I can get more out of this example 

```c
// every subscription should have a handle
  rc_handle = calloc(1, sizeof(sm_ans_xapp_t));

// this part is not clear to me
// may be to generate the subscription data for RC reports in Service Style 2 
// returns a rc_sub_data_t structure containing the necessary data for the subscription 

rc_sub_data_t rc_sub = gen_rc_sub_style_2();

// subscribe the node for RC info, listen for a specific RC ran function 3, store the RC result in rc_sub, and the call back function is sm_cb_rc
rc_handle[0] = report_sm_xapp_api(&nodes.n[i].id, RC_ran_function, &rc_sub, sm_cb_rc);

```

The following is similar, but they are subscribing to flows of different QoS

```c
  const int KPM_ran_function = 1;

  // KPM handle
  kpm_handle = calloc(4, sizeof(sm_ans_xapp_t));
  assert(kpm_handle != NULL && "Memory exhausted");

  printf("[xApp]: reporting period = %lu [ms]\n", period_ms);

  // KPM SUBSCRIPTION FOR CELL LEVEL MEASUREMENTS Style 1
  kpm_sub_data_t kpm_sub_1 = gen_kpm_sub_style_1();
  defer({ free_kpm_sub_data(&kpm_sub_1); });
  kpm_handle[0] = report_sm_xapp_api(&nodes.n[0].id, KPM_ran_function, &kpm_sub_1, sm_cb_kpm_1);
  assert(kpm_handle[0].success == true);

  // KPM SUBSCRIPTION FOR UE LEVEL MEASUREMENTS Style 3
//   subscribing to a QoS id = 131 
  const uint8_t five_qi_matched = 131;
  kpm_sub_data_t kpm_sub_3_gbr_matched = gen_kpm_sub_style_3(five_qi_matched);
  defer({ free_kpm_sub_data(&kpm_sub_3_gbr_matched); });
  kpm_handle[1] = report_sm_xapp_api(&nodes.n[0].id, KPM_ran_function, &kpm_sub_3_gbr_matched, sm_cb_kpm_3);
  assert(kpm_handle[1].success == true);

  // SUBSCRIBE TO UE 1 AND 2 GBR
//   gathering the kpm of qos id of 4
  const uint8_t five_qi_others = 4;
  kpm_sub_data_t kpm_sub_3_gbr_others = gen_kpm_sub_style_3(five_qi_others);
  defer({ free_kpm_sub_data(&kpm_sub_3_gbr_others); });
  kpm_handle[2] = report_sm_xapp_api(&nodes.n[0].id, KPM_ran_function, &kpm_sub_3_gbr_others, sm_cb_kpm_3);
  assert(kpm_handle[2].success == true);

    // SUBSCRIBE TO UE 301 AND 302 NON-GBR
    // gathering the kpm of QoS id 9 
  const uint8_t five_qi_non_gbr = 9;
  kpm_sub_data_t kpm_sub_3_non_gbr = gen_kpm_sub_style_3(five_qi_non_gbr);
  defer({ free_kpm_sub_data(&kpm_sub_3_non_gbr); });
  kpm_handle[3] = report_sm_xapp_api(&nodes.n[0].id, KPM_ran_function, &kpm_sub_3_non_gbr, sm_cb_kpm_3);
  assert(kpm_handle[3].success == true);
```

The following part of the code is responsible for sending Radio Control (RC) control messages to adjust the Quality of Service (QoS) configuration for Data Radio Bearers (DRBs) when certain conditions are met. It runs in a loop and processes a set of matched UEs to check their downlink throughput. If the throughput exceeds a threshold, it sends a control message to adjust the DRB QoS configuration.

```c
      uint32_t cp_last_dl_thp_gbr_matched = 0;
      gnb_e2sm_t cp_matched_ue_id = {0};
      defer({ free_gnb_ue_id_e2sm(&cp_matched_ue_id); });
      {
        // use a lock and get a copy to prevent race read condition. Apparently the cp_matched_ue_id contains more that a single ue id. It is a combination of many things, including the gnb id and ue id. Defined in gnb.h
        lock_guard(&mtx);
        cp_matched_ue_id = cp_gnb_ue_id_e2sm(&matched_ue_id_list[i]);
        cp_last_dl_thp_gbr_matched = last_dl_thp_gbr_matched[i];
      }

      if(cp_last_dl_thp_gbr_matched >= 10000){
        // RC CONTROL Service Style 1
        rc_ctrl_req_data_t rc_ctrl = {0};
        defer({ free_rc_ctrl_req_data(&rc_ctrl); });

        // generate the header in the control message
        rc_ctrl.hdr = gen_rc_ctrl_hdr(&cp_matched_ue_id);

        // get the id of the data radio bearer 
        int64_t cp_matched_drb_id = get_matched_drb_id(cp_matched_ue_id);
        // generate the actual control message 
        rc_ctrl.msg = gen_rc_ctrl_msg(cp_matched_drb_id);

        // send the control message to the E2 node
        control_sm_xapp_api(&nodes.n[0].id, RC_ran_function, &rc_ctrl);
        printf("RC Control message Style 1 \"DRB QoS Configuration\" sent\n");

        ctrl_msg_call_once = false;
      }
```

Here I want to unfold the sturcture of ***gnb_e2sm_t***. It seems that it may somehow be of use. If there is a way to get that information, that would be great 
```c
typedef struct{
  // 6.2.3.16
  // Mandatory
  // AMF UE NGAP ID
  // Defined in TS 38.413 [6] (NGAP) clause 9.3.3.1.
  // Defined in TS 38.401 [2].
  // fill with openair3/NGAP/ngap_gNB_ue_context.h:61
//   Access and Mobility Management Function User Equipment NGAP ID
// It is a unique identifier assigned to a UE by the AMF within the context of NGAP (Next Generation Application Protocol) signaling
// It is used exclusively within the NGAP messages exchanged between the gNB and the AMF.
// When a UE first connects to the 5G network, it performs a registration procedure. During this process, the AMF assigns a unique AMF UE NGAP ID to the UE
  uint64_t amf_ue_ngap_id; // [0, 2^40 ]

  // Mandatory
  // GUAMI 6.2.3.17 
//   GUAMI is a key identifier in 5G networks that uniquely identifies an AMF (Access and Mobility Management Function). This identifier ensures that each AMF can be uniquely recognized within the entire 5G network, which is essential for correctly routing signaling messages and managing user sessions.
  guami_t guami;

  // gNB-CU UE F1AP ID List
  // C-ifCUDUseparated 
//   Each UE connected to the gNB has a unique F1AP ID assigned by the gNB-CU. This ID is used in F1AP signaling messages to identify the UE.
// The F1AP ID is unique within the context of the gNB-CU, ensuring that each UE can be individually addressed.
  size_t gnb_cu_ue_f1ap_lst_len;  // [1,4]
  uint32_t *gnb_cu_ue_f1ap_lst;

  //gNB-CU-CP UE E1AP ID List
  //C-ifCPUPseparated 
//   similar, but for the identificaiton of UE when communicating between cp and up, if there is such separation 
  size_t gnb_cu_cp_ue_e1ap_lst_len;  // [1, 65535]
  uint32_t *gnb_cu_cp_ue_e1ap_lst;

  // RAN UE ID
  // Optional
  // 6.2.3.25
  // OCTET STRING (SIZE (8))
  // Defined in TS 38.473 (F1AP) 
  // clause 9.2.2.1
  // UE CONTEXT SETUP REQUEST
  uint64_t *ran_ue_id;

  // M-NG-RAN node UE XnAP ID
  // C- ifDCSetup
  // 6.2.3.19
//   This identifier is used to uniquely identify a UE within the context of XnAP signaling between NG-RAN nodes.
  uint32_t *ng_ran_node_ue_xnap_id;

  // Global gNB ID
  // 6.2.3.3
  // Optional
  // This IE shall not be used. Global NG-RAN Node ID IE shall replace this IE 
  global_gnb_id_t *global_gnb_id;

  // Global NG-RAN Node ID
  // C-ifDCSetup
  // 6.2.3.2
  global_ng_ran_node_id_t *global_ng_ran_node_id;

} gnb_e2sm_t ;
```

I would say the gnb_cu_ue_f1ap_lst / gNB-CU-CP UE E1AP ID List is particulary useful when combined with the gnb id, because then we can track which node is new, and assign it to a certain slice. But it seems that this is only valid when there is a CU/DU split OR further, a CU CP split. 

this file is a little bit too complex, let me get back to it tomorrow. 

#### xapp_kpm_rc.c
this also seems like a ran resource control for the KPM.

```c
  int const KPM_ran_function = 2;

  for (size_t i = 0; i < nodes.len; ++i) {
    e2_node_connected_xapp_t* n = &nodes.n[i];

// eq_sm being a function pointer, go throught the ran functions and check if one of them equal the kpm ran function, whose id is 2. Return the function idx 
    size_t const idx = find_sm_idx(n->rf, n->len_rf, eq_sm, KPM_ran_function);
    assert(n->rf[idx].defn.type == KPM_RAN_FUNC_DEF_E && "KPM is not the received RAN Function");
    // if REPORT Service is supported by E2 node, send SUBSCRIPTION
    // e.g. OAI CU-CP
    if (n->rf[idx].defn.kpm.ric_report_style_list != NULL) {
      // Generate KPM SUBSCRIPTION message
      kpm_sub_data_t kpm_sub = gen_kpm_subs(&n->rf[idx].defn.kpm);

// install subscription, store it in the handle list 
      hndl[i] = report_sm_xapp_api(&n->id, KPM_ran_function, &kpm_sub, sm_cb_kpm);
      assert(hndl[i].success == true);

      free_kpm_sub_data(&kpm_sub);
    }
  }
```

the following code snippet demo how to fill a control message
```c
static
rc_ctrl_req_data_t gen_rc_ctrl_msg(ran_func_def_ctrl_t const* ran_func)
{
  assert(ran_func != NULL);

  rc_ctrl_req_data_t rc_ctrl = {0};

// iter over the control styles defined by the ran function
  for (size_t i = 0; i < ran_func->sz_seq_ctrl_style; i++) {
    assert(cmp_str_ba("Radio Bearer Control", ran_func->seq_ctrl_style[i].name) == 0 && "Add requested CONTROL Style. At the moment, only Radio Bearer Control supported");

    // CONTROL HEADER
    rc_ctrl.hdr.format = ran_func->seq_ctrl_style[i].hdr;
    assert(rc_ctrl.hdr.format == FORMAT_1_E2SM_RC_CTRL_HDR && "Indication Header Format received not valid");
    rc_ctrl.hdr.frmt_1.ric_style_type = 1;
    // 6.2.2.6
    {
      lock_guard(&mtx);
      rc_ctrl.hdr.frmt_1.ue_id = cp_ue_id_e2sm(&ue_id);
    }

    // CONTROL MESSAGE
    rc_ctrl.msg.format = ran_func->seq_ctrl_style[i].msg;
    assert(rc_ctrl.msg.format == FORMAT_1_E2SM_RC_CTRL_MSG && "Indication Message Format received not valid");

    fill_rc_ctrl_act(ran_func->seq_ctrl_style[i].seq_ctrl_act,
                     ran_func->seq_ctrl_style[i].sz_seq_ctrl_act,
                     &rc_ctrl.hdr.frmt_1,
                     &rc_ctrl.msg.frmt_1);
  }

  return rc_ctrl;
}
```

*I begin to feel this is somewhat promising, when I looked at the callback function:*
```c
static
void sm_cb_kpm(sm_ag_if_rd_t const* rd)
{
  assert(rd != NULL);
  assert(rd->type == INDICATION_MSG_AGENT_IF_ANS_V0);
  assert(rd->ind.type == KPM_STATS_V3_0);

  // Reading Indication Message Format 3
  kpm_ind_data_t const* ind = &rd->ind.kpm.ind;
  kpm_ric_ind_hdr_format_1_t const* hdr_frm_1 = &ind->hdr.kpm_ric_ind_hdr_format_1;
  kpm_ind_msg_format_3_t const* msg_frm_3 = &ind->msg.frm_3;

  int64_t const now = time_now_us();
  static int counter = 1;
  {
    lock_guard(&mtx);

    printf("\n%7d KPM ind_msg latency = %ld [μs]\n", counter, now - hdr_frm_1->collectStartTime); // xApp <-> E2 Node

    // Reported list of measurements per UE
    for (size_t i = 0; i < msg_frm_3->ue_meas_report_lst_len; i++) {
      // log UE ID
      ue_id_e2sm_t const ue_id_e2sm = msg_frm_3->meas_report_per_ue[i].ue_meas_report_lst;
      ue_id_e2sm_e const type = ue_id_e2sm.type;
      log_ue_id_e2sm[type](ue_id_e2sm);
      // Save UE ID for filling RC Control message
      free_ue_id_e2sm(&ue_id);
      ue_id = cp_ue_id_e2sm(&ue_id_e2sm);

      // log measurements
      log_kpm_measurements(&msg_frm_3->meas_report_per_ue[i].ind_msg_format_1);
      
    }
    counter++;
  }
}
```

because here you can actually get the list of UEs associated with a gNB. 
```c
ue_id_e2sm_t const ue_id_e2sm = msg_frm_3->meas_report_per_ue[i].
```

The other stuff in log_kpm_measurements seems less important. 


#### xapp_rc_moni.c
this one is not particularly interesting, very similar to the kpm examples above. 

#### xapp_slice_moni_ctrl.c
[WARNING] DO not get hope high. I looked at it before, and it seems to be an incomplete version of slice control as deescribed in the paper. 

But it is worth looking into what type of messages a slice indicate supports. 
```c
int main(int argc, char *argv[])
{
  // init the xapp arguments from the command line arguments
  fr_args_t args = init_fr_args(argc, argv);

  //Init the xApp
  // init the xapp api with the given arguments
  init_xapp_api(&args);
  sleep(1);

// retrieve an array connected e2 nodes 
  e2_node_arr_xapp_t nodes = e2_nodes_xapp_api();
  // ensure the allocated memory for nodes is freed when the function scope ends 
  defer({ free_e2_node_arr_xapp(&nodes); });

  assert(nodes.len > 0);
  printf("Connected E2 nodes len = %d\n", nodes.len);

  // SLICE indication
  // slice indication should be sent from the E2 elements to the RIC 
  const char* inter_t = "5_ms";
  sm_ans_xapp_t* slice_handle = NULL;

  if(nodes.len > 0){
    slice_handle = calloc(nodes.len, sizeof(sm_ans_xapp_t) );
    assert(slice_handle != NULL);
  }
  // a slice handle manages subscriptions, allow xapp to refer to it later. It should be associated with a callback function as well 

  // iter over each connected node
  for(size_t i = 0; i < nodes.len; ++i) {
    e2_node_connected_xapp_t *n = &nodes.n[i];
    for (size_t j = 0; j < n->len_rf; ++j)
      printf("Registered ran func id = %d \n ", n->rf[j].id);

    // subscribe the xapp to receive slice indication message from the specified E2 nodes, SM_SLICE_ID identifies the types of the SM for which xAPP is subscribing
    slice_handle[i] = report_sm_xapp_api(&nodes.n[i].id, SM_SLICE_ID, (void*)inter_t, sm_cb_slice);
    assert(slice_handle[i].success == true);
    sleep(2);
    
    // Control ADD slice
    slice_ctrl_req_data_t ctrl_msg_add = fill_slice_sm_ctrl_req(SM_SLICE_ID, SLICE_CTRL_SM_V0_ADD);
    control_sm_xapp_api(&nodes.n[i].id, SM_SLICE_ID, &ctrl_msg_add);
    free_slice_ctrl_msg(&ctrl_msg_add.msg);

    sleep(1);
    // Control DEL slice
    slice_ctrl_req_data_t ctrl_msg_del = fill_slice_sm_ctrl_req(SM_SLICE_ID, SLICE_CTRL_SM_V0_DEL);
    control_sm_xapp_api(&nodes.n[i].id, SM_SLICE_ID, &ctrl_msg_del);
    free_slice_ctrl_msg(&ctrl_msg_del.msg);

    sleep(1);

    // Control ASSOC slice
    slice_ctrl_req_data_t  ctrl_msg_assoc = fill_slice_sm_ctrl_req(SM_SLICE_ID, SLICE_CTRL_SM_V0_UE_SLICE_ASSOC);
    control_sm_xapp_api(&nodes.n[i].id, SM_SLICE_ID, &ctrl_msg_assoc);
    free_slice_ctrl_msg(&ctrl_msg_assoc.msg);

    sleep(1);
  }

  // Remove the handle previously returned
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

looking at the main function, it will collect indication messages for 5 seconds, and impose three different control messages (add slice, del slice, associate UE with a slice), and then the xapp will quit. 

What we need is to have a mechanism to tell which new UE is LL, which is not. 

I want to investigate what is in the slice indication messages. They maybe useful, so I looked into the callback function. 

```c
// a callback function to handle slice indication message 
static
void sm_cb_slice(sm_ag_if_rd_t const* rd)
{
  assert(rd != NULL);
  assert(rd->type == INDICATION_MSG_AGENT_IF_ANS_V0);
  assert(rd->ind.type == SLICE_STATS_V0);

  int64_t now = time_now_us();

  // printf("SLICE ind_msg latency = %ld μs\n", now - rd->ind.slice.msg.tstamp);
  if (rd->ind.slice.msg.ue_slice_conf.len_ue_slice > 0) {
    // printf("there is ue associated with the gnb, the number is %d\n", rd->ind.slice.msg.ue_slice_conf.len_ue_slice);
    assoc_rnti = rd->ind.slice.msg.ue_slice_conf.ues->rnti; // TODO: assign the rnti after get the indication msg
    printf("assoc_rnti: %d\n", assoc_rnti);
  }
}
```
it seems that it just check the assoc_rnti of the first UE in this slice that sends this indication message. 

the following code snippet fills the added/modified slice information before sending a control message to the gnb
```c
static
void fill_add_mod_slice(slice_conf_t* add)
{
  assert(add != NULL);

  // the number of slices to be modified or added
  uint32_t set_len_slices = 0;
  // An array containing the IDs of the slices to be added or modified
  uint32_t set_slice_id[] = {0, 2, 5};
  // An array of labels corresponding to each slice
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
  // An array specifying the low and high positions for static slicing
  uint32_t set_st_low_high_p[] = {0, 3, 4, 7, 8, 12};
  /// SET DL NVS SLICE PARAMETER///
  nvs_slice_conf_e nvs_conf[] = {SLICE_SM_NVS_V0_RATE, SLICE_SM_NVS_V0_CAPACITY, SLICE_SM_NVS_V0_RATE};
  float mbps_rsvd = 0.2;
  float mbps_ref = 10.0;
  float pct_rsvd = 0.7;
  /// SET DL EDF SLICE PARAMETER///
  int deadline[] = {20, 20, 40};
  int guaranteed_prbs[] = {10, 4, 10};

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

// fills the parameters of each new slice 
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
    } else if (set_type == SLICE_ALG_SM_V0_NVS) {
      s->params.type = SLICE_ALG_SM_V0_NVS;
      if (nvs_conf[i] == SLICE_SM_NVS_V0_RATE) {
        s->params.u.nvs.conf = SLICE_SM_NVS_V0_RATE;
        s->params.u.nvs.u.rate.u1.mbps_required = mbps_rsvd;
        s->params.u.nvs.u.rate.u2.mbps_reference = mbps_ref;
        printf("ADD NVS DL SLICE: id %u, conf %d(rate), mbps_required %f, mbps_reference %f\n", s->id, s->params.u.nvs.conf, s->params.u.nvs.u.rate.u1.mbps_required, s->params.u.nvs.u.rate.u2.mbps_reference);
      } else if (nvs_conf[i] == SLICE_SM_NVS_V0_CAPACITY) {
        s->params.u.nvs.conf = SLICE_SM_NVS_V0_CAPACITY;
        s->params.u.nvs.u.capacity.u.pct_reserved = pct_rsvd;
        printf("ADD NVS DL SLICE: id %u, conf %d(capacity), pct_reserved %f\n", s->id, s->params.u.nvs.conf, s->params.u.nvs.u.capacity.u.pct_reserved);
      } else {
        assert(0 != 0 && "Unkown NVS conf type\n");
      }
    } else if (set_type == SLICE_ALG_SM_V0_EDF) {
      s->params.type = SLICE_ALG_SM_V0_EDF;
      s->params.u.edf.deadline = deadline[i];
      s->params.u.edf.guaranteed_prbs = guaranteed_prbs[i];
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
```

the del is much simpler, but perhaps of less interest to our goal. It just takes a note of which slice to delete. 
```c
static
void fill_del_slice(del_slice_conf_t* del)
{
  assert(del != NULL);

  /// SET DL ID ///
  // in this case it is deleting the slice with id 2
  uint32_t dl_ids[] = {2};
  // calculate the number of DL slice ids in the array 
  del->len_dl = sizeof(dl_ids)/sizeof(dl_ids[0]);
  if (del->len_dl > 0)
    del->dl = calloc(del->len_dl, sizeof(uint32_t));
  for (uint32_t i = 0; i < del->len_dl; i++) {
    del->dl[i] = dl_ids[i];
    printf("DEL DL SLICE: id %u\n", dl_ids[i]);
  }
  printf("done filling slice delete control message\n");

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
```

Really the assoc is what we want:
```c
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
```
But right now, what I do not understand is why setting the rnti to assoc_rnti obtained from the callback function. It seems that this part is not finished yet. 