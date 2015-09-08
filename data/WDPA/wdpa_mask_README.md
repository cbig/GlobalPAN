## WDPA mask

```
uri:       wdpa_mask.tif  
metadata:  wdpa_mask_meta.json
mediatype: GeoTIFF  
createdOn: 2015-09-06T13:52:00+03:00  
createdBy:  
  name:    Joona Lehtomäki
  email:   joona.lehtomaki@gmail.com
  orcid:   http://orcid.org/0000-0002-7891-0843
  uri":    https://jlehtoma.github.com
referenceRepo: ADD DOI
```

## Description

This is rasterized version of the World Database on Protected Areas (WDPA) 
covering the whole globe on a 0.0166667 degree resolution. Marine PAs are 
excluded. Because of the heterogenous and overlapping content of the WDPA,
the rasterization uses the following decision logic in deciding which value
(WDPAID) is assigned: 

For overlapping polygons, 

1. Select the higher IUCN category 
(Ia > Ib > II> > III > IV > V > VI > [Not Assigned, Not Applicable, 
Not Repored]).
2. If the IUCN category is the same for one or more polygons, select the one 
with the largest total area within the aggreagte pixel.
3. If the total area within the aggreagte pixel is the same for one or more
polygons, select the one with the largest overall area (also outside the
aggregate pixel).
4. If the largest overall area is the same for one or more polygons, select
the one with the larger WDPAID value.
5. Value assigned to the resulting raster pixel is the value from field 
`WDPAID` in the original data.

## Provenance

1. Source data (`WDPA_June2015.zip`) downloaded from [http://www.protectedplanet.net](http://www.protectedplanet.net) on 2015-06-05.
2. Data unzipped and marine areas filtered out using 
`src/01_preprocess/01_unzip_and_subset_WDPA.R`
3. Data rasterized using `src/01_preprocess/02_rasterize_WDPA.R`
