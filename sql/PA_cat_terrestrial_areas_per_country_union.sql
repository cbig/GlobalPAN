SELECT 
  country, iucn_cat, COUNT(*), sum(ST_Area(ST_Union(Geography(the_geom_4326)))) / 10000000 AS area_km2
FROM 
  staging.wdpa_poly_jan2014
WHERE
  marine = '0'
GROUP BY	
  country, iucn_cat
ORDER BY
  country, iucn_cat;