x <- c("raster", "tidyverse", "lubridate", "sf")
lapply(x, library, character.only = TRUE, verbose = FALSE)

# Import the US States and project to albers equal area
states <- st_read(dsn = us_prefix,
                  layer = "cb_2016_us_state_20m", quiet= TRUE) %>%
  st_transform("+init=epsg:2163") %>%  # e.g. US National Atlas Equal Area
  filter(!(NAME %in% c("Alaska", "Hawaii", "Puerto Rico"))) %>%
  mutate(group = 1) %>%
  st_simplify(., preserveTopology = TRUE)

# Import the NEON domains and project to albers equal area
neon_domains <- st_read(dsn = domain_prefix,
                        layer = "NEON_Domains", quiet= TRUE) %>%
  st_transform("+init=epsg:2163") %>%  # e.g. US National Atlas Equal Area
  filter(!(DomainName %in% c("Taiga", "Tundra", "Pacific Tropical"))) %>%
  st_intersection(., st_union(states))

# Import and process MTBS data and project to albers equal area
mtbs_fire <- st_read(dsn = mtbs_prefix,
                     layer = "mtbs_perims_1984-2015_DD_20170815", quiet= TRUE) %>%
  tolower() %>%
  st_transform("+init=epsg:2163") %>%
  st_intersection(., st_union(states))


