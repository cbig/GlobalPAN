
# Description -------------------------------------------------------------

# GPAN connectivity project: construct needed mask files for Zonation
# analyses based on the WDPA_mask layer, 9.9.2015.

# Functionality ------------------------------------------------------------

library(raster)

# Filter out large water areas from the original wdpa_mask.tif 
WDPA_mask <- raster("data/WDPA/wdpa_mask.tif")
Land_Sea_mask <- raster("data/masks/CBIG_LandmaskNodata_r16b.tif") # This is the ready-made Land_sea_mask form CBIG global database whit appropriate resolution. It is based on WorldGrids LMBGSH continental land mask in 1km resolution.
WDPA_mask[is.na(Land_Sea_mask)] <- NA
writeRaster(WDPA_mask, "data/masks/wdpa_mask_only_land.tif",
            format="GTiff", datatype="INT4S", options="COMPRESS=DEFLATE",
            overwrite=T)

# make a hierarchical mask that removes PAs LAST
WDPA_hier_mask <- WDPA_mask
WDPA_hier_mask[!is.na(WDPA_hier_mask)] <- 1
WDPA_hier_mask[is.na(WDPA_hier_mask)] <- 0
WDPA_hier_mask[is.na(Land_Sea_mask)] <- NA
writeRaster(WDPA_hier_mask, "data/masks/wdpa_last_hier_mask.tif",
            format="GTiff", datatype="INT4S", options="COMPRESS=DEFLATE",
            overwrite=T)

# make a hierarchical mask that removes PAs FIRST
WDPA_hier_mask_first <- WDPA_mask
WDPA_hier_mask_first[!is.na(WDPA_hier_mask_first)] <- 0
WDPA_hier_mask_first[is.na(WDPA_hier_mask_first)] <- 1
WDPA_hier_mask_first[is.na(Land_Sea_mask)] <- NA
writeRaster(WDPA_hier_mask_first, "data/masks/wdpa_first_hier_mask.tif",
            format="GTiff", datatype="INT4S", options="COMPRESS=DEFLATE",
            overwrite=T)

# IDs have to be reclassified for the PLU mask because some of the codes
# are too large for zonation to handle  (eg. ones starting with 555555...)
WDPA_plu_work <- WDPA_mask
WDPA_plu_work[WDPA_hier_mask==0] <- (length(unique(WDPA_plu_work)+1)) # Assign areas outside GPAN to a own PLU.
WDPA_IDs <- unique(WDPA_plu_work)
New_IDs <- 1:length(WDPA_IDs)
RCL_table <- cbind(WDPA_IDs, New_IDs)
WDPA_numbered <- reclassify(WDPA_plu_work, RCL_table)
writeRaster(WDPA_numbered, "data/masks/wdpa_plu_mask.tif", format="GTiff",
            datatype="INT4S", options="COMPRESS=DEFLATE", overwrite=T)

## Make species richness raster and filter out areas without mammals
s_richness <- raster("C:/HY-Data/KULLBERG/GPAN_2015_DATA/temp_stuff/Short_richness_from_part_maps.tif")
m_richness <- raster("C:/HY-Data/KULLBERG/GPAN_2015_DATA/temp_stuff/Med_richness_from_part_maps.tif")
l_richness <- raster("C:/HY-Data/KULLBERG/GPAN_2015_DATA/temp_stuff/Long_richness_from_part_maps.tif")
richness <- sum(stack(s_richness, m_richness, l_richness))

WDPA_numbered <- raster("data/masks/wdpa_plu_mask.tif")
WDPA_numbered_clip <- WDPA_numbered
WDPA_numbered_clip[richness==0] <- NA
writeRaster(WDPA_numbered_clip, "data/masks/wdpa_plu_mask_clip.tif", format="GTiff",
            datatype="INT4S", options="COMPRESS=DEFLATE", overwrite=T)

WDPA_hier_mask_first <- raster("data/masks/wdpa_first_hier_mask.tif")
WDPA_hier_mask_first_clip <- WDPA_hier_mask_first
WDPA_hier_mask_first_clip[richness==0] <- NA
writeRaster(WDPA_hier_mask_first_clip, "data/masks/wdpa_first_hier_mask_clipped.tif", format="GTiff",
            datatype="INT4S", options="COMPRESS=DEFLATE", overwrite=T)

Land_Sea_mask <- raster("data/masks/CBIG_LandmaskNodata_r16b.tif")
Land_Sea_mask_clip <- Land_Sea_mask
Land_Sea_mask_clip[richness==0] <- NA
writeRaster(Land_Sea_mask_clip, "data/masks/CBIG_LandmaskNodata_r16b_clip.tif", format="GTiff",
            datatype="INT4S", options="COMPRESS=DEFLATE", overwrite=T)
