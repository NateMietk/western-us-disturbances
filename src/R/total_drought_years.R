x <- c("raster", "tidyverse", "lubridate")
lapply(x, library, character.only = TRUE, verbose = FALSE)

pdsi_files <- list.files("data/climate/pdsi/monthly_mean_75thpct", pattern = ".tif$", 
                            full.names = TRUE)

pdsi <- stack(pdsi_files)

start_date <- as.Date(paste("1979", "01", "01", sep = "-"))
end_date <- as.Date(paste("1980", "10", "31", sep = "-"))
date_seq <- seq(start_date, end_date, by = "1 month")
month_seq <- month(date_seq)
year_seq <- year(date_seq)

names(pdsi) <- paste("pdsi", year_seq,
                       unique(month(date_seq, label = TRUE)),
                       sep = "_")
p4string <- "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"
projection(pdsi) <- CRS(p4string)

pdsi <- stackApply(pdsi, year_seq, fun = mean,  na.rm = TRUE)

pdsi[pdsi > -2] <- NA
