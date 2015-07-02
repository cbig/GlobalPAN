CREATE TABLE extracttoraster_finlandIa AS
SELECT ST_ExtractToRaster(
         ST_AddBand(ST_MakeEmptyRaster(rast_finlandIa), '32BF'::text, -9999, -9999), 
         'wdpa', 
         'wdpa_poly_geom', 
         'geom', 
         'wdpaid', 
         'VALUE_OF_BIGGEST') rast_finlandIa
FROM (SELECT * FROM wdpa.wdpa_poly
      WHERE iso3 = 'FIN' AND iucn_cat IN ('Ia')) AS finlandIa;