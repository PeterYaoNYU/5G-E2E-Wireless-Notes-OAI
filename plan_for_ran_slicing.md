The situation is as follows:
# 4G part:
I can see that the static slicing is immplmented in this file: (/mydata/openairinterface5g/openair2/LAYER2/MAC/slicing/slicing.c)

Specifically, the function static_dl() is the slice level scheduling algorithm, and we also have the corresponding static_ul(). I can also see in that file how to initialize the static slicing services in the function static_ul_init(). 

```c
pp_impl_param_t static_ul_init(module_id_t mod_id, int CC_id) {
  slice_info_t *si = calloc(1, sizeof(slice_info_t));
  DevAssert(si);

  si->num = 0;
  si->s = calloc(MAX_STATIC_SLICES, sizeof(slice_t));
  DevAssert(si->s);
  for (int i = 0; i < MAX_MOBILES_PER_ENB; ++i)
    si->UE_assoc_slice[i] = -1;

  /* insert default slice, all resources */
  static_slice_param_t *ulp = malloc(sizeof(static_slice_param_t));
  ulp->posLow = 0;
  ulp->posHigh = to_prb(RC.mac[mod_id]->common_channels[CC_id].ul_Bandwidth) - 1;
  default_sched_ul_algo_t *algo = &RC.mac[mod_id]->pre_processor_ul.ul_algo;
  algo->data = NULL;
  DevAssert(0 == addmod_static_slice_ul(si, 0, strdup("default"), algo, ulp));
  const UE_list_t *UE_list = &RC.mac[mod_id]->UE_info.list;
  for (int UE_id = UE_list->head; UE_id >= 0; UE_id = UE_list->next[UE_id])
    slicing_add_UE(si, UE_id);

  pp_impl_param_t sttc;
  sttc.algorithm = STATIC_SLICING;
  sttc.add_UE = slicing_add_UE;
  sttc.remove_UE = slicing_remove_UE;
  sttc.move_UE = slicing_move_UE;
  sttc.addmod_slice = addmod_static_slice_ul;
  sttc.remove_slice = remove_static_slice_ul;
  sttc.ul = static_ul;
  // current DL algo becomes default scheduler
  sttc.ul_algo = *algo;
  sttc.destroy = static_destroy;
  sttc.slices = si;

  return sttc;
}
```

What is missing is that (1) there is no RAN function implemented to control the slices from flexric. (2) in the file (/mydata/openairinterface5g/openair2/LAYER2/MAC/eNB_scheduler_dlsch.c), which is the downlink shared channel, I cannot see the presence of an entry where I can initialize the slice-level scheduling algorithm. (3) Without decent tutorial, I have serious trouble setting up the whole LTE setting. Besides, it sounds obsolete. 

# 5G Part slicing
The merge request commit is 2b588dd4540dc6dca79e7e454e705ce243b88c0. The author seems to be a Phd student at Eurecomm. 

Here is the Flexric's first author's comment on this MR:
https://lists.eurecom.fr/sympa/arc/mosaic5g_techs/2024-05/msg00006.html. So it seems somewhere between super reliable and not reliable at all. 

When I checkout that commit, I can see the following: 

1. I can see an NVS slice level scheduler implemented in file (/mydata/openairinterface5g/openair2/LAYER2/NR_MAC_gNB/slicing/nr_slicing.c)  with function nvs_nr_dl() and many other supporting functions. I would consider it superior to NVS. 

2. I can see a support function where it tries to match UE's NSSAI with the existing slice's NSSAI, though I am not sure how well that is integrated with the gnb upon UE connection. (nr_slicing_add_UE())

3. I can see that there is RAN function implemented to allow FlexRIC to change slice information. Though I am not sure how to do that from flexric. (this is another promising direction, we can try that from the flexric's side). The file is at: /mydata/openairinterface5g/openair2/E2AP/RAN_FUNCTION/O-RAN/rc_ctrl_service_style_2.c. 

I have not looked too much into this particular file. Upon first glance, 

```c
static void set_new_dl_slice_algo(int mod_id, int algo)
{
  gNB_MAC_INST *nrmac = RC.nrmac[mod_id];
  assert(nrmac);

  nr_pp_impl_param_dl_t dl = nrmac->pre_processor_dl;
  switch (algo) {
    case NVS_SLICING:
      nrmac->pre_processor_dl = nvs_nr_dl_init(mod_id);
      break;
    default:
      nrmac->pre_processor_dl.algorithm = 0;
      nrmac->pre_processor_dl = nr_init_fr1_dlsch_preprocessor(0); // assume CC_id = 0
      nrmac->pre_processor_dl.slices = NULL;
      break;
  }
  if (dl.slices)
    dl.destroy(&dl.slices);
  if (dl.dl_algo.data)
    dl.dl_algo.unset(&dl.dl_algo.data);
}
```

This function changes the slice level scheduling algo to NVS at the MAC layer of base station mod_id. 

The problem is that I cannot see any codechange in the flexric, so I am worried that flexric cannot support that: this being merely a change on the base station for future flexric update. OR there is also the possibility that flexric's current control message already can support that kind of control, but I do not know how it does that, the specific control msg formath and everything. This being the reason why I am a little bit more inclined to set the default slice sched algo at MAC to NVS directly, which goes long enough to fulfill out needs. 

4. I can see how to init the MAC layer with the NVS function, thanks to the support of this README: https://gitlab.eurecom.fr/oai/openairinterface5g/-/blob/2b588dd4540dc6dca79e7e454e705ce243b88c0c/openair2/LAYER2/NR_MAC_gNB/slicing/README.md 

I can see that to change the MAC layer slice sched from the current None Slicing to NVS, this can be changed, in the shared downlink scheduling channel file: (/mydata/openairinterface5g/openair2/LAYER2/NR_MAC_gNB/gNB_scheduler_dlsch.c)

```c
nr_pp_impl_param_dl_t nr_init_fr1_dlsch_preprocessor(int CC_id) {
  /* during initialization: no mutex needed */
  /* in the PF algorithm, we have to use the TBsize to compute the coefficient.
   * This would include the number of DMRS symbols, which in turn depends on
   * the time domain allocation. In case we are in a mixed slot, we do not want
   * to recalculate all these values just, and therefore we provide a look-up
   * table which should approximately give us the TBsize */
  for (int mcsTableIdx = 0; mcsTableIdx < 3; ++mcsTableIdx) {
    for (int mcs = 0; mcs < 29; ++mcs) {
      if (mcs > 27 && mcsTableIdx == 1)
        continue;

      const uint8_t Qm = nr_get_Qm_dl(mcs, mcsTableIdx);
      const uint16_t R = nr_get_code_rate_dl(mcs, mcsTableIdx);
      pf_tbs[mcsTableIdx][mcs] = nr_compute_tbs(Qm,
                                                R,
                                                1, /* rbSize */
                                                10, /* hypothetical number of slots */
                                                0, /* N_PRB_DMRS * N_DMRS_SLOT */
                                                0 /* N_PRB_oh, 0 for initialBWP */,
                                                0 /* tb_scaling */,
                                                1 /* nrOfLayers */) >> 3;
    }
  }

  nr_pp_impl_param_dl_t impl;
  memset(&impl, 0, sizeof(impl));
  impl.dl = nr_fr1_dlsch_preprocessor;
  impl.dl_algo = nr_proportional_fair_wbcqi_dl;
  impl.dl_algo.data = impl.dl_algo.setup();
  return impl;
}
```

Currently, with this 
>  impl.dl = nr_fr1_dlsch_preprocessor;

this is none slicing, but I think we can reference from the RAN function mentioned earlier to make it use NVS for slice sched. 

What I am not sure about is how, when the UE joins the gnb, the gnb can assign them to the correct slice according to the nssai. I can see a potential solution, so let me elaborate here a little. I want to restrict all the changes to mac layer: 

Each UE seems to have this:
```c
typedef struct {
  /// LCs in this slice
  NR_list_t lcid;
  /// total amount of data awaiting for this UE
  uint32_t num_total_bytes;
  uint16_t dl_pdus_total;
} NR_UE_slice_info_t;

/*! \brief scheduling control information set through an API */
#define MAX_CSI_REPORTS 48
typedef struct {
  /// CCE index and aggregation, should be coherent with cce_list
  NR_SearchSpace_t *search_space;
  NR_ControlResourceSet_t *coreset;
  NR_sched_pdcch_t sched_pdcch;

  /// CCE index and Aggr. Level are shared for PUSCH/PDSCH allocation decisions
  /// corresponding to the sched_pusch/sched_pdsch structures below
  int cce_index;
  uint8_t aggregation_level;

  /// Array of PUCCH scheduling information
  /// Its size depends on TDD configuration and max feedback time
  /// There will be a structure for each UL slot in the active period determined by the size
  NR_sched_pucch_t *sched_pucch;
  int sched_pucch_size;

  /// Sched PUSCH: scheduling decisions, copied into HARQ and cleared every TTI
  NR_sched_pusch_t sched_pusch;

  /// Sched SRS: scheduling decisions
  NR_sched_srs_t sched_srs;

  /// uplink bytes that are currently scheduled
  int sched_ul_bytes;
  /// estimation of the UL buffer size
  int estimated_ul_buffer;

  /// PHR info: power headroom level (dB)
  int ph;
  /// PHR info: nominal UE transmit power levels (dBm)
  int pcmax;

  /// Sched PDSCH: scheduling decisions, copied into HARQ and cleared every TTI
  NR_sched_pdsch_t sched_pdsch;
  /// UE-estimated maximum MCS (from CSI-RS)
  uint8_t dl_max_mcs;

  /// For UL synchronization: store last UL scheduling grant
  frame_t last_ul_frame;
  sub_frame_t last_ul_slot;

  /// total amount of data awaiting for this UE
  uint32_t num_total_bytes;
  uint16_t dl_pdus_total;
  /// per-LC status data
  mac_rlc_status_resp_t rlc_status[NR_MAX_NUM_LCID];

  /// Estimation of HARQ from BLER
  NR_bler_stats_t dl_bler_stats;
  NR_bler_stats_t ul_bler_stats;

  uint16_t ta_frame;
  int16_t ta_update;
  bool ta_apply;
  uint8_t tpc0;
  uint8_t tpc1;
  int raw_rssi;
  int pusch_snrx10;
  int pucch_snrx10;
  uint16_t ul_rssi;
  uint8_t current_harq_pid;
  int pusch_consecutive_dtx_cnt;
  int pucch_consecutive_dtx_cnt;
  bool ul_failure;
  int ul_failure_timer;
  int release_timer;
  struct CSI_Report CSI_report;
  bool SR;
  /// information about every HARQ process
  NR_UE_harq_t harq_processes[NR_MAX_HARQ_PROCESSES];
  /// HARQ processes that are free
  NR_list_t available_dl_harq;
  /// HARQ processes that await feedback
  NR_list_t feedback_dl_harq;
  /// HARQ processes that await retransmission
  NR_list_t retrans_dl_harq;
  /// information about every UL HARQ process
  NR_UE_ul_harq_t ul_harq_processes[NR_MAX_HARQ_PROCESSES];
  /// UL HARQ processes that are free
  NR_list_t available_ul_harq;
  /// UL HARQ processes that await feedback
  NR_list_t feedback_ul_harq;
  /// UL HARQ processes that await retransmission
  NR_list_t retrans_ul_harq;
  NR_UE_mac_ce_ctrl_t UE_mac_ce_ctrl; // MAC CE related information
  /// number of active DL LCs
  uint8_t dl_lc_num;
  /// order in which DLSCH scheduler should allocate LCs
  uint8_t dl_lc_ids[NR_MAX_NUM_LCID];

  /// Timer for RRC processing procedures
  uint32_t rrc_processing_timer;

  /// sri, ul_ri and tpmi based on SRS
  nr_srs_feedback_t srs_feedback;
  nssai_t dl_lc_nssai[NR_MAX_NUM_LCID];

  /// last scheduled slice index
  int last_sched_slice;
  /// hold information of slices
  NR_UE_slice_info_t sliceInfo[NR_MAX_NUM_SLICES];
  /// DL harq to slice map
  int harq_slice_map[NR_MAX_HARQ_PROCESSES];

  // Information about the QoS configuration for each LCID/DRB
  NR_QoS_config_t qos_config[NR_MAX_NUM_LCID - 4][NR_MAX_NUM_QFI]; // 0 -CCCH and 1- 3 SRBs(0,1,2)
} NR_UE_sched_ctrl_t;
```
What cathes my attention is this 
>  nssai_t dl_lc_nssai[NR_MAX_NUM_LCID];

A list that matches the logical channel of this UE to a NSSAI.

I can see that in the UE conf file, there is this information: 
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


If the NSSAI mathes somehow (which I am not sure really, this is the part where I am least sure), then I can, at the beginning of each scheudling TTI, loop through the list of UEs, and find the slice that it should belong to, and change the value of this: sched_ctrl->last_sched_slice as well. This function looks like it should do the job somehow:

```c
void nr_slicing_add_UE(nr_slice_info_t *si, NR_UE_info_t *new_ue)
{
  AssertFatal(si->num > 0 && si->s != NULL, "no slices exists, cannot add UEs\n");
  NR_UE_sched_ctrl_t *sched_ctrl = &new_ue->UE_sched_ctrl;
  long lcid = 0;
  reset_nr_list(&new_ue->dl_id);
  for (int i = 0; i < si->num; ++i) {
    reset_nr_list(&new_ue->UE_sched_ctrl.sliceInfo[i].lcid);
    for (int l = 0; l < sched_ctrl->dl_lc_num; ++l) {
      lcid = sched_ctrl->dl_lc_ids[l];
      if (nssai_matches(sched_ctrl->dl_lc_nssai[lcid], si->s[i]->nssai.sst, &si->s[i]->nssai.sd)) {

        add_nr_list(&new_ue->UE_sched_ctrl.sliceInfo[i].lcid, lcid);
        LOG_D(NR_MAC, "add lcid %ld to slice idx %d\n", lcid, i);

        if (!check_nr_list(&new_ue->dl_id, si->s[i]->id)) {
          add_nr_list(&new_ue->dl_id, si->s[i]->id);
          LOG_D(NR_MAC, "add dl id %d to new UE rnti %x\n", si->s[i]->id, new_ue->rnti);
        }

        UE_iterator(si->s[i]->UE_list, UE) {
          if (UE->rnti == new_ue->rnti)
            break;
        }
        if (UE == NULL) {
          int num_UEs = si->s[i]->num_UEs;
          if (si->s[i]->UE_list[num_UEs] == NULL) {
            si->s[i]->UE_list[num_UEs] = new_ue;
            si->s[i]->num_UEs += 1;
            LOG_W(NR_MAC, "Matched slice, Add UE rnti 0x%04x to slice idx %d, sst %d, sd %d\n",
                  new_ue->rnti, i, si->s[i]->nssai.sst, si->s[i]->nssai.sd);
          } else {
            LOG_E(NR_MAC, "cannot add new UE rnti 0x%04x to slice idx %d, num_UEs %d\n",
                  new_ue->rnti, i, si->s[i]->num_UEs);
          }
        }
      } else {
        LOG_D(NR_MAC, "cannot find matched slice (lcid %ld <sst %d sd %d>, slice idx %d <sst %d sd %d>), do nothing for UE rnti 0x%04x\n",
              lcid, sched_ctrl->dl_lc_nssai[lcid].sst, sched_ctrl->dl_lc_nssai[lcid].sd, i, si->s[i]->nssai.sst, si->s[i]->nssai.sd, new_ue->rnti);
      }
    }
  }
}
```
But right now it is not really used anywhere. I think, in the MAC layer, whenever we iterate over the list of UEs with MACRO UE_iterator(UE_list, UE), there is a possibility of assigning it to the correct slice. 