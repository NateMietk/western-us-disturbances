

mpb_shp1 <- st_read("../data/ads/wus/mpb/r1_mpb.gpkg") %>%
  st_buffer(., dist = 0) %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "mpb", "r1_mpb_wus_dis.gpkg"))) {
  st_write(mpb_shp1, file.path(ads_out, "mpb", "r1_mpb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}

mpb_shp2 <- st_read("../data/ads/wus/mpb/r2_mpb.gpkg") %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "mpb", "r2_mpb_wus_dis.gpkg"))) {
  st_write(mpb_shp2, file.path(ads_out, "mpb", "r2_mpb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}
mpb_shp3 <- st_read("../data/ads/wus/mpb/r3_mpb.gpkg") %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "mpb", "r3_mpb_wus_dis.gpkg"))) {
  st_write(mpb_shp3, file.path(ads_out, "mpb", "r3_mpb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}
mpb_shp4 <- st_read("../data/ads/wus/mpb/r4_mpb.gpkg") %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "mpb", "r4_mpb_wus_dis.gpkg"))) {
  st_write(mpb_shp4, file.path(ads_out, "mpb", "r4_mpb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}

mpb_shp5 <- st_read("../data/ads/wus/mpb/r5_mpb.gpkg") %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "mpb", "r5_mpb_wus_dis.gpkg"))) {
  st_write(mpb_shp5, file.path(ads_out, "mpb", "r5_mpb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}
mpb_shp6 <- st_read("../data/ads/wus/mpb/r6_mpb.gpkg") %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "mpb", "r6_mpb_wus_dis.gpkg"))) {
  st_write(mpb_shp6, file.path(ads_out, "mpb", "r6_mpb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}

# mpb polygons
mpb_wus_list <- list(mpb_shp1, mpb_shp2, mpb_shp3,
                     mpb_shp4, mpb_shp5, mpb_shp6)
mpb_wus <- do.call(rbind, mpb_wus_list) %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "mpb", "mpb_wus_dis.gpkg"))) {
  st_write(mpb_wus, file.path(ads_out, "mpb", "mpb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE, overwrite = TRUE )}












sb_shp1 <- st_read("../data/ads/wus/sb/r1_sb.gpkg") %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "sb", "r1_sb_wus_dis.gpkg"))) {
  st_write(sb_shp1, file.path(ads_out, "sb", "r1_sb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}

sb_shp2 <- st_read("../data/ads/wus/sb/r2_sb.gpkg") %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "sb", "r2_sb_wus_dis.gpkg"))) {
  st_write(sb_shp2, file.path(ads_out, "sb", "r2_sb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}
sb_shp3 <- st_read("../data/ads/wus/sb/r3_sb.gpkg") %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "sb", "r3_sb_wus_dis.gpkg"))) {
  st_write(sb_shp3, file.path(ads_out, "sb", "r3_sb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}
sb_shp4 <- st_read("../data/ads/wus/sb/r4_sb.gpkg") %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "sb", "r4_sb_wus_dis.gpkg"))) {
  st_write(sb_shp4, file.path(ads_out, "sb", "r4_sb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}

sb_shp5 <- st_read("../data/ads/wus/sb/r5_sb.gpkg") %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "sb", "r5_sb_wus_dis.gpkg"))) {
  st_write(sb_shp5, file.path(ads_out, "sb", "r5_sb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}
sb_shp6 <- st_read("../data/ads/wus/sb/r6_sb.gpkg") %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "sb", "r6_sb_wus_dis.gpkg"))) {
  st_write(sb_shp6, file.path(ads_out, "sb", "r6_sb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}

# sb polygons
sb_wus_list <- list(sb_shp1, sb_shp2, sb_shp3,
                     sb_shp4, sb_shp5, sb_shp6)
sb_wus <- do.call(rbind, sb_wus_list) %>%
  st_make_valid() %>%
  group_by(group) %>%
  summarise() %>%
  st_cast() %>%
  st_cast("MULTIPOLYGON")

if (!file.exists(file.path(ads_out, "sb", "sb_wus_dis.gpkg"))) {
  st_write(sb_wus, file.path(ads_out, "sb", "sb_wus_dis.gpkg"),
           driver = "GPKG",
           update=TRUE)}



# Panel A: Drought