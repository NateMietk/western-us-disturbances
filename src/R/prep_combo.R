# Prep the data
source("src/R/prep_pdsi.R")
source("src/R/prep_ads.R")
source("src/R/prep_mtbs.R")

# Prep for the plots

# Threshold the pdsi image so only areas that experienced more than ten years 
# of drought are present. 
pdsi_m10yr <- pdsi_rcl
pdsi_m10yr[pdsi_m10yr >= 4] <- NA
pdsi_df <- as.data.frame(as(pdsi_rcl, "SpatialPixelsDataFrame")) %>%
  mutate(pdsi_class = layer)



sb <- raster("data/raw/ads/sb_wus.tif")
ysb <- c(11009, 11009, 2)
rclsb <- matrix(ysb, ncol=3, byrow=TRUE)
sb_rcl <- reclassify(sb, rclsb)
sb_rcl[sb_rcl != 1] <- 0

mpb <- raster("data/raw/ads/mpb_wus.tif")
ympb <- c(11006, 11006, 3)
rclmpb <- matrix(ympb, ncol=3, byrow=TRUE)
mpb_rcl <- reclassify(mpb, rclmpb)
mpb_rcl[mpb_rcl != 1] <- 0

forst_sb_mpb <- merge(forests, sb, mpb)

combo  <- brick(pdsi_rcl, mpb, sb, mtbs_rst)


mpb_df <- as.data.frame(as(mpb, "SpatialPixelsDataFrame")) %>%
  mutate(mpb = 1)
sb_df <- as.data.frame(as(sb, "SpatialPixelsDataFrame")) %>%
  mutate(sb = 2)

mtbs_df <- as.data.frame(as(mtbs_rst, "SpatialPixelsDataFrame")) %>%
  mutate(fire_only = ifelse(layer == 0, 0, 1))



years_vec = 1984:2014

rcl_ht = matrix(c(0.1, 99, 10, -999, 0, 0), nrow = 2, ncol=3, byrow=T)
ht_rc = raster::reclassify(high_temps, rcl_ht)

rcl_fire = matrix(c(0.1, 999, 100, -999, 0, 0), nrow = 2, ncol=3, byrow=T)
fire_rc = raster::reclassify(fire_events, rcl_fire)

# drought_events1 is already 0s and 1s

interaction_stack = list()
for(i in 1:31){
  interaction_stack[[i]] = drought_events1[[i]] + ht_rc[[i]] + fire_rc[[i]]
}

int_st = raster::stack(interaction_stack)

freqs = freq(int_st)

rc_kv = matrix(c(0,10.1,0, 99,100.1,0), nrow = 2, ncol=3, byrow=T) #keeping values

rc_ci = matrix(c(0,10.1,0, 99,100.1,0, 10.5,11.1,2, 100.5,101.5,2, 109,110.5,2, 110.5,111.5, 3), nrow = 6, ncol=3, byrow=T) # counting interactions

int_st_kv = raster::reclassify(int_st, rc_kv)
int_st_ci = raster::reclassify(int_st, rc_ci)

int_st_ci_map = raster::calc(int_st_ci, max)
int_st_kv_map = raster::calc(int_st_kv, max)
int_st_kv_map = raster::asFactor(int_st_kv_map)

#plot(int_st_ci_map)
#plot(int_st_kv_map)

kv_levs = levels(int_st_kv_map)[[1]]
kv_levs$interactions = c('None', 'Drought & Heat', 'Drought & Fire', 'Heat & Fire', 'Drought, Heat & Fire')
colnames(kv_levs) = c("ID", "interactions")
levels(int_st_kv_map) = kv_levs

iskm = deratify(int_st_kv_map, 'interactions')



