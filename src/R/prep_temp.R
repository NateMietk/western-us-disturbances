
# Monthly mean 
source("src/R/aggregate_climate_data.R")



anom_fun <- function(x, y) {
  x - y
}
mean_fun <- function(x, y) {
  (x + y)/2
}

celsius <- function(x) {
  x - 272.15
}

# Import and process the PDSI data
start_date <- as.Date(paste("1979", "1", "1", sep = "-"))
end_date <- as.Date(paste("2016", "12", "31", sep = "-"))
date_seq <- seq(start_date, end_date, by = "1 month")
month_seq <- month(date_seq)
year_seq <- year(date_seq)


# Create raster stack of monthly mean
monthly_tmmx_files <- list.files(file.path(prefix, "climate/tmean","monthly_mean"), 
                                 pattern = ".tif", full.names = TRUE)
tmmx_mean <- stack(monthly_tmmx_files)

monthly_tmmn_files <- list.files(file.path(prefix, "climate/tmmn","monthly_mean"), 
                                 pattern = ".tif", full.names = TRUE)

tmmn_mean <- stack(monthly_tmmn_files) 
tmean <- overlay(x = tmmx_mean, y = tmmn_mean, fun = mean_fun)

# Monthly average tmean
year <- 1979:2016
for(i in year){
  r_sub <- subset(tmean_c,  grep(i, names(tmean_c))) # subset based on year
  # Write out the monthly anomalies by year
  if(!file.exists(file.path(prefix, "climate", paste0("tmean/monthly_mean/tmean_", i, "_mean.tif")))){
    writeRaster(r_sub, filename = file.path(prefix, "climate", paste0("tmean/monthly_mean/tmean_", i, "_mean.tif")),
                format = "GTiff") }
}

# For import after the monthly mean creation - this is so we do not have to recalculate means everytime.
tmean_list <- list.files(file.path(prefix, "climate/tmean","monthly_mean"), 
                         pattern = ".tif", full.names = TRUE)
tmean <- stack(tmean_list)

idx = seq(as.Date("1979-01-15"), as.Date("2016-12-15'"), by = "month")
tmean = setZ(tmean, idx, 'months')

# Create anomalies
# Split 1984-2016 period and take climatology
tclimatology = subset(tmean, 
                      which(getZ(tmean)>=as.Date('1979-01-01') & 
                              getZ(tmean)<=as.Date('2016-12-31')))
names(tclimatology) <- paste(year(date_seq), month(date_seq), 
                                day(date_seq), sep = "-")
tclimatology_mon = zApply(tclimatology, by = months, mean, name = month.abb[])

# Reorder the climatology from alphabetical
tclimatology_mon <- 
  stack(tclimatology_mon[[5]],tclimatology_mon[[4]],tclimatology_mon[[8]],
        tclimatology_mon[[1]],tclimatology_mon[[9]], tclimatology_mon[[7]], 
        tclimatology_mon[[6]],tclimatology_mon[[2]],tclimatology_mon[[12]],
        tclimatology_mon[[11]],tclimatology_mon[[10]], tclimatology_mon[[3]])

# Produce monthly anomalies

tmean_anomalies <- overlay(x = tmean, y = tclimatology_mon, fun = anom_fun)
tmean_anomalies <- tmmx_annomalies
tmean_anomalies = setZ(tmean_anomalies, idx)
names(tmean_anomalies) <- paste(year(date_seq), month(date_seq), 
                                day(date_seq), sep = "-")

# Create summer only series
tmean_june_anom <- subset(tmean_anomalies,  grep(".6.1$", names(tmean_anomalies)),
                         drop = TRUE) # subset based on year
tmean_july_anom <- subset(tmean_anomalies,  grep(".7.1$", names(tmean_anomalies)),
                         drop = TRUE) # subset based on year
tmean_august_anom <- subset(tmean_anomalies,  grep(".8.1$", names(tmean_anomalies)),
                           drop = TRUE) # subset based on year

tmean_summer_anom <- stack(tmean_june_anom, tmean_july_anom, tmean_august_anom)
# Produce standardized anomalies
# tmean_std_anom <- tmean_anom / tmean_sd
# names(tmean_std_anom) <- paste(year(date_seq), month(date_seq), 
#                               day(date_seq), sep = "-")

# Yearly average anomalous tmean
year <- 1979:2016
tmean_yr_anom <- stack()
for(i in year){
  r_sub <- subset(tmean_anomalies,  grep(i, names(tmean_anomalies))) # subset based on year
  # Write out the monthly anomalies by year
  if(!file.exists(paste0("data/climate/tmean/monthly_anomalies/tmean_", i, "_anom.tif"))){
    writeRaster(r_sub, filename = paste0("data/climate/tmean/monthly_anomalies/tmean_", i, "_anom.tif"),
                format = "GTiff") }
  t_mean <- calc(r_sub, mean)
  # Write out the yearly aggregates
  if(!file.exists(paste0("data/climate/tmean/yearly_anomalies/tmean_", i, "_anom.tif"))){
    writeRaster(t_mean, filename = paste0("data/climate/tmean/yearly_anomalies/tmean_", i, "_anom.tif"),
                format = "GTiff") }
  
  tmean_yr_anom <- stack(tmean_yr_anom, t_mean)
}

# Anything less than -2 is considered moderate drought
mod_tmean <- tmean_summer_anom
mod_tmean[mod_tmean > -2] <- NA

m <- c(-2, 99, 0,  -99,  -2, 1)
rclmat <- matrix(m, ncol=3, byrow=TRUE)

tmean_bool <- reclassify(mod_tmean, rclmat)
names(tmean_bool) <- paste("tmean", year,
                          sep = "_")

tmean_tots <- stackApply(tmean_bool, rep(1, each = 33), fun = sum) %>%
  mask(as(neon_domains, "Spatial"))

y <- c(-99, 0, 0,
       1, 5, 1, 
       5, 7, 2,
       7, 9, 3, 
       9, 12, 4, 
       12, 19, 5)
rclyr <- matrix(y, ncol=3, byrow=TRUE)
tmean_rcl <- reclassify(tmean_tots, rclyr)

# Prep for the plots

tmean_df <- as.data.frame(as(tmean_rcl, "SpatialPixelsDataFrame")) %>%
  mutate(tmean_class = layer)

nd_df <- fortify(as(neon_domains, "Spatial"), region = "id")




# red = Niwot Ridge Mountain Research Station
# green = Wind River Experimental Forest
# blue = Yellowstone Northern Range