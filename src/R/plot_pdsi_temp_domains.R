source("src/R/prep_pdsi.R")z
source("src/functions/ggplot_theme.R")

# Extract the site specific data 
poly_extract <- filter(neon_domains, (DomainName %in% c("Northern Rockies", 
                                                        "Southern Rockies / Colorado Plateau",
                                                        "Pacific Northwest"))) %>%
  as("Spatial")

drops <- c("poly_extract.DomainName", "OBJECTID", "Shape_Leng", 
           "DomainID", "Shape_Le_1", "id", "group", "Shape_Area")
poly_extract[ , !(names(poly_extract) %in% drops)]

# pdsi time series
pdsi_mean <- data.frame(poly_extract$DomainName, 
                        raster::extract(pdsi_anomalies, poly_extract, layer = 1,
                                        fun = mean))

names(pdsi_mean) <- c("domains", paste(year(date_seq), month(date_seq), 
                          day(date_seq), sep = "-"))

# tmean time series
tmean_mean <- data.frame(poly_extract$DomainName, 
                         raster::extract(tmean_anomalies8416, poly_extract, layer = 1,
                                         fun = mean))

names(tmean_mean) <- c("domains", paste(year(date_seq), month(date_seq), 
                                        day(date_seq), sep = "-"))

# Prep data for plotting and calulate a 36-month moving average 
pdsi_mean_cln <- pdsi_mean %>%
  gather( year, value, -domains) %>%
  group_by(domains) %>%
  arrange(domains) %>%
  mutate( med_5yr =rollapply(value, 36, mean, align='center', fill=NA)) %>%
  ungroup() %>%
  mutate(date = as.POSIXct(year, format = "%Y-%m-%d"),
         month = month(date)) %>%
  filter(month %in% c(6, 7, 8))

tmean_mean_cln <- tmean_mean %>%
  gather( year, value, -domains) %>%
  group_by(domains) %>%
  arrange(domains) %>%
  mutate( med_5yr =rollapply(value, 36, mean, align='center', fill=NA)) %>%
  ungroup() %>%
  mutate(date = as.POSIXct(year, format = "%Y-%m-%d")) %>%
  filter(month %in% c(6, 7, 8))

# Plot the time series for summer months of tmean and pdsi
pdsi_ts <- pdsi_mean_cln %>%
  filter(date >= "1984-01-01" & date <= "2016-12-01") %>%
  ggplot(aes(x = date, y = value, color = domains, group = domains)) +
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
  xlab("") + ylab("Anomolous mean \nsummer drought (PDSI)") +
  theme_pub() + theme(legend.position = "none",
                      axis.text.x=element_blank())

tmean_ts <- tmean_mean_cln %>%
  filter(date >= "1984-01-01" & date <= "2016-12-01") %>%
  ggplot(aes(x = date, y = value, color = domains, group = domains)) +
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
  xlab("Year") + ylab("Anomolous mean \nmonthly temperature") +
  theme_pub() + theme(legend.position = "none")

grid.arrange(pdsi_ts, tmean_ts, nrow = 2)
g <- arrangeGrob(pdsi_ts, tmean_ts, nrow = 2)

ggsave(file = "results/timeseries_domains.eps", g, width = 5, height = 4,
       scale = 3, dpi = 600, units = "cm") #saves p

