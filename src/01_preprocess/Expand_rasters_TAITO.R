
# Description -------------------------------------------------------------

# This is a script for extending the extent of multiple raster layers using
# Rmpi. The Script is written for the GPAN connectivity project to expand
# the modelled mammal range maps. It is planned to be used with SLURM/sbatch
# in CSC Taito super cluster for spawning the slaves. NOTE: the file paths are
# specific to my CSC working environment.

# Funcionality ------------------------------------------------------------

library(Rmpi)
mpi.remote.exec(library(raster))

setwd("/wrk/pkullber/Data/mammal_data/")

# load the raster paths
R_files <- list.files("/wrk/pkullber/Data/mammal_data/test", pattern = "\\.tif$", full.names=TRUE)
mpi.remote.exec(path <- "/wrk/pkullber/Data/mammal_data/test_o/")

mpi.remote.exec(mer_and_save <- function(x) {
  Ext_ras <- raster(nrow=10800, ncol=21600)
  proj4string(Ext_ras) <- CRS("+init=epsg:4326")
  W_rast <- raster(unlist(x))
  M_ras <- merge(W_rast, Ext_ras)
  writeRaster(M_ras, paste(path, "expanded" ,tail(unlist(strsplit(x, split="/")), n=1), sep=""), format="GTiff", options=("COMPRESS=DEFLATE"))
  removeTmpFiles(0.3)
  return(NULL)
})

mpi.applyLB(R_files, function(x) {mer_and_save(x)})

mpi.close.Rslaves()
mpi.quit()
