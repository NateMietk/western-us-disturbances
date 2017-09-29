
x <- c("raster", "tidyverse", "sf", "assertthat", "purrr", "httr", "rvest")
lapply(x, library, character.only = TRUE, verbose = FALSE)

prefix <- file.path("data")
raw_prefix <- file.path(prefix, "raw")
us_prefix <- file.path(raw_prefix, "cb_2016_us_state_20m")
domain_prefix <- file.path(raw_prefix, "NEONDomains_0")
site_prefix <- file.path(raw_prefix, "neon_site")
forest_prefix <- file.path(raw_prefix, "conus_forestgroup")
mtbs_prefix <- file.path(raw_prefix, "mtbs_perimeter_data")

# Check if directory exists for all variable aggregate outputs, if not then create
var_dir <- list(prefix, raw_prefix, us_prefix, domain_prefix, site_prefix, forest_prefix, mtbs_prefix)

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
  unzip(dest, exdir = raw_prefix)
  unlink(dest)
  assert_that(file.exists(mtbs_shp))
}

ads_shp <- 
  
  fpa_gdb <- file.path(fpa_prefix, "Data", "FPA_FOD_20170508.gdb")
if (!file.exists(fpa_gdb)) {
  pg <- read_html("https://www.fs.usda.gov/detail/r1/forest-grasslandhealth/?cid=stelprdb5366459")
  fils <- html_nodes(pg, xpath=".//dd[@class='product']//li/a[contains(., 'zip') and contains(., 'GDB')]") 
  dest <- paste0(fpa_prefix, ".zip")
  walk2(html_attr(fils, 'href'),  html_text(fils), 
        ~GET(sprintf("https:%s", .x), write_disk(dest), progress()))
  unzip(dest, exdir = fpa_prefix)
  unlink(dest)
  assert_that(file.exists(fpa_gdb))
}

# Region 1 ADS data from 2000-2016
# https://www.fs.usda.gov/detail/r1/forest-grasslandhealth/?cid=stelprdb5366459

r1 <- list(c("https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fseprd532758.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fseprd492807.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprd3826344.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5447839.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5409124.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5353135.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5260291.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015394.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015889.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015395.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015157.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015818.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015819.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_014991.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_014709.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015820.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015158.zip"))

# Region 2 ADS data from 1994-2016
# https://www.fs.usda.gov/detail/r2/forest-grasslandhealth/?cid=fsbdev3_041629

r2 <- list(c("https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fseprd533949.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fseprd490660.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprd3829398.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5447183.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5409983.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5349026.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5247576.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183456.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183454.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183448.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183445.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183443.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183437.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183433.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183428.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183422.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183421.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183420.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183415.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183412.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183409.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183378.zip", 
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183376.zip" 
))

# Region 3 ADS data from 1997-2015
# https://www.fs.usda.gov/detail/r3/landmanagement/gis/?cid=stelprd3805189
r3 <- list(c("https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5183421.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2014.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2013.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2012.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2011.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2010.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2009.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2008.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2007.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2007.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2005.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2004.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2003.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2003.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2003.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth2000.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth1999.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth1998.zip",
             "http://www.fs.fed.us/r3/gis/forest_health/ForestHealth1997.zip"))

# Region 4 ADS data from 1991-2016
# https://www.fs.usda.gov/detail/r1/forest-grasslandhealth/?cid=stelprdb5366459


r4 <- list(c("https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015158.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fseprd492804.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprd3826350.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5447837.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5447837.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5353145.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5353145.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015214.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_014771.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015215.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015888.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015888.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015565.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_014989.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_014772.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_014990.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015216.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5260307.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5260308.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5260309.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5260310.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_014773.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_014773.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015218.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_015393.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev3_014921.zip"))

# Region 5 ADS data from 1978-2016
# https://www.fs.usda.gov/detail/r5/forest-grasslandhealth/?cid=fsbdev3_046696

r5 <- list(c("https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fseprd525351.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fseprd525351.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprd3824053.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5441833.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5405114.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5362557.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5327958.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprd3856629.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprd3856628.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprd3856627.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprd3856626.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprd3856625.zip",
             "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprd3856634.zip"
             ))

# Region 6 ADS data from 1980-2016
# https://www.fs.usda.gov/detail/r6/forest-grasslandhealth/insects-diseases/?cid=stelprd3791643
# To find the zip file locations you need to inspect the drop down element and append the base url

r6 <- list(c( "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fseprd532327.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fseprd485517.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprd3822558.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5448081.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5401227.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5341945.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/stelprdb5328431.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026247.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026061.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_025955.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_025764.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026136.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026010.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026009.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026209.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026008.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026306.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026208.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026207.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026304.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_025913.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_025823.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026303.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026206.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_025717.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_025842.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026135.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_025734.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026440.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026327.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026132.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_025841.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_025840.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026034.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026325.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026226.zip",
              "https://www.fs.usda.gov/Internet/FSE_DOCUMENTS/fsbdev2_026131.zip"))














