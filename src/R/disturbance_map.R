library(gridExtra)

source("src/R/plot_theme.R")

nd_df <- fortify(as(neon_domains, "Spatial"), region = "id")

nks_df <- data.frame(as(neon_sites, "Spatial")) 
nks_df <-  nks_df %>% 
  mutate(long = coords.x1,
         lat = coords.x2,
         id = SiteID)

# Panel A: Drought
pdsi_p <- ggplot() +
  geom_raster(data = pdsi_df, aes(x = x,
                                  y = y,
                                  fill = factor(pdsi_class)),
              show.legend = FALSE) +
  scale_fill_manual(values = c("transparent", "darkgreen", "green3", 
                               "yellow", "darkorange1", "red3"))  +
  geom_polygon(data = nd_df, aes(x = long, y = lat, group = group),
               color='black', fill = "transparent", size = 0.25) +
  geom_point(data = nks_df,  aes(x = long, y = lat, group = id), size = 2,
             colour='#000000', shape = 18) +
  theme(legend.position = "none") +
  theme_map()
  
# Panel B: Bark Beetle
ads_p <- ggplot() +
  geom_raster(data = mpb_df, 
              aes(x = x, y = y, fill = factor(mpb)),
              show.legend = FALSE) +
  geom_raster(data = sb_df, 
              aes(x = x, y = y, fill = factor(sb)),
              show.legend = FALSE) +
  scale_fill_manual(
    breaks = c("1", "2"),
    values = c("forestgreen", "red3"))  +
  geom_polygon(data = nd_df, aes(x = long, y = lat, group = group),
               color='black', fill = "transparent", size = 0.25) +
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

g <- arrangeGrob(pdsi_p, ads_p, mtbs_p, nrow = 1)

ggsave(file = "results/disturbaces.png", g, width = 5, height = 2.5,
       scale = 3, dpi = 600, units = "cm") #saves p
