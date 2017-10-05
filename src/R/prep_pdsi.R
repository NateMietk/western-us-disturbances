source("src/R/prep_bounds.R")

# Import and process the PDSI data
start_date <- as.Date(paste("1979", "01", "01", sep = "-"))
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
monthly_mean <- projectRaster(rasters ,crs = p4string_ea, res = 4000) %>%
  crop(as(neon_domains, "Spatial")) %>%
  mask(as(neon_domains, "Spatial"))
names(monthly_mean) <- paste("pdsi", year(date_seq),
                        month(date_seq, label = TRUE),
                        sep = "_")
# Monthly mean 75th percentile
mean_75thpct <- stack()
for (j in 1:nlayers(monthly_mean)){
  pctile <- calc(monthly_mean[[j]], 
                 fun = function(x) raster::quantile(x, probs = 0.75, na.rm = T))
  mean_75thpct <- stack(mean_75thpct, pctile)
}
names(mean_75thpct) <- paste("pdsi", year(date_seq),
                             month(date_seq, label = TRUE),
                             sep = "_")
writeRaster(mean_75thpct, filename = "data/climate/pdsi/monthly_mean_75thpct/all_yrs/pdsi_19792016_75th.tif",
            format = "GTiff") 

# Yearly average 75th percentile PDSI
year <- 1980:2016
pdsi_yr_mean <- stack()
for(i in year){
  r_sub <- subset(mean_75thpct,  grep(i, names(mean_75thpct))) # subset based on year
  if(!file.exists(paste0("data/climate/pdsi/monthly_mean_75thpct/pdsi_", i, "_75th.tif"))){
    writeRaster(r_sub, filename = paste0("data/climate/pdsi/monthly_mean_75thpct/pdsi_", i, "_75th.tif"),
              format = "GTiff") }
  p_mean <- calc(r_sub, mean)
  pdsi_yr_mean <- stack(pdsi_yr_mean, p_mean)
}
names(pdsi_yr_mean) <- paste("pdsi", year,
                             sep = "_")

# Anything less than -2 is considered moderate drought
mod_pdsi <- pdsi_yr_mean
mod_pdsi[mod_pdsi > -2] <- NA

m <- c(-2, 99, 0,  -99,  -2, 1)
rclmat <- matrix(m, ncol=3, byrow=TRUE)

pdsi_bool <- reclassify(mod_pdsi, rclmat)
names(pdsi_bool) <- paste("pdsi", year,
                           sep = "_")

pdsi_tots <- stackApply(pdsi_bool, rep(1, each = 37), fun = sum) %>%
  mask(as(neon_domains, "Spatial"))

y <- c(-99, 0, 0,
       1, 5, 1, 
       5, 7, 2,
       7, 9, 3, 
       9, 12, 4, 
       12, 19, 5)
rclyr <- matrix(y, ncol=3, byrow=TRUE)
pdsi_rcl <- reclassify(pdsi_tots, rclyr)

# Prep for the plots

pdsi_df <- as.data.frame(as(pdsi_rcl, "SpatialPixelsDataFrame")) %>%
  mutate(pdsi_class = layer)

nd_df <- fortify(as(neon_domains, "Spatial"), region = "id")



