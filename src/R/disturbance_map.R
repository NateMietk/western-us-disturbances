library(gridExtra)

source("src/functions/plot_theme.R")
forest <- as.data.frame(as(forests, "SpatialPixelsDataFrame")) %>%
  mutate(forest_only = ifelse(conus_forestgroup == 0, 0, 1))
nd_df <- fortify(as(neon_domains, "Spatial"), region = "id")

nks_df <- data.frame(as(neon_sites, "Spatial")) 
nks_df <-  nks_df %>% 
  mutate(long = coords.x1,
         lat = coords.x2,
         id = SiteID)

mpb_shp <- st_read("data/raw/ads/mpb_wus.gpkg") 
mpb_shp <- mpb_shp %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise()
mpb_shp <- mpb_shp %>%
  nc_dissolve %>% 
  st_cast() %>% 
  st_cast("MULTIPOLYGON")

sb_shp <- st_read("data/raw/ads/sb_wus.gpkg")

mpb_df <- fortify(as(mpb_shp, "Spatial"), region = "group")
sb_df <- fortify(as(sb_shp, "Spatial"), region = "group")

# Panel A: Drought
pdsi_p <- ggplot() +
  geom_raster(data = pdsi_df, aes(x = x,
                                  y = y,
                                  fill = factor(pdsi_class)),
              show.legend = FALSE) +
  scale_fill_manual(values = c("transparent", "darkgreen", "green3", 
                               "yellow", "orange", "red3"))  +
  geom_polygon(data = nd_df, aes(x = long, y = lat, group = group),
               color='black', fill = "transparent", size = 0.25) +
  geom_point(data = nks_df,  aes(x = long, y = lat, group = id), size = 2,
             colour='#000000', shape = 18) +
  theme(legend.position = "none") +
  theme_map()
  
# Panel B: Bark Beetle
ads_p <- ggplot() +
  # map the raster
  geom_raster(data = forest, aes(x = x,
                                 y = y,
                                 fill = factor(forest_only),
                                 alpha = factor(forest_only)),
              show.legend = FALSE) +
  scale_alpha_discrete(name = "", range = c(0, 1), guide = F) +
  # geom_raster(data = mpb_df, 
  #             aes(x = x, y = y, fill = factor(mpb)),
  #             show.legend = FALSE) +
  # geom_raster(data = sb_df, 
  #             aes(x = x, y = y, fill = factor(sb)),
  #             show.legend = FALSE) +
  scale_fill_manual(
    values = c("transparent", "olivedrab1"))  +
  geom_polygon(data = mpb_df, aes(x = long, y = lat, group = group),
               color='darkgreen', fill = "darkgreen", size = 0.01) +
  geom_polygon(data = sb_df, aes(x = long, y = lat, group = group),
               color='red3', fill = "red3", size = 0.01) +
  geom_polygon(data = nd_df, aes(x = long, y = lat, group = group),
               color='black', fill = "transparent", size = 0.15) +
  geom_polygon(data = nd_df, aes(x = long, y = lat, group = group),
               color='black', fill = "transparent", size = 0.15) +
  theme(legend.position = "none") +
  theme_map()

# Panel C: Wildfire
mtbs_p <- ggplot() +
  geom_raster(data = mtbs_df, aes(x = x, y = y, fill = factor(fire_only)),
              show.legend = FALSE) +
  scale_fill_manual(values = "#D62728") +
geom_polygon(data=nd_df, aes(x = long, y = lat, group = group),
               color='black', fill = "transparent", size = 0.25) +
  theme(legend.position = "none") +
  theme_map()

# Panel D: Combination
combo_p <- ggplot() +
  geom_polygon(data = nd_df, aes(x = long, y = lat, group = group),
               color='black', fill = "transparent", size = 0.25) +
  geom_point(data = nks_df,  aes(x = long, y = lat, group = id), size = 2,
             colour='#000000', shape = 18) +
  theme(legend.position = "none") +
  theme_map()

g <- arrangeGrob(pdsi_p, ads_p, mtbs_p, combo_p, nrow = 1)

ggsave(file = "results/disturbaces.png", g, width = 5, height = 2.5,
       scale = 3, dpi = 600, units = "cm") #saves p
