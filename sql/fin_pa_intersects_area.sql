SELECT sub.f1_ID AS f1_ID, sub.f2_ID as f2_ID, sub.perc AS perc
FROM (SELECT f1.wdpaid AS f1_ID, f2.wdpaid AS f2_ID, ST_Area(ST_Intersection(f1.geom, f2.geom)) / ST_Area(f1.geom) * 100 AS perc
      FROM wdpa.wdpa_poly_geom_fin f1,
        wdpa.wdpa_poly_geom_fin f2
      WHERE f1.wdpaid < f2.wdpaid AND 
        ST_Intersects(f1.geom, f2.geom)) AS sub
WHERE sub.perc > 1
ORDER BY, f1_ID, f2_ID, perc
