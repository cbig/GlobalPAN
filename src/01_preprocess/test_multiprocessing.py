#!/usr/bin/env python

import glob
import logging
import multiprocessing
import os
import subprocess
import sys
import time
from poly_density import rasterize_wdpa, fn_timer

import parmap


def frange(x, y, jump):
    values = []
    while x < y:
        values.append(x)
        x += jump
    return values

def worker(extent, poly_ds, outdir, cellsize, poly_lyr=0):
    # NOTE: extent is a dict {chunk_id: (x_min, y_min, x_max, y_max)}
    chunk_id = extent.keys()[0]
    extent_val = extent.values()[0]

    name = multiprocessing.current_process().name
    logger.info('Worker {0} starting on extent {1}: {2}'.format(name, chunk_id, extent))

    outfile = os.path.join(outdir, "chunk-{0}.tif".format(name))
    logger.debug('Worker {0} creating raster {1}'.format(name, outfile))

    return(rasterize_wdpa(extent = extent_val, 
                          poly_ds = poly_ds,
                          poly_lyr = poly_lyr,
                          cellsize = cellsize, 
                          outfile = outfile,
                          logger=logger,
                          chunk_id=chunk_id))

def chop_extent(extent, cellsize, chunks=None):

    # Get the extent
    (minx, miny, maxx, maxy) = extent
    # Define differential along x and y
    x_diff = abs(maxx - minx)
    y_diff = abs(maxy - miny)
    # Define the differences in cells determined by a given resolution.
    x_diff_cells = x_diff / cellsize
    y_diff_cells = y_diff / cellsize

    if chunks is None:
        # Define how many cores are available and use that to construct a 
        # chunk dimension (cores / 2). This dimension will define the equal
        # number of rows and columns.
        chunks = multiprocessing.cpu_count()
        logger.debug("No chunk number provided, using available CPU count ({0})".format(chunks))
    
    logger.info("Splitting the extent into {0} chunks".format(chunks))

    # Figure out to how many pieces the overall extent can be broken into 
    n_rows = 0
    n_cols = 0

    while (n_rows * n_cols) < chunks:
        n_rows += 1
        if (n_rows * n_cols) < chunks:
            n_cols += 1

    # Construct the actual chunks. Define chunk dimensions by quotients and 
    # remainders.
    (x_quotent, x_remainder) = divmod(x_diff, n_cols)
    if x_remainder == 0:
        # Define the x increment
        x_incr = x_diff / n_cols
        minxs = frange(minx, maxx, x_incr)
        maxxs = [x + x_quotent for x in minxs]
    else:
        x_incr = (x_diff - x_remainder) / n_cols
        # If there is a remainder, add it to the last max value (i.e. the last
        # chunk will be larger than the others)
        minxs = frange(minx, maxx - x_remainder, x_incr)
        maxxs = [x + x_incr for x in minxs]
        maxxs[-1] = maxxs[-1] + x_remainder

    (y_quotent, y_remainder) = divmod(y_diff, n_rows)
    if y_remainder == 0:
        # Define the y increment
        y_incr = y_diff / n_rows
        minys = frange(miny, maxy, y_incr)
        maxys = [x + y_quotent for x in minys]
    else:
        y_incr = (y_diff - y_remainder) / n_rows
        # If there is a remainder, add it to the last max value (i.e. the last
        # chunk will be larger than the others)
        minys = frange(miny, maxy - y_remainder, y_incr)
        maxys = [x + y_incr for x in minys]
        maxys[-1] = maxys[-1] + y_remainder

    xs = zip(minxs, maxxs)
    ys = zip(minys, maxys)

    # Construct the final chunk coordinates
    coords = []
    chunk_id = 1
    for i_item in ys:
        for j_item in xs:
            coords.append({chunk_id: (j_item[0], i_item[0], j_item[1], i_item[1])})
            chunk_id += 1
    
    return coords


@fn_timer
def execute_in_parallel(extent, poly_ds, outdir, cellsize, chunks=None):
    
    extent_chunks = chop_extent(extent, cellsize, chunks) 
    #import pprint
    #pprint.pprint(extent_chunks)
    #print(cellsize)
    #sys.exit(0) 
    parmap.map(worker, extent_chunks, poly_ds, outdir, cellsize)

if __name__ == '__main__':
    multiprocessing.log_to_stderr()
    logger = multiprocessing.get_logger()


    logger.setLevel(logging.INFO)

    extent_fin = (20., 60., 32., 70.)
    extent_global = (-180., -90., 180., 90.)
    extent_global_western = (-180., -90., 0., 90.)
    extent_global_eastern = (0., -90., 180., 90.)
    extent_north_eastern = (0., 0., 180, 90.)

    poly_ds_fin = "/home/jlehtoma/Data/WDPA/wdpa_poly_geom_fin.shp"
    poly_ds_global = "/home/jlehtoma/Data/WDPA/WDPA_June2015-shapefile/WDPA_June2015-shapefile-polygons_nomarine.shp"
    outdir = "/home/jlehtoma/Data/WDPA/chunks"
    cellsize_1 = 1
    cellsize = 1. / 60.
    chunks = 30

    execute_in_parallel(extent=extent_global_western,
                        poly_ds=poly_ds_global,
                        outdir=outdir,
                        cellsize=cellsize,
                        chunks=chunks)

    if chunks > 1:
        # Merge result rasters

        output_path_temp = os.path.join(outdir, "wdpa_mask_temp_northeastern.tif")
        input_files = glob.glob(os.path.join(outdir, "*.tif"))
        input_files.sort()

        logger.info("Merging resulting rasters...")
        args = ['gdal_merge.py', '-o', output_path_temp, '-of', "GTiff", '-a_nodata', "-9999"] + input_files
        ps = subprocess.Popen(args, stdout=subprocess.PIPE)
        output = ps.communicate()[0]

        logger.info("Translating to final raster...")
        output_path = os.path.join(outdir, "..", "wdpa_mask_northeastern.tif")
        args = ['gdal_translate', '-a_srs', 'EPSG:4326', '-co', 'COMPRESS=DEFLATE', output_path_temp, output_path]
        ps = subprocess.Popen(args, stdout=subprocess.PIPE)
        output = ps.communicate()[0]
