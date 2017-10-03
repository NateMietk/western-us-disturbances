
x <- c("raster", "tidyverse", "sf", "assertthat", "purrr", "httr", 
       "rvest", "lubridate", "rgdal", "tools", "snowfall")
lapply(x, library, character.only = TRUE, verbose = FALSE)

prefix <- ifelse(Sys.getenv("LOGNAME") == "NateM", file.path("data"), 
                 ifelse(Sys.getenv("LOGNAME") == "nami1114", file.path("data"), 
                        file.path("../data")))
raw_prefix <- file.path(prefix, "raw")
elev_prefix <- file.path(raw_prefix, 'metdata_elevationdata')
us_prefix <- file.path(raw_prefix, "cb_2016_us_state_20m")
domain_prefix <- file.path(raw_prefix, "NEONDomains_0")
site_prefix <- file.path(raw_prefix, "neon_site")
forest_prefix <- file.path(raw_prefix, "conus_forestgroup")
mtbs_prefix <- file.path(raw_prefix, "mtbs_perimeter_data")
ads <- file.path(prefix, "ads")
r1_dir <- file.path(prefix, "r1")
r2_dir <- file.path(prefix, "r2")
r3_dir <- file.path(prefix, "r3")
r4_dir <- file.path(prefix, "r4")
r5_dir <- file.path(prefix, "r5")
r6_dir <- file.path(prefix, "r6")
ads_out <- file.path(prefix, "wus")
source("src/R/ads_https.R")

# Check if directory exists for all variable aggregate outputs, if not then create
var_dir <- list(prefix, raw_prefix, us_prefix, domain_prefix, site_prefix, forest_prefix, mtbs_prefix,
                ads_out, elev_prefix, ads, r1_dir, r2_dir, r3_dir, r4_dir, r5_dir, r6_dir)

lapply(var_dir, function(x) if(!dir.exists(x)) dir.create(x, showWarnings = FALSE))

#Download the USA States layer

us_shp <- file.path(us_prefix, "cb_2016_us_state_20m.shp")
if (!file.exists(us_shp)) {
  loc <- "https://www2.census.gov/geo/tiger/GENZ2016/shp/cb_2016_us_state_20m.zip"
  dest <- paste0(us_prefix, ".zip")
  download.file(loc, dest)
  unzip(dest, exdir = us_prefix)
  unlink(dest)
  assert_that(file.exists(us_shp))
}

# Download elevation

elev_nc <- file.path(elev_prefix, 'metdata_elevationdata.nc')
if (!file.exists(elev_nc)) {
  loc <- "https://climate.northwestknowledge.net/METDATA/data/metdata_elevationdata.nc"
  dest <- paste0(elev_prefix, "/metdata_elevationdata.nc")
  download.file(loc, dest)
  assert_that(file.exists(elev_nc))
}

#Download the NEON sites

site_shp <- file.path(site_prefix, "NEON_Field_Sites.shp")
if (!file.exists(site_shp)) {
  loc <- "http://www.neonscience.org/sites/default/files/NEONFieldSites-v15web.zip"
  dest <- paste0(site_prefix, ".zip")
  download.file(loc, dest)
  unzip(dest, exdir = site_prefix)
  unlink(dest)
  assert_that(file.exists(site_shp))
}


#Download the NEON domains

domain_shp <- file.path(domain_prefix, "NEON_Domains.shp")
if (!file.exists(domain_shp)) {
  loc <- "http://www.neonscience.org/sites/default/files/NEONDomains_0.zip"
  dest <- paste0(prefix, ".zip")
  download.file(loc, dest)
  unzip(dest, exdir = domain_prefix)
  unlink(dest)
  assert_that(file.exists(domain_shp))
}

#Download US forest groups

forest_img <- file.path(forest_prefix, "conus_forestgroup.img")
if (!file.exists(forest_img)) {
  loc <- "https://data.fs.usda.gov/geodata/rastergateway/forest_type/conus_forestgroup.zip"
  dest <- paste0(prefix, ".zip")
  download.file(loc, dest)
  unzip(dest, exdir = forest_prefix)
  unlink(dest)
  assert_that(file.exists(forest_img))
}

#Download the MTBS fire polygons

mtbs_shp <- file.path(mtbs_prefix, 'mtbs_perims_1984-2015_DD_20170815.shp')
if (!file.exists(mtbs_shp)) {
  loc <- "https://edcintl.cr.usgs.gov/downloads/sciweb1/shared/MTBS_Fire/data/composite_data/burned_area_extent_shapefile/mtbs_perimeter_data.zip"
  dest <- paste0(raw_prefix, ".zip")
  download.file(loc, dest)
  unzip(dest, exdir = mtbs_prefix)
  unlink(dest)
  assert_that(file.exists(mtbs_shp))
}


# This section will download all of the ads data for regions 1-6 from 1978-2016 (regioanlly variable)
# Becuase these files are a COMPLETE MESS(!) after download I was forced to go into ArcGIS and clean the files.
# This allowed for efficient import. Not ideal, but for now it works.

if(!dir.exists(file.path(r1_dir, "cleaned"))){
  for(i in seq_along(r1_https)){
    dest <- paste0(ads, ".zip")
    download.file(r1_https[[i]], dest)
    unzip(dest, exdir = r1_dir)
    unlink(dest)
  }
}

if(!dir.exists(file.path(r2_dir, "cleaned"))){
  for(i in seq_along(r2_https)){
    dest <- paste0(ads, ".zip")
    download.file(r2_https[[i]], dest)
    unzip(dest, exdir = r2_dir)
    unlink(dest)
  }
}

if(!dir.exists(file.path(r3_dir, "cleaned"))){
  for(i in seq_along(r3_https)){
    dest <- paste0(ads, ".zip")
    download.file(r3_https[[i]], dest)
    unzip(dest, exdir = r3_dir)
    unlink(dest)
  }
}

if(!dir.exists(file.path(r4_dir, "cleaned"))){
  for(i in seq_along(r4_https)){
    dest <- paste0(ads, ".zip")
    download.file(r4_https[[i]], dest)
    unzip(dest, exdir = r4_dir)
    unlink(dest)
  }
}

if(!dir.exists(file.path(r5_dir, "cleaned"))){
  for(i in seq_along(r5_https)){
    dest <- paste0(ads, ".zip")
    download.file(r5_https[[i]], dest)
    unzip(dest, exdir = r5_dir)
    unlink(dest)
  }
}

if(!dir.exists(file.path(r6_dir, "cleaned"))){
  for(i in seq_along(r6_https)){
    dest <- paste0(ads, ".zip")
    download.file(r6_https[[i]], dest)
    unzip(dest, exdir = r6_dir)
    unlink(dest)
  }
}

