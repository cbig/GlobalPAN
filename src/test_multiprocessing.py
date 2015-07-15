#!/usr/bin/env python

import logging
import multiprocessing
import os
import sys
import time
from functools import wraps
from poly_density import rasterize_wdpa

import parmap

def frange(x, y, jump):
    values = []
    while x < y:
        values.append(x)
        x += jump
    return values

def fn_timer(function):
    @wraps(function)
    def function_timer(*args, **kwargs):
        t0 = time.time()
        result = function(*args, **kwargs)
        t1 = time.time()
        logger.info("\nTotal time running %s: %s seconds" %
               (function.func_name, str(t1-t0)))
        return result
    return function_timer 


def worker(extent, outdir, cellsize):
    name = multiprocessing.current_process().name
    logger.info('Worker {0} starting on extent {1}'.format(name, extent))

    outfile = os.path.join(outdir, "chunk-{0}.tif".format(name))

    return(rasterize_wdpa(extent = extent, 
                          poly_ds = "/home/jlehtoma/Data/WDPA/wdpa_poly_geom_fin.shp", 
                          poly_lyr = 0, 
                          cellsize = cellsize, 
                          outfile = outfile))

def chop_extent(extent, chunks=None):

    # Get the extent
    (minx, miny, maxx, maxy) = extent
    # Define differential along x and y
    diffx = abs(maxx - minx)
    diffy = abs(maxy - miny)

    if chunks is None:
        # Define how many cores are available and use that to construct a 
        # chunk dimension (cores / 2). This dimension will define the equal
        # number of rows and columns.
        chunk_dim = multiprocessing.cpu_count() / 2

    # Construct the actual chunks. Define chunk dimensions by quotients and 
    # remainders.
    timesx = divmod(diffx, chunk_dim)
    # If there is no remainders and the range can be split equally
    if timesx[1] == 0:
        minxs = frange(minx, maxx, timesx[0])
        maxxs = [x + timesx[0] for x in minxs]
    # If there is a remainder, add it to the last max value (i.e. the last
    # chunk will be larger than the others)
    else:
        minxs = frange(minx, maxx - timesx[1], (diffx - timesx[1]) / timesx[0])
        maxxs = [x + (diffx - timesx[1]) / timesx[0] for x in minxs]
        maxxs[-1] = maxxs[-1] + timesx[1]

    timesy = divmod(diffy, chunk_dim)
    if timesy[1] == 0:
        minys = frange(miny, maxy, timesy[0])
        maxys = [x + timesy[0] for x in minys]
    else:
        minys = frange(miny, maxy - timesy[1], (diffy - timesy[1]) / timesx[0])
        maxys = [x + (diffy - timesy[1]) / timesx[0] for x in minys]
        maxys[-1] = maxys[-1] + timesy[1]

    xs = zip(minxs, maxxs)
    ys = zip(minys, maxys)

    # Construct the final chunk coordinates
    coords = []
    coords.append((xs[0][0], ys[0][0], xs[0][1], ys[0][1]))
    coords.append((xs[0][1], ys[0][0], xs[1][1], ys[0][1]))
    coords.append((xs[0][0], ys[1][0], xs[0][1], ys[1][1]))
    coords.append((xs[0][1], ys[1][0], xs[1][1], ys[1][1]))
    
    return coords

@fn_timer
def execute_in_parallel(extent, outdir, cellsize):
    
    extent_chunks = chop_extent(extent_fin)
    return parmap.map(worker, extent_chunks, outdir, cellsize)

if __name__ == '__main__':
    multiprocessing.log_to_stderr()
    logger = multiprocessing.get_logger()
    logger.setLevel(logging.INFO)
    
    extent_fin = (20., 60., 32., 70.)
    
    execute_in_parallel(extent_fin, "/home/jlehtoma/Data/WDPA/chunks", 0.5)
