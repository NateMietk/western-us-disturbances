source("src/R/prep_pdsi.R")




# Extract the site specific data 
data_mean <- data.frame(coordinates(neon_sites),
                        neon_sites$SiteName, 
                        raster::extract(mean_75thpct, neon_sites, layer = 1, 
                                        buffer = 10000, fun = mean))
names(data_mean) <- c("x", "y", "site",  paste(year(date_seq), month(date_seq), 
                                               day(date_seq), sep = "-"))

# Prep data for plotting and calulate a 3-year moving average 
data_mean <- data_mean %>%
  select(-x, -y) %>%
  gather( year, value, -site) %>%
  group_by(site) %>%
  arrange(site) %>%
  mutate( med_5yr =rollapply(value, 36, mean, align='center', fill=NA)) %>%
  ungroup() %>%
  mutate(date = as.POSIXct(year, format = "%Y-%m-%d"))


source("src/R/ggplot_theme.R")
data_mean %>%
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
  xlab("Year") + ylab("75th percentile Palmer's Drought Severity Index") +
  theme_pub() + theme(legend.position = "none")

