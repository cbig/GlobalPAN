CREATE TABLE extracttoraster_finlandIa AS
SELECT ST_ExtractToRaster(
         ST_AddBand(ST_MakeEmptyRaster(rast), '32BF'::text, -9999, -9999), 
         'wdpa', 
         'wdpa_poly_geom_fin', 
         'geom', 
         'wdpaid', 
         'VALUE_OF_BIGGEST') rast
FROM (SELECT rast FROM wdpa_raster.cell_area) AS rast;