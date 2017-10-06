# Prep the data
source("src/R/prep_pdsi.R")
source("src/R/prep_ads.R")
source("src/R/prep_mtbs.R")

# Prep for the plots

# Threshold the pdsi image so only areas that experienced more than ten years 
# of drought are present. 
pdsi_m10yr <- pdsi_rcl
pdsi_m10yr[pdsi_m10yr >= 4] <- NA
pdsi_df <- as.data.frame(as(pdsi_rcl, "SpatialPixelsDataFrame")) %>%
  mutate(pdsi_class = layer)



sb <- raster("data/raw/ads/sb_wus.tif")
ysb <- c(11009, 11009, 2)
rclsb <- matrix(ysb, ncol=3, byrow=TRUE)
sb_rcl <- reclassify(sb, rclsb)
sb_rcl[sb_rcl != 1] <- 0

mpb <- raster("data/raw/ads/mpb_wus.tif")
ympb <- c(11006, 11006, 3)
rclmpb <- matrix(ympb, ncol=3, byrow=TRUE)
mpb_rcl <- reclassify(mpb, rclmpb)
mpb_rcl[mpb_rcl != 1] <- 0

forst_sb_mpb <- merge(forests, sb, mpb)

combo  <- brick(pdsi_rcl, mpb, sb, mtbs_rst)


mpb_df <- as.data.frame(as(mpb, "SpatialPixelsDataFrame")) %>%
  mutate(mpb = 1)
sb_df <- as.data.frame(as(sb, "SpatialPixelsDataFrame")) %>%
  mutate(sb = 2)

mtbs_df <- as.data.frame(as(mtbs_rst, "SpatialPixelsDataFrame")) %>%
  mutate(fire_only = ifelse(layer == 0, 0, 1))

