SELECT
    rid AS r, filename,
    ST_Width(rast) AS w,
    ST_Height(rast) AS h,
    round(ST_PixelWidth(rast)::numeric,4) AS pw,
    round(ST_PixelHeight(rast)::numeric,4) AS ph,
    ST_SRID(rast) AS srid,
    ST_BandPixelType(rast,1) AS bt
FROM wdpa_raster.cell_area