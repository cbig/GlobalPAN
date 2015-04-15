SELECT 
  ISO3, IUCN_CAT, COUNT(*), sum(ST_Area(Geography(geom))) AS computed_area_km, rep_area AS rep_area_km
FROM 
  public.wdpa_150312
WHERE
  marine = '0'
GROUP BY	
  ISO3, IUCN_CAT, rep_area
ORDER BY
  ISO3, IUCN_CAT;