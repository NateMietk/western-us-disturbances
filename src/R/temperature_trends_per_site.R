x <- c("raster", "tidyverse", "lubridate", "sf")
lapply(x, library, character.only = TRUE, verbose = FALSE)

# Import the NEON sites, clean to western focus only, and project to albers equal area
neon_domains <- st_read(dsn = domain_prefix,
                        layer = "NEON_Domains", quiet= TRUE) %>%
  st_transform(p4string_ea) %>%
  filter(DomainName %in% c("Desert Southwest", "Pacific Northwest", "Great Basin",
                           "Southern Rockies / Colorado Plateau", "Northern Rockies", "Pacific Southwest")) %>%
  st_intersection(., st_union(states)) %>%
  mutate(id = row_number(),
         group = 1)%>%
  group_by(group) %>%
  summarise()

# Import the NEON sites, clean to terrestial only, and project to albers equal area
neon_sites <- st_read(dsn = site_prefix,
                      layer = "NEON_Field_Sites", quiet= TRUE) %>%
  st_transform("+init=epsg:2163") %>%  # e.g. US National Atlas Equal Area
  mutate(group = 1) %>%
  filter(PMC %in% c("D16CT1", "D13CT1", "D12CT1")) %>%
  as(., "Spatial")

tmmx_files <- list.files("data/climate/tmmx/monthly_mean", pattern = ".tif$", 
                         full.names = TRUE)

tmmx_84 <- stack("data/climate/tmmx/monthly_mean/tmmx_1984_mean.tif") - 273.15
tmmx_16 <- stack("data/climate/tmmx/monthly_mean/tmmx_2016_mean.tif") - 273.15

p4string <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
projection(tmmx_84) <- CRS(p4string)
projection(tmmx_16) <- CRS(p4string)

tmmx_84_yr <- stackApply(tmmx_84, 1, fun = mean,  na.rm = TRUE) %>%
  projectRaster(crs = p4string_ea, res = 4000) %>%
  crop(as(neon_domains, "Spatial")) %>%
  mask(as(neon_domains, "Spatial"))  

tmmx_16_yr <- stackApply(tmmx_16, 1, fun = mean,  na.rm = TRUE) %>%
  projectRaster(crs = p4string_ea, res = 4000) %>%
  crop(as(neon_domains, "Spatial")) %>%
  mask(as(neon_domains, "Spatial"))  

data_mean <- data.frame(coordinates(neon_sites),
                   neon_sites$SiteName, 
                   raster::extract(tmmx_84_yr, neon_sites),
                   raster::extract(tmmx_16_yr, neon_sites),
                   raster::extract(tmmx_84_yr_std, neon_sites),
                   raster::extract(tmmx_16_yr_std, neon_sites))
names(data_mean) <- c("x", "y", "name", "t1984", "t2016", "sd1984", "sd2016")

data_mean <- data_mean %>%
  select(name, t1984, t2016) %>%
  gather( key, value, -name) %>%
  mutate(year = ifelse(key == "t1984", "1984", "2016"))

source("src/R/ggplot_theme.R")
data_mean %>%
  ggplot(aes(x = year, y = value)) +
  geom_point(aes(color = name)) +
  geom_line(aes(group = name, color = name), size = 0.5, alpha = 0.5) +
  xlab("Year") + ylab("Mean temperature (degrees C)") +
  theme_pub() + theme(legend.position = "none")

# red = Niwot Ridge Mountain Research Station
# green = Wind River Experimental Forest
# blue = Yellowstone Northern Range