source("src/functions/plot_theme.R")

# Convert shapefiles and background files to plottable dataframes
forest <- as.data.frame(as(forests, "SpatialPixelsDataFrame")) %>%
  mutate(forest_only = ifelse(conus_forestgroup == 0, 0, 1))

nd_df <- fortify(as(neon_domains, "Spatial"), region = "id")

nks_df <- data.frame(as(neon_sites, "Spatial")) %>% 
  mutate(long = coords.x1,
         lat = coords.x2,
         id = SiteID)

# Import and prep bark beetle dissolved shapefile
mpb <- st_read(file.path(prefix, "ads/wus/mpb/mpb_wus_dis.shp"))
mpb_df <- fortify(as(mpb, "Spatial"), region = "group")
mpb_rst <- rasterize(as(mpb, "Spatial"), elevation, background = 0, field = "group")

sb <- st_read(file.path(prefix, "ads/wus/sb/sb_wus_dis.shp"))
sb_df <- fortify(as(sb, "Spatial"), region = "group")
sb_rst <- rasterize(as(sb, "Spatial"), elevation, background = 0, field = "group")

wsb <- st_read(file.path(prefix, "ads/wus/wsb/wsb_wus_dis.shp"))
wsb_rst <- rasterize(as(wsb, "Spatial"), elevation, background = 0, field = "group")

bb_all <- merge(mpb_rst, sb_rst)

# Covert to 500m pixel rasters
mpb_df <- as.data.frame(as(mpb_rst, "SpatialPixelsDataFrame")) %>%
  mutate(mpb = 1)
sb_df <- as.data.frame(as(sb_rst, "SpatialPixelsDataFrame")) %>%
  mutate(sb = 2)
wsb_df <- as.data.frame(as(wsb_rst, "SpatialPixelsDataFrame")) %>%
  mutate(wsb = 3)

# Prep MTBS
mtbs_rst <- rasterize(as(mtbs_fire, "Spatial"), mpb_rst, background = 0, field = "group")
mtbs_df <- as.data.frame(as(mtbs_rst, "SpatialPixelsDataFrame")) %>%
  mutate(fire_only = 1)

# Prep PDSI for the plots
pdsi_df <- as.data.frame(as(pdsi_rcl, "SpatialPixelsDataFrame")) %>%
  mutate(pdsi_class = layer)

# Rasterize 4k
mpb_rst_4k <- rasterize(as(mpb, "Spatial"), pdsi_anomalies, background = 0, field = "group")
sb_rst_4k <- rasterize(as(sb, "Spatial"), pdsi_anomalies, background = 0, field = "group")
mtbs_rst_4k <- rasterize(as(mtbs_fire, "Spatial"), pdsi_anomalies, background = 0, field = "group")

bb_all_4k <- mpb_rst_4k + sb_rst_4k


