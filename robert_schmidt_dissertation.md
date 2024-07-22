I want to take some notes down while reading robert schmidt (from eirocomm, flexric's first author)'s dissertation. I think it is detailed enough, and contains a lot of relevant information. It is a good place to find relevant backgorund without losing track of the main focus of slicing. Meanwhile, it breifly talks about how the core network should be combined with the RAN. 

---

>A PDU session is created for each slice per UE, allowing the handling of slices in the core network and appropriate mapping to the radio bearers in the RAN through the SDAP layer  

This shows how slice extends to the core via a PDU session and the mapping to the radio bearer.   


### On OAI MAC Scheduling Pipeline
>The pipeline implicitly prioritizes
control information over user data: periodic common control information (i.e., information
to all UEs, like broadcast) is prioritized over periodic dedicated control information (i.e.,
per-UE information, like random access), which in turn has precedence over the actual
data scheduling.

>In the LTE version, we modified the existing “default” MAC scheduler (as opposed to
the alternative “fairRR” scheduler1) to support the presented MAC scheduling framework.
We implemented the user scheduling algorithms RR, PF, and MT, as well as the slice
scheduling algorithms for “no” slicing2, static slicing, NVS, “SCN19” (the algorithm
presented in Section 6.3), and the EDF slice algorithm [91]. The “no” slicing inter-
scheduler for both UL and DL, as well as the intra-schedulers, have been implemented
in roughly 1100 lines of code (LOC); the slice algorithms for static, NVS, and SCN19
slicing (DL only) are implemented in roughly 1100 LOC.

>The NR version of OAI had a simplistic, single-UE scheduler which allocated all
resources in every slot in both DL and UL to a single UE. We implemented a new multi-UE
MAC scheduler following the design of the presented MAC scheduling framework in
roughly 3000 LOC, including “no” slicing and a PF scheduler, in DL and UL. For slicing,
we added the NVS algorithm in roughly 400 LOC.

>“No” slicing behaves like a slice algorithm that gives all resources to a single slice.

>The Slicing E2SM allows to configure a slice algorithm and the slices, and is in-
dependent of the employed RAT. For each slice, the following configuration can be
set: (1) generic configuration (state) like the slice ID and slice label, (2) the slice’s
user scheduling algorithm (inter-scheduler, processing), and (3) slice algorithm-specific
resources (per intra-scheduler), e.g., RBs for static slicing, rate and capacity (in percent)
for NVS, abstracting the radio resources according to the slice algorithm-specific slice

>In the simplest case, as shown in Listing 6.1, no slice algorithm is configured. The
“no slicing” inter-scheduler (“None”) calls a single intra-scheduler for all UEs on all
free RBs; the intra-scheduler uses a PF scheduling algorithm (5G “pf_dl” in DL, UL
correspondingly). (For the mapping of the inter-/intra-schedulers, compare to Figure 6.3.)
In Listings 6.2 and 6.3, the static and NVS algorithms are loaded for the inter-
scheduler, respectively. In both cases, two slices (corresponding to two intra-schedulers)
are created with slice algorithm-specific parameters (“params”). For static slicing, a
number of RBs are statically configured, whereas for NVS, rate-based (slice ID 0) and
capacity-based slices (slice ID 1) are configured. The static slicing example in Listing 6.2
further shows how UEs are associated to the individual slices, i.e., intra-schedulers.

>To verify the MAC scheduling framework implementation in OAI within a controlled
environment without interference and for a possibly larger number of UEs, we use an
emulation mode in the form of the “L2 simulator”: in this mode, the eNB directly
exchanges MAC-layer nFAPI [27] messages with an UE emulator, also based on OAI.
Thus, no PHY layer is present, and no PHY channels (with associated noise, interference,
or other models) are emulated. This mode is functionally equivalent to a radio deployment,
as it runs in real-time, i.e., subframes are handled exactly every millisecond.