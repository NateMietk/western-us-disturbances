
dagent_select <- function(y, x, lvl) {
  require(snowfall)
  require(raster)
  require(sf)
  require(tidyverse)
  # y = input shapefile
  # x = number of splits to iterate on in parallel
  # lvl = the shapefile attribute to rasterize
  # j = the larger underlying raster (4k)
  # k = the smaller underlying raster (200m)
  
  p4string_ea <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"
  
  out_shp <- y %>%
    st_cast("MULTIPOLYGON") %>%
    setNames(tolower(names(.))) %>%
    mutate(dca1 = ifelse(file_path_sans_ext(x) %in% "r6", agent1,
                         ifelse(file_path_sans_ext(x) %in% "r3", dca, dca1))) %>%
    filter(dca1 %in% lvl) %>%
    st_simplify(., preserveTopology = TRUE, dTolerance = 1) %>%
    st_transform(p4string_ea) %>%
    st_buffer(., 0) %>%
    st_intersection(., st_union(neon_domains)) %>%
    group_by(dca1) %>%
    summarise() %>%
    mutate(group = 1)
}

rst_create <- function(y, x, j, lvl) {
  ncor <- parallel::detectCores()
  require(snowfall)
  require(raster)
  require(sf)
  require(tidyverse)
  features <- 1:nrow(y[,])
  parts <- split(features, cut(features, ncor))
  outrst <- rasterize(as(y[parts[[x]],], "Spatial"), j, lvl)
}