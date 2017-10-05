x <- c("raster", "tidyverse", "lubridate", "ncdf4", "sf", "zoo")
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
  st_transform("+init=epsg:2163") %>%  # e.g. US National Atlas Equal Area
  mutate(group = 1) %>%
  filter(PMC %in% c("D16CT1", "D13CT1", "D12CT1")) %>%
  as(., "Spatial")

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

mpdsi_bool <- reclassify(mod_pdsi, rclmat)
names(mpdsi_bool) <- paste("pdsi", year,
                           sep = "_")

mpdsi_tots <- stackApply(mpdsi_bool, rep(1, each = 33), fun = sum) %>%
  mask(as(neon_domains, "Spatial"))

y <- c(1, 5, 1, 
       5, 7, 2,
       7, 9, 3, 
       9, 12, 4, 
       12, 18, 5)
rclyr <- matrix(y, ncol=3, byrow=TRUE)
reclassify(mpdsi_tots, rclyr)




