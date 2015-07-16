SELECT f1.wdpaid AS f1_ID, f2.wdpaid AS f2_ID, 
FROM wdpa.wdpa_poly_geom_fin f1,
     wdpa.wdpa_poly_geom_fin f2
WHERE f1.wdpaid < f2.wdpaid AND
  ST_Overlaps(f1.geom, f2.geom)
ORDER BY f1.wdpaid, f2.wdpaid
