First, a general comment on the link that you sent me earlier today:
https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/DEPLOY_SA5G_SLICING.md
Very informative. It gives me a general impression of end to end network slicing, in contrast with the slicing at the RAN level. A strange detail is that they associate a slice with a single gnb, instead of one gnb supporting multiple slices. 

### mac_ctrl.c
1. sends a MAC control message to a gnb. 

### hw.c
1. list all connected gnbs. 
2. print the information of the gnb, including the plmn, mcc, mnc, nb_id. 

### xapp_keysight_kpm_rc.c
This xapp is rather complex with more than 1k loc. The subscription of the KPM messages is especially perplexing. If it is of interest, I will dig into it more deeply, but here is what I see
1. subscribing to various kinds of key performance metrics, including, Remote Radio Unit Physical Resource Blocks Total Downlink/Uplink, QoS over a radio bearer.
2. subscribing to both the cell level and the UE level. 
3. Subscribing to UE with different QoS requirement. 
4. a control message that is emitted at most once: if the dl throughput of a certain ue exceed 10k (unit not known), then a control message will be sent to the base station. The corresponding radion bearer will be controlled. But it is not clear to me what the effect of the control will be. If a contorl message is sent, the xapp demo will terminate itself. 

The control seems to be one of the following:
```c
typedef enum {
  DRB_QoS_Configuration_7_6_2_1 = 1,
  QoS_flow_mapping_configuration_7_6_2_1 = 2,
  Logical_channel_configuration_7_6_2_1 = 3,
  Radio_admission_control_7_6_2_1 = 4,
  DRB_termination_control_7_6_2_1 = 5,
  DRB_split_ratio_control_7_6_2_1 = 6,
  PDCP_Duplication_control_7_6_2_1 = 7,
} rc_ctrl_service_style_1_e;
```

I do think that the next program is clearer and more concise.

### xapp_kpm_rc.c
1. Subscribe to all E2 nodes that accept subscription. 
2. Send control messages to all eligible nodes that support the particular RAN contorl function. The particular control used here seems to be QoS FLow Mapping configuration. 

### xapp_gtp_mac_rlc_pdcp_moni.c
1. just install a buch of report mechanisim of gtp, mac, rlc, and pdcp layer (some components in O-RAN may not have all of them, and it will adapt)

### xapp_kpm_moni.c
1. Just monitor the kpm of all supporting nodes for 10 seconds. 
2. log the list of ues associated with the gnb, as well the the kpm: RRU.PrbTotDl, RRU.PrbTotUl, DRB.PdcpSduVolumeDL, DRB.PdcpSduVolumeUL, DRB.RlcSduDelayDl, DRB.UEThpDl, DRB.UEThpUl. 

### xapp_rc_moni.c
I began to see importance in this monitor file, because it has a report mechanism for UE modification. 

It is quite perplexing. To the best of my knowledge, upon first glance, it seems to be 
1. subscribing to changes in UE info. 
2. Printing such parameter change. 

### xapp_slice_moni_ctrl.c 
1. add slice, del slice, modify slice qos setting. 
2. associate ue with a slice. 
3. the report indication message concerns the number of ues in the slice. 

### xapp_tc_all.c
1. if the aggregarted head of line tx packkets waiting time to be transmitted (sending to the MAC layer) exceeds a threshold, add a new queue and a new pacer. 
2. there seems to be attempts to create and associate new slices, but that part is commented out. 