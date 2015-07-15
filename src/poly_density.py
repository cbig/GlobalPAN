#!/usr/bin/env python
"""
 poly_density.py
 Calculate density of polygon data as a raster surface.
 Each raster cell contains a value indicating the percent cover of the
 underlying polygon.

 To get decent performance on large vector datasets, the input vector dataset
 must
 have a gdal-recognized spatial index (ie a .qix file for shapefiles as created
 by shtree)

 Author: Matthew T. Perry

 License: You are free to use or modify this code for any purpose.
          This license grants no warranty of any kind, express or implied.
"""

import logging
import os
import sys
import time
from functools import wraps

import gdal
import numpy as np
import ogr

def fn_timer(function):
    @wraps(function)
    def function_timer(*args, **kwargs):
        logger = logging.getLogger('timer')
        logger.setLevel(logging.DEBUG)
        ch = logging.StreamHandler()
        logger.addHandler(ch)
        t0 = time.time()
        result = function(*args, **kwargs)
        t1 = time.time()
        logger.info("\nTotal time running %s: %s seconds" %
               (function.func_name, str(t1-t0)))
        return result
    return function_timer 

@fn_timer
def rasterize_wdpa(extent, poly_ds, poly_lyr, cellsize, outfile, format="GTiff"):

    # Get the input layer
    ds = ogr.Open(poly_ds)
    lyr = ds.GetLayer(poly_lyr)
    featureCount = lyr.GetFeatureCount()

    print("MESSAGE: Working with layer <{0}> with {1} features.".format(lyr.GetName(),
        featureCount))

    # TODO: Confirm dataset is polygon and extents overlap

    ydist = extent[3] - extent[1]
    xdist = extent[2] - extent[0]
    xcount = int((xdist / cellsize) + 1)
    ycount = int((ydist / cellsize) + 1)

    # Create output raster
    driver = gdal.GetDriverByName(format)
    dst_ds = driver.Create(outfile, xcount, ycount, 1, gdal.GDT_Float32)

    # the GT(2) and GT(4) coefficients are zero,
    # and the GT(1) is pixel width, and GT(5) is pixel height.
    # The (GT(0),GT(3)) position is the top left corner of the top left pixel
    gt = (extent[0], cellsize, 0, extent[3], 0, (cellsize*-1.))
    dst_ds.SetGeoTransform(gt)

    dst_band = dst_ds.GetRasterBand(1)
    dst_band.SetNoDataValue(-9999)

    pixelnum = 0

    for ypos in range(ycount):
        # Create output line array
        outArray = np.zeros((1, xcount))
        for xpos in range(xcount):
            # create a 4-item list of extents
            minx = xpos * cellsize + extent[0]
            maxy = extent[3] - ypos * cellsize
            miny = maxy - cellsize
            maxx = minx + cellsize

            # Create Polygon geometry from BBOX
            wkt = 'POLYGON ((%f %f, %f %f, %f %f, %f %f, %f %f))' \
                % (minx, miny, minx, maxy, maxx, maxy, maxx, miny, minx,
                    miny)
            g = ogr.CreateGeometryFromWkt(wkt)

            # Set spatial filter
            lyr.SetSpatialFilter(g)

            # Loop through all features/geometries w/in filter
            feat = lyr.GetNextFeature()
            area = 0
            while feat is not None:
                try:
                    # Intersect with polygon lyr
                    sg = feat.GetGeometryRef().Intersection(g)
                    if sg:
                        area = area + sg.GetArea()
                    feat = lyr.GetNextFeature()
                except AttributeError, e:
                    print("WARNING: Features in grid cell {0}".format(wkt) +
                    	"do not seem to have geometry or are empty")
                    print(e)
                    feat = lyr.GetNextFeature()

            lyr.ResetReading()

            # Calculate area of intersection
            pct_cover = area / (cellsize * cellsize)

            # Assign percent areal cover as value in line array
            np.put(outArray, xpos, (pct_cover*100))

            pixelnum += 1

        sys.stdout.write("\r (%.2f%%) calculated... " % (float(pixelnum) /
                                                      (xcount * ycount) *
                                                      100.))
        sys.stdout.flush()
        dst_band.WriteArray(outArray, 0, ypos)

    return(0)

if __name__ == "__main__":
	rasterize_wdpa(poly_ds = "/home/jlehtoma/Data/WDPA/wdpa_poly_geom_fin.shp",
				   poly_lyr = 0,
    			   extent = [19., 59., 32., 71.],
    			   cellsize = 0.5,
    			   outfile = "../data/WDPA/wdpa_polygeom_fin_01degree.tif",
    			   format = "GTiff")

	sys.stdout.write("done!\n")
	sys.stdout.flush()

	# WDPA specific benchmarks on cbig-arnold
	#  - Full data, 1 degree (~111 km) resolution = 3106 s (51 min)
    #  - Finland, 0.1 degree (~11 km) resolution  = 194s (3 min)
    #  - Finland, 0.016666 degree (~1.6 km) resolution  =  3871 (64 min)