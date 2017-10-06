
source("src/R/prep_bounds.R")


# Monthly mean 
source("src/functions/daily_to_monthly_tmmx.R")
tmmx_mean <- stack()
daily_files <- list.files(file.path(temp_prefix, "daily"), pattern = ".nc", full.names = TRUE)

masks <- as(neon_domains, "Spatial")
sfInit(parallel = TRUE, cpus = parallel::detectCores())
sfExportAll()

sfLapply(daily_files, 
         daily_to_monthly,
         masks = masks)
sfStop()


# Yearly average 75th percentile tmmx
year <- 1980:2016
tmmx_yr_mean <- stack()
for(i in year){
  r_sub <- subset(tmmx_mean,  grep(i, names(tmmx_mean))) # subset based on year
  if(!file.exists(file.path(temp_mnths,paste0("tmmx_", i, "_mean.tif")))){
    writeRaster(r_sub, filename = file.path(temp_mnths,paste0("tmmx_", i, "_mean.tif")),
                format = "GTiff") }
  p_mean <- calc(r_sub, mean)
  tmmx_yr_mean <- stack(tmmx_yr_mean, p_mean)
}
names(tmmx_yr_mean) <- paste("tmmx", year,
                             sep = "_")

# Anything less than -2 is considered moderate drought
mod_tmmx <- tmmx_yr_mean
mod_tmmx[mod_tmmx > -2] <- NA

m <- c(-2, 99, 0,  -99,  -2, 1)
rclmat <- matrix(m, ncol=3, byrow=TRUE)

tmmx_bool <- reclassify(mod_tmmx, rclmat)
names(tmmx_bool) <- paste("tmmx", year,
                          sep = "_")

tmmx_tots <- stackApply(tmmx_bool, rep(1, each = 37), fun = sum) %>%
  mask(as(neon_domains, "Spatial"))

y <- c(-99, 0, 0,
       1, 5, 1, 
       5, 7, 2,
       7, 9, 3, 
       9, 12, 4, 
       12, 19, 5)
rclyr <- matrix(y, ncol=3, byrow=TRUE)
tmmx_rcl <- reclassify(tmmx_tots, rclyr)

# Prep for the plots

tmmx_df <- as.data.frame(as(tmmx_rcl, "SpatialPixelsDataFrame")) %>%
  mutate(tmmx_class = layer)

nd_df <- fortify(as(neon_domains, "Spatial"), region = "id")

# tmmx_files <- list.files("data/climate/tmmx/monthly_mean", pattern = ".tif$", 
#                          full.names = TRUE)
# 
# tmmx_84 <- stack("data/climate/tmmx/monthly_mean/tmmx_1984_mean.tif") - 273.15
# tmmx_16 <- stack("data/climate/tmmx/monthly_mean/tmmx_2016_mean.tif") - 273.15
# 
# p4string <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
# projection(tmmx_84) <- CRS(p4string)
# projection(tmmx_16) <- CRS(p4string)
# 
# tmmx_84_yr <- stackApply(tmmx_84, 1, fun = mean,  na.rm = TRUE) %>%
#   projectRaster(crs = p4string_ea, res = 4000) %>%
#   crop(as(neon_domains, "Spatial")) %>%
#   mask(as(neon_domains, "Spatial"))  
# 
# tmmx_16_yr <- stackApply(tmmx_16, 1, fun = mean,  na.rm = TRUE) %>%
#   projectRaster(crs = p4string_ea, res = 4000) %>%
#   crop(as(neon_domains, "Spatial")) %>%
#   mask(as(neon_domains, "Spatial"))  
# 
# data_mean <- data.frame(coordinates(neon_sites),
#                         neon_sites$SiteName, 
#                         raster::extract(tmmx_84_yr, neon_sites),
#                         raster::extract(tmmx_16_yr, neon_sites),
#                         raster::extract(tmmx_84_yr_std, neon_sites),
#                         raster::extract(tmmx_16_yr_std, neon_sites))
# names(data_mean) <- c("x", "y", "name", "t1984", "t2016", "sd1984", "sd2016")
# 
# data_mean <- data_mean %>%
#   select(name, t1984, t2016) %>%
#   gather( key, value, -name) %>%
#   mutate(year = ifelse(key == "t1984", "1984", "2016"))
# 
# source("src/R/ggplot_theme.R")
# data_mean %>%
#   ggplot(aes(x = year, y = value)) +
#   geom_point(aes(color = name)) +
#   geom_line(aes(group = name, color = name), size = 0.5, alpha = 0.5) +
#   xlab("Year") + ylab("Mean temperature (degrees C)") +
#   theme_pub() + theme(legend.position = "none")

# red = Niwot Ridge Mountain Research Station
# green = Wind River Experimental Forest
# blue = Yellowstone Northern Range