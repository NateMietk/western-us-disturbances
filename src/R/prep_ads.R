
source("src/R/get_data.R")

p4string_ea <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"   #http://spatialreference.org/ref/sr-org/6903/

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

elevation <- raster(file.path(raw_prefix, "metdata_elevationdata", "metdata_elevationdata.nc")) %>%
  projectRaster(crs = p4string_ea, res = 500) %>%
  crop(as(neon_domains, "Spatial")) %>%
  mask(as(neon_domains, "Spatial"))
elevation <- calc(elevation, fun = function(x){x[x < 0] <- NA; return(x)})

# Import and merge ads data for MPB, SBW, SB
# List all feature classes in a file geodatabase

# Notes on damage causal agenets (DCA):
# 12040 -> western spruce budworm (Choristoneura occidentalis)
# 11006 -> mountain pine beetle (Dendroctonus ponderosae)
# 11009 -> spruce beetle (Dendroctonus rufipennis)

# Of course, region 6 has a different coding scheme for damage agents...
# Notes on damage causal agenets (AGENT1):
# BS -> western spruce budworm (Choristoneura occidentalis)
# 6B, 6J, 6K, 6L, 6P, 6S, 6W -> mountain pine beetle (Dendroctonus ponderosae)
# 3 -> spruce beetle (Dendroctonus rufipennis)

ncor <- parallel::detectCores()

source("src/R/ads_clean_functions.R")

reg_1245 <- list(file.path(r1_dir, "cleaned"), file.path(r2_dir, "cleaned"),
                 file.path(r4_dir, "cleaned"), file.path(r5_dir, "cleaned"))
  
shp_1 <- lapply(unlist(lapply(file.path(r1_dir, "cleaned"), 
                              function(dir) list.files(path = dir, pattern = "*.shp$", full.names = TRUE))),
                function(x) 
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x)))%>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  filter(dca1 %in% c("11006","12040","11009")) %>%
                  st_simplify(., preserveTopology = TRUE, dTolerance = 0.1) %>%
                  st_transform(p4string_ea) %>%
                  st_buffer(., 0) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  group_by(dca1) %>%
                  summarise() %>%
                  mutate(group = 1))
shp_combine_1 <- do.call(rbind, shp_1) 

mpb_combine_1 <- shp_combine_1 %>%
  filter(dca1 %in% c("11006")) %>%
  group_by(group) %>%
  summarise()
mpb_rst_1 <- rasterize(as(mpb_combine_1, "Spatial"), elevation, "group")
writeRaster(mpb_rst_1, filename = file.path(ads_out, "mpb", "r1_mpb.tif"), format = "GTiff", overwrite=TRUE)

sb_combine_1 <- shp_combine_1 %>%
  filter(dca1 %in% c("11009")) %>%
  group_by(group) %>%
  summarise()
sb_rst_1 <- rasterize(as(sb_combine_1, "Spatial"), elevation, "group")
writeRaster(sb_rst_1, filename = file.path(ads_out, "sb", "r1_sb.tif"), format = "GTiff", overwrite=TRUE)

wsb_combine_1 <- shp_combine_1 %>%
  filter(dca1 %in% c("12040")) %>%
  group_by(group) %>%
  summarise()
wsb_rst_1 <- rasterize(as(wsb_combine_1, "Spatial"), elevation, "group")
writeRaster(wsb_rst_1, filename = file.path(ads_out, "wsb", "r1_wsb.tif"), format = "GTiff", overwrite=TRUE)

shp_2 <- lapply(unlist(lapply(file.path(r2_dir, "cleaned"),
                              function(dir) list.files(path = dir, pattern = "*.shp$", full.names = TRUE))),
                function(x) 
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  filter(dca1 %in% c("11006","12040","11009")) %>%
                  st_simplify(., preserveTopology = TRUE, dTolerance = 0.1) %>%
                  st_transform(p4string_ea) %>%
                  st_buffer(., 0) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  group_by(dca1) %>%
                  summarise() %>%
                  mutate(group = 1))
shp_combine_2 <- do.call(rbind, shp_2) 

mpb_combine_2 <- shp_combine_2 %>%
  filter(dca1 %in% c("11006")) %>%
  group_by(group) %>%
  summarise()
mpb_rst_2 <- rasterize(as(mpb_combine_2, "Spatial"), elevation, "group")
writeRaster(mpb_rst_2, filename = file.path(ads_out, "mpb", "r2_mpb.tif"), format = "GTiff", overwrite=TRUE)

sb_combine_2 <- shp_combine_2 %>%
  filter(dca1 %in% c("11009")) %>%
  group_by(group) %>%
  summarise()
sb_rst_2 <- rasterize(as(sb_combine_2, "Spatial"), elevation, "group")
writeRaster(sb_rst_2, filename = file.path(ads_out, "sb", "r2_sb.tif"), format = "GTiff", overwrite=TRUE)

wsb_combine_2 <- shp_combine_2 %>%
  filter(dca1 %in% c("12040")) %>%
  group_by(group) %>%
  summarise()
wsb_rst_2 <- rasterize(as(wsb_combine_2, "Spatial"), elevation, "group")
writeRaster(wsb_rst_2, filename = file.path(ads_out, "wsb", "r2_wsb.tif"), format = "GTiff", overwrite=TRUE)

shp_3 <- lapply(unlist(lapply(file.path(r3_dir, "cleaned"), 
                              function(dir) list.files(path = dir, pattern = "*.shp$", full.names = TRUE))),
                function(x) 
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  mutate(dca1 = dca) %>%
                  filter(dca1 %in% c("11006","12040","11009")) %>%
                  st_simplify(., preserveTopology = TRUE, dTolerance = 0.1) %>%
                  st_transform(p4string_ea) %>%
                  st_buffer(., 0) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  group_by(dca1) %>%
                  summarise() %>%
                  mutate(group = 1))
shp_combine_3 <- do.call(rbind, shp_3) 

mpb_combine_3 <- shp_combine_3 %>%
  filter(dca1 %in% c("11006")) %>%
  group_by(group) %>%
  summarise()
mpb_rst_3 <- rasterize(as(mpb_combine_3, "Spatial"), elevation, "group")
writeRaster(mpb_rst_3, filename = file.path(ads_out, "mpb", "r3_mpb.tif"), format = "GTiff", overwrite=TRUE)

sb_combine_3 <- shp_combine_3 %>%
  filter(dca1 %in% c("11009")) %>%
  group_by(group) %>%
  summarise()
sb_rst_3 <- rasterize(as(sb_combine_3, "Spatial"), elevation, "group")
writeRaster(sb_rst_3, filename = file.path(ads_out, "sb", "r3_sb.tif"), format = "GTiff", overwrite=TRUE)

wsb_combine_3 <- shp_combine_3 %>%
  filter(dca1 %in% c("12040")) %>%
  group_by(group) %>%
  summarise()
wsb_rst_3 <- rasterize(as(wsb_combine_3, "Spatial"), elevation, "group")
writeRaster(wsb_rst_3, filename = file.path(ads_out, "wsb", "r3_wsb.tif"), format = "GTiff", overwrite=TRUE)

shp_4 <- lapply(unlist(lapply(file.path(r4_dir, "cleaned"), 
                              function(dir) list.files(path = dir, pattern = "*.shp$", full.names = TRUE))),
                function(x) 
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  filter(dca1 %in% c("11006","12040","11009")) %>%
                  st_simplify(., preserveTopology = TRUE, dTolerance = 0.1) %>%
                  st_transform(p4string_ea) %>%
                  st_buffer(., 0) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  group_by(dca1) %>%
                  summarise() %>%
                  mutate(group = 1))
shp_combine_4 <- do.call(rbind, shp_4) 

mpb_combine_4 <- shp_combine_4 %>%
  filter(dca1 %in% c("11006")) %>%
  group_by(group) %>%
  summarise()
mpb_rst_4 <- rasterize(as(mpb_combine_4, "Spatial"), elevation, "group")
writeRaster(mpb_rst_4, filename = file.path(ads_out, "mpb", "r4_mpb.tif"), format = "GTiff", overwrite=TRUE)

sb_combine_4 <- shp_combine_4 %>%
  filter(dca1 %in% c("11009")) %>%
  group_by(group) %>%
  summarise()
sb_rst_4 <- rasterize(as(sb_combine_4, "Spatial"), elevation, "group")
writeRaster(sb_rst_4, filename = file.path(ads_out, "sb", "r4_sb.tif"), format = "GTiff", overwrite=TRUE)

wsb_combine_4 <- shp_combine_4 %>%
  filter(dca1 %in% c("12040")) %>%
  group_by(group) %>%
  summarise()
wsb_rst_4 <- rasterize(as(wsb_combine_4, "Spatial"), elevation, "group")
writeRaster(wsb_rst_4, filename = file.path(ads_out, "wsb", "r4_wsb.tif"), format = "GTiff", overwrite=TRUE)

shp_5 <- lapply(unlist(lapply(file.path(r5_dir, "cleaned"), 
                              function(dir) list.files(path = dir, pattern = "*.shp$", full.names = TRUE))),
                function(x) 
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  filter(dca1 %in% c("11006","12040","11009")) %>%
                  st_simplify(., preserveTopology = TRUE, dTolerance = 0.1) %>%
                  st_transform(p4string_ea) %>%
                  st_buffer(., 0) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  group_by(dca1) %>%
                  summarise() %>%
                  mutate(group = 1))
shp_combine_5 <- do.call(rbind, shp_5) 

mpb_combine_5 <- shp_combine_5 %>%
  filter(dca1 %in% c("11006")) %>%
  group_by(group) %>%
  summarise()
mpb_rst_5 <- rasterize(as(mpb_combine_5, "Spatial"), elevation, "group")
writeRaster(mpb_rst_5, filename = file.path(ads_out, "mpb", "r5_mpb.tif"), format = "GTiff", overwrite=TRUE)

sb_combine_5 <- shp_combine_5 %>%
  filter(dca1 %in% c("11009")) %>%
  group_by(group) %>%
  summarise()
sb_rst_5 <- rasterize(as(sb_combine_5, "Spatial"), elevation, "group")
writeRaster(sb_rst_5, filename = file.path(ads_out, "sb", "r5_sb.tif"), format = "GTiff", overwrite=TRUE)

shp_6 <- lapply(unlist(lapply(r6_dir, 
                              function(dir) list.files(path = dir, pattern = ".shp$", full.names = TRUE))),
                function(x) 
                  st_read(dsn = x, layer = basename(file_path_sans_ext(x))) %>%
                  st_cast("MULTIPOLYGON") %>%
                  setNames(tolower(names(.))) %>%
                  mutate(dca1 = agent1) %>%
                  filter(dca1 %in% c("BS","3","6B", "6J", "6K", "6L", "6P", "6S", "6W")) %>%
                  st_simplify(., preserveTopology = TRUE, dTolerance = 0.1) %>%
                  st_transform(p4string_ea) %>%
                  st_buffer(., 0) %>%
                  st_intersection(., st_union(neon_domains)) %>%
                  group_by(dca1) %>%
                  summarise() %>%
                  mutate(group = 1))
shp_combine_6 <- do.call(rbind, shp_6) 

mpb_combine_6 <- shp_combine_6 %>%
  filter(dca1 %in% c("6B", "6J", "6K", "6L", "6P", "6S", "6W")) %>%
  group_by(group) %>%
  summarise()
mpb_rst_6 <- rasterize(as(mpb_combine_6, "Spatial"), elevation, "group")
writeRaster(mpb_rst_6, filename = file.path(ads_out, "mpb", "r6_mpb.tif"), format = "GTiff", overwrite=TRUE)

sb_combine_6 <- shp_combine_6 %>%
  filter(dca1 %in% c("3")) %>%
  group_by(group) %>%
  summarise()
sb_rst_6 <- rasterize(as(sb_combine_6, "Spatial"), elevation, "group")
writeRaster(sb_rst_6, filename = file.path(ads_out, "sb", "r6_sb.tif"), format = "GTiff", overwrite=TRUE)

wsb_combine_6 <- shp_combine_6 %>%
  filter(dca1 %in% c("BS")) %>%
  group_by(group) %>%
  summarise()
wsb_rst_6 <- rasterize(as(wsb_combine_6, "Spatial"), elevation, "group")
writeRaster(wsb_rst_6, filename = file.path(ads_out, "wsb", "r6_wsb.tif"), format = "GTiff", overwrite=TRUE)

# mpb polygons
mpb_wus_list <- list(mpb_combine_1, mpb_combine_2, mpb_combine_3, mpb_combine_4, mpb_combine_5, mpb_combine_6)
mpb_wus <- do.call(rbind, mpb_wus_list)
if (!file.exists(file.path(ads_out, "mpb", "mpb_wus.gpkg"))) {
  st_write(mpb_wus, file.path(ads_out, "mpb", "mpb_wus.gpkg"), 
           driver = "GPKG",
           update=TRUE)}
         
# sb polygons
sb_wus_list <- list(sb_combine_1, sb_combine_2, sb_combine_3, sb_combine_4, sb_combine_5, sb_combine_6)
sb_wus <- do.call(rbind, sb_wus_list)
if (!file.exists(file.path(ads_out, "sb", "sb_wus.gpkg"))) {
  st_write(sb_wus, file.path(ads_out, "sb", "sb_wus.gpkg"), 
           driver = "GPKG",
           update=TRUE)}

# wsb polygons
wsb_wus_list <- list(wsb_combine_1, wsb_combine_2, wsb_combine_3, wsb_combine_4, wsb_combine_5, wsb_combine_6)
wsb_wus <- do.call(rbind, wsb_wus_list)
if (!file.exists(file.path(ads_out, "wsb", "wsb_wus.gpkg"))) {
  st_write(wsb_wus, file.path(ads_out, "wsb", "wsb_wus.gpkg"), 
           driver = "GPKG",
           update=TRUE)}

mpb_overall <- mpb_rst_1 + mpb_rst_2 + mpb_rst_3 + mpb_rst_4 + mpb_rst_5 + mpb_rst_6
writeRaster(mpb_overall, filename = "../data/out/mpb/mpb.tif", format = "GTiff", overwrite=TRUE)

sb_overall <- sb_rst_1 + sb_rst_2 + sb_rst_3 + sb_rst_4 + sb_rst_5 + sb_rst_6
writeRaster(sb_overall, filename = "../data/out/sb/sb.tif", format = "GTiff", overwrite=TRUE)

wsb_overall <- wsb_rst_1 + wsb_rst_2 + wsb_rst_3 + wsb_rst_4 + wsb_rst_5 + wsb_rst_6
writeRaster(wsb_overall, filename = "../data/out/wsb/wsb.tif", format = "GTiff", overwrite=TRUE)


