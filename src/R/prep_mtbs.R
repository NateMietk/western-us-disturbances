x <- c("raster", "tidyverse", "lubridate", "sf")
lapply(x, library, character.only = TRUE, verbose = FALSE)

# Import the NEON sites, clean to western focus only, and project to albers equal area
neon_domains <- st_read(dsn = domain_prefix,
                        layer = "NEON_Domains", quiet= TRUE) %>%
  st_transform(p4string_ea) %>%
  filter(DomainName %in% c("Desert Southwest", "Pacific Northwest", "Great Basin",
                           "Southern Rockies / Colorado Plateau", "Northern Rockies", "Pacific Southwest")) %>%
  st_intersection(., st_union(states)) %>%
  mutate(id = row_number())

# Import and process MTBS data and project to albers equal area
mtbs_fire <- st_read(dsn = mtbs_prefix,
                     layer = "mtbs_perims_1984-2015_DD_20170815", quiet= TRUE) %>%
  st_transform(p4string_ea) %>%
  st_buffer(., 0) %>%
  st_intersection(., st_union(neon_domains)) %>%
  mutate(id = row_number(),
         group = 1) 

mtbs_rst <- rasterize(as(mtbs_fire, "Spatial"), elevation, "group")

mtbs_df <- as.data.frame(as(mtbs_rst, "SpatialPixelsDataFrame")) %>%
  mutate(fire_only = ifelse(layer == 0, 0, 1))

nd_df <- fortify(as(neon_domains, "Spatial"), region = "id")
