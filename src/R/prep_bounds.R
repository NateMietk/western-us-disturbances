x <- c("raster", "tidyverse", "lubridate", "ncdf4", "sf", "zoo", "snowfall")
lapply(x, library, character.only = TRUE, verbose = FALSE)

p4string_ea <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"   #http://spatialreference.org/ref/sr-org/6903/

# Import the US States and project to albers equal area
states <- st_read(dsn = us_prefix,
                  layer = "cb_2016_us_state_20m", quiet= TRUE) %>%
  st_transform(p4string_ea) %>%
  filter(!(NAME %in% c("Alaska", "Hawaii", "Puerto Rico"))) %>%
  mutate(group = 1) %>%
  st_simplify(., preserveTopology = TRUE)

# Import the NEON domains and project to albers equal area
neon_domains <- st_read(dsn = domain_prefix,
                        layer = "NEON_Domains", quiet= TRUE) %>%
  st_transform(p4string_ea) %>%
  filter(DomainName %in% c("Desert Southwest", "Pacific Northwest", "Great Basin",
                           "Southern Rockies / Colorado Plateau", "Northern Rockies", "Pacific Southwest")) %>%
  st_intersection(., st_union(states)) %>%
  mutate(id = row_number(),
         group = 1) 

# Import the NEON sites, clean to terrestial only, and project to albers equal area
neon_sites <- st_read(dsn = site_prefix,
                      layer = "NEON_Field_Sites", quiet= TRUE) %>%
  st_transform(p4string_ea) %>%
  filter(PMC %in% c("D16CT1", "D13CT1", "D12CT1")) %>%
  mutate(group = 'Key',
         id = row_number())

# Import the forest groups and project to albers equal area
forests <- raster(file.path(forest_prefix, "conus_forestgroup.img")) %>%
  projectRaster(crs = p4string_ea, res = 500) %>%
  crop(as(neon_domains, "Spatial")) %>%
  mask(as(neon_domains, "Spatial"))

forests[forests %in% c("100", "120", "140", "160", "180", "200", "240", "260", 
           "300","320", "340", "360", "380", "400", "500", "600", "700", "800", 
           "900", "910", "920", "940", "950", "980" , "990")] <- NA

forests[forests >= 1] <- 1
forests[forests < 1] <- 0


