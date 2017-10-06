
source("src/R/prep_bounds.R")


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

# Import and process the PDSI data
start_date <- as.Date(paste("1980", "01", "01", sep = "-"))
end_date <- as.Date(paste("2016", "12", "31", sep = "-"))
date_seq <- seq(start_date, end_date, by = "1 month")
month_seq <- month(date_seq)
year_seq <- year(date_seq)

# Create raster stack of monthly mean
monthly_files <- list.files(file.path("~/Dropbox/Professional/RScripts/modeling-human-ignition/data/climate/tmmx",
                                      "monthly_mean"), pattern = ".tif", full.names = TRUE)
tmmx_mean <- stack(monthly_files) 
tmmx_mean <- tmmx_mean - 273.15
tmmx_mean <- dropLayer(tmmx_mean, 1:12)

idx = seq(as.Date("1980/1/1"), as.Date("2016/12/31"), by = "month")
tmmx_mean = setZ(tmmx_mean, idx)
# names(monthly_mean) <- paste(year(date_seq), month(date_seq), 
#                              day(date_seq), sep = "-")

# Create anomalies
# Split 1984-2016 period and take climatology
tclimatology = subset(tmmx_mean, 
                      which(getZ(tmmx_mean)>=as.Date('1980-01-01') & 
                              getZ(tmmx_mean)<=as.Date('2016-12-31')))
tclimatology_mon = zApply(tclimatology, by=months, mean, name=month.abb[])

# Reorder the climatology from alphabetical
tclimatology_mon <- 
  stack(tclimatology_mon[[5]],tclimatology_mon[[4]],tclimatology_mon[[8]],
        tclimatology_mon[[1]],tclimatology_mon[[9]], tclimatology_mon[[7]], 
        tclimatology_mon[[6]],tclimatology_mon[[2]],tclimatology_mon[[12]],
        tclimatology_mon[[11]],tclimatology_mon[[10]], tclimatology_mon[[3]])

# Produce monthly anomalies
fun <- function(x, y) {
  x - y
}
tmmx_annomalies <- overlay(x = tmmx_mean, y = tclimatology_mon, fun = fun)
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

# Yearly average anomalous PDSI
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