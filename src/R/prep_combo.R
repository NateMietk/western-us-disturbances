# Prep the data
# source("src/R/prep_pdsi.R")
# source("src/R/prep_ads.R")
# source("src/R/prep_mtbs.R")

# Prep for the plots

# Threshold the pdsi image so only areas that experienced more than ten years 
# of drought are present. 

# Reclass drought >10years to 0 and 1s
pdsi10_rc = matrix(c(-999, 3.5, 0, 3.5, 999, 1), nrow = 2, ncol=3, byrow=T)
pdsi10_rc = raster::reclassify(pdsi_rcl, pdsi10_rc, background = 0)

rcl_bb = matrix(c(-999, 0, 0, 0, 99, 10), nrow = 2, ncol=3, byrow=T)
bb_rc = raster::reclassify(bb_all_4k, rcl_bb, background = 0)

rcl_fire = matrix(c(-999, 0, 0, 0, 999, 100), nrow = 2, ncol=3, byrow=T)
fire_rc = raster::reclassify(mtbs_rst_4k, rcl_fire, background = 0)

int_st = fire_rc + bb_rc +pdsi_rc 
freqs = freq(int_st)

rc_kv = matrix(c(0,10.1,0, 99,100.1,0), nrow = 2, ncol=3, byrow=T) #keeping values
rc_ci = matrix(c(0, 10.1, 0, 
                 99, 100.1, 0, 
                 10.5, 11.1, 2, 
                 100.5, 101.5, 2, 
                 109, 110.5, 2, 
                 110.5, 111.5, 3), 
               nrow = 6, ncol=3, byrow=T) # counting interactions

int_st_kv = raster::reclassify(int_st, rc_kv)
int_st_ci = raster::reclassify(int_st, rc_ci)

int_st_ci_map = raster::calc(int_st_ci, max)
int_st_kv_map = raster::calc(int_st_kv, max)
int_st_kv_map = raster::asFactor(int_st_kv_map)

#plot(int_st_ci_map)
#plot(int_st_kv_map)

kv_levs = levels(int_st_kv_map)[[1]]
kv_levs$interactions = c('None', 'Drought & Bark Beetle', 
                         'Drought & Fire', 'Bark Beetle & Fire', 
                         'Drought, Bark Beetle & Fire')
colnames(kv_levs) = c("ID", "interactions")
levels(int_st_kv_map) = kv_levs

iskm = deratify(int_st_kv_map, 'interactions')

my_colors = c("white", "burlywood", "gold", "red", "black")
my_labels = c('None', 'Drought & Bark Beetle', 
              'Drought & Fire', 'Bark Beetle & Fire', 
              'Drought, Bark Beetle & Fire')

iskm.p = rasterToPoints(iskm)
iskm.df =data.frame(iskm.p)
colnames(iskm.df) = c("long", "lat", "interactions")
iskm.df$interactions = as.factor(iskm.df$interactions)

ncells(iskm == 1)
