I followed every step here: https://gitlab.eurecom.fr/oai/cn5g/oai-cn5g-fed/-/blob/master/docs/DEPLOY_SA5G_SLICING.md

Note that you may need to login to a docker hub so that you can pull all those images. I changed my docker directory to /mydata/docker, because the dafault file system is really running out of space for additional docker images. 


Anyway, the deployment itself is not a challenging job, because it is just preconfigured docker images (they literally prepared the docker compose file for you, and all you have to do is to hit run)

What I want to do here, and what is missing from the tutorial, is 2 things:

1. Analyze the docker log, to see how the core slicing is done. 

2. Analyze the docker compose file, to see how to configure if we later want to do our own slicing. 

Meanwhile, it is also important to thinkt about how it may combine with what we currently have (RAN slicing with flexric) and to think about what we are missing (UE Slice configuration)


### Docker Log Analysis:

#### AMF
Below is the last part of the AMF log. 

```
* Could not resolve host: oai-nrf
* Closing connection 0
[2024-07-06 18:47:53.726] [amf_sbi] [info] Get response with HTTP code (0)
[2024-07-06 18:47:53.726] [amf_sbi] [info] Cannot get response when calling http://oai-nrf:80/nnrf-nfm/v1/nf-instances/dea5515e-f04c-49af-a17b-6961aaf5ab0d
[2024-07-06 18:47:53.726] [amf_app] [warning] NF Instance Registration, got issue when registering to NRF
[2024-07-06 18:47:53.727] [amf_app] [debug] Received SBI_REGISTER_NF_INSTANCE_RESPONSE
[2024-07-06 18:47:53.727] [amf_app] [debug] Handle NF Instance Registration response
[2024-07-06 18:47:53.727] [amf_app] [debug] Delete AMF Profile instance...
[2024-07-06 18:47:53.727] [amf_app] [debug] Delete AMF Profile instance...
[2024-07-06 18:48:13.551] [amf_app] [info]
[2024-07-06 18:48:13.551] [amf_app] [info] |--------------------------------------------------------------------------------------------------------------------|
[2024-07-06 18:48:13.551] [amf_app] [info] |------------------------------------------------------gNBs' information---------------------------------------------|
[2024-07-06 18:48:13.551] [amf_app] [info] |    Index    |      Status      |       Global ID       |       gNB Name       |                 PLMN               |
[2024-07-06 18:48:13.551] [amf_app] [info] |      1      |    Connected     |        0x1        |       UERANSIM-gnb-208-95-1           |               208, 95              |
[2024-07-06 18:48:13.551] [amf_app] [info] |      2      |    Connected     |        0x1400        |                  |               208, 95              |
[2024-07-06 18:48:13.551] [amf_app] [info] |      3      |    Connected     |        0xe000        |       gnb-rfsim           |               208, 95              |
[2024-07-06 18:48:13.551] [amf_app] [info] |--------------------------------------------------------------------------------------------------------------------|
[2024-07-06 18:48:13.551] [amf_app] [info]
[2024-07-06 18:48:13.551] [amf_app] [info] |--------------------------------------------------------------------------------------------------------------------|
[2024-07-06 18:48:13.551] [amf_app] [info] |----------------------------------------------------UEs' information------------------------------------------------|
[2024-07-06 18:48:13.551] [amf_app] [info] | Index |      5GMM state      |      IMSI        |     GUTI      | RAN UE NGAP ID | AMF UE ID |  PLMN   |  Cell ID  |
[2024-07-06 18:48:13.551] [amf_app] [info] |      1|       5GMM-REGISTERED|   208950000000035|               |               1|          1| 208, 95 |0x      100|
[2024-07-06 18:48:13.551] [amf_app] [info] |      2|       5GMM-REGISTERED|   208950000000036|               |               1|          3| 208, 95 |0x   e00000|
[2024-07-06 18:48:13.551] [amf_app] [info] |      3|       5GMM-REGISTERED|   208950000000037|               |               0|          2| 208, 95 |0x   140010|
[2024-07-06 18:48:13.551] [amf_app] [info] |--------------------------------------------------------------------------------------------------------------------|
[2024-07-06 18:48:13.551] [amf_app] [info]
[2024-07-06 18:48:13.727] [amf_app] [debug] Send ITTI msg to SBI task to trigger the registration request towards NRF
[2024-07-06 18:48:13.727] [amf_sbi] [info] Receive Register NF Instance Request, handling ...
[2024-07-06 18:48:13.727] [amf_sbi] [debug] Send NF Instance Registration to NRF (HTTP version 1)
[2024-07-06 18:48:13.727] [amf_app] [debug] AMF profile to json:
 {"amfInfo":{"amfRegionId":"01","amfSetId":"001","guamiList":[{"amfId":"10041","plmnId":{"mcc":"208","mnc":"95"}},{"amfId":"10041","plmnId":{"mcc":"001","mnc":"01"}}]},"capacity":100,"custom_info":null,"heartBeatTimer":50,"ipv4Addresses":["192.168.70.138"],"nfInstanceId":"dea5515e-f04c-49af-a17b-6961aaf5ab0d","nfInstanceName":"OAI-AMF","nfServices":[{"ipEndPoints":[{"ipv4Address":"192.168.70.138","port":8080,"transport":"TCP"}],"nfServiceStatus":"REGISTERED","scheme":"http","serviceInstanceId":"namf_communication","serviceName":"namf_communication","versions":[{"apiFullVersion":"1.0.0","apiVersionInUri":"v1"}]}],"nfStatus":"REGISTERED","nfType":"AMF","priority":1,"sNssais":[{"sd":"ffffff","sst":1},{"sd":"1","sst":1},{"sd":"7b","sst":222},{"sd":"80","sst":128},{"sd":"82","sst":130}]}
[2024-07-06 18:48:13.727] [amf_sbi] [debug] Send NF Instance Registration to NRF, NRF URL http://oai-nrf:80/nnrf-nfm/v1/nf-instances/dea5515e-f04c-49af-a17b-6961aaf5ab0d
[2024-07-06 18:48:13.727] [amf_sbi] [debug] Send NF Instance Registration to NRF, msg body:
 {"amfInfo":{"amfRegionId":"01","amfSetId":"001","guamiList":[{"amfId":"10041","plmnId":{"mcc":"208","mnc":"95"}},{"amfId":"10041","plmnId":{"mcc":"001","mnc":"01"}}]},"capacity":100,"custom_info":null,"heartBeatTimer":50,"ipv4Addresses":["192.168.70.138"],"nfInstanceId":"dea5515e-f04c-49af-a17b-6961aaf5ab0d","nfInstanceName":"OAI-AMF","nfServices":[{"ipEndPoints":[{"ipv4Address":"192.168.70.138","port":8080,"transport":"TCP"}],"nfServiceStatus":"REGISTERED","scheme":"http","serviceInstanceId":"namf_communication","serviceName":"namf_communication","versions":[{"apiFullVersion":"1.0.0","apiVersionInUri":"v1"}]}],"nfStatus":"REGISTERED","nfType":"AMF","priority":1,"sNssais":[{"sd":"ffffff","sst":1},{"sd":"1","sst":1},{"sd":"7b","sst":222},{"sd":"80","sst":128},{"sd":"82","sst":130}]}
[2024-07-06 18:48:13.727] [amf_sbi] [info] Send HTTP message to http://oai-nrf:80/nnrf-nfm/v1/nf-instances/dea5515e-f04c-49af-a17b-6961aaf5ab0d
[2024-07-06 18:48:13.727] [amf_sbi] [info] HTTP message Body: {"amfInfo":{"amfRegionId":"01","amfSetId":"001","guamiList":[{"amfId":"10041","plmnId":{"mcc":"208","mnc":"95"}},{"amfId":"10041","plmnId":{"mcc":"001","mnc":"01"}}]},"capacity":100,"custom_info":null,"heartBeatTimer":50,"ipv4Addresses":["192.168.70.138"],"nfInstanceId":"dea5515e-f04c-49af-a17b-6961aaf5ab0d","nfInstanceName":"OAI-AMF","nfServices":[{"ipEndPoints":[{"ipv4Address":"192.168.70.138","port":8080,"transport":"TCP"}],"nfServiceStatus":"REGISTERED","scheme":"http","serviceInstanceId":"namf_communication","serviceName":"namf_communication","versions":[{"apiFullVersion":"1.0.0","apiVersionInUri":"v1"}]}],"nfStatus":"REGISTERED","nfType":"AMF","priority":1,"sNssais":[{"sd":"ffffff","sst":1},{"sd":"1","sst":1},{"sd":"7b","sst":222},{"sd":"80","sst":128},{"sd":"82","sst":130}]}
* Could not resolve host: oai-nrf
* Closing connection 0
[2024-07-06 18:48:13.730] [amf_sbi] [info] Get response with HTTP code (0)
[2024-07-06 18:48:13.730] [amf_sbi] [info] Cannot get response when calling http://oai-nrf:80/nnrf-nfm/v1/nf-instances/dea5515e-f04c-49af-a17b-6961aaf5ab0d
[2024-07-06 18:48:13.730] [amf_app] [warning] NF Instance Registration, got issue when registering to NRF
[2024-07-06 18:48:13.730] [amf_app] [debug] Delete AMF Profile instance...
[2024-07-06 18:48:13.730] [amf_app] [debug] Received SBI_REGISTER_NF_INSTANCE_RESPONSE
[2024-07-06 18:48:13.730] [amf_app] [debug] Handle NF Instance Registration response
[2024-07-06 18:48:13.730] [amf_app] [debug] Delete AMF Profile instance...
```

Looking at it, here is what I found. 
-  it cannot resolve NRF but it is not causing any trouble, 
-  I can see that somehow the slice information is configured in AMF as well. ffffff is the default slice, and the other slices are configured somewhere. AMF may be using this information to help the gnb find the correct SMF. 

#### AUSF 
```
[2024-07-06 18:29:52.198] [ausf_app] [debug] ausf profile to JSON:                                                                                                  {"ausfInfo":{"groupId":"oai-ausf-testgroupid","routingIndicators":["0210","9876"],"supiRanges":[{"end":"","pattern":"209238210938","start":"q0930j0c80283ncjf"}]},"capacity":100,"fqdn":"","heartBeatTimer":50,"ipv4Addresses":["192.168.70.135"],"nfInstanceId":"5fe3d583-6db3-42b2-9182-8ce23c88c80f","nfInstanceName":"OAI-AUSF","nfStatus":"REGISTERED","nfType":"AUSF","priority":1,"sNssais":[]}                                                                                                  [2024-07-06 18:29:52.198] [ausf_nrf] [info] Sending NF registeration request                                                                                       [2024-07-06 18:29:52.198] [ausf_app] [info] Send HTTP message with body {"ausfInfo":{"groupId":"oai-ausf-testgroupid","routingIndicators":["0210","9876"],"supiRanges":[{"end":"","pattern":"209238210938","start":"q0930j0c80283ncjf"}]},"capacity":100,"fqdn":"","heartBeatTimer":50,"ipv4Addresses":["192.168.70.135"],"nfInstanceId":"5fe3d583-6db3-42b2-9182-8ce23c88c80f","nfInstanceName":"OAI-AUSF","nfStatus":"REGISTERED","nfType":"AUSF","priority":1,"sNssais":[]}
* Could not resolve host: oai-nrf
* Closing connection 0
```
I can see that AUSF does not have any slice information. 

```
[2024-07-06 18:38:23.554] [ausf_app] [info] Get response with HTTP code (201)
* Connection #0 to host oai-udm left intact
[2024-07-06 18:38:23.554] [ausf_server] [debug] 5g-aka-confirmation response:
 {"authResult":true,"kseaf":"3ba84bbbd0d460765cdd1d58d2f2e4d219488301c323f81147b9974f32613af7","supi":"208950000000035"}
[2024-07-06 18:38:23.554] [ausf_server] [info] Send 5g-aka-confirmation response to SEAF (Code 200)
[2024-07-06 18:38:37.391] [ausf_server] [info] Received ue_authentications_post Request
[2024-07-06 18:38:37.391] [ausf_app] [info] Handle UE Authentication Request
[2024-07-06 18:38:37.392] [ausf_app] [info] ServingNetworkName 5G:mnc095.mcc208.3gppnetwork.org
[2024-07-06 18:38:37.392] [ausf_app] [info] supiOrSuci 208950000000037
[2024-07-06 18:38:37.392] [ausf_app] [debug] UDM's URI http://oai-udm:8080/nudm-ueau/v1/208950000000037/security-information/generate-auth-data
[2024-07-06 18:38:37.392] [ausf_app] [info] Received authInfo from AMF without ResynchronizationInfo IE
[2024-07-06 18:38:37.392] [ausf_app] [info] Send HTTP message with body {"ausfInstanceId":"400346f4-087e-40b1-a4cd-00566953999d","servingNetworkName":"5G:mnc095.mcc208.3gppnetwork.org"}
*   Trying 192.168.70.134:8080...
* Connected to oai-udm (192.168.70.134) port 8080 (#0)
* Using HTTP2, server supports multiplexing
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7f1fac01be00)
> POST /nudm-ueau/v1/208950000000037/security-information/generate-auth-data HTTP/2^M
Host: oai-udm:8080^M
accept: */*^M
content-type: application/json^M
content-length: 113^M
^M
```
I can see that it is communicating with the UDM and authenticate the UE. The number of appearance is eactly 3, which matches the number of UE. 

#### NSSF
```
[2024-07-06 18:29:46.842] [nssf_sbi] [info] HTTP2 server started
[2024-07-06 18:38:23.769] [nssf_sbi] [debug] Received request for NS Selection - (HTTP_VERSION 2)
[2024-07-06 18:38:23.769] [nssf_sbi] [debug] QueryString: nf-type=AMF&nf-id=dea5515e-f04c-49af-a17b-6961aaf5ab0d&slice-info-request-for-pdu-session={"roamingIndication":"NON_ROAMING","sNssai":{"sd":"128","sst":128}}
[2024-07-06 18:38:23.769] [nssf_sbi] [info]  Query_PARAM::NF_TYPE - AMF
[2024-07-06 18:38:23.769] [nssf_sbi] [info]  Query_PARAM::NF_ID - dea5515e-f04c-49af-a17b-6961aaf5ab0d
[2024-07-06 18:38:23.770] [nssf_sbi] [info]  Query_PARAM::SLICE_INFO_PDU_SESSION - {"roamingIndication":"NON_ROAMING","sNssai":{"sd":"128","sst":128}}
[2024-07-06 18:38:23.770] [nssf_app] [info]
[2024-07-06 18:38:23.770] [nssf_sbi] [info] NS Selection: Got a request with slice info for PDU Session, Instance ID: dea5515e-f04c-49af-a17b-6961aaf5ab0d
[2024-07-06 18:38:23.770] [nssf_app] [info] NS Selection: Handle case - PDU Session (HTTP_VERSION 2)
[2024-07-06 18:38:23.770] [nssf_app] [debug] Validating S-NSSAI for NSI
[2024-07-06 18:38:23.771] [nssf_app] [info] NS Selection: Authorized Network Slice Info Returned !!!
[2024-07-06 18:38:23.771] [nssf_app] [info] //---------------------------------------------------------
[2024-07-06 18:38:41.447] [nssf_sbi] [debug] Received request for NS Selection - (HTTP_VERSION 2)
[2024-07-06 18:38:41.447] [nssf_sbi] [debug] QueryString: nf-type=AMF&nf-id=dea5515e-f04c-49af-a17b-6961aaf5ab0d&slice-info-request-for-pdu-session={"roamingIndication":"NON_ROAMING","sNssai":{"sd":"130","sst":130}}
[2024-07-06 18:38:41.448] [nssf_sbi] [info]  Query_PARAM::NF_TYPE - AMF
[2024-07-06 18:38:41.448] [nssf_sbi] [info]  Query_PARAM::NF_ID - dea5515e-f04c-49af-a17b-6961aaf5ab0d
[2024-07-06 18:38:41.449] [nssf_sbi] [info]  Query_PARAM::SLICE_INFO_PDU_SESSION - {"roamingIndication":"NON_ROAMING","sNssai":{"sd":"130","sst":130}}
[2024-07-06 18:38:41.449] [nssf_app] [info]
[2024-07-06 18:38:41.449] [nssf_sbi] [info] NS Selection: Got a request with slice info for PDU Session, Instance ID: dea5515e-f04c-49af-a17b-6961aaf5ab0d
[2024-07-06 18:38:41.449] [nssf_app] [info] NS Selection: Handle case - PDU Session (HTTP_VERSION 2)
[2024-07-06 18:38:41.449] [nssf_app] [debug] Validating S-NSSAI for NSI
[2024-07-06 18:38:41.449] [nssf_app] [info] NS Selection: Authorized Network Slice Info Returned !!!
[2024-07-06 18:38:41.449] [nssf_app] [info] //---------------------------------------------------------
[2024-07-06 18:38:45.949] [nssf_sbi] [debug] Received request for NS Selection - (HTTP_VERSION 2)
[2024-07-06 18:38:45.949] [nssf_sbi] [debug] QueryString: nf-type=AMF&nf-id=dea5515e-f04c-49af-a17b-6961aaf5ab0d&slice-info-request-for-pdu-session={"roamingIndication":"NON_ROAMING","sNssai":{"sd":"16777215","sst":1}}
[2024-07-06 18:38:45.949] [nssf_sbi] [info]  Query_PARAM::NF_TYPE - AMF
[2024-07-06 18:38:45.949] [nssf_sbi] [info]  Query_PARAM::NF_ID - dea5515e-f04c-49af-a17b-6961aaf5ab0d
[2024-07-06 18:38:45.950] [nssf_sbi] [info]  Query_PARAM::SLICE_INFO_PDU_SESSION - {"roamingIndication":"NON_ROAMING","sNssai":{"sd":"16777215","sst":1}}
[2024-07-06 18:38:45.950] [nssf_app] [info]
[2024-07-06 18:38:45.950] [nssf_sbi] [info] NS Selection: Got a request with slice info for PDU Session, Instance ID: dea5515e-f04c-49af-a17b-6961aaf5ab0d
[2024-07-06 18:38:45.950] [nssf_app] [info] NS Selection: Handle case - PDU Session (HTTP_VERSION 2)
[2024-07-06 18:38:45.950] [nssf_app] [debug] Validating S-NSSAI for NSI
[2024-07-06 18:38:45.950] [nssf_app] [info] NS Selection: Authorized Network Slice Info Returned !!!
[2024-07-06 18:38:45.950] [nssf_app] [info] //---------------------------------------------------------
```

It receives 3 times the slice selection request from AMF. Each time the AMF has a specific NSSAI. 

#### UDM
I did not find anything interesting. As expected, there are 3 authentication messages from the AUSF. 

```
[2024-07-06 18:38:23.511] [udm_ueau] [info] Handle generate_auth_data()                                                                                            [2024-07-06 18:38:23.511] [udm_ueau] [info] Handle Generate Auth Data Request                                                                                      [2024-07-06 18:38:23.511] [udm_ueau] [debug] GET Request:http://oai-udr:8080/nudr-dr/v1/subscription-data/208950000000035/authentication-data/authentication-subscription
[2024-07-06 18:38:23.511] [udm_app] [info] Send HTTP message with body
*   Trying 192.168.70.133:8080...
* Connected to oai-udr (192.168.70.133) port 8080 (#0)
* Using HTTP2, server supports multiplexing
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fa7d801a4d0)
> GET /nudr-dr/v1/subscription-data/208950000000035/authentication-data/authentication-subscription HTTP/2^M
Host: oai-udr:8080^M
accept: */*^M
^M
< HTTP/2 200 ^M
< date: Sat, 06 Jul 2024 18:38:23 GMT^M
< ^M
* Connection #0 to host oai-udr left intact
[2024-07-06 18:38:23.514] [udm_app] [info] Got response with httpcode (200)
[2024-07-06 18:38:23.514] [udm_ueau] [info] Result For F1-Alg Key
c a 34 60 1d 4f 7 67 73 3 65 2c 4 62 53 5b
[2024-07-06 18:38:23.514] [udm_ueau] [info] Result For F1-Alg OPC
63 bf a5 e e6 52 33 65 ff 14 c1 f4 5f 88 73 7d
[2024-07-06 18:38:23.514] [udm_ueau] [info] Result For F1-Alg AMF
80 0
[2024-07-06 18:38:23.514] [udm_ueau] [info] Result For F1-Alg SQN:
0 0 0 0 0 20
[2024-07-06 18:38:23.514] [udm_ueau] [info] Current SQN 000000000040
1b 38 21 fc 91 66 8f 3d 31 4c 8c a5 7e a9 f7 10
6 73 1f e3 5 58 16 25 76 77 be 9a a7 2 9e d8
1b 38 21 fc 91 66 8f 3d 31 4c 8c a5 7e a9 f7 10
9a d8 7b 19 bc c2 d6 3d ea dc da 60 1e 98 5e c1
ad 87 e5 3a 84 90 b8 2b 69 f9 68 b7 92 b0 1c 20
95 d5 8b 2c 7 b5 a fc e5 d1 2a 55 a5 ef 82 5
[2024-07-06 18:38:23.516] [udm_ueau] [info] XRES*(new)
15 95 a4 1f 5e d5 10 9f 55 13 29 2a c4 e4 84 2b 94 c5 9e 8 7d 57 b0 98 5f 9e b2 8 3e 1e 68 1c
[2024-07-06 18:38:23.516] [udm_ueau] [debug] derive_kausf ...
[2024-07-06 18:38:23.516] [udm_ueau] [info] derive_kausf key                                                          46 b8 ed 1d 5f 3f f5 bb 32 b0 db 16 f3 d7 e2 11 46 a8 48 3a c7 3d e4 d1 b0 b7 76 c8 1a 84 85 c
[2024-07-06 18:38:23.516] [udm_ueau] [info] derive_kausf kausf
bd 2c ef 9a 1d 5d 88 24 72 13 b de 78 77 32 3f 80 90 71 46 a1 85 6 80 b2 73 19 6f 11 d6 3f 75
[2024-07-06 18:38:23.516] [udm_ueau] [info] New SQN (for next round) = 000000000060
[2024-07-06 18:38:23.516] [udm_ueau] [debug] PATCH Request:http://oai-udr:8080/nudr-dr/v1/subscription-data/208950000000035/authentication-data/authentication-subscription
[2024-07-06 18:38:23.516] [udm_ueau] [info] Update UDR with PATCH message, body:  [{"from":"","op":"replace","path":"","value":"{\"lastIndexes\":{\"ausf\":0},\"sqn\":\"000000000060\",\"sqnScheme\":\"NON_TIME_BASED\"}"}]
[2024-07-06 18:38:23.516] [udm_app] [info] Send HTTP message with body [{"from":"","op":"replace","path":"","value":"{\"lastIndexes\":{\"ausf\":0},\"sqn\":\"000000000060\",\"sqnScheme\":\"NON_TIME_BASED\"}"}]
*   Trying 192.168.70.133:8080...
* Connected to oai-udr (192.168.70.133) port 8080 (#0)
* Using HTTP2, server supports multiplexing
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fa7d801a4b0)
> PATCH /nudr-dr/v1/subscription-data/208950000000035/authentication-data/authentication-subscription HTTP/2^M
Host: oai-udr:8080^M
accept: */*^M
content-type: application/json^M
content-length: 137^M
^M
* We are completely uploaded and fine
< HTTP/2 204 ^M
[2024-07-06 18:38:23.528] [udm_app] [info] Got response with httpcode (204)
< date: Sat, 06 Jul 2024 18:38:23 GMT^M
< ^M
* Connection #0 to host oai-udr left intact
[2024-07-06 18:38:23.528] [udm_ueau] [info] Send 200 Ok response to AUSF
[2024-07-06 18:38:23.528] [udm_ueau] [info] AuthInfoResult {"authType":"5G_AKA","authenticationVector":{"autn":"85a2a04f00088000cca9e316eb8b6b15","avType":"5G_HE_AKA","kausf":"bd2cef9a1d5d882472130bde7877323f80907146a1850680b273196f11d63f75","rand":"748db0926a7bbb3fbd5b287d2543d736","xresStar":"94c59e087d57b0985f9eb2083e1e681c"}}
[2024-07-06 18:38:23.528] [udm_ueau] [info] Send response to AUSF
[2024-07-06 18:38:23.528] [udm_ueau] [info] Update sqn in Database
[2024-07-06 18:38:23.534] [udm_ueau] [info] Handle Authentication Confirmation
[2024-07-06 18:38:23.534] [udm_ueau] [debug] GET Request:http://oai-udr:8080/nudr-dr/v1/subscription-data/208950000000035/authentication-data/authentication-subscription
[2024-07-06 18:38:23.534] [udm_app] [info] Send HTTP message with body
*   Trying 192.168.70.133:8080...
* Connected to oai-udr (192.168.70.133) port 8080 (#0)                                                         * Using HTTP2, server supports multiplexing
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fa7d802c8b0)
> GET /nudr-dr/v1/subscription-data/208950000000035/authentication-data/authentication-subscription HTTP/2^M
Host: oai-udr:8080^M
accept: */*^M
^M
< HTTP/2 200 ^M
< date: Sat, 06 Jul 2024 18:38:23 GMT^M
[2024-07-06 18:38:23.537] [udm_app] [info] Got response with httpcode (200)
< ^M
* Connection #0 to host oai-udr left intact
[2024-07-06 18:38:23.537] [udm_ueau] [debug] PUT Request:http://oai-udr:8080/nudr-dr/v1/subscription-data/208950000000035/authentication-data/authentication-status[2024-07-06 18:38:23.537] [udm_ueau] [debug] PATCH Request body = {"authRemovalInd":false,"authType":"5G_AKA","nfInstanceId":"400346f4-087e-40b1-a4cd-00566953999d","servingNetworkName":"5G:mnc095.mcc208.3gppnetwork.org","success":true,"timeStamp":"2024-07-06T18:38:23Z"}                                                        [2024-07-06 18:38:23.537] [udm_app] [info] Send HTTP message with body {"authRemovalInd":false,"authType":"5G_AKA","nfInstanceId":"400346f4-087e-40b1-a4cd-00566953999d","servingNetworkName":"5G:mnc095.mcc208.3gppnetwork.org","success":true,"timeStamp":"2024-07-06T18:38:23Z"}
*   Trying 192.168.70.133:8080...
* Connected to oai-udr (192.168.70.133) port 8080 (#0)
* Using HTTP2, server supports multiplexing
* Connection state changed (HTTP/2 confirmed)
* Copying HTTP/2 data in stream buffer to connection buffer after upgrade: len=0
* Using Stream ID: 1 (easy handle 0x7fa7d802c8b0)
> PUT /nudr-dr/v1/subscription-data/208950000000035/authentication-data/authentication-status HTTP/2^M
Host: oai-udr:8080^M
accept: */*^M
content-type: application/json^M
content-length: 204^M
^M
* We are completely uploaded and fine
< HTTP/2 204 ^M
< date: Sat, 06 Jul 2024 18:38:23 GMT^M
[2024-07-06 18:38:23.554] [udm_app] [info] Got response with httpcode (204)         
```
And it happened exactly 3 times. And I do not know why it cannot find the NRF. There are 2 NRF configured. 


#### UDR
the retrieval of subscription data happens exactly 6 times
```
[2024-07-06 18:38:23.513] [udr_server] [info] Received response:
[2024-07-06 18:38:23.513] [udr_app] [info] [UE Id 208950000000035] Retrieve the Authentication Subscription data of an UE
[2024-07-06 18:38:23.513] [udr_db] [info] [UE Id 208950000000035] Query Authentication Subscription
[2024-07-06 18:38:23.513] [udr_db] [info] [UE Id 208950000000035] MySQL Query: SELECT * FROM AuthenticationSubscription WHERE ueid='208950000000035'
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [0]: ueid
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [1]: authenticationMethod
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [2]: encPermanentKey
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [3]: protectionParameterId
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [4]: sequenceNumber
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [5]: authenticationManagementField
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [6]: algorithmId
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [7]: encOpcKey
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [8]: encTopcKey
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [9]: vectorGenerationInHss
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [10]: n5gcAuthMethod
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [11]: rgAuthenticationInd
[2024-07-06 18:38:23.514] [udr_db] [debug] [UE Id 208950000000035] Row [12]: supi
[2024-07-06 18:38:23.514] [udr_app] [info] [UE Id 208950000000035] AuthenticationSubscription: {"algorithmId":"milenage","authenticationManagementField":"8000","authenticationMethod":"5G_AKA","encOpcKey":"63bfa50ee6523365ff14c1f45f88737d","encPermanentKey":"0C0A34601D4F07677303652C0462535B","protectionParameterId":"0C0A34601D4F07677303652C0462535B","sequenceNumber":{"lastIndexes":{"ausf":0},"sqn":"000000000020","sqnScheme":"NON_TIME_BASED"},"supi":"208950000000035"}
[2024-07-06 18:38:23.514] [udr_server] [info] HTTP Response code 200 (HTTP Version 2).
```
2 for each UE. 


### NRF for slice 1 & 2
```
[2024-07-06 18:29:57.317] [nrf_app] [debug] Added a subscription to the DB
[2024-07-06 18:29:57.317] [nrf_app] [debug] Subscription information
[2024-07-06 18:29:57.317] [nrf_app] [debug]     Sub ID: 2
[2024-07-06 18:29:57.317] [nrf_app] [debug]     Notification URI: 192.168.70.140:8080/nsmf-nfstatus-notify/v1/subscriptions
[2024-07-06 18:29:57.317] [nrf_app] [debug]     Subscription condition: Type: NF_TYPE_COND, condition: UPF
[2024-07-06 18:29:57.317] [nrf_app] [debug]     Notification Events: NF_REGISTERED, NF_DEREGISTERED,
[2024-07-06 18:29:57.317] [nrf_app] [debug]     Validity time: 20390531T235959
[2024-07-06 18:29:57.325] [nrf_sbi] [info] Got a request to register an NF instance/Update an NF instance, Instance ID: d4f729dd-565b-4d02-95e3-934b8287fb16
[2024-07-06 18:29:57.325] [nrf_app] [info] Handle Register NF Instance/Update NF Instance (HTTP version 2)
[2024-07-06 18:29:57.325] [nrf_app] [debug] NF Profile with ID d4f729dd-565b-4d02-95e3-934b8287fb16, NF type SMF
[2024-07-06 18:29:57.326] [nrf_app] [debug] Convert a json-type profile to a NF profile (profile ID: d4f729dd-565b-4d02-95e3-934b8287fb16)
[2024-07-06 18:29:57.326] [nrf_app] [debug]     Instance name: OAI-SMF
[2024-07-06 18:29:57.326] [nrf_app] [debug] Set NF status to REGISTERED
[2024-07-06 18:29:57.326] [nrf_app] [debug] getCustomInfo -> null
[2024-07-06 18:29:57.326] [nrf_app] [debug]     Status: REGISTERED
[2024-07-06 18:29:57.326] [nrf_app] [debug]     Heartbeat timer: 50
[2024-07-06 18:29:57.326] [nrf_app] [debug]     Priority: 1
[2024-07-06 18:29:57.326] [nrf_app] [debug]     Capacity: 100
[2024-07-06 18:29:57.326] [nrf_app] [debug]     SNSSAI (SD, SST): 1, 16777215
[2024-07-06 18:29:57.326] [nrf_app] [debug]     IPv4 Addr: 192.168.70.140
[2024-07-06 18:29:57.326] [nrf_app] [debug]     SMF profile, SMF Info
[2024-07-06 18:29:57.326] [nrf_app] [debug]             NSSAI SD: 16777215, SST: 1
[2024-07-06 18:29:57.326] [nrf_app] [debug]             DNN: oai
[2024-07-06 18:29:57.326] [nrf_app] [info] Check if a profile with this ID d4f729dd-565b-4d02-95e3-934b8287fb16 exist
[2024-07-06 18:29:57.326] [nrf_app] [info] NF profile (ID d4f729dd-565b-4d02-95e3-934b8287fb16) not found
[2024-07-06 18:29:57.326] [nrf_app] [info] Added/Updated NF Profile (ID d4f729dd-565b-4d02-95e3-934b8287fb16) to the DB
[2024-07-06 18:29:57.326] [nrf_app] [debug] Subscribe to the HeartbeatTimer expire event (after NF registration): interval 20, current time 1720290597326
[2024-07-06 18:29:57.326] [nrf_app] [info] Handle NF status registered event, profile id d4f729dd-565b-4d02-95e3-934b8287fb16
[2024-07-06 18:29:57.326] [nrf_app] [info]      Find a NF profile with ID d4f729dd-565b-4d02-95e3-934b8287fb16
[2024-07-06 18:29:57.326] [nrf_app] [info]      Get the list of subscriptions related to this profile, profile id d4f729dd-565b-4d02-95e3-934b8287fb16
[2024-07-06 18:29:57.326] [nrf_app] [info]      Verifying subscription, subscription id 1
[2024-07-06 18:29:57.326] [nrf_app] [debug]     Current time 20240706T182957.326195
[2024-07-06 18:29:57.326] [nrf_app] [info]      Verifying subscription, subscription id 2
[2024-07-06 18:29:57.326] [nrf_app] [debug]     Current time 20240706T182957.326225
[2024-07-06 18:29:57.326] [nrf_app] [debug]     No subscription found
[2024-07-06 18:29:57.326] [nrf_app] [debug] Added/Updated NF Profile with the NF instance info
[2024-07-06 18:29:57.326] [nrf_app] [debug] NF instance info
[2024-07-06 18:29:57.326] [nrf_app] [debug]     Instance ID: d4f729dd-565b-4d02-95e3-934b8287fb16
[2024-07-06 18:29:57.326] [nrf_app] [debug]     Instance name: OAI-SMF
[2024-07-06 18:29:57.326] [nrf_app] [debug]     Instance type: SMF
[2024-07-06 18:29:57.326] [nrf_app] [debug]     Status: REGISTERED
[2024-07-06 18:29:57.326] [nrf_app] [debug]     HeartBeat timer: 10
```
This is subscription for SMF with NSSAI (ffffff 1) ( the default one)


```
[2024-07-06 18:29:56.163] [nrf_app] [debug] Added a subscription to the DB
[2024-07-06 18:29:56.163] [nrf_app] [debug] Subscription information
[2024-07-06 18:29:56.163] [nrf_app] [debug]     Sub ID: 1
[2024-07-06 18:29:56.163] [nrf_app] [debug]     Notification URI: 192.168.70.139:8080/nsmf-nfstatus-notify/v1/subscriptions
[2024-07-06 18:29:56.163] [nrf_app] [debug]     Subscription condition: Type: NF_TYPE_COND, condition: UPF
[2024-07-06 18:29:56.163] [nrf_app] [debug]     Notification Events: NF_REGISTERED, NF_DEREGISTERED,
[2024-07-06 18:29:56.163] [nrf_app] [debug]     Validity time: 20390531T235959
[2024-07-06 18:29:56.171] [nrf_sbi] [info] Got a request to register an NF instance/Update an NF instance, Instance ID: 83011b63-dac3-4662-9af7-3d951dd0849d
[2024-07-06 18:29:56.171] [nrf_app] [info] Handle Register NF Instance/Update NF Instance (HTTP version 2)
[2024-07-06 18:29:56.172] [nrf_app] [debug] NF Profile with ID 83011b63-dac3-4662-9af7-3d951dd0849d, NF type SMF
[2024-07-06 18:29:56.172] [nrf_app] [debug] Convert a json-type profile to a NF profile (profile ID: 83011b63-dac3-4662-9af7-3d951dd0849d)
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Instance name: OAI-SMF
[2024-07-06 18:29:56.172] [nrf_app] [debug] Set NF status to REGISTERED
[2024-07-06 18:29:56.172] [nrf_app] [debug] getCustomInfo -> null
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Status: REGISTERED
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Heartbeat timer: 50
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Priority: 1
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Capacity: 100
[2024-07-06 18:29:56.172] [nrf_app] [debug]     SNSSAI (SD, SST): 128, 128
[2024-07-06 18:29:56.172] [nrf_app] [debug]     IPv4 Addr: 192.168.70.139
[2024-07-06 18:29:56.172] [nrf_app] [debug]     SMF profile, SMF Info
[2024-07-06 18:29:56.172] [nrf_app] [debug]             NSSAI SD: 128, SST: 128
[2024-07-06 18:29:56.172] [nrf_app] [debug]             DNN: default
[2024-07-06 18:29:56.172] [nrf_app] [info] Check if a profile with this ID 83011b63-dac3-4662-9af7-3d951dd0849d exist
[2024-07-06 18:29:56.172] [nrf_app] [info] NF profile (ID 83011b63-dac3-4662-9af7-3d951dd0849d) not found
[2024-07-06 18:29:56.172] [nrf_app] [info] Added/Updated NF Profile (ID 83011b63-dac3-4662-9af7-3d951dd0849d) to the DB
[2024-07-06 18:29:56.172] [nrf_app] [debug] Subscribe to the HeartbeatTimer expire event (after NF registration): interval 20, current time 1720290596172
[2024-07-06 18:29:56.172] [nrf_app] [info] Handle NF status registered event, profile id 83011b63-dac3-4662-9af7-3d951dd0849d
[2024-07-06 18:29:56.172] [nrf_app] [info]      Find a NF profile with ID 83011b63-dac3-4662-9af7-3d951dd0849d
[2024-07-06 18:29:56.172] [nrf_app] [info]      Get the list of subscriptions related to this profile, profile id 83011b63-dac3-4662-9af7-3d951dd0849d
[2024-07-06 18:29:56.172] [nrf_app] [info]      Verifying subscription, subscription id 1
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Current time 20240706T182956.172899
[2024-07-06 18:29:56.172] [nrf_app] [debug]     No subscription found
[2024-07-06 18:29:56.172] [nrf_app] [debug] Added/Updated NF Profile with the NF instance info
[2024-07-06 18:29:56.172] [nrf_app] [debug] NF instance info
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Instance ID: 83011b63-dac3-4662-9af7-3d951dd0849d
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Instance name: OAI-SMF
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Instance type: SMF
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Status: REGISTERED
[2024-07-06 18:29:56.172] [nrf_app] [debug]     HeartBeat timer: 10
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Priority: 1
[2024-07-06 18:29:56.172] [nrf_app] [debug]     Capacity: 100
```
above is the subscription for another slice configured to register with this NRF. 

I can also see how it add the UPF to the network funciton repo, 

```
[2024-07-06 18:29:58.627] [nrf_sbi] [info] Got a request to register an NF instance/Update an NF instance, Instance ID: 51009c63-8f48-45c0-a5e4-d131f0214db7
[2024-07-06 18:29:58.627] [nrf_app] [info] Handle Register NF Instance/Update NF Instance (HTTP version 2)
[2024-07-06 18:29:58.627] [nrf_app] [debug] NF Profile with ID 51009c63-8f48-45c0-a5e4-d131f0214db7, NF type UPF
[2024-07-06 18:29:58.627] [nrf_app] [debug] Convert a json-type profile to a NF profile (profile ID: 51009c63-8f48-45c0-a5e4-d131f0214db7)
[2024-07-06 18:29:58.627] [nrf_app] [debug]     Instance name: OAI-UPF
[2024-07-06 18:29:58.627] [nrf_app] [debug] Set NF status to REGISTERED
[2024-07-06 18:29:58.627] [nrf_app] [debug] getCustomInfo -> null
[2024-07-06 18:29:58.627] [nrf_app] [debug]     Status: REGISTERED
[2024-07-06 18:29:58.627] [nrf_app] [debug]     Heartbeat timer: 50
[2024-07-06 18:29:58.627] [nrf_app] [debug]     Priority: 1
[2024-07-06 18:29:58.627] [nrf_app] [debug]     Capacity: 100
[2024-07-06 18:29:58.627] [nrf_app] [debug]     SNSSAI (SD, SST): 128, 128
[2024-07-06 18:29:58.627] [nrf_app] [debug]     FQDN:
[2024-07-06 18:29:58.627] [nrf_app] [debug]     IPv4 Addr: 192.168.70.142
[2024-07-06 18:29:58.627] [nrf_app] [debug]     UPF profile, UPF Info
[2024-07-06 18:29:58.627] [nrf_app] [debug]             NSSAI SD: 128, SST: 128
[2024-07-06 18:29:58.627] [nrf_app] [debug]             DNN: default
[2024-07-06 18:29:58.627] [nrf_app] [info] Check if a profile with this ID 51009c63-8f48-45c0-a5e4-d131f0214db7 exist
[2024-07-06 18:29:58.627] [nrf_app] [info] NF profile (ID 51009c63-8f48-45c0-a5e4-d131f0214db7) not found
[2024-07-06 18:29:58.627] [nrf_app] [info] Added/Updated NF Profile (ID 51009c63-8f48-45c0-a5e4-d131f0214db7) to the DB
```
and it seems to be configured with the right NSSAI. 

#### NRF for slice 3
similar to above, I can also see the SMF and UPF subscription each with the NSSAI. 

Below is just for the UPF for slice 3. 
```
[2024-07-06 18:30:06.140] [nrf_sbi] [info] Got a request to register an NF instance/Update an NF instance, Instance ID: 79d60489-ad94-45d0-8bc9-84da923c1b1e
[2024-07-06 18:30:06.140] [nrf_app] [info] Handle Register NF Instance/Update NF Instance (HTTP version 2)
[2024-07-06 18:30:06.140] [nrf_app] [debug] NF Profile with ID 79d60489-ad94-45d0-8bc9-84da923c1b1e, NF type UPF
[2024-07-06 18:30:06.140] [nrf_app] [debug] Convert a json-type profile to a NF profile (profile ID: 79d60489-ad94-45d0-8bc9-84da923c1b1e)
[2024-07-06 18:30:06.140] [nrf_app] [debug]     Instance name: VPP-UPF
[2024-07-06 18:30:06.140] [nrf_app] [debug] Set NF status to REGISTERED
[2024-07-06 18:30:06.140] [nrf_app] [debug] getCustomInfo -> null
[2024-07-06 18:30:06.140] [nrf_app] [debug]     Status: REGISTERED
[2024-07-06 18:30:06.140] [nrf_app] [debug]     Heartbeat timer: 10
[2024-07-06 18:30:06.140] [nrf_app] [debug]     Priority: 1
[2024-07-06 18:30:06.140] [nrf_app] [debug]     Capacity: 100
[2024-07-06 18:30:06.140] [nrf_app] [debug]     SNSSAI (SD, SST): 130, 130
[2024-07-06 18:30:06.140] [nrf_app] [debug]     FQDN: vpp-upf.node.5gcn.mnc95.mcc208.3gppnetwork.org
[2024-07-06 18:30:06.140] [nrf_app] [debug]     IPv4 Addr: 192.168.70.201
[2024-07-06 18:30:06.140] [nrf_app] [debug]     UPF profile, UPF Info
[2024-07-06 18:30:06.140] [nrf_app] [debug]             NSSAI SD: 130, SST: 130
[2024-07-06 18:30:06.140] [nrf_app] [debug]             DNN: oai.ipv4
[2024-07-06 18:30:06.140] [nrf_app] [debug]             Endpoint: N6, IPv4 Addr: 192.168.73.201, FQDN: internet.oai.org, NWI: internet.oai.org
[2024-07-06 18:30:06.140] [nrf_app] [debug]             Endpoint: N3, IPv4 Addr: 192.168.72.201, FQDN: access.oai.org, NWI: access.oai.org
[2024-07-06 18:30:06.140] [nrf_app] [info] Check if a profile with this ID 79d60489-ad94-45d0-8bc9-84da923c1b1e exist
[2024-07-06 18:30:06.140] [nrf_app] [info] NF profile (ID 79d60489-ad94-45d0-8bc9-84da923c1b1e) not found
[2024-07-06 18:30:06.140] [nrf_app] [info] Added/Updated NF Profile (ID 79d60489-ad94-45d0-8bc9-84da923c1b1e) to the DB
```


#### SMF for slice 1 
I can see that it is configured with the peering UPF and the right NSSSAI:
```
[2024-07-06 18:29:55.145] [config ] [info]     + oai-upf
[2024-07-06 18:29:55.145] [config ] [info]       + host...................................: oai-upf
[2024-07-06 18:29:55.145] [config ] [info]       + port...................................: 8805
[2024-07-06 18:29:55.145] [config ] [info]       + enable_usage_reporting.................: No
[2024-07-06 18:29:55.145] [config ] [info]       + enable_dl_pdr_in_session_establishment.: No
[2024-07-06 18:29:55.145] [config ] [info]   Local Subscription Infos:
[2024-07-06 18:29:55.145] [config ] [info]     - local_subscription_info
[2024-07-06 18:29:55.145] [config ] [info]       + dnn....................................: default
[2024-07-06 18:29:55.145] [config ] [info]       + ssc_mode...............................: 1
[2024-07-06 18:29:55.145] [config ] [info]       + snssai:
[2024-07-06 18:29:55.145] [config ] [info]         - sst..................................: 128
[2024-07-06 18:29:55.145] [config ] [info]         - sd...................................: 0x000080 (128)
[2024-07-06 18:29:55.145] [config ] [info]       + qos_profile:
[2024-07-06 18:29:55.145] [config ] [info]         - 5qi..................................: 5
[2024-07-06 18:29:55.145] [config ] [info]         - priority.............................: 1
[2024-07-06 18:29:55.145] [config ] [info]         - arp_priority.........................: 1
[2024-07-06 18:29:55.145] [config ] [info]         - arp_preempt_vulnerability............: NOT_PREEMPTABLE
[2024-07-06 18:29:55.145] [config ] [info]         - arp_preempt_capability...............: NOT_PREEMPT
[2024-07-06 18:29:55.145] [config ] [info]         - session_ambr_dl......................: 100Mbps
[2024-07-06 18:29:55.145] [config ] [info]         - session_ambr_ul......................: 50Mbps
[2024-07-06 18:29:55.145] [config ] [info]   + smf_info:
[2024-07-06 18:29:55.145] [config ] [info]     - snssai_smf_info_item:
[2024-07-06 18:29:55.145] [config ] [info]       + snssai:
[2024-07-06 18:29:55.145] [config ] [info]         - sst..................................: 128
[2024-07-06 18:29:55.145] [config ] [info]         - sd...................................: 0x000080 (128)
[2024-07-06 18:29:55.145] [config ] [info]       + dnns:
[2024-07-06 18:29:55.145] [config ] [info]         - dnn..................................: default
[2024-07-06 18:29:55.145] [config ] [info] Peer NF Configuration:
[2024-07-06 18:29:55.145] [config ] [info]   nrf:
[2024-07-06 18:29:55.145] [config ] [info]     - host.....................................: oai-nrf-slice12
[2024-07-06 18:29:55.145] [config ] [info]     - sbi
[2024-07-06 18:29:55.145] [config ] [info]       + URL....................................: http://oai-nrf-slice12:8080
[2024-07-06 18:29:55.145] [config ] [info]       + API Version............................: v1
[2024-07-06 18:29:55.146] [config ] [info] DNNs:
[2024-07-06 18:29:55.146] [config ] [info] - DNN:
[2024-07-06 18:29:55.146] [config ] [info]     + DNN......................................: default
[2024-07-06 18:29:55.146] [config ] [info]     + PDU session type.........................: IPV4
[2024-07-06 18:29:55.146] [config ] [info]     + IPv4 subnet..............................: 12.2.1.0/25
[2024-07-06 18:29:55.146] [config ] [info]     + DNS Settings:
[2024-07-06 18:29:55.146] [config ] [info]       - primary_dns_ipv4.......................: 172.21.3.100
[2024-07-06 18:29:55.146] [config ] [info]       - secondary_dns_ipv4.....................: 8.8.8.8
[2024-07-06 18:29:55.146] [itti   ] [start] Starting...
```

And I can also see it creating a PDU session. 

#### UPF
All I can see is the basic info about this UPF, and the constant heartbeat between UPF and NRF. 

As said, UPF has the NSSAI info within:
```
[2024-07-06 20:29:58.489] [config ] [debug] PDN Network validation for UE Subnet:  12.2.1.0
[2024-07-06 20:29:58.489] [config ] [debug] IP Pool :  12.2.1.1 - 12.2.1.126
[2024-07-06 20:29:58.490] [config ] [info] ==== OPENAIRINTERFACE upf vBranch: HEAD Abrev. Hash: 93cab8f Date: Thu Dec 14 14:16:09 2023 +0000 ====
[2024-07-06 20:29:58.490] [config ] [info] Basic Configuration:
[2024-07-06 20:29:58.490] [config ] [info]   - log_level..................................: debug
[2024-07-06 20:29:58.490] [config ] [info]   - register_nf................................: Yes
[2024-07-06 20:29:58.490] [config ] [info]   - http_version...............................: 2
[2024-07-06 20:29:58.490] [config ] [info] UPF Configuration:
[2024-07-06 20:29:58.490] [config ] [info]   - host.......................................: oai-upf
[2024-07-06 20:29:58.490] [config ] [info]   - SBI
[2024-07-06 20:29:58.490] [config ] [info]     + URL......................................: http://oai-upf:8080
[2024-07-06 20:29:58.490] [config ] [info]     + API Version..............................: v1
[2024-07-06 20:29:58.490] [config ] [info]     + IPv4 Address ............................: 192.168.70.142
[2024-07-06 20:29:58.490] [config ] [info]   - N3:
[2024-07-06 20:29:58.490] [config ] [info]     + Port.....................................: 2152
[2024-07-06 20:29:58.490] [config ] [info]     + IPv4 Address ............................: 192.168.70.142
[2024-07-06 20:29:58.490] [config ] [info]     + MTU......................................: 1500
[2024-07-06 20:29:58.490] [config ] [info]     + Interface name: .........................: eth0
[2024-07-06 20:29:58.490] [config ] [info]     + Network Instance.........................: access.oai.org
[2024-07-06 20:29:58.490] [config ] [info]   - N4:
[2024-07-06 20:29:58.490] [config ] [info]     + Port.....................................: 8805
[2024-07-06 20:29:58.490] [config ] [info]     + IPv4 Address ............................: 192.168.70.142
[2024-07-06 20:29:58.490] [config ] [info]     + MTU......................................: 1500
[2024-07-06 20:29:58.490] [config ] [info]     + Interface name: .........................: eth0
[2024-07-06 20:29:58.490] [config ] [info]   - N6:
[2024-07-06 20:29:58.490] [config ] [info]     + Port.....................................: 2152
[2024-07-06 20:29:58.490] [config ] [info]     + IPv4 Address ............................: 192.168.70.142
[2024-07-06 20:29:58.490] [config ] [info]     + MTU......................................: 1500
[2024-07-06 20:29:58.490] [config ] [info]     + Interface name: .........................: eth0
[2024-07-06 20:29:58.490] [config ] [info]     + Network Instance.........................: core.oai.org
[2024-07-06 20:29:58.490] [config ] [info]   - Instance ID................................: 0
[2024-07-06 20:29:58.490] [config ] [info]   - Remote N6 Gateway..........................: localhost
[2024-07-06 20:29:58.490] [config ] [info]   - Support Features:
[2024-07-06 20:29:58.490] [config ] [info]     + Enable BPF Datapath......................: No
[2024-07-06 20:29:58.490] [config ] [info]     + Enable SNAT..............................: Yes
[2024-07-06 20:29:58.490] [config ] [info]   - upf_info:
[2024-07-06 20:29:58.490] [config ] [info]     + snssai_upf_info_item:
[2024-07-06 20:29:58.490] [config ] [info]       - snssai:
[2024-07-06 20:29:58.490] [config ] [info]         + sst..................................: 128
[2024-07-06 20:29:58.490] [config ] [info]         + sd...................................: 0x000080 (128)
[2024-07-06 20:29:58.490] [config ] [info]       - dnns:
[2024-07-06 20:29:58.490] [config ] [info]         + dnn..................................: default
```
#### gNB

For the log of the gnb and the ue. I will only check the OAI ones, cuz I don't care about the rest. 

it does has nssai preocnfigured. 
```
gNBs =
(
 {
    ////////// Identification parameters:
    gNB_ID = 0xe00;

#     cell_type =  "CELL_MACRO_GNB";

    gNB_name  =  "gnb-rfsim";

    // Tracking area code, 0x0000 and 0xfffe are reserved values
    tracking_area_code  =  40960;

    plmn_list = ({ mcc = 208; mnc = 95; mnc_length = 2; snssaiList = ({ sst = 1, sd = 0xffffff }) });

    nr_cellid = 12345678L

#     tr_s_preference     = "local_mac"
```

and it is preconfigured with the amf address, which is not surprising.

The rest si what you would see in a gnb log file. 


#### UE
Nothing in particular. 


## Docker compose and config

I think that the logs is interesting, but more interesting is to look at the docker compose file and to see how things are actually brought together. Becuase they are just standard containers, and somehow they are brought together to form slices with the confi and docker compose. 

#### NSSF 
NSSF is one of the most importatnt, so I want to see its conf file. 

The first file,  ./conf/slicing_base_config.yaml, is recurrent in many containers. 

#### the nssf_slice_config.yaml
To be frank I do not totally understand it, but there are several things worth noticing:

```yaml
# Reference:- TS 29.531 R16.0.0., Section- 6.1.6 Data Model 
info:
  version: 1.4.0
  description: OAI-NSSF Release v1.4.0
configuration:
  nsiInfoList:
    - snssai:
        sst: 128
        sd: '128'
      nsiInformationList:
        nrfId: http://192.168.70.136:8080/nnrf-disc/v1/nf-instances
        nsiId: '11'
    - snssai:
        sst: 1
      nsiInformationList:
        nrfId: http://192.168.70.136:8080/nnrf-disc/v1/nf-instances
        nsiId: '12'
    - snssai:
        sst: 130
        sd: '130'
      nsiInformationList:
        nrfId: http://192.168.70.137:8080/nnrf-disc/v1/nf-instances
        nsiId: '12'
    - snssai:
        sst: 222
        sd: '123'
      nsiInformationList:
        nrfId: http://oai-cn5g-nrf-10.fr:8080/nnrf-disc/v1/nf-instances
        nsiId: '11'
    - snssai:
        sst: 130
      nsiInformationList:
        nrfId: http://oai-cn5g-nrf-20.fr:8080/nnrf-disc/v1/nf-instances
        nsiId: '20'
        nrfNfMgtUri: http://oai-cn5g-nrf-10.fr:8080/nnrf-nfm/v1/nf-instances
    - snssai:
        sst: 131
        sd: '131'
      nsiInformationList:
        nrfId: http://oai-cn5g-nrf-20.fr:8080/nnrf-disc/v1/nf-instances
        nsiId: '20'
    - snssai:
        sst: 132
        sd: '132'
      nsiInformationList:
        nrfId: http://oai-cn5g-nrf-20.fr:8080/nnrf-disc/v1/nf-instances
        nsiId: '20'
    - snssai:
        sst: 133
      nsiInformationList:
        nrfId: http://oai-cn5g-nrf-20.fr:8080/nnrf-disc/v1/nf-instances
        nsiId: '20'
  taInfoList:
    - tai:
        plmnId:
          mcc: '208'
          mnc: '95'
        tac: '33456'
      supportedSnssaiList:
      - sst: 222
        sd: '123'
      - sst: 128
  amfInfoList:
    - targetAmfSet: oai5gcn.mcc208.mnc95.regionid128.setid1.3gppnetwork.org
      nrfAmfSet: http://oai-cn5g-nrf.fr:8080/nnrf-disc/v1/nf-instances'
      nrfAmfSetNfMgtUri: http://oai-cn5g-nrf.fr:8080/nnrf-nfm/v1/nf-instances
      amfList:
        - nfId: 405e8251-cc5a-45dd-a494-efb9eaf1cd58
          supportedNssaiAvailabilityData:
              tai:
                plmnId:
                  mcc: 208
                  mnc: 95
                tac: 33456
              supportedSnssaiList:
                - sst: 128
                  sd: 128
                - sst: 1
                - sst: 130
                  sd: 130
        - nfId: 405e8251-cc5a-45dd-a494-efb9eaf1cd68
          supportedNssaiAvailabilityData:
              tai:
                plmnId:
                  mcc: 208
                  mnc: 95
                tac: 33457
              supportedSnssaiList:
                - sst: 130
                - sst: 131
                  sd: 131
              taiList:
                - tai:
                    plmnId:
                      mcc: 208
                      mnc: 95
                    tac: 33458
                  supportedSnssaiList:
                    - sst: 132
                      sd: 132
    - targetAmfSet: oai5gcn.mcc208.mnc95.regionid128.setid2.3gppnetwork.org
      nrfAmfSet: http://oai-cn5g-nrf.fr:8080/nnrf-disc/v1/nf-instances
      nrfAmfSetNfMgtUri: http://oai-cn5g-nrf.fr:8080/nnrf-nfm/v1/nf-instances
      amfList:
        - nfId: 405e8251-cc5a-45dd-a494-efb9eaf1cd78
          supportedNssaiAvailabilityData:
              tai:
                plmnId:
                  mcc: 208
                  mnc: 95
                tac: 33460
              supportedSnssaiList:
                - sst: 133
```

I can see a list of nssai configured. Three of them are useful (128, 1, 130). They all configure to the corresponsing nrf. 


I can see a list of amf. We really only need 1, but 2 amf is provided. One of them gives what we want. 

```
        - nfId: 405e8251-cc5a-45dd-a494-efb9eaf1cd58
          supportedNssaiAvailabilityData:
              tai:
                plmnId:
                  mcc: 208
                  mnc: 95
                tac: 33456
              supportedSnssaiList:
                - sst: 128
                  sd: 128
                - sst: 1
                - sst: 130
                  sd: 130
```
Which is exaclty what it is trying to configure. 

On the other hand, the slicing base config is much clearer. It is basically trying to configure the AMF module. 

```
################################################################################
# Licensed to the OpenAirInterface (OAI) Software Alliance under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The OpenAirInterface Software Alliance licenses this file to You under
# the OAI Public License, Version 1.1  (the "License"); you may not use this file
# except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.openairinterface.org/?page_id=698
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#-------------------------------------------------------------------------------
# For more information about the OpenAirInterface (OAI) Software Alliance:
#      contact@openairinterface.org
################################################################################

# OAI CN Configuration File
### This file can be used by all OAI NFs
### Some fields are specific to an NF and will be ignored by other NFs

############# Common configuration

# Log level for all the NFs
log_level:
  general: debug

# If you enable registration, the other NFs will use the NRF discovery mechanism
register_nf:
  general: yes

http_version: 2

############## SBI Interfaces
### Each NF takes its local SBI interfaces and remote interfaces from here, unless it gets them using NRF discovery mechanisms
nfs:
  amf:
    host: oai-amf
    sbi:
      port: 8080
      api_version: v1
      interface_name: eth0
    n2:
      interface_name: eth0
      port: 38412
  udm:
    host: oai-udm
    sbi:
      port: 8080
      api_version: v1
      interface_name: eth0
  udr:
    host: oai-udr
    sbi:
      port: 8080
      api_version: v1
      interface_name: eth0
  ausf:
    host: oai-ausf
    sbi:
      port: 8080
      api_version: v1
      interface_name: eth0
  nssf:
    host: oai-nssf
    sbi:
      port: 8080
      api_version: v1
      interface_name: eth0

#### Common for UDR and AMF
database:
  host: mysql
  user: test
  type: mysql
  password: test
  database_name: oai_db
  generate_random: true
  connection_timeout: 300 # seconds

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
  relative_capacity: 30
  statistics_timer_interval: 20  # in seconds
  emergency_support: false
  served_guami_list:
    - mcc: 208
      mnc: 95
      amf_region_id: 01
      amf_set_id: 001
      amf_pointer: 01
    - mcc: 001
      mnc: 01
      amf_region_id: 01
      amf_set_id: 001
      amf_pointer: 01
  plmn_support_list:
    - mcc: 208
      mnc: 95
      tac: 0xa000
      nssai:
        - sst: 1
        - sst: 1
          sd: 000001 # in hex
        - sst: 222
          sd: 00007B # in hex
        - sst: 128
          sd: 000080 # in hex
        - sst: 130
          sd: 000082 # in hex
  supported_integrity_algorithms:
    - "NIA1"
    - "NIA2"
  supported_encryption_algorithms:
    - "NEA1"
    - "NEA2"
nssf:
  slice_config_path: /openair-nssf/etc/nssf_slice_config.yaml
```
I can see that it is stating which plmn it is serving and the GUAMI. I cna see that it is supporting which sst and sd. 

Looking at slicing specific config file, I can see the following:

```
################################################################################
# Licensed to the OpenAirInterface (OAI) Software Alliance under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The OpenAirInterface Software Alliance licenses this file to You under
# the OAI Public License, Version 1.1  (the "License"); you may not use this file
# except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.openairinterface.org/?page_id=698
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#-------------------------------------------------------------------------------
# For more information about the OpenAirInterface (OAI) Software Alliance:
#      contact@openairinterface.org
################################################################################

# OAI CN Configuration File
### This file can be used by all OAI NFs
### Some fields are specific to an NF and will be ignored by other NFs

## NOTE ON YAML ANCHORS ##
# We use YAML anchors to ease the configuration and to avoid duplicating parts of the configuration.
# This is especially true for the SNSSAIs, as we have to define them for multiple NFs.
# Please note that the use of anchors is not mandatory, and you can define the SNSSAI in each NF yourself.
# You can read more about anchors here: https://yaml.org/spec/1.2.2/#anchors-and-aliases

############# Common configuration

# This file is only used by the SMF and NRF of slice 1, non-SMF configuration is omitted

# Log level for all the NFs
log_level:
  general: debug

# If you enable registration, the other NFs will use the NRF discovery mechanism
register_nf:
  general: yes

http_version: 2

############## SBI Interfaces
nfs:
  smf:
    host: oai-smf-slice1
    sbi:
      port: 8080
      api_version: v1
      interface_name: eth0
    n4:
      interface_name: eth0
      port: 8805
  nrf:
    host: oai-nrf-slice12
    sbi:
      port: 8080
      api_version: v1
      interface_name: eth0
  upf:
    host: oai-upf
    sbi:
      port: 8080
      api_version: v1
      interface_name: eth0
    n3:
      interface_name: eth0
      port: 2152
    n4:
      interface_name: eth0
      port: 8805
    n6:
      interface_name: eth0
    n9:
      interface_name: eth0
      port: 2152

# anchor is set to re-use slice config in SMF
snssais:
  - &slice1
    sst: 128
    sd: 000080 # in hex

smf:
  support_features:
    use_local_subscription_info: yes # Use infos from local_subscription_info or from UDM
    use_local_pcc_rules: yes # Use infos from local_pcc_rules or from PCF
  ue_dns:
    primary_ipv4: "172.21.3.100"
    secondary_ipv4: "8.8.8.8"
  # the DNN you configure here should be configured in "dnns"
  # follows the SmfInfo datatype from 3GPP TS 29.510
  smf_info:
    sNssaiSmfInfoList:
      - sNssai: *slice1
        dnnSmfInfoList:
          - dnn: "default"
  local_subscription_infos:
    - single_nssai: *slice1
      dnn: "default"
      qos_profile:
        5qi: 5
        session_ambr_ul: "50Mbps"
        session_ambr_dl: "100Mbps"

upf:
  support_features:
    enable_bpf_datapath: no    # If "on": BPF is used as datapath else simpleswitch is used, DEFAULT= off
    enable_snat: yes           # If "on": Source natting is done for UE, DEFAULT= off
  remote_n6_gw: localhost      # Dummy host since simple-switch does not use N6 GW
  upf_info:
    sNssaiUpfInfoList:
      - sNssai: *slice1
        dnnUpfInfoList:
          - dnn: "default"

## DNN configuration
dnns:
  - dnn: "default"
    pdu_session_type: "IPV4"
    ipv4_subnet: "12.2.1.0/25"

```

The first part is as usual, it is just replacing the functioniality of an nrf by providing the name and interfaces each NF should expose themselves. 

Then it is telling the upf which slice it should support, and also the smf. 

And looking at the configuration file for the second slice with the gnb, combined with our existing knowledge of the RAN slicing with OAI. I has a theory. The reason why all other slices had a sst and sd is that they being simulators naturally support them. 1 however is the default slice for all data anyway, hence the slice that demo with OAI is can only do that. It seems that we still need to know more about the OAI part. 

