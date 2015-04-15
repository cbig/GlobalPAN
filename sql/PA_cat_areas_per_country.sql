SELECT 
  ISO3, IUCN_CAT, COUNT(*), sum(ST_Area(Geography(geom))) / 10000 AS area_ha
FROM 
  public.wdpa_150312
GROUP BY	
  ISO3, IUCN_CAT
ORDER BY
  ISO3, IUCN_CAT;