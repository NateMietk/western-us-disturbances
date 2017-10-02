
source("src/R/get_data.R")

p4string_ea <- "+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +a=6370997 +b=6370997 +units=m +no_defs"   #http://spatialreference.org/ref/sr-org/6903/

# Import the US States and project to albers equal area
states <- st_read(dsn = us_prefix,
                  layer = "cb_2016_us_state_20m", quiet= TRUE) %>%
  st_transform(p4string_ea) %>%
  filter(STUSPS %in% c("CO", "WA", "OR", "NV", "CA", "ID", "UT",
                       "WY", "NM", "AZ"))%>%
  st_simplify(., preserveTopology = TRUE) %>%
    mutate(id = row_number())

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

# Import and process MTBS data and project to albers equal area
mtbs_fire <- st_read(dsn = mtbs_prefix,
                     layer = "mtbs_perims_1984-2015_DD_20170815", quiet= TRUE) %>%
  st_transform(p4string_ea) %>%
  st_intersection(., st_union(neon_domains)) %>%
  mutate(id = row_number())

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

reg_raw <- list(file.path(r1_dir, "cleaned"), file.path(r2_dir, "cleaned"), file.path(r3_dir, "cleaned"), 
                 file.path(r4_dir, "cleaned"), file.path(r5_dir, "cleaned"), file.path(r6_dir, "cleaned"))

reg_shp <- lapply(unlist(lapply(reg_raw, function(dir) list.files(path = dir, pattern = "*.shp$", full.names = TRUE))),
       function(x) 
         st_read(dsn = x, layer = basename(file_path_sans_ext(x))))

sfInit(parallel = TRUE, cpus = ncor)
sfExport(list = c("ncor", "neon_domains", "reg_shp", "elevation"))
mpb <- sfLapply(1:ncor, dagent_select, y = reg_shp, lvl = c("11006", "6B", "6J", "6K", "6L", "6P", "6S", "6W"))
wsb <- sfLapply(1:ncor, dagent_select, y = reg_shp, lvl = c("BS", "12040"))
sb <- sfLapply(1:ncor, dagent_select, y = reg_shp, lvl = c("3", "11009"))
sfStop()

mpb_combine <- do.call(rbind, mpb) 

sfInit(parallel = TRUE, cpus = ncor)
sfExport(list = c("ncor", "neon_domains", "mpb_combine", "elevation"))
mpb_rst <- sfLapply(1:ncor, rst_create, y = mpb_combine, j = elevation, lvl = "dca1") 
sfStop()

mpb_rst <- do.call(merge, mpb_rst)









