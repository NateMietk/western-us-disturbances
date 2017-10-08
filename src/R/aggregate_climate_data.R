
library(raster)
library(lubridate)
library(rgdal)
library(tidyverse)
library(assertthat)
library(snowfall)
library(ncdf4)
# Creat directories for state data
raw_prefix <- ifelse(Sys.getenv("LOGNAME") == "NateM", file.path("data", "raw"),
                     ifelse(Sys.getenv("LOGNAME") == "nami1114", file.path("data", "raw"),
                            file.path("../data", "raw")))
domain_prefix <- file.path(raw_prefix, "NEONDomains_0")

# Check if directory exists for all variable aggregate outputs, if not then create
var_dir <- list(raw_prefix, domain_prefix)
lapply(var_dir, function(x) if(!dir.exists(x)) dir.create(x, showWarnings = FALSE))

domain_shp <- file.path(domain_prefix, "NEON_Domains.shp")
if (!file.exists(domain_shp)) {
  loc <- "http://www.neonscience.org/sites/default/files/NEONDomains_0.zip"
  dest <- paste0(prefix, ".zip")
  download.file(loc, dest)
  unzip(dest, exdir = domain_prefix)
  unlink(dest)
  assert_that(file.exists(domain_shp))
}

neon_domains <- st_read(dsn = domain_prefix,
                        layer = "NEON_Domains", quiet= TRUE) %>%
  st_transform(crs = "+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0") %>%
  filter(DomainName %in% c("Desert Southwest", "Pacific Northwest", "Great Basin",
                           "Southern Rockies / Colorado Plateau", "Northern Rockies", "Pacific Southwest")) %>%
  st_intersection(., st_union(states)) %>%
  mutate(id = row_number(),
         group = 1)

daily_to_monthly <- function(file, mask){
  x <- c("lubridate", "rgdal", "ncdf4", "raster", "tidyverse", "snowfall")
  lapply(x, require, character.only = TRUE)

  file_split <- file %>%
    basename %>%
    strsplit(split = "_") %>%
    unlist
  var <- file_split[1]
  year <- substr(file_split[2], start = 1, stop = 4)

  # Check if directory exists for all variable aggregate outputs, if not then create
  data_pro <- file.path("../data",  "climate")
  data_var <- file.path(data_pro, var)
  dir_mean <- file.path(data_var, "monthly_mean")

  var_dir <- list(data_pro, data_var, dir_mean)

  lapply(var_dir, function(x) if(!dir.exists(x)) dir.create(x, showWarnings = FALSE))

  raster <- brick(file)
  p4string <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
  projection(raster) <- CRS(p4string)

  start_date <- as.Date(paste(year, "01", "01", sep = "-"))
  end_date <- as.Date(paste(year, "12", "31", sep = "-"))
  date_seq <- seq(start_date, end_date, by = "1 day")
  date_seq <- date_seq[1:nlayers(raster)]
  month_seq <- month(date_seq)
  day_seq <- day(date_seq)

  # Mean
  if(!file.exists(file.path(dir_mean, paste0(var, "_", year, "_mean",".tif")))) {
    p4string_ea <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"   #http://spatialreference.org/ref/sr-org/6903/

    monthly_mean <- stackApply(raster, month_seq, fun = mean)
    monthly_mean <- flip(t(monthly_mean), direction = "x")
    monthly_mean <- mask(monthly_mean, mask)
    monthly_mean <- projectRaster(p4string_ea, res = 4000)

    names(monthly_mean) <- paste(var, year,
                                 unique(month(date_seq, label = TRUE)),
                                 sep = "_")
    writeRaster(monthly_mean, filename = file.path(dir_mean, paste0(var, "_", year, "_mean",".tif")),
                format = "GTiff")
              }
}

daily_files <- list.files(".", pattern = ".nc", full.names = TRUE)

sfInit(parallel = TRUE, cpus = parallel::detectCores())
sfExportAll()

sfLapply(daily_files,
         daily_to_monthly,
         mask = neon_domains)
sfStop()
