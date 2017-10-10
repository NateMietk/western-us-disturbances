source("src/R/prep_pdsi.R")
source("src/functions/ggplot_theme.R")

# Extract the site specific data 
pdsi_mean <- data.frame(coordinates(as(neon_sites, "Spatial")),
                        neon_sites$SiteName, 
                        raster::extract(pdsi_anomalies, as(neon_sites, "Spatial"), 
                                        layer = 1, buffer = 50000, fun = mean))
names(pdsi_mean) <- c("x", "y", "site",  paste(year(date_seq), month(date_seq),
                                               day(date_seq), sep = "-"))

tmean_anomalies8416 <- subset(tmean_anomalies,
                      which(getZ(tmean_anomalies)>=as.Date('1984-01-01') &
                              getZ(tmean_anomalies)<=as.Date('2016-12-31')))
tmean_mean <- data.frame(coordinates(as(neon_sites, "Spatial")),
                        neon_sites$SiteName, 
                        raster::extract(tmean_anomalies8416, as(neon_sites, "Spatial"), 
                                        layer = 1, buffer = 50000, fun = mean))
names(tmean_mean) <- c("x", "y", "site",  paste(year(date_seq), month(date_seq), 
                                               day(date_seq), sep = "-"))

# Prep data for plotting and calulate a 3-year moving average 
pdsi_mean_cln <- pdsi_mean %>%
  select(-x, -y) %>%
  gather( year, value, -site) %>%
  group_by(site) %>%
  arrange(site) %>%
  mutate(med_5yr =rollapply(value, 36, mean, align='center', fill=NA)) %>%
  ungroup() %>%
  mutate(date = as.POSIXct(year, format = "%Y-%m-%d"),
         month = month(date)) %>%
  filter(month %in% c(5, 6, 7, 8, 9))

tmean_mean_cln <- tmean_mean %>%
  select(-x, -y) %>%
  gather( year, value, -site) %>%
  group_by(site) %>%
  arrange(site) %>%
  mutate(med_5yr =rollapply(value, 36, mean, align='center', fill=NA)) %>%
  ungroup() %>%
  mutate(date = as.POSIXct(year, format = "%Y-%m-%d"),
         month = month(date)) 

# Plot the time series for summer months of tmean and pdsi
pdsi_ts <- pdsi_mean_cln %>%
  filter(date >= "1984-01-01" & date <= "2016-12-01") %>%
  ggplot(aes(x = date, y = value, color = site, group = site)) +
  #geom_point() +
  #geom_line(size = 0.5) +
  geom_line(aes(y = med_5yr), size = 0.5) +
  geom_hline(yintercept = 0, size = 0.5) + 
  scale_y_continuous(limits = c(-4, 5), breaks = c(-2, 0, 2, 4)) +
  scale_x_datetime(date_breaks = "4 year", date_labels = "%Y", expand = c(0, 0),
                   limits = c(
                     as.POSIXct("1984-01-01"),
                     as.POSIXct("2016-12-01")
                   )) + 
  xlab("") + ylab("Monthly mean \ndrought anomalies") +
  theme_pub() + theme(legend.position = "none",
                      axis.text.x=element_blank())

tmean_ts <- tmean_mean_cln %>%
  filter(date >= "1984-01-01" & date <= "2016-12-01") %>%
  ggplot(aes(x = date, y = value, color = site, group = site)) +
  #geom_point(alpha = 0.15) +
  #geom_line(size = 0.5, alpha = 0.15) +
  geom_line(aes(y = med_5yr), size = 0.5) +
  geom_hline(yintercept = 0, size = 0.5) + 
  scale_y_continuous(limits = c(-1.5, 1.5)) +
  scale_x_datetime(date_breaks = "4 year", 
                   date_labels = "%Y", expand = c(0, 0),
                   limits = c(
                     as.POSIXct("1984-01-01"),
                     as.POSIXct("2016-12-01")
                   )) + 
  xlab("Year") + ylab("Monthly mean \ntemperature anomalies") +
  theme_pub() + theme(legend.position = "none")

grid.arrange(pdsi_ts, tmean_ts, nrow = 2)
g <- arrangeGrob(pdsi_ts, tmean_ts, nrow = 2)

ggsave(file = "results/timeseries_pts.eps", g, width = 5, height = 3.5,
       scale = 3, dpi = 600, units = "cm") #saves p
