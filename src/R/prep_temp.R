
#source("src/R/prep_bounds.R")


# Monthly mean 
# source("src/functions/daily_to_monthly_tmmx.R")
# tmmx_mean <- stack()
# daily_files <- list.files(file.path(temp_prefix, "daily"), pattern = ".nc", full.names = TRUE)
# 
# masks <- as(neon_domains, "Spatial")
# sfInit(parallel = TRUE, cpus = parallel::detectCores())
# sfExportAll()
# 
# sfLapply(daily_files, 
#          daily_to_monthly,
#          masks = masks)
# sfStop()
anom_fun <- function(x, y) {
  x - y
}
mean_fun <- function(x, y) {
  (x + y)/2
}


# Import and process the PDSI data
start_date <- as.Date(paste("1980", "01", "01", sep = "-"))
end_date <- as.Date(paste("2016", "12", "31", sep = "-"))
date_seq <- seq(start_date, end_date, by = "1 month")
month_seq <- month(date_seq)
year_seq <- year(date_seq)

# Create raster stack of monthly mean
monthly_tmmx_files <- list.files(file.path(prefix, "climate/tmmx","monthly_mean"), 
                                 pattern = ".tif", full.names = TRUE)
tmmx_mean <- stack(monthly_tmmx_files)

monthly_tmmn_files <- list.files(file.path(prefix, "climate/tmmn","monthly_mean"), 
                                 pattern = ".tif", full.names = TRUE)

domain_ll <- st_transform(neon_domains, crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0")
tmmn_mean <- stack(monthly_tmmn_files) %>%
  crop(as(domain_ll, "Spatial")) %>%
  mask(as(domain_ll, "Spatial")) %>%
  projectRaster(crs = p4string_ea, res = 4000) %>%
  crop(as(neon_domain, "Spatial")) %>%
  mask(as(neon_domain, "Spatial")) 
  
tmean <- overlay(x = tmmx_mean, y = tmmn_mean, fun = mean)

idx = seq(as.Date("1980/1/1"), as.Date("2016/12/31"), by = "month")
tmean = setZ(tmean, idx)

# Monthly average tmean
year <- 1979:2016
for(i in year){
  r_sub <- subset(tmean,  grep(i, names(tmean))) # subset based on year
  # Write out the monthly anomalies by year
  if(!file.exists(paste0("data/climate/tmean/monthly_mean/tmean_", i, "_mean.tif"))){
    writeRaster(r_sub, filename = paste0("data/climate/tmean/monthly_mean/tmean_", i, "_mean.tif"),
                format = "GTiff") }
}

# Create anomalies
# Split 1984-2016 period and take climatology
tclimatology = subset(tmean, 
                      which(getZ(tmean)>=as.Date('1980-01-01') & 
                              getZ(tmean)<=as.Date('2016-12-31')))
tclimatology_mon = zApply(tclimatology, by=months, mean, name=month.abb[])

# Reorder the climatology from alphabetical
tclimatology_mon <- 
  stack(tclimatology_mon[[5]],tclimatology_mon[[4]],tclimatology_mon[[8]],
        tclimatology_mon[[1]],tclimatology_mon[[9]], tclimatology_mon[[7]], 
        tclimatology_mon[[6]],tclimatology_mon[[2]],tclimatology_mon[[12]],
        tclimatology_mon[[11]],tclimatology_mon[[10]], tclimatology_mon[[3]])

# Produce monthly anomalies

tmmx_annomalies <- overlay(x = tmean, y = tclimatology_mon, fun = anom_fun)
tmmx_annomalies = setZ(tmmx_annomalies, idx)
names(tmmx_annomalies) <- paste(year(date_seq), month(date_seq), 
                                day(date_seq), sep = "-")

names(tmmx_annomalies) <- paste(month(date_seq), sep = "-")

# Create summer only series
tmmx_june_anom <- subset(tmmx_annomalies,  grep(".6.1$", names(tmmx_annomalies)),
                           drop = TRUE) # subset based on year
tmmx_july_anom <- subset(tmmx_annomalies,  grep(".7.1$", names(tmmx_annomalies)),
                         drop = TRUE) # subset based on year
tmmx_august_anom <- subset(tmmx_annomalies,  grep(".8.1$", names(tmmx_annomalies)),
                         drop = TRUE) # subset based on year

tmmx_summer_anom <- stack(tmmx_june_anom, tmmx_july_anom, tmmx_august_anom)
# Produce standardized anomalies
# tmmx_std_anom <- tmmx_anom / tmmx_sd
# names(tmmx_std_anom) <- paste(year(date_seq), month(date_seq), 
#                               day(date_seq), sep = "-")

# Yearly average anomalous tmean
year <- 1984:2016
tmmx_yr_anom <- stack()
for(i in year){
  r_sub <- subset(tmmx_annomalies,  grep(i, names(tmmx_annomalies))) # subset based on year
  # Write out the monthly anomalies by year
  if(!file.exists(paste0("data/climate/tmmx/monthly_anomalies/tmmx_", i, "_anom.tif"))){
    writeRaster(r_sub, filename = paste0("data/climate/tmmx/monthly_anomalies/tmmx_", i, "_anom.tif"),
                format = "GTiff") }
  t_mean <- calc(r_sub, mean)
  # Write out the yearly aggregates
  if(!file.exists(paste0("data/climate/tmmx/yearly_anomalies/tmmx_", i, "_anom.tif"))){
    writeRaster(t_mean, filename = paste0("data/climate/tmmx/yearly_anomalies/tmmx_", i, "_anom.tif"),
                format = "GTiff") }
  
  tmmx_yr_anom <- stack(tmmx_yr_anom, t_mean)
}

# Anything less than -2 is considered moderate drought
mod_tmmx <- tmmx_summer_anom
mod_tmmx[mod_tmmx > -2] <- NA

m <- c(-2, 99, 0,  -99,  -2, 1)
rclmat <- matrix(m, ncol=3, byrow=TRUE)

tmmx_bool <- reclassify(mod_tmmx, rclmat)
names(tmmx_bool) <- paste("tmmx", year,
                          sep = "_")

tmmx_tots <- stackApply(tmmx_bool, rep(1, each = 33), fun = sum) %>%
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




# red = Niwot Ridge Mountain Research Station
# green = Wind River Experimental Forest
# blue = Yellowstone Northern Range