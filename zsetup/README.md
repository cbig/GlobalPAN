# GPAN connectivity variants

1. 01_gpc_abf_mam
1. 02_gpc_abf_mam_hms
1. 03_gpc_abf_mam_hms_plu
1. 04_gpc_abf_mam_hms_plu_dsc
1. 05_gpc_abf_mam_hms_plu_dsa (+ set of runs with varied weights?)
1. 06_gpc_abf_mam_hms_plu_dcc
1. 07_gpc_abf_mam_hms_plu_dca (+ set of runs with varied weights?)
1. 08_gpc_abf_mam_hms_plu_dsa_dca (+ set of runs with varied weights)

## Description

| Code | Description                                  |
|------|----------------------------------------------|
| abf | additive benefit function|
| mam | mammal distributions, modelled (see Rondinini et al. 2011)|
| hms | hierarchical mask, protected areas|
| plu | planning units, protected areas as planning units, the layer is produced based on [link to the decision rule] |
| dsc | connectivity using distribution smoothing, species specific|
| dsa | connectivity using distribution smoothing, using arbitrary kernels|
| bcc | betweenness centrality connectivity, species specific|
| bca | betweenness centrality connectivity, using arbitrary kernels|
