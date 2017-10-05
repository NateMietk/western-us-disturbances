source("src/R/prep_bounds.R")

# Import and process MTBS data and project to albers equal area
mtbs_fire <- st_read(dsn = mtbs_prefix,
                     layer = "mtbs_perims_1984-2015_DD_20170815", quiet= TRUE) %>%
  st_transform(p4string_ea) %>%
  st_buffer(., 0) %>%
  st_intersection(., st_union(neon_domains)) %>%
  mutate(id = row_number(),
         group = 1) 

mtbs_rst <- rasterize(as(mtbs_fire, "Spatial"), elevation, "group")
