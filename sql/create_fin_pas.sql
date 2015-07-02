SELECT *
INTO wdpa.wdpa_poly_fin
FROM wdpa.wdpa_poly
WHERE iso3 = 'FIN';

-- Define a primary key
ALTER TABLE wdpa.wdpa_poly_fin ADD PRIMARY KEY (gid);

-- Spatially enable it
SELECT Populate_Geometry_Columns('wdpa.wdpa_poly_fin'::regclass);