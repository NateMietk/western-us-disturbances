daily_to_monthly <- function(file, mask){
  x <- c("lubridate", "rgdal", "ncdf4", "raster", "tidyverse", "snowfall")
  lapply(x, require, character.only = TRUE)
  p4string_ea <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"   #http://spatialreference.org/ref/sr-org/6903/
  
  file_split <- file %>%
    basename %>%
    strsplit(split = "_") %>%
    unlist
  var <- file_split[1]
  year <- substr(file_split[2], start = 1, stop = 4)
  
  # Check if directory exists for all variable aggregate outputs, if not then create
  data_var <- file.path(tem_prefix, var)
  dir_mean <- file.path(data_var, "monthly_mean")
  
  var_dir <- list(data_var, dir_mean)
  
  lapply(var_dir, function(x) 
    if(!dir.exists(x)) dir.create(x, showWarnings = FALSE))
  
  raster <- brick(file) 
  p4string <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
  projection(raster) <- CRS(p4string)
  raster <- projectRaster(raster, crs = p4string_ea, res = 4000)

  
  start_date <- as.Date(paste(year, "01", "01", sep = "-"))
  end_date <- as.Date(paste(year, "12", "31", sep = "-"))
  date_seq <- seq(start_date, end_date, by = "1 day")
  date_seq <- date_seq[1:nlayers(raster)]
  month_seq <- month(date_seq)
  day_seq <- day(date_seq)
  
  # Mean
  if(!file.exists(file.path(dir_mean, paste0(var, "_", year, "_mean",".tif")))) {
    monthly_mean <- stackApply(raster, month_seq, fun = mean)
    names(monthly_mean) <- paste(year(date_seq), month(date_seq), 
                                 day(date_seq), sep = "-")
    tmmx_mean <- mask(monthly_mean, mask)
    writeRaster(tmmx_mean, filename = file.path(dir_mean, paste0(var, "_", year, "_mean",".tif")),
                format = "GTiff") 
  }
}