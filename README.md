# Creating dense time series stacks of multiple disturbances across the western US

## Authors

Nathan Mietkiewicz

## Requirements

Downloading and processing the data requires that you have [R](https://www.r-project.org/) installed, and the following R packages:

```r
x <- c("raster", "rgdal", "tidyverse", "assertthat", "purrr", "httr",
       "rvest", "lubridate", "ncdf4", "sf", "zoo", "snowfall", "tools")
lapply(x, library, character.only = TRUE, verbose = FALSE)
```

## Running the script

To run the R script, you can use `Rscript` from the terminal:

``` bash
Rscript get_data.R
source src/bash/get_temp_data.sh
```

This will pull all data needed for this project from the internet.  The data that will be acquired are:

1.  NEON Site locations
2.  NEON domains
3.  State boundaries
4.  4k Elevation from GridMet
5.  Monitoring Trends in Burn Severity (MTBS) fire polygons
6.  Forest groups of the lower 48 States
7.  All Aerial Detection Survey (ADS) data from regions 1-6 for years spanning 1978-2016 (regional variation)
8.  Download all daily maximum and minimum temperature data from 1979-2016 for the whole  US from the GridMet server.

## The unfortunate part...

The ADS are frankly a mess. The packages in R could not adequately repair all of the geometry errors and null values (i.e., rdgal, sf, rgeos).  After unpacking the archaic`.e00` files, batch repair geometry on all shapfiles for all years in all regions needed to be done in either ArcGIS or QGIS. Almost all years/regions had errors that were reconciled. Those unpacked and repaired files should be then moved and reside in the "cleaned" folders within each region.

## Cleaning all raw data

The next major step will be to clean and aggregate when necessary all data to produce the final output.  To accomplish this you will run the following scripts:

``` bash
Rscript prep_bounds.R
Rscript prep_ads.R
Rscript prep_pdsi.R
Rscript prep_temp.R
Rscript prep_map_data.R
Rscript prep_combo.R
```

1.  The `prep_bounds.R` file will import and prepare all shapefile boundaries (e.g., states, domains, site location, mtbs, forest groups).  It will clean and organize all data.

2.  The `prep_ads.R` file will take a long time to run.  It runs for each region and will create aggregated shapefiles for Mountain pine beetle, spruce beetle, and spruce budworm.  The resulting shapefiles will have all polygons found for that region with the causal damage agent ID and polygon year within the attribute data.  The resulting shapefile is fine for depicting total extent of insect damage, but should NOT be used as a time series until further cleaning is done.  The very last part of this script will create western US wide shapefiles of each causal damage agent.  

3.  The `prep_pdsi.R` file takes monthly PDSI aggregates for the whole US, converting them to 1) monthly anomalies for the western US, and 2) one classified raster of total years each pixel observed severe (<-2 PDSI) summer drought.  The monthly anomalies will be fed into the time series figure, while the classified image will be fed into a Spatial depiction of disturbances.

4.  The `prep_temp.R` will take daily time series stacks of maximum and minimum temperatures and computes 1) monthly mean temperature, and 2) monthly mean temperature anomalies.  These results will be fed into the time series figure only.  This script will call and run the `aggregate_climate_data.R` script automatically.  This will take the daily data and aggregate to monthly and clip to the the domains within the wetern US.

5.  The `prep_map_data.R` will convert all bark beetle outbreak and mtbs shapefiles to 4k rasters.  These will be used to create the disturbance map and disturbance combination map.

6.  The `prep_combo.R` file will reclassify and merge and rasters to create a raster of number and type of disturbances.  This does NOT depict the sequence of disturbance combinations, simply the total observed number and type for any given pixel from 1984-2016.

## Map creation

``` bash
Rscript disturbance_map.R
```

Here we take all the cleaned and processed data and create a 4 panel figure.  Where panel: a) Severe drought (<-2 PDSI), b) total mountain pine beetle and spruce beetle outbreak extent from 1984-2016, c) total burned area by wildfire from 1984-2016, and d) depicts where each of these disturbances overlap in space.  Note, panel "d" uses on pixels that observed more than 10 years of severe drought.

![disturbaces](results/disturbaces.jp2)

## Time series creation.

``` bash
Rscript plot_pdsi_temp_domains.R
Rscript plot_pdsi_temp.R
```
These scripts both create a 2 panel figure, where panel a) mean temperature anomalies and b) mean drought anomalies for summer months (JJA) from 1984-2016.  The resulting figures all have three running mean lines that correspond to the NEON sites we are proposing to work at (Yellowstone, Wind River, Niwot Ridge).  The `plot_pdsi_temp_domains.R` script will create monthly means and a 36-month running average for all domains that the three corresponding sites fall within.  The `plot_pdsi_temp.R` will take a 50k buffer around each site and calculate the monthly means and a 36-month running average.  
