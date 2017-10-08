
# Import SB dissolved shapefile
sb <- raster("data/raw/ads/sb_wus.tif")
ysb <- c(11009, 11009, 2)
rclsb <- matrix(ysb, ncol=3, byrow=TRUE)
sb_rcl <- reclassify(sb, rclsb)
sb_rcl[sb_rcl != 1] <- 0

mpb <- raster("../data/ads/wus/mpb/mpb_wus_dis.shp")
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
