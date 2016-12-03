---
title: "Working with spatial and climate data from GSODR"
author: "Adam H Sparks"
date: "2016-11-30"
output: rmarkdown::html_vignette
vignette: >
  %\VignetteEngine{knitr::knitr}
  %\VignetteIndexEntry{Working with spatial and climate data from GSODR}
  %\VignetteEncoding{UTF-8}
---

# Introduction

The GSODR package provides the ability to interact with GSOD data using
spatial methods. The `get_GSOD` function allows for the data to be saved as
a GeoPackage file which can be read by most GIS software packages or in R using
R's GIS capabilities with contributed packages as well.

Following is an example of how you might download and save GSOD annual data for
a given country, Philippines in this example, and convert it into a KML file for
viewing in GoogleEarth. The second portion uses the same GeoPackage file to
import the data back into R and combine the GSOD data with the included CHELSA
data and plot the station temperatures for daily GSOD, average monthly GSOD and
CHELSA temperatures (1979-2013).

## Example - Download and plot data for a single country
Download data for Philippines for year 2010 and generate a spatial, year summary
file, PHL-2010.gpkg, in the user's home directory.


```r
library(GSODR)
get_GSOD(years = 2010, country = "Philippines", dsn = "~/",
         filename = "PHL-2010", GPKG = TRUE, max_missing = 5)
```


```r
library(rgdal)
```

```
## Loading required package: sp
```

```
## rgdal: version: 1.2-4, (SVN revision 643)
##  Geospatial Data Abstraction Library extensions to R successfully loaded
##  Loaded GDAL runtime: GDAL 1.11.5, released 2016/07/01
##  Path to GDAL shared files: /usr/local/Cellar/gdal/1.11.5_1/share/gdal
##  Loaded PROJ.4 runtime: Rel. 4.9.3, 15 August 2016, [PJ_VERSION: 493]
##  Path to PROJ.4 shared files: (autodetected)
##  Linking to sp version: 1.2-3
```

```r
library(spacetime)
library(plotKML)
```

```
## plotKML version 0.5-6 (2016-05-02)
```

```
## URL: http://plotkml.r-forge.r-project.org/
```

```r
layers <- ogrListLayers(dsn = path.expand("~/PHL-2010.gpkg"))
pnts <- readOGR(dsn = path.expand("~/PHL-2010.gpkg"), layers[1])
```

```
## OGR data source with driver: GPKG 
## Source: "/Users/U8004755/PHL-2010.gpkg", layer: "GSOD"
## with 4703 features
## It has 46 fields
```

```r
# Plot results in Google Earth as a spacetime object:
pnts$DATE = as.Date(paste(pnts$YEAR, pnts$MONTH, pnts$DAY, sep = "-"))
row.names(pnts) <- paste("point", 1:nrow(pnts), sep = "")

tmp_ST <- STIDF(sp = as(pnts, "SpatialPoints"),
                time = pnts$DATE - 0.5,
                data = pnts@data[, c("TEMP", "STNID")],
                endTime = pnts$DATE + 0.5)

shape = "http://maps.google.com/mapfiles/kml/pal2/icon18.png"

kml(tmp_ST, dtime = 24 * 3600, colour = TEMP, shape = shape, labels = TEMP,
    file.name = "Temperatures_PHL_2010-2010.kml", folder.name = "TEMP")
```

```
## KML file opened for writing...
```

```
## Writing to KML...
```

```
## Closing  Temperatures_PHL_2010-2010.kml
```

```r
system("zip -m Temperatures_PHL_2010-2010.kmz Temperatures_PHL_2010-2010.kml")
```

Compare the GSOD weather data from the Philippines with climatic data provided
by the GSODR package in the `GSOD_clim` data set.


```r
library(dplyr)
```

```
## 
## Attaching package: 'dplyr'
```

```
## The following objects are masked from 'package:stats':
## 
##     filter, lag
```

```
## The following objects are masked from 'package:base':
## 
##     intersect, setdiff, setequal, union
```

```r
library(ggplot2)
library(reshape2)

data(GSOD_clim)
cnames <- paste0("CHELSA_temp_", 1:12, "_1979-2013")
clim_temp <- GSOD_clim[GSOD_clim$STNID %in% pnts$STNID,
                       paste(c("STNID", cnames))]
clim_temp_df <- data.frame(STNID = rep(clim_temp$STNID, 12),
                           MONTHC = as.vector(sapply(1:12, rep,
                                                    times = nrow(clim_temp))), 
                           CHELSA_TEMP = as.vector(unlist(clim_temp[, cnames])))

pnts$MONTHC <- as.numeric(paste(pnts$MONTH))
temp <- left_join(pnts@data, clim_temp_df, by = c("STNID", "MONTHC"))
```

```
## Warning in left_join_impl(x, y, by$x, by$y, suffix$x, suffix$y): joining
## factors with different levels, coercing to character vector
```

```r
temp <- temp %>% 
  group_by(MONTH) %>% 
  mutate(AVG_DAILY_TEMP = round(mean(TEMP), 1))

df_melt <- na.omit(melt(temp[, c("STNID", "DATE", "CHELSA_TEMP", "TEMP", "AVG_DAILY_TEMP")],
                        id = c("DATE", "STNID")))

ggplot(df_melt, aes(x = DATE, y = value)) +
  geom_point(aes(color = variable), alpha = 0.2) +
  scale_x_date(date_labels = "%b") +
  ylab("Temperature (C)") +
  xlab("Month") +
  labs(colour = "") +
  scale_color_brewer(palette = "Dark2") +
  facet_wrap( ~ STNID)
```

![Comparison of GSOD daily values and average monthly values with CHELSA climate monthly values](figure/example_1.2-1.png)

# Notes

## Sources

#### CHELSA climate layers
CHELSA (climatic surfaces at 1 km resolution) is based on a quasi-mechanistical
statistical downscaling of the ERA interim global circulation model
(Karger et al. 2016). ESA's CCI-LC cloud probability monthly averages are based
on the MODIS snow products (MOD10A2). <http://chelsa-climate.org/>

#### EarthEnv MODIS cloud fraction 
<http://www.earthenv.org/cloud>

#### ESA's CCI-LC cloud probability
<http://maps.elie.ucl.ac.be/CCI/viewer/index.php>

#### Elevation Values

90m hole-filled SRTM digital elevation (Jarvis *et al.* 2008) was used
to identify and correct/remove elevation errors in data for station
locations between -60˚ and 60˚ latitude. This applies to cases here
where elevation was missing in the reported values as well. In case the
station reported an elevation and the DEM does not, the station reported
is taken. For stations beyond -60˚ and 60˚ latitude, the values are
station reported values in every instance. See
<https://github.com/adamhsparks/GSODR/blob/devel/data-raw/fetch_isd-history.md>
for more detail on the correction methods.

## WMO Resolution 40. NOAA Policy

*Users of these data should take into account the following (from the
[NCDC website](http://www7.ncdc.noaa.gov/CDO/cdoselect.cmd?datasetabbv=GSOD&countryabbv=&georegionabbv=)):*

> "The following data and products may have conditions placed on their 
international commercial use. They can be used within the U.S. or for
non-commercial international activities without restriction. The
non-U.S. data cannot be redistributed for commercial purposes.
Re-distribution of these data by others must provide this same
notification." [WMO Resolution 40. NOAA
Policy](http://www.wmo.int/pages/about/Resolution40.html)

# References
Stachelek, J. 2016. Using the Geopackage Format with R. 
URL: https://jsta.github.io/2016/07/14/geopackage-r.html