#!/usr/bin/env r

# Description -------------------------------------------------------------

# Simple helper script that can be used to unzip downloaded WDPA data and
# to select PAs other than marine (using ogr2ogr in gdalUtils). 
# NOTE: script assumes that it is run within a RStudio project, i.e. paths
# are not relative to this file. Modify paths if the script is run from 
# command line.

# Funcionality ------------------------------------------------------------

# Use regular expression matching so that the zip file is not hardcoded to a 
# specific WDPA version.
source_zip <- list.files(path = "data/WDPA", pattern = "^(WDPA).+\\.zip$", 
                         full.names = TRUE)
if (length(source_zip) == 0) {
  stop("Couldn't find a suitable zip-file.")
}

# Unzip the file
message("Unzipping ", source_zip, " to the same directory...", appendLF = FALSE)
unzip(zipfile = source_zip, exdir = dirname(source_zip), overwrite = TRUE)
message("done")

# Select subset of data ---------------------------------------------------

# First, let's figure out the correct shapefile. We're only interested in the
# polygon data (not points), so let's get that.
source_ds <- list.files(path = dirname(source_zip), 
                        pattern = "^(WDPA).+(polygons)\\.shp$", 
                        full.names = TRUE)
if (length(source_ds) == 0) {
  stop("Couldn't find a suitable polygon shapefile.")
}

# Let's also construct a name for a destination dataset (shapefile withouth
# marine PAs)
dest_ds <- unlist(strsplit(x = basename(source_ds), split = "\\."))
dest_ds <- file.path(dirname(source_ds), 
                     paste0(dest_ds[1], "_nonmarine.", dest_ds[2]))


library(gdalUtils)
library(rgdal)

# We'll pre-check to make sure there is a valid GDAL install.
# Note this isn't strictly neccessary, as executing the function will
# force a search for a valid GDAL install.
gdal_setInstallation()
valid_install <- !is.null(getOption("gdalUtils_gdalPath"))

if (valid_install) {
  message("Copying all but marine PAs to a new shapefile ", dest_ds, 
          " ...", appendLF = FALSE)
  # Using ogr2ogr, select only terrestrial (0) and coastal (1), i.e. != 2
  layer <- ogrListLayers(source_ds)[1]
  ogr2ogr(src_datasource_name = source_ds, dst_datasource_name = dest_ds,
          layer = layer, skipfailures = TRUE,
          where = "MARINE <> '2'", preserve_fid = TRUE, lco = "ENCODING=UTF-8")
  message("done")
} else {
 stop("No valid GDAL installation found on the system") 
}
