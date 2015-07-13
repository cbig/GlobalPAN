### Script for calculating distances between PAs using rasters

setwd("C://HY-Data/KULLBERG/GPAN_2015_DATA/Distances")
library(raster)
library(rgdal)

# load rasterized PA layer and land-sea mask
PA_r <- raster("C:/HY-Data/KULLBERG/GPAN_2015_DATA/Distances/CBIG_ProtectedAreaIDMask/WDPA_IDAreaWeightedIntersectTerr_r16d.tif")
Land <- raster("C:/HY-Data/KULLBERG/GPAN_2015_DATA/Distances/LandSea/CBIG_LandmaskNodata_r16b.tif")

# select a subset of the data
cropbox1 <- c(95,105,0,45)
PA_r <- crop(PA_r, cropbox1)
Land <- crop(Land, cropbox1)
PA_r[PA_r == 2147483647] <- NA

# merge rasters
PA_ls <- merge(PA_r, Land)
#PA_ls[PA_ls==2147483647] = NA

# find max and min coordinates for each PA ID for building bounding boxes
PA_xy <- as.data.frame(PA_r, xy = TRUE, na.rm = TRUE)
PA_xy_mm <- aggregate(cbind(x, y) ~ WDPA_IDAreaWeightedIntersectTerr_r16d, 
                      PA_xy, function(XX) {c(min=min(XX) , max=max(XX) )})
#XY_val=unlist(as.vector(PA_xy_mm[1, 2:3]))

# extract unique IDs 
IDS <- unique(PA_ls)
IDS <- IDS[-1]

## Set timer
ptm <- proc.time()

# set calcualtion window size in degrees
SIZE <- 3

##Loop trough all PAs
PA_edge_dist <- data.frame()

for (i in IDS) {

  # make a croping window and crop
  XY_i <- unlist((as.vector(PA_xy_mm[PA_xy_mm$WDPA_IDAreaWeightedIntersectTerr_r16d == i, 
                                     2:3])))
  cropbox2 <- c(XY_i[1] - SIZE, XY_i[2] + SIZE, XY_i[3] - SIZE, XY_i[4] + SIZE)
  PA_i_B <- crop(PA_ls, cropbox2)
  
  # calculate distances from all pixels in one PA to all other PA-pixels along land
  PAd <- gridDistance(PA_i_B, origin = i, omit = NA)
  
  #Pick only the smallest values
  Smallest <- zonal(PAd, PA_i_B,min)
  
  #write distances as edgelist  
  i_vec <- rep(i, nrow(Smallest))
  Dist <- cbind(i_vec, Smallest)
  PA_edge_dist <- rbind(PA_edge_dist, Dist[-1, ])
}

#record time
TIME <- proc.time() - ptm
TIME

#Record timer results
Crop <- paste(cropbox2, collapse = "-")
list_length <- nrow(PA_edge_dist )
PA_N <- length(IDS)
TIME2 <- unname(unlist(TIME[3]))
write.table(data.frame(Crop, list_length, PA_N, TIME2, SIZE), 
            file = "con_raster_distance_times3.csv", append = TRUE, 
            row.names = FALSE)

#write results
write.table(PA_edge_dist, 
            file = paste("C://HY-Data/KULLBERG/GPAN_2015_DATA/Distances/Dist_tables/", 
                         "PA_rast_dist_area_", Crop, "windowS_", SIZE, ".csv", 
                         sep = ""), append = FALSE, sep = "\t", 
            row.names = FALSE)
