SELECT A1.wdpaid as from_ID, A2.wdpaid as to_ID, ST_Distance(A1.geom, A2.geom) 
FROM wdpa.wdpa_poly as A1, wdpa.wdpa_poly as A2
WHERE A1.iso3 = 'FIN' AND 
      A1.iucn_cat = 'Ia' AND 
      A2.iso3 = 'FIN' AND 
      A2.iucn_cat = 'Ia' AND
      A1.wdpaid < A2.wdpaid
ORDER BY A1.wdpaid, A2.wdpaid