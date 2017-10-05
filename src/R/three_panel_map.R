# Create the map
source("src/R/plot_theme.R")

#Panel A: Drought
source("src/R/prep_pdsi.R")

pdsi_p <- pdsi_df %>%
  ggplot() +
  
  # map the raster
  geom_raster(data = pdsi_df, aes(x = x,
                                  y = y,
                                  fill = factor(pdsi_class)),
              show.legend = FALSE) +
  scale_fill_manual(
    # breaks = c("0", "1", "2", "3", "4", "5"),
    # labels = c("", "1 - 5", "5 - 7", "7 - 9", "9 - 12", "12- 19"),
    values = c("transparent", "darkgreen", "forestgreen", "darkorange1",
                    "orangered1", "red3"))  +
  
  # map the neon domains
  geom_polygon(data = nd_df, aes(x = long, y = lat, group = group),
               color='black', fill = "transparent", size = 0.25) +
  theme(legend.position = "none") +
  theme_map()
  
# Panel B: Bark Beetle

# Panel C: Wildfire
source("src/R/prep_mtbs.R")
p <- ggplot() +

  # map the raster
  geom_raster(data = mtbs_df, aes(x = x,
                                 y = y,
                                 fill = factor(fire_only)),
              show.legend = FALSE) +
  scale_fill_manual(values = "#D62728") +

  # map the neon domains
  geom_polygon(data=nd_df, aes(x = long, y = lat, group = group),
               color='black', fill = "transparent", size = 0.25) +

  theme(legend.position = "none") +
  theme_map()

ggsave(file = "results/site_map.eps", p, width = 4, height = 3,
       dpi = 300, units = "cm") #saves p
