README
================

<!-- README.md is derived from README.Rmd, update the latter not the former -->
Ecological Survey of Central Arizona
====================================

todos:
------

-   soil GPS to database
-   update all of the old datasets with a pointer to the new, auth. data set, and with temporal coverages
-   parcels

caution:
--------

careful of two AA111 sampling\_events in 2000, presumably Jan 01 is wrong as it is a full month before the next survey date and is new year's day 2000-05-01 | AA111 2000-01-01 | AA111

dataset inventory:
------------------

-   282: trees -&gt; update
-   281: soils -&gt; house 2000 soils data
    -   data to keep:
    -   27\_soil\_1.csv
    -   27\_soilbulkdensity\_1.csv
    -   27\_soil\_samples\_1.csv
    -   27\_soil\_texture\_1.csv
    -   27\_soilchemconc\_1.csv
    -   27\_soilchemmass\_1.csv
    -   27\_soilncphconduct\_1.csv
-   280: shrubs -&gt; update
-   278: will become the data set for one-off, snapshot data (i.e., data that are not part of the long-term effort), including:
    -   myco
    -   weather
    -   dowels
    -   traffic
    -   pollen (but see 277)
-   277: pollen -&gt; update
-   276: buildings -&gt; update
-   287: neighborhoods -&gt; update
-   272: landuse (MAG) -&gt; update
-   269: landuse history -&gt; no change
-   268: cacti -&gt; update
-   267: sweepnets -&gt; update
-   266: annuals -&gt; update
-   652: new, authoritative data set for ESCA *plots*, including 2015 data (but not survey year 2000 soils)
-   653: new, authoritative data set for ESCA *parcels*, including 2015 data

except for the new, authoritative data sets (knb-lter-cap.652 and knb-lter-cap.653), update means to expand the metadata to include a pointer to the new, authoritative data set, and to imporove the quality of the data and metadata as needed but as minimally as possible to generate a passing data set.

data entities:
--------------

**plots:**

-   human indicators
-   landscape\_irrigation
-   vegetation:
    -   annuals
    -   shrubs\_succulents
    -   trees
    -   counts
    -   hedges
-   sampling event and site details (bring general\_description, and the weather stuff from human\_indicators in here)
-   arthropods
-   buildings
-   landuse
-   neighborhoods
-   soil:
    -   center core (including texture 2005-2015)
    -   texture 2000 (2000 as a separate data entity)
    -   perimeter:
    -   raw lachat: have N & P for 2015, and N for 2010
    -   raw traacs: P for 2010

**parcels:**

-   vegetation:
    -   shrubs\_succulents
    -   trees
    -   counts
    -   hedges
-   sampling event and site details
-   parcel characteristics survey
-   landscape\_irrigation?
