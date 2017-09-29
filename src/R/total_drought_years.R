x <- c("raster", "tidyverse", "lubridate")
lapply(x, library, character.only = TRUE, verbose = FALSE)

pdsi_mean_files <- list.files("data/pdsi/monthly_mean/", pattern = ".tif", 
                            full.names = TRUE, recursive = TRUE)

pdsi <- stack(pdsi_mean_files)

start_date <- as.Date(paste("1979", "01", "01", sep = "-"))
end_date <- as.Date(paste("2016", "12", "31", sep = "-"))
date_seq <- seq(start_date, end_date, by = "1 month")
month_seq <- month(date_seq)
year_seq <- year(date_seq)

names(pdsi) <- paste("pdsi", year_seq,
                       unique(month(date_seq, label = TRUE)),
                       sep = "_")


pdsi <- stackApply(pdsi, year_seq, fun = mean)

pdsi[pdsi > -2] <- NA
