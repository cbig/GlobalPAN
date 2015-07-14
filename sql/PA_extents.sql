SELECT wdpaid, iso3, SUM(rep_area) as area, ST_YMin(ST_Extent(geom)) as y_min, ST_XMin(ST_Extent(geom)) as x_min, ST_YMax(ST_Extent(geom)) as y_max, ST_XMax(ST_Extent(geom)) as x_max INTO wdpa.wdpa_pa_extents
FROM wdpa.wdpa_poly_geom 
GROUP BY wdpaid, iso3
ORDER BY wdpaid, iso3;