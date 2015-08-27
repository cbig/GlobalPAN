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
from osgeo import osr


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


def rasterize_wdpa(extent, poly_ds, poly_lyr, cellsize, outfile, chunk_id,
                   format="GTiff", logger=None):

    # This dictionary defines the selection preference order in the rasterization rule set
    pref_iucn_cat = {"Ia": 1,
                     "Ib": 2,
                     "II": 3,
                     "III": 4,
                     "IV": 5,
                     "Not Assigned": 8,
                     "Not Applicable": 8,
                     "Not Reported": 8,
                     "V": 6,
                     "VI": 7,
                     "init": 10}

    # Get the input layer
    ds = ogr.Open(poly_ds)
    lyr = ds.GetLayer(poly_lyr)

    featureCount = lyr.GetFeatureCount()

    if logger is None:
        logger = logging.getLogger('rasterizer')
        logger.setLevel(logging.DEBUG)
        ch = logging.StreamHandler()
        logger.addHandler(ch)
    else:
        logger = logger

    logger.info(("Working with layer <{0}> with {1} features.".format(lyr.GetName(), featureCount)))
    logger.debug("Extent: {0},\npoly_ds: {1},\npoly_lyr: {2},\ncellsize: {3},\noutfile: {4},\nformat: {5}".format(extent, poly_ds, poly_lyr, cellsize, outfile, format))

    # TODO: Confirm dataset is polygon and extents overlap

    ydist = extent[3] - extent[1]
    xdist = extent[2] - extent[0]
    xcount = int((xdist / cellsize) + 1)
    ycount = int((ydist / cellsize) + 1)

    # Create output raster
    driver = gdal.GetDriverByName(format)
    dst_ds = driver.Create(outfile, xcount, ycount, 1, gdal.GDT_Int32)

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
            # logger.debug(wkt)
            # Set spatial filter
            lyr.SetSpatialFilter(g)

            # Loop through all features/geometries w/in filter
            feat = lyr.GetNextFeature()

            # Assign a dictionary to hold the necessary attribute information for the currently selected item.
            selected_item = {"wdpaid": -9999, "iucn_cat": "init", "gis_area": 0, "inters_area": 0}

            while feat is not None:
                try:
                    # Intersect with polygon lyr
                    sg = feat.GetGeometryRef().Intersection(g)

                    if sg:
                        # If the polygon lyr actually intersects, start looking at attributes.
                        wdpaid = feat.GetField("wdpaid")
                        iucn_cat = feat.GetField("iucn_cat")
                        gis_area = feat.GetField("gis_area")
                        sg_inters_area = sg.GetArea()

                        # FIRST: comparison rule IUCN category.
                        # Since the attribute data associated with the current largest intersection area are
                        # stored in selected_item, use that for comparison. NOTE: preference number must be smaller.
                        if pref_iucn_cat[iucn_cat] < pref_iucn_cat[selected_item["iucn_cat"]]:
                            # So far, this is the largest intersection -> assign the current WDPAID as selected.
                            selected_item["wdpaid"] = wdpaid
                            selected_item["iucn_cat"] = iucn_cat
                            selected_item["gis_area"] = gis_area
                            selected_item["inters_area"] = sg_inters_area
                        elif pref_iucn_cat[iucn_cat] == pref_iucn_cat[selected_item["iucn_cat"]]:
                            # Move to SECOND rule: decide whether the intersecting part area >= what is currently the
                            # largest.
                            if sg_inters_area > selected_item["inters_area"]:
                                # Select this, it has preferred IUCN category
                                selected_item["wdpaid"] = wdpaid
                                selected_item["iucn_cat"] = iucn_cat
                                selected_item["gis_area"] = gis_area
                                selected_item["inters_area"] = sg_inters_area
                            elif sg_inters_area == selected_item["inters_area"]:
                                # Can't believe it, it's still a tie! Move on to the THIRD decision rule which is the
                                # overall area of the PA entity.
                                if gis_area > selected_item["gis_area"]:
                                    selected_item["wdpaid"] = wdpaid
                                    selected_item["iucn_cat"] = iucn_cat
                                    selected_item["gis_area"] = gis_area
                                    selected_item["inters_area"] = sg_inters_area
                                elif gis_area == selected_item["gis_area"]:
                                    # Still a tie, on a FOURTH level just use the higher WDPAID
                                    if wdpaid > selected_item["wdpaid"]:
                                        selected_item["wdpaid"] = wdpaid
                                        selected_item["iucn_cat"] = iucn_cat
                                        selected_item["gis_area"] = gis_area
                                        selected_item["inters_area"] = sg_inters_area

                        # logger.debug(area)
                    feat = lyr.GetNextFeature()
                except AttributeError, e:
                    logger.warning("WARNING: Features in grid cell {0}".format(wkt) +
                                   "do not seem to have geometry or are empty")
                    feat = lyr.GetNextFeature()

            lyr.ResetReading()

            # Assign the selected WDPAID as value in line array
            np.put(outArray, xpos, selected_item["wdpaid"])

            pixelnum += 1


        logger.info("Chunk %s [%s]: %.2f%% calculated... " % (chunk_id, extent, float(pixelnum) / (xcount * ycount) * 100.))
        dst_band.WriteArray(outArray, 0, ypos)

    return(0)


@fn_timer 
def wrapper(*args, **kwargs):     
    rasterize_wdpa(*args, **kwargs)

if __name__ == "__main__":
    wrapper(poly_ds="/home/jlehtoma/Data/WDPA/WDPA_June2015-shapefile/WDPA_June2015-shapefile-polygons.shp",
            poly_lyr=0,
            extent=(-180., -90., 180., 90.),
            cellsize=0.016666,
            chunk_id=1,
            outfile="../data/WDPA/wdpa_mask.tif",
            format="GTiff")

    sys.stdout.write("done!\n")
    sys.stdout.flush()

    # WDPA specific benchmarks on cbig-arnold
    #  - Full data, 1 degree (~111 km) resolution = 3106 s (51 min)
    #  - Finland, 0.1 degree (~11 km) resolution  = 128 s (2.1 min)
    #  - Multiprocessing Finland, 0.1 degree (~11 km) resolution  =  (46 s
    #    [12 chunks], 38 s [24 chunks], 30 s [32 chunks])
    #  - Finland, 0.016666 degree (~1.6 km) resolution  =  3871 s (64 min)
    #  - Multiprocessing Finland, 0.016666 degree (~1.6 km) resolution  =
    #    (557 s (9.3 min) [32 chunks])

    # WDPA specific benchmarks on LH2-BIOTI
    #  - Finland, 0.1 degree (~11 km) resolution  = 205s (3.4 min)
    #  - Multiprocessing Finland, 0.1 degree (~11km) resolution  = 86.5s
    #    (1.4 min)
