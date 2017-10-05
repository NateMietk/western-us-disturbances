
source("src/R/get_data.R")
source("src/R/ads_clean_functions.R")

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
         group = 1)%>%
  group_by(group) %>%
  summarise()

# Import and merge ads data for MPB, SBW, SB
# Notes on damage causal agenets (DCA):
# 12040 -> western spruce budworm (Choristoneura occidentalis)
# 11006 -> mountain pine beetle (Dendroctonus ponderosae)
# 11009 -> spruce beetle (Dendroctonus rufipennis)

# Of course, region 6 has a different coding scheme for damage agents...
# Notes on damage causal agenets (AGENT1):
# BS -> western spruce budworm (Choristoneura occidentalis)
# 6B, 6J, 6K, 6L, 6P, 6S, 6W -> mountain pine beetle (Dendroctonus ponderosae)
# 3 -> spruce beetle (Dendroctonus rufipennis)

# These data natively are a COMPLETE mess. The packages in R could not adequately repair
# all of the geometry errors and null values (i.e., rdgal, sf, rgeos).  After unpacking the *.e00
# files I also had to run batch repair geometry on all shapfiles for all years in all regions.
# Almost all had errors that were reconciled. Those unpacked and repaired files reside in the cleaned folders.

shp_1 <- lapply(unlist(lapply(file.path(r1_dir, "cleaned"),
                              function(dir) list.files(path = dir, pattern = "*.shp$", full.names = TRUE))),
                function(x)
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  filter(dca1 %in% c("11006","12040","11009")) %>%
                  st_transform(p4string_ea) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  mutate(group = 1,
                         year = if (exists('rpt_yr', where=.)) rpt_yr
                         else basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  select(dca1, group, year, geometry))
# This will combine all years for a given region into one shapefile
shp_combine_1 <- do.call(rbind, shp_1) %>%
  mutate(year = as.factor(ifelse(year == "r1_ads2005_polygon", "2005", 
                                 ifelse(year == "r1_ads2010_polygon", "2010",year)))) 

mpb_combine_1 <- shp_combine_1 %>%
  filter(dca1 %in% c("11006"))

sb_combine_1 <- shp_combine_1 %>%
  filter(dca1 %in% c("11009"))

wsb_combine_1 <- shp_combine_1 %>%
  filter(dca1 %in% c("12040"))

if (!file.exists(file.path(ads_out, "mpb", "r1_mpb.gpkg"))) {
  st_write(mpb_combine_1, file.path(ads_out, "mpb", "r1_mpb.gpkg"),
           driver = "GPKG",
           update=TRUE)}
if (!file.exists(file.path(ads_out, "sb", "r1_sb.gpkg"))) {
  st_write(sb_combine_1, file.path(ads_out, "sb", "r1_sb.gpkg"),
           driver = "GPKG",
           update=TRUE)}
if (!file.exists(file.path(ads_out, "wsb", "r1_wsb.gpkg"))) {
  st_write(wsb_combine_1, file.path(ads_out, "wsb", "r1_wsb.gpkg"),
           driver = "GPKG",
           update=TRUE)}

shp_2 <- lapply(unlist(lapply(file.path(r2_dir, "cleaned"),
                              function(dir) list.files(path = dir, pattern = "*.shp$", full.names = TRUE))),
                function(x)
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  filter(dca1 %in% c("11006","12040","11009")) %>%
                  st_transform(p4string_ea) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  mutate(group = 1,
                         year = if (exists('rpt_yr', where=.)) rpt_yr
                         else if(exists('survey_yr', where = .)) survey_yr
                         else basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  select(dca1, group, year, geometry))

shp_combine_2 <- do.call(rbind, shp_2) %>%
  mutate(year = as.factor(region2_year(year)))

mpb_combine_2 <- shp_combine_2 %>%
  filter(dca1 %in% c("11006"))
sb_combine_2 <- shp_combine_2 %>%
  filter(dca1 %in% c("11009"))
wsb_combine_2 <- shp_combine_2 %>%
  filter(dca1 %in% c("12040"))

if (!file.exists(file.path(ads_out, "mpb", "r2_mpb.gpkg"))) {
  st_write(mpb_combine_2, file.path(ads_out, "mpb", "r2_mpb.gpkg"),
           driver = "GPKG",
           update=TRUE)}
if (!file.exists(file.path(ads_out, "sb", "r2_sb.gpkg"))) {
  st_write(sb_combine_2, file.path(ads_out, "sb", "r2_sb.gpkg"),
           driver = "GPKG",
           update=TRUE)}
if (!file.exists(file.path(ads_out, "wsb", "r2_wsb.gpkg"))) {
  st_write(wsb_combine_2, file.path(ads_out, "wsb", "r2_wsb.gpkg"),
           driver = "GPKG",
           update=TRUE)}

shp_3 <- lapply(unlist(lapply(file.path(r3_dir, "cleaned"),
                              function(dir) list.files(path = dir, pattern = "*.shp$", full.names = TRUE))),
                function(x)
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  mutate(dca1 = if (exists('dca', where=.)) dca
                         else dca1) %>%
                  filter(dca1 %in% c("11006","12040","11009")) %>%
                  st_transform(p4string_ea) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  mutate(group = 1,
                         year = if(exists('survey_yea', where = .)) survey_yea
                         else basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  select(dca1, group, year, geometry))
shp_combine_3 <- do.call(rbind, shp_3) 

mpb_combine_3 <- shp_combine_3 %>%
  filter(dca1 %in% c("11006"))
sb_combine_3 <- shp_combine_3 %>%
  filter(dca1 %in% c("11009"))
wsb_combine_3 <- shp_combine_3 %>%
  filter(dca1 %in% c("12040"))

if (!file.exists(file.path(ads_out, "mpb", "r3_mpb.gpkg"))) {
  st_write(mpb_combine_3, file.path(ads_out, "mpb", "r3_mpb.gpkg"),
           driver = "GPKG",
           update=TRUE)}
if (!file.exists(file.path(ads_out, "sb", "r3_sb.gpkg"))) {
  st_write(sb_combine_3, file.path(ads_out, "sb", "r3_sb.gpkg"),
           driver = "GPKG",
           update=TRUE)}
if (!file.exists(file.path(ads_out, "wsb", "r3_wsb.gpkg"))) {
  st_write(wsb_combine_3, file.path(ads_out, "wsb", "r3_wsb.gpkg"),
           driver = "GPKG",
           update=TRUE)}

shp_4 <- lapply(unlist(lapply(file.path(r4_dir, "cleaned"),
                              function(dir) list.files(path = dir, pattern = "*.shp$", full.names = TRUE))),
                function(x)
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  filter(dca1 %in% c("11006","12040","11009")) %>%
                  st_transform(p4string_ea) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  mutate(group = 1,
                         year = if (exists('rpt_yr', where=.)) rpt_yr
                         else basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  select(dca1, group, year, geometry))
shp_combine_4 <- do.call(rbind, shp_4) %>%
  mutate(year = as.factor(ifelse(year == "r4_ads1998d0_polygon", 1998,
                                 ifelse(year == "r4_ads1999d0_polygon", 1999,
                                        ifelse(year == "0", 2010, year)))))

mpb_combine_4 <- shp_combine_4 %>%
  filter(dca1 %in% c("11006"))
sb_combine_4 <- shp_combine_4 %>%
  filter(dca1 %in% c("11009"))
wsb_combine_4 <- shp_combine_4 %>%
  filter(dca1 %in% c("12040"))

if (!file.exists(file.path(ads_out, "mpb", "r4_mpb.gpkg"))) {
  st_write(mpb_combine_4, file.path(ads_out, "mpb", "r4_mpb.gpkg"),
           driver = "GPKG",
           update=TRUE)}
if (!file.exists(file.path(ads_out, "sb", "r4_sb.gpkg"))) {
  st_write(sb_combine_4, file.path(ads_out, "sb", "r4_sb.gpkg"),
           driver = "GPKG",
           update=TRUE)}
if (!file.exists(file.path(ads_out, "wsb", "r4_wsb.gpkg"))) {
  st_write(wsb_combine_4, file.path(ads_out, "wsb", "r4_wsb.gpkg"),
           driver = "GPKG",
           update=TRUE)}

shp_5 <- lapply(unlist(lapply(file.path(r5_dir, "cleaned"),
                              function(dir) list.files(path = dir, pattern = "*.shp$", full.names = TRUE))),
                function(x)
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  filter(dca1 %in% c("11006","12040","11009")) %>%
                  st_transform(p4string_ea) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  mutate(group = 1,
                         year = if (exists('rpt_yr', where=.)) rpt_yr
                         else basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  select(dca1, group, year, geometry))
shp_combine_5 <- do.call(rbind, shp_5)

mpb_combine_5 <- shp_combine_5 %>%
  filter(dca1 %in% c("11006"))
sb_combine_5 <- shp_combine_5 %>%
  filter(dca1 %in% c("11009"))

if (!file.exists(file.path(ads_out, "mpb", "r5_mpb.gpkg"))) {
  st_write(mpb_combine_5, file.path(ads_out, "mpb", "r5_mpb.gpkg"),
           driver = "GPKG",
           update=TRUE)}
if (!file.exists(file.path(ads_out, "sb", "r5_sb.gpkg"))) {
  st_write(sb_combine_5, file.path(ads_out, "sb", "r5_sb.gpkg"),
           driver = "GPKG",
           update=TRUE)}

shp_6 <- lapply(unlist(lapply(file.path(r6_dir, "cleaned"),
                              function(dir) list.files(path = dir, pattern = ".shp$", full.names = TRUE))),
                function(x)
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  mutate(dca1 = agent1) %>%
                  filter(dca1 %in% c("BS","3","6B", "6K", "6L", "6P", "6S", "6W")) %>%
                  mutate(dca1 = ifelse(dca1 %in% c("6B", "6K", "6L", "6P", "6S", "6W"), "11006", 
                                       ifelse(dca1 %in% c("3"), "11009", "12040"))) %>%
                  st_transform(p4string_ea) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  mutate(group = 1,
                         year = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  select(dca1, group, year, geometry))
shp_combine_6 <- do.call(rbind, shp_6) %>%
  mutate(year = as.factor(region6_year(year)),
         dca1 = as.numeric(dca1))

mpb_combine_6 <- shp_combine_6 %>%
  filter(dca1 %in% c("11006")) 
sb_combine_6 <- shp_combine_6 %>%
  filter(dca1 %in% c("11009")) 
wsb_combine_6 <- shp_combine_6 %>%
  filter(dca1 %in% c("12040")) 

if (!file.exists(file.path(ads_out, "mpb", "r6_mpb.gpkg"))) {
  st_write(mpb_combine_6, file.path(ads_out, "mpb", "r6_mpb.gpkg"),
           driver = "GPKG",
           update=TRUE)}
if (!file.exists(file.path(ads_out, "sb", "r6_sb.gpkg"))) {
  st_write(sb_combine_6, file.path(ads_out, "sb", "r6_sb.gpkg"),
           driver = "GPKG",
           update=TRUE)}
if (!file.exists(file.path(ads_out, "wsb", "r6_wsb.gpkg"))) {
  st_write(wsb_combine_6, file.path(ads_out, "wsb", "r6_wsb.gpkg"),
           driver = "GPKG",
           update=TRUE)}

# mpb_combine_1 <- st_read(dsn = file.path(ads_out, "mpb", "r1_mpb.gpkg"))
# mpb_combine_2 <- st_read(dsn = file.path(ads_out, "mpb", "r2_mpb.gpkg"))
# mpb_combine_3 <- st_read(dsn = file.path(ads_out, "mpb", "r3_mpb.gpkg"))
# mpb_combine_4 <- st_read(dsn = file.path(ads_out, "mpb", "r4_mpb.gpkg"))
# mpb_combine_5 <- st_read(dsn = file.path(ads_out, "mpb", "r5_mpb.gpkg"))
# mpb_combine_6 <- st_read(dsn = file.path(ads_out, "mpb", "r6_mpb.gpkg"))

# mpb polygons
mpb_wus_list <- list(mpb_combine_1, mpb_combine_2, mpb_combine_3,
                     mpb_combine_4, mpb_combine_5, mpb_combine_6)
mpb_wus <- do.call(rbind, mpb_wus_list)
if (!file.exists(file.path(ads_out, "mpb", "mpb_wus.gpkg"))) {
  st_write(mpb_wus, file.path(ads_out, "mpb", "mpb_wus.gpkg"),
           driver = "GPKG",
           update=TRUE)}

# sb_combine_1 <- st_read(dsn = file.path(ads_out, "sb", "r1_sb.gpkg"))
# sb_combine_2 <- st_read(dsn = file.path(ads_out, "sb", "r2_sb.gpkg"))
# sb_combine_3 <- st_read(dsn = file.path(ads_out, "sb", "r3_sb.gpkg"))
# sb_combine_4 <- st_read(dsn = file.path(ads_out, "sb", "r4_sb.gpkg"))
# sb_combine_5 <- st_read(dsn = file.path(ads_out, "sb", "r5_sb.gpkg"))
# sb_combine_6 <- st_read(dsn = file.path(ads_out, "sb", "r6_sb.gpkg"))

# sb polygons
sb_wus_list <- list(sb_combine_1, sb_combine_2, sb_combine_3,
                    sb_combine_4, sb_combine_5, sb_combine_6)
sb_wus <- do.call(rbind, sb_wus_list)
if (!file.exists(file.path(ads_out, "sb", "sb_wus.gpkg"))) {
  st_write(sb_wus, file.path(ads_out, "sb", "sb_wus.gpkg"),
           driver = "GPKG",
           update=TRUE)}

# wsb_combine_1 <- st_read(dsn = file.path(ads_out, "wsb", "r1_wsb.gpkg"))
# wsb_combine_2 <- st_read(dsn = file.path(ads_out, "wsb", "r2_wsb.gpkg"))
# wsb_combine_3 <- st_read(dsn = file.path(ads_out, "wsb", "r3_wsb.gpkg"))
# wsb_combine_4 <- st_read(dsn = file.path(ads_out, "wsb", "r4_wsb.gpkg"))
# wsb_combine_6 <- st_read(dsn = file.path(ads_out, "wsb", "r6_wsb.gpkg"))

# wsb polygons
wsb_wus_list <- list(wsb_combine_1, wsb_combine_2, wsb_combine_3,
                     wsb_combine_4, wsb_combine_6)
wsb_wus <- do.call(rbind, wsb_wus_list)
if (!file.exists(file.path(ads_out, "wsb", "wsb_wus.gpkg"))) {
  st_write(wsb_wus, file.path(ads_out, "wsb", "wsb_wus.gpkg"),
           driver = "GPKG",
           update=TRUE)}

# Create western US raster compsite of bark beetle and budworm at 500m res

elevation <- raster(file.path(raw_prefix, "metdata_elevationdata", "metdata_elevationdata.nc")) %>%
  projectRaster(crs = p4string_ea, res = 500) %>%
  crop(as(neon_domains, "Spatial")) %>%
  mask(as(neon_domains, "Spatial"))
elevation <- calc(elevation, fun = function(x){x[x < 0] <- NA; return(x)})

if (!file.exists(file.path(ads_out, "mpb", "mpb_wus.tif"))) {
  mpb_wus_rst <- rasterize(as(mpb_wus, "Spatial"), elevation, "group")
  writeRaster(mpb_wus_rst, filename = file.path(ads_out, "mpb", "mpb_wus.tif"),
              format = "GTiff")}

if (!file.exists(file.path(ads_out, "sb", "sb_wus.tif"))) {
  sb_wus_rst <- rasterize(as(sb_wus, "Spatial"), elevation, "group")
  writeRaster(sb_wus_rst, filename = file.path(ads_out, "sb", "sb_wus.tif"),
              format = "GTiff", overwrite=TRUE)}

if (!file.exists(file.path(ads_out, "wsb", "wsb_wus.tif"))) {
  wsb_wus_rst <- rasterize(as(wsb_wus, "Spatial"), elevation, "group")
  writeRaster(wsb_wus_rst, filename = file.path(ads_out, "wsb", "wsb_wus.tif"),
              format = "GTiff", overwrite=TRUE)}

# Create combine bb disturbance layer
all_wus_list <- list(mpb_wus, sb_wus, wsb_wus)
all_wus <- do.call(rbind, all_wus_list) 
if (!file.exists(file.path(ads_out, "combine", "all_wus.gpkg"))) {
  st_write(all_wus, file.path(ads_out, "combine", "all_wus.gpkg"),
           driver = "GPKG",
           update=TRUE)}

if (!file.exists(file.path(ads_out, "combine", "all_wus.tif"))) {
  all_wus_rst <- rasterize(as(all_wus, "Spatial"), elevation, "dca1")
  writeRaster(all_wus_rst, filename = file.path(ads_out, "combine", "all_wus.tif"),
              format = "GTiff", overwrite=TRUE)}



