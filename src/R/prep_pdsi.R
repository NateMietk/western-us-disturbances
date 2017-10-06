source("src/R/prep_bounds.R")

# Import and process the PDSI data
start_date <- as.Date(paste("1980", "01", "01", sep = "-"))
end_date <- as.Date(paste("2016", "12", "31", sep = "-"))
date_seq <- seq(start_date, end_date, by = "1 month")
month_seq <- month(date_seq)
year_seq <- year(date_seq)

nc <- nc_open("~/Dropbox/Professional/RScripts/modeling-human-ignition/data/raw/climate/pdsi_19792016.nc")
nc_att <- attributes(nc$var)$names
ncvar <- ncvar_get(nc, nc_att)
tvar <- aperm(ncvar, c(3,2,1))
proj <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs +towgs84=0,0,0 "

rasters <- brick(tvar, crs= proj)
extent(rasters) <- c(-124.793, -67.043, 25.04186, 49.41686)

# Create raster stack of monthly mean
pdsi_mm <- projectRaster(rasters ,crs = p4string_ea, res = 4000) %>%
  crop(as(neon_domains, "Spatial")) %>%
  mask(as(neon_domains, "Spatial"))
pdsi_mm <- dropLayer(pdsi_mm, 1:12)

idx = seq(as.Date("1980/1/1"), as.Date("2016/12/31"), by = "month")
pdsi_mm = setZ(pdsi_mm, idx)
# names(monthly_mean) <- paste(year(date_seq), month(date_seq), 
#                              day(date_seq), sep = "-")

# Create anomalies
# Split 1984-2016 period and take climatology
pclimatology = subset(pdsi_mm, 
                      which(getZ(pdsi_mm)>=as.Date('1980-01-01') & 
                              getZ(pdsi_mm)<=as.Date('2016-12-31')))
pclimatology_mon = zApply(pclimatology, by=months, mean, name=month.abb[])

# Reorder the climatology from alphabetical
pclimatology_mon <- stack(
  pclimatology_mon[[5]],pclimatology_mon[[4]],pclimatology_mon[[8]],
      pclimatology_mon[[1]],pclimatology_mon[[9]], pclimatology_mon[[7]], 
      pclimatology_mon[[6]],pclimatology_mon[[2]],pclimatology_mon[[12]],
      pclimatology_mon[[11]],pclimatology_mon[[10]], pclimatology_mon[[3]])

# Produce monthly anomalies
fun <- function(x, y) {
  x - y
}
pdsi_annomalies <- overlay(x = pdsi_mm, y = pclimatology_mon, fun = fun)
pdsi_annomalies = setZ(pdsi_annomalies, idx)
names(pdsi_annomalies) <- paste(year(date_seq), month(date_seq), 
                             day(date_seq), sep = "-")
                             
# Create summer only series
pdsi_june_anom <- subset(pdsi_annomalies,  grep(".6.1$", names(pdsi_annomalies)),
                         drop = TRUE) # subset based on year
pdsi_july_anom <- subset(pdsi_annomalies,  grep(".7.1$", names(pdsi_annomalies)),
                         drop = TRUE) # subset based on year
pdsi_august_anom <- subset(pdsi_annomalies,  grep(".8.1$", names(pdsi_annomalies)),
                           drop = TRUE) # subset based on year

pdsi_summer_anom <- stack(pdsi_june_anom, pdsi_july_anom, pdsi_august_anom)
year <- 1984:2016
pdsi_sum_yr_anom <- stack()
for(i in year){
  r_sub <- subset(pdsi_summer_anom,  grep(i, names(pdsi_summer_anom))) # subset based on year
  p_mean <- calc(r_sub, mean)
  pdsi_sum_yr_anom <- stack(pdsi_sum_yr_anom, p_mean)
}
# Create standardized anomalies
# pdsi_sd <- calc(monthly_mean, fun = sd, na.rm = TRUE) 
# 
# pdsi_std_anom <- pdsi_annomalies / pdsi_sd
# names(pdsi_std_anom) <- paste(year(date_seq), month(date_seq), 
#                               day(date_seq), sep = "-")
#
# Yearly average anomalous PDSI
year <- 1984:2016
pdsi_yr_anom <- stack()
for(i in year){
  r_sub <- subset(pdsi_annomalies,  grep(i, names(pdsi_annomalies))) # subset based on year
  # Write out the monthly anomalies by year
  if(!file.exists(paste0("data/climate/pdsi/monthly_anomalies/pdsi_", i, "_anom.tif"))){
    writeRaster(r_sub, filename = paste0("data/climate/pdsi/monthly_anomalies/pdsi_", i, "_anom.tif"),
                format = "GTiff") }
  p_mean <- calc(r_sub, mean)
  # Write out the yearly aggregates
  if(!file.exists(paste0("data/climate/pdsi/yearly_anomalies/pdsi_", i, "_anom.tif"))){
    writeRaster(p_mean, filename = paste0("data/climate/pdsi/yearly_anomalies/pdsi_", i, "_anom.tif"),
                format = "GTiff") }
  pdsi_yr_anom <- stack(pdsi_yr_anom, p_mean)
}

# Anything less than -2 is considered moderate drought
mod_pdsi <- pdsi_sum_yr_anom
mod_pdsi[mod_pdsi > -2] <- NA

m <- c(-2, 99, 0,  -99,  -2, 1)
rclmat <- matrix(m, ncol=3, byrow=TRUE)

pdsi_bool <- reclassify(mod_pdsi, rclmat)
names(pdsi_bool) <- paste("pdsi", year,
                          sep = "_")

pdsi_tots <- stackApply(pdsi_bool, rep(1, each = 33), fun = sum) %>%
  mask(as(neon_domains, "Spatial"))

y <- c(-99, 0, 0,
       1, 6, 1,
       6, 8, 2,
       8, 10, 3,
       10, 14, 4,
       14, 20, 5)
rclyr <- matrix(y, ncol=3, byrow=TRUE)
pdsi_rcl <- reclassify(pdsi_tots, rclyr)

# Prep for the plots

pdsi_df <- as.data.frame(as(pdsi_rcl, "SpatialPixelsDataFrame")) %>%
  mutate(pdsi_class = layer)
