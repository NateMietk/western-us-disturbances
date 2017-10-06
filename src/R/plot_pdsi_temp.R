source("src/R/prep_pdsi.R")
source("src/functions/ggplot_theme.R")

# Extract the site specific data 
date_seq2 <- 1980:2016
pdsi_mean <- data.frame(coordinates(as(neon_sites, "Spatial")),
                        neon_sites$SiteName, 
                        raster::extract(pdsi_sum_yr_anom, as(neon_sites, "Spatial"), 
                                        layer = 1, buffer = 50000, fun = mean))
names(pdsi_mean) <- c("x", "y", "site",  paste(year(date_seq), month(date_seq),
                                               day(date_seq), sep = "-"))

# Prep data for plotting and calulate a 3-year moving average 
pdsi_mean_cln <- pdsi_mean %>%
  select(-x, -y) %>%
  gather( year, value, -site) %>%
  group_by(site) %>%
  arrange(site) %>%
  mutate( med_5yr =rollapply(value, 60, mean, align='center', fill=NA)) %>%
  ungroup() %>%
  mutate(date = as.POSIXct(year, format = "%Y-%m-%d"),
         month = month(date)) %>%
  filter(month %in% c(6, 7, 8))

pdsi_mean_cln %>%
  filter(date >= "1984-01-01" & date <= "2016-12-01") %>%
  ggplot(aes(x = date, y = value, color = site, group = site)) +
  geom_point(alpha = 0.15) +
  geom_line(size = 0.5, alpha = 0.15) +
  geom_line(aes(y = med_5yr), size = 1.5, alpha = 0.75) +
  geom_hline(yintercept = 0, alpha = 0.5) + 
  scale_x_datetime(date_breaks = "4 year", date_labels = "%Y", expand = c(0, 0),
                   limits = c(
                     as.POSIXct("1984-01-01"),
                     as.POSIXct("2016-12-01")
                   )) + 
  xlab("Year") + ylab("Summer anomalies of PDSI") +
  theme_pub() + theme(legend.position = "none")

# Extract the site specific data 
tmmx_mean <- data.frame(coordinates(as(neon_sites, "Spatial")),
                        neon_sites$SiteName, 
                        raster::extract(tmmx_annomalies, as(neon_sites, "Spatial"), layer = 1))
names(tmmx_mean) <- c("x", "y", "site",  paste(year(date_seq), month(date_seq), 
                                               day(date_seq), sep = "-"))

# Prep data for plotting and calulate a 3-year moving average 
tmmx_mean <- tmmx_mean %>%
  select(-x, -y) %>%
  gather( year, value, -site) %>%
  group_by(site) %>%
  arrange(site) %>%
  mutate( med_5yr =rollapply(value, 60, mean, align='center', fill=NA)) %>%
  ungroup() %>%
  mutate(date = as.POSIXct(year, format = "%Y-%m-%d"),
         month = month(date)) %>%
  filter(month %in% c(6, 7, 8))

tmmx_mean %>%
  filter(date >= "1984-01-01" & date <= "2016-12-01") %>%
  ggplot(aes(x = date, y = value, color = site, group = site)) +
  geom_point(alpha = 0.15) +
  geom_line(size = 0.5, alpha = 0.15) +
  geom_line(aes(y = med_5yr), size = 1.5, alpha = 0.75) +
  geom_hline(yintercept = 0, alpha = 0.5) + 
  scale_x_datetime(date_breaks = "4 year", date_labels = "%Y", expand = c(0, 0),
                   limits = c(
                     as.POSIXct("1984-01-01"),
                     as.POSIXct("2016-12-01")
                   )) + 
  xlab("Year") + ylab("") +
  theme_pub() + theme(legend.position = "none")


