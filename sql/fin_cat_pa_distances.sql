-- ('Ia','Ib','II' ,'III','IV','V','VI')
WITH fin_cat_pa AS (
    SELECT * FROM wdpa.wdpa_poly
    WHERE iso3 = 'FIN' AND iucn_cat IN ('Ia')
 )
SELECT f1.wdpaid AS from_ID, f2.wdpaid AS to_ID,
  ST_Distance(f1.geog, f2.geog) / 1000 AS distance_km
FROM fin_cat_pa f1 CROSS JOIN fin_cat_pa f2
WHERE f1.wdpaid < f2.wdpaid
ORDER BY f1.wdpaid, f2.wdpaid
-- When using geom (geometry type):
--   geometry type runs in 817 ms
--   geography (casting) type runs in 50282 ms
-- When using geog (gegraphy type):
--   geometry (casting) type runs in 978 ms
--   geography type runs in 49608 ms
-- AFTER CLUSTERING 
--   CLUSTER wdpa.wdpa_poly USING wdpa_poly_geog_idx;
-- When using geog (gegraphy type):
--   geometry (casting) type runs in  ms
--   geography type runs in 206853 ms 