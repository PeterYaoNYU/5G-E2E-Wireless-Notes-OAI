running the UE, with this command
```bash
sudo ./nr-uesoftmodem -O ../../../targets/PROJECTS/GENERIC-NR-5GC/CONF/ue.conf -r 106 --numerology 1 --band 78 -C 3619200000 --sa --uicc0.imsi 001010000000001 --rfsim
```

Ideally this shoudl give us the right NSSAI SSt and NSSAI SD, which should connect it with the correct slice. 

However, it does not work, even though the configuration gives the correct sst and sd, which are both 1, and should connect to the nvs slice successfully, it did not do that. 

### 2 possible approaches

I think there are 2 paths, if either succeeds, we have what we want really. 

1. there are slices configured in the RAN system, and when the UE joins, it can find itself the correct slice. 

2. The UE cannot find the correct slice as in the first case, but with the manual control from the flexric, it is able to join the slice that we intended for it. 

### Some relevant code snippets 

this is the code that initializes the UE in the base station when it is added. 

```c

//------------------------------------------------------------------------------
NR_UE_info_t *add_new_nr_ue(gNB_MAC_INST *nr_mac, rnti_t rntiP, NR_CellGroupConfig_t *CellGroup)
{
  NR_ServingCellConfigCommon_t *scc = nr_mac->common_channels[0].ServingCellConfigCommon;
  NR_UEs_t *UE_info = &nr_mac->UE_info;
  LOG_I(NR_MAC, "Adding new UE context with RNTI 0x%04x\n", rntiP);
  dump_nr_list(UE_info->list);

  // We will attach at the end, to mitigate race conditions
  // This is not good, but we will fix it progressively
  NR_UE_info_t *UE = calloc(1, sizeof(NR_UE_info_t));
  if(!UE) {
    LOG_E(NR_MAC,"want to add UE %04x but the fixed allocated size is full\n",rntiP);
    return NULL;
  }

  UE->rnti = rntiP;
  UE->uid = uid_linear_allocator_new(&UE_info->uid_allocator);
  UE->CellGroup = CellGroup;

  if (CellGroup)
    UE->Msg4_ACKed = true;
  else
    UE->Msg4_ACKed = false;

  NR_UE_sched_ctrl_t *sched_ctrl = &UE->UE_sched_ctrl;
  memset(sched_ctrl, 0, sizeof(*sched_ctrl));
  sched_ctrl->dl_max_mcs = 28; /* do not limit MCS for individual UEs */
  sched_ctrl->ta_update = 31;
  sched_ctrl->sched_srs.frame = -1;
  sched_ctrl->sched_srs.slot = -1;

  // initialize UE BWP information
  NR_UE_DL_BWP_t *dl_bwp = &UE->current_DL_BWP;
  memset(dl_bwp, 0, sizeof(*dl_bwp));
  NR_UE_UL_BWP_t *ul_bwp = &UE->current_UL_BWP;
  memset(ul_bwp, 0, sizeof(*ul_bwp));
  configure_UE_BWP(nr_mac, scc, sched_ctrl, NULL, UE, -1, -1);

  /* set illegal time domain allocation to force recomputation of all fields */
  sched_ctrl->sched_pdsch.time_domain_allocation = -1;
  sched_ctrl->sched_pusch.time_domain_allocation = -1;

  /* Set default BWPs */
  AssertFatal(UE->sc_info.n_ul_bwp <= NR_MAX_NUM_BWP, "uplinkBWP_ToAddModList has %d BWP!\n", UE->sc_info.n_ul_bwp);

  /* get Number of HARQ processes for this UE */
  // pdsch_servingcellconfig == NULL in SA -> will create default (8) number of HARQ processes
  create_dl_harq_list(sched_ctrl, &UE->sc_info);
  // add all available UL HARQ processes for this UE
  // nb of ul harq processes not configurable
  create_nr_list(&sched_ctrl->available_ul_harq, 16);
  for (int harq = 0; harq < 16; harq++)
    add_tail_nr_list(&sched_ctrl->available_ul_harq, harq);
  create_nr_list(&sched_ctrl->feedback_ul_harq, 16);
  create_nr_list(&sched_ctrl->retrans_ul_harq, 16);

  reset_srs_stats(UE);

  /* prepare LC list for all slices in this UE */
  for (int slice = 0; slice < NR_MAX_NUM_SLICES; slice++) {
    create_nr_list(&sched_ctrl->sliceInfo[slice].lcid, NR_MAX_NUM_LCID);
  }
  create_nr_list(&UE->dl_id, NR_MAX_NUM_SLICES);

  // associate UEs to the first slice if slice exists (there is no DRB setup in this stage)
  nr_pp_impl_param_dl_t *dl = &RC.nrmac[0]->pre_processor_dl;
  if (dl->slices)
    dl->add_UE(dl->slices, UE);
  NR_SCHED_LOCK(&UE_info->mutex);
  int i;
  for(i=0; i<MAX_MOBILES_PER_GNB; i++) {
    if (UE_info->list[i] == NULL) {
      UE_info->list[i] = UE;
      break;
    }
  }
  if (i == MAX_MOBILES_PER_GNB) {
    LOG_E(NR_MAC,"Try to add UE %04x but the list is full\n", rntiP);
    delete_nr_ue_data(UE, nr_mac->common_channels, &UE_info->uid_allocator);
    NR_SCHED_UNLOCK(&UE_info->mutex);
    return NULL;
  }
  NR_SCHED_UNLOCK(&UE_info->mutex);

  LOG_D(NR_MAC, "Add NR rnti %x\n", rntiP);
  dump_nr_list(UE_info->list);
  return (UE);
}

```

This looks suspicious, but does to seem to have been called, I will validate that: 

```c

static void set_nssaiConfig(const int srb_len,
                            const f1ap_srb_to_be_setup_t *req_srbs,
                            const int drb_len,
                            const f1ap_drb_to_be_setup_t *req_drbs,
                            NR_UE_sched_ctrl_t *sched_ctrl)
{
  gNB_MAC_INST *mac = RC.nrmac[0];
  for (int i = 0; i < srb_len; i++) {
    const f1ap_srb_to_be_setup_t *srb = &req_srbs[i];
    const long lcid = get_lcid_from_srbid(srb->srb_id);
    /* consider first slice as default slice and assign it for SRBs */
    nr_pp_impl_param_dl_t *dl = &mac->pre_processor_dl;
    if (dl->slices) {
      nssai_t *default_nssai = &dl->slices->s[0]->nssai;
      sched_ctrl->dl_lc_nssai[lcid] = *default_nssai;
    } else {
      nssai_t nssai = {.sst = 0, .sd = 0};
      sched_ctrl->dl_lc_nssai[lcid] = nssai;
    }
    LOG_I(NR_MAC, "Setting NSSAI sst: %d, sd: %d for SRB: %ld\n", sched_ctrl->dl_lc_nssai[lcid].sst, sched_ctrl->dl_lc_nssai[lcid].sd, srb->srb_id);
  }

  for (int i = 0; i < drb_len; i++) {
    const f1ap_drb_to_be_setup_t *drb = &req_drbs[i];

    long lcid = get_lcid_from_drbid(drb->drb_id);
    sched_ctrl->dl_lc_nssai[lcid] = drb->nssai;
    LOG_I(NR_MAC, "Setting NSSAI sst: %d, sd: %d for DRB: %ld\n", drb->nssai.sst, drb->nssai.sd, drb->drb_id);
  }
}
```

Similaryly, need to check this
```c
void prepare_initial_ul_rrc_message(gNB_MAC_INST *mac, NR_UE_info_t *UE)
{
  NR_SCHED_ENSURE_LOCKED(&mac->sched_lock);
  /* create this UE's initial CellGroup */
  int CC_id = 0;
  const NR_ServingCellConfigCommon_t *scc = mac->common_channels[CC_id].ServingCellConfigCommon;
  const NR_ServingCellConfig_t *sccd = mac->common_channels[CC_id].pre_ServingCellConfig;
  NR_CellGroupConfig_t *cellGroupConfig = get_initial_cellGroupConfig(UE->uid, scc, sccd, &mac->radio_config);

  UE->CellGroup = cellGroupConfig;
  process_CellGroup(cellGroupConfig, UE);

  /* Assign SRB1 to default slice */
  const long lcid = 1;
  nr_pp_impl_param_dl_t *dl = &mac->pre_processor_dl;
  if (dl->slices) {
    nssai_t *default_nssai = &dl->slices->s[0]->nssai;
    UE->UE_sched_ctrl.dl_lc_nssai[lcid] = *default_nssai;
    LOG_I(NR_MAC, "Setting NSSAI sst: %d, sd: %d for SRB: %ld\n", default_nssai->sst, default_nssai->sd, lcid);

    dl->add_UE(dl->slices, UE);
  }

  /* activate SRB0 */
  nr_rlc_activate_srb0(UE->rnti, UE, send_initial_ul_rrc_message);

  /* the cellGroup sent to CU specifies there is SRB1, so create it */
  DevAssert(cellGroupConfig->rlc_BearerToAddModList->list.count == 1);
  const NR_RLC_BearerConfig_t *bearer = cellGroupConfig->rlc_BearerToAddModList->list.array[0];
  DevAssert(bearer->servedRadioBearer->choice.srb_Identity == 1);
  nr_rlc_add_srb(UE->rnti, bearer->servedRadioBearer->choice.srb_Identity, bearer);
}
```

### Approach 1
1. start the flexric, 
2. start the gnb:
```bash
sudo RFSIMULATOR=server ./ran_build/build/nr-softmodem -O /mydata/gnb.conf --sa --rfsim
```
3. start the xapp to provision the slices.
You should be able to see this in the output:
```

[NR_MAC]   Frame.Slot 256.0

[NR_MAC]   Frame.Slot 384.0

[NR_MAC]   Frame.Slot 512.0

[NR_MAC]   [E2-Agent]: RC CONTROL rx, RIC Style Type 2, Action ID 6
[NR_MAC]   Add default DL slice id 99, label default, sst 0, sd 0, slice sched algo NVS_CAPACITY, pct_reserved 0.05, ue sched algo nr_proportional_fair_wbcqi_dl
[NR_MAC]   configure slice 0, label SST1SD1, Dedicated_PRB_Policy_Ratio 70
[NR_MAC]   add DL slice id 1, label SST1SD1, slice sched algo NVS_CAPACITY, pct_reserved 0.66, ue sched algo nr_proportional_fair_wbcqi_dl
[NR_MAC]   no UE connected
[NR_MAC]   configure slice 1, label SST1SD5, Dedicated_PRB_Policy_Ratio 30
[NR_MAC]   add DL slice id 2, label SST1SD5, slice sched algo NVS_CAPACITY, pct_reserved 0.28, ue sched algo nr_proportional_fair_wbcqi_dl
[NR_MAC]   no UE connected
[E2-AGENT]: CONTROL ACKNOWLEDGE tx
[NR_MAC]   Frame.Slot 640.0

[NR_MAC]   Frame.Slot 768.0
```
2. start the ue. 
We can see the following output:
```
[HW]   A client connects, sending the current time
[NR_MAC]   Frame.Slot 640.0

[NR_PHY]   [RAPROC] 663.19 Initiating RA procedure with preamble 52, energy 54.0 dB (I0 0, thres 120), delay 0 start symbol 0 freq index 0
[NR_MAC]   663.19 UE RA-RNTI 010b TC-RNTI 7b92: Activating RA process index 0
[NR_MAC]   UE 7b92: 664.7 Generating RA-Msg2 DCI, RA RNTI 0x10b, state 1, CoreSetType 0, RAPID 52
[NR_MAC]   UE 7b92: Msg3 scheduled at 664.17 (664.7 k2 7 TDA 3)
[NR_MAC]   Adding new UE context with RNTI 0x7b92
[NR_MAC]   [gNB 0][RAPROC] PUSCH with TC_RNTI 0x7b92 received correctly, adding UE MAC Context RNTI 0x7b92
[NR_MAC]   [RAPROC] RA-Msg3 received (sdu_lenP 7)
[NR_MAC]   prepare_initial_ul_rrc_message is called
[NR_MAC]   Assign SRB1 to default slice
[NR_MAC]   Setting NSSAI sst: 0, sd: 0 for SRB: 1
[NR_MAC]   Matched slice, Add UE rnti 0x7b92 to slice idx 0, sst 0, sd 0
[RLC]   Activated srb0 for UE 31634
[RLC]   Added srb 1 to UE 31634
[NR_MAC]   Activating scheduling RA-Msg4 for TC_RNTI 0x7b92 (state WAIT_Msg3)
[NR_MAC]   Unexpected ULSCH HARQ PID 0 (have -1) for RNTI 0x7b92 (ignore this warning for RA)
[NR_RRC]   Decoding CCCH: RNTI 7b92, payload_size 6
[NR_RRC]   Created new UE context: CU UE ID 1 DU UE ID 31634 (rnti: 7b92, random ue id 3e428bc369000000)
[RRC]   activate SRB 1 of UE 1
[NR_RRC]   rrc_gNB_generate_RRCSetup for RNTI 7b92
[NR_MAC]   No CU UE ID stored for UE RNTI 7b92, adding CU UE ID 1
[NR_MAC]   UE 7b92 Generate msg4: feedback at  665.17, payload 149 bytes, next state WAIT_Msg4_ACK
[NR_MAC]   (UE RNTI 0x7b92) Received Ack of RA-Msg4. CBRA procedure succeeded!
[NR_RRC]   5g_s_TMSI: 0x123456789ABC, amf_set_id: 0x48 (72), amf_pointer: 0x34 (52), 5g TMSI: 0x56789ABC
[NR_RRC]   UE 1 Processing NR_RRCSetupComplete from UE
[NR_RRC]   [FRAME 00000][gNB][MOD 00][RNTI 1] UE State = NR_RRC_CONNECTED
[NGAP]   UE 1: Chose AMF 'OAI-AMF' (assoc_id 175) through selected PLMN Identity index 0 MCC 208 MNC 95
[NGAP]   FIVEG_S_TMSI_PRESENT
[NR_MAC]   Frame.Slot 768.0
UE RNTI 7b92 CU-UE-ID 1 in-sy
```  

I can see that the SRB is assigned to the default slice, because of this code: 

```c
void prepare_initial_ul_rrc_message(gNB_MAC_INST *mac, NR_UE_info_t *UE)
{
  LOG_I(NR_MAC, "prepare_initial_ul_rrc_message is called\n");
  NR_SCHED_ENSURE_LOCKED(&mac->sched_lock);
  /* create this UE's initial CellGroup */
  int CC_id = 0;
  const NR_ServingCellConfigCommon_t *scc = mac->common_channels[CC_id].ServingCellConfigCommon;
  const NR_ServingCellConfig_t *sccd = mac->common_channels[CC_id].pre_ServingCellConfig;
  NR_CellGroupConfig_t *cellGroupConfig = get_initial_cellGroupConfig(UE->uid, scc, sccd, &mac->radio_config);

  UE->CellGroup = cellGroupConfig;
  process_CellGroup(cellGroupConfig, UE);

  /* Assign SRB1 to default slice */
  const long lcid = 1;
  nr_pp_impl_param_dl_t *dl = &mac->pre_processor_dl;
  if (dl->slices) {
    LOG_I(NR_MAC, "Assign SRB1 to default slice\n");
    nssai_t *default_nssai = &dl->slices->s[0]->nssai;
    UE->UE_sched_ctrl.dl_lc_nssai[lcid] = *default_nssai;
    LOG_I(NR_MAC, "Setting NSSAI sst: %d, sd: %d for SRB: %ld\n", default_nssai->sst, default_nssai->sd, lcid);

    dl->add_UE(dl->slices, UE);
  }

  /* activate SRB0 */
  nr_rlc_activate_srb0(UE->rnti, UE, send_initial_ul_rrc_message);

  /* the cellGroup sent to CU specifies there is SRB1, so create it */
  DevAssert(cellGroupConfig->rlc_BearerToAddModList->list.count == 1);
  const NR_RLC_BearerConfig_t *bearer = cellGroupConfig->rlc_BearerToAddModList->list.array[0];
  DevAssert(bearer->servedRadioBearer->choice.srb_Identity == 1);
  nr_rlc_add_srb(UE->rnti, bearer->servedRadioBearer->choice.srb_Identity, bearer);
}
```

What I do not feel happy about is the fact that
1. the process is hardcoded. 
2. It is SRB, carrying the control information, I want to see the DRB being assigned to the correct slice. 

I cannot wrap my head around the reason why. 

#### Approach 2

I do not think that the first approach is such a good idea. I do not think the control message in the xapp slice is useful. I tried that, and it reports the receipt of the control ACK. But at the gnb I see absolutely nothing. 


#### Overall Summary: 
I do think that I have to tweak the code just a little bit, the reasons being:
1. Apparently, the code to associate a UE with a slice is not complete in flexric (if you want me to double check / demo it I can do that) 

2. I see no way to give the slice information to the UE in the configuration file. The NSSAI in that configuration apperas to me as never have been used. The SSD and ST (components of NSSAI) both default to 0, no matter what it says in the configuration file of the UE. I cannot find where it read from the configuration file as well. 

Enough said, I think I cannot see other ways to do that but to hardcode the slice selection. Besides, the RNTI of the UE is Random upon every attachment of the UE. 

So here is the part that I tweaked. I tried to comprehend the system and make the ue/gnb reads the NSSAI number in the UE configuration file, but the system is much more complex than I thought (I think RAN system code is HARD, given there is more complex and unfamiliar protocols, and bearers are not a clear concept at different layers, and PHY gets involved), and I could not do that. 

So I can only change the code, where there is already UE but no slice. When new slices are added via xapp, they will try to find mathcing UEs for this slice. I tweak it so that it can think of odd UE in the list as belonging to slice 1, and even belonging to slice 2. I observe that upon UE attachment, this function is called 

>bool add_mod_rc_slice(int mod_id, size_t slices_len, ran_param_list_t* lst) 


To find matching and existing UEs to the new slice. This function is in file: openair2/E2AP/RAN_FUNCTION/O-RAN/rc_ctrl_service_style_2.c 

So here is how I changed it:

```c
    UE_iterator(UE_info->list, UE) {
      rnti_t rnti = UE->rnti;
      LOG_I(NR_MAC, "trying to associate UE rnti %x with slice label %s\n", rnti, label_nssai);
      NR_UE_sched_ctrl_t *sched_ctrl = &UE->UE_sched_ctrl;
      bool assoc_ue = 0;
      long lcid = 0;

      if (sched_ctrl->dl_lc_num == 0)
        LOG_I(NR_MAC, "UE rnti %x has no DL LC\n", rnti);
      for (int l = 0; l < sched_ctrl->dl_lc_num; ++l) {
        lcid = sched_ctrl->dl_lc_ids[l];
        LOG_I(NR_MAC, "l %d, lcid %ld, sst %d, sd %d\n", l, lcid, sched_ctrl->dl_lc_nssai[lcid].sst, sched_ctrl->dl_lc_nssai[lcid].sd);
        // if (nssai_matches(sched_ctrl->dl_lc_nssai[lcid], RC_nssai.sst, &RC_nssai.sd)) {
        if (i % 2 == ue_idx % 2) {          
          rrc_gNB_ue_context_t* rrc_ue_context_list = rrc_gNB_get_ue_context_by_rnti_any_du(RC.nrrrc[mod_id], rnti);
          uint16_t UE_mcc = rrc_ue_context_list->ue_context.ue_guami.mcc;
          uint16_t UE_mnc = rrc_ue_context_list->ue_context.ue_guami.mnc;

          uint8_t UE_sst = sched_ctrl->dl_lc_nssai[lcid].sst;
          uint32_t UE_sd = sched_ctrl->dl_lc_nssai[lcid].sd;
          LOG_D(NR_MAC, "UE: mcc %d mnc %d, sst %d sd %d, RC: mcc %d mnc %d, sst %d sd %d\n",
                UE_mcc, UE_mnc, UE_sst, UE_sd, RC_mcc, RC_mnc, RC_nssai.sst, RC_nssai.sd);

          // if (UE_mcc == RC_mcc && UE_mnc == RC_mnc && UE_sst == RC_nssai.sst && UE_sd == RC_nssai.sd) {
          if (UE_mcc == RC_mcc && UE_mnc == RC_mnc) {
            dl->add_UE(dl->slices, UE);
	    assoc_ue = true;
          } else {
            LOG_E(NR_MAC, "Failed adding UE (PLMN: mcc %d mnc %d, NSSAI: sst %d sd %d) to slice (PLMN: mcc %d mnc %d, NSSAI: sst %d sd %d)\n",
                  UE_mcc, UE_mnc, UE_sst, UE_sd, RC_mcc, RC_mnc, RC_nssai.sst, RC_nssai.sd);
          }
        }
      }
      if (!assoc_ue)
        LOG_E(NR_MAC, "Failed matching UE rnti %x with current slice (sst %d, sd %d), might lost user plane data\n", rnti, RC_nssai.sst, RC_nssai.sd);
    }
```
Iterating over the UE, and not care about NSSAI. 

One thing that also needs to be changed is that the UE mmc and mnc does not match the slice mmc and mnc (mandated by the flexric really). I am really forgetting how I tweaked it (after playing too much video games, all knowledge gets flushed away). 

Yes here. In file: /mydata/openairinterface5g/openair2/RRC/NR/rrc_gNB_UE_context.c

In function:
```c
//-----------------------------------------------------------------------------
// return a new ue context structure if ue_identityP, rnti not found in collection
rrc_gNB_ue_context_t *rrc_gNB_create_ue_context(sctp_assoc_t assoc_id,
                                                rnti_t rnti,
                                                gNB_RRC_INST *rrc_instance_pP,
                                                const uint64_t ue_identityP,
                                                uint32_t du_ue_id)
//-----------------------------------------------------------------------------
{
  rrc_gNB_ue_context_t *ue_context_p = rrc_gNB_allocate_new_ue_context(rrc_instance_pP);
  if (ue_context_p == NULL)
    return NULL;

  gNB_RRC_UE_t *ue = &ue_context_p->ue_context;
  ue->rnti = rnti;
  ue->random_ue_identity = ue_identityP;
  f1_ue_data_t ue_data = {.secondary_ue = du_ue_id, .du_assoc_id = assoc_id};
  AssertFatal(!cu_exists_f1_ue_data(ue->rrc_ue_id),
              "UE F1 Context for ID %d already exists, logic bug\n",
              ue->rrc_ue_id);
  cu_add_f1_ue_data(ue->rrc_ue_id, &ue_data);
  ue->max_delays_pdu_session = 20; /* see rrc_gNB_process_NGAP_PDUSESSION_SETUP_REQ() */

  ue->ue_guami.mcc = 505;
  ue->ue_guami.mnc = 1;

  RB_INSERT(rrc_nr_ue_tree_s, &rrc_instance_pP->rrc_ue_head, ue_context_p);
  LOG_I(NR_RRC,
        "Created new UE context: CU UE ID %u DU UE ID %u (rnti: %04x, random ue id %lx)\n",
        ue->rrc_ue_id,
        du_ue_id,
        ue->rnti,
        ue->random_ue_identity);
  return ue_context_p;
}

```
the two lines 
```
ue->ue_guami.mcc = 505;
ue->ue_guami.mnc = 1;
```

are added to configure the UE with the mcc and mnc that matches the new slice. Because that information, even if provided in the UE configuration, is never used. It has to be hardcoded someway, or major change to the OAI's way of init a UE.


---

***Missing Picture***: provide the slice info from gnb to the core. 

