
source("src/R/prepare_data.R")
source("src/R/plot_theme.R")

# Create data frames for map creation
neon_domains <- as(neon_domains, "Spatial")
nd_df <- fortify(neon_domains, region = 'id')

# Create data frames for map creation
mtbs <- as(mtbs, "Spatial")
mtbs_df <- fortify(mtbs, region = 'id')

# Create the map
p <- ggplot() +
  # map the neon domains
  geom_polygon(data = nd_df, aes(x = long, y = lat, group = group), 
               color = 'black', fill = "transparent", size = .25) +
  geom_polygon(data = nd_df, aes(x = long, y = lat, group = group), 
               color = 'black', fill = "transparent", size = .25) +

  # map the forested sites that are in the study
  geom_point(data = nks_df,  aes(x = long, y = lat), size = 2,
             colour='#D62728', fill = NA, shape = 18) +
  theme(legend.position = "none") +
  theme_map()

ggsave(file = "results/site_map.eps", p, width = 4, height = 3, 
       dpi = 300, units = "cm") #saves p



