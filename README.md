# README

## CAP LTER Ecological Survey of Central Arizona

### knb-lter-cap.652.4 2022-07-12

Version four provides a fix to an error that Rebecca M. identified with the soil perimeter data in which 2015 phosphorus concentrations were presented as ppb but should have been presented as ppm in keeping with phos data from 2005 and 2010, and in accordance with the metadata. Though, only the soil perimeter data were updated, this updated relied on a newer capeml workflow and thus a config.yaml file was added as well.

### dataset inventory:

- 282: trees -&gt; updated with pointer in abstract, no other changes (did not realize until after having loaded in PASTA that there were not any keywords in this data set)
- 281: soils -&gt; modified and updated to house only 2000 soil data
  - data to keep:
    - 27\_soil\_1.csv
    - 27\_soilbulkdensity\_1.csv
    - 27\_soil\_samples\_1.csv
    - 27\_soil\_texture\_1.csv
    - 27\_soilchemconc\_1.csv
    - 27\_soilchemmass\_1.csv
    - 27\_soilncphconduct\_1.csv
- 280: shrubs -&gt; updated with pointer in abstract, and added minimal keyword (CAP-specific and LTER core area)
- 278: the data set for one-off, snapshot data (i.e., data that are not part of the long-term effort), including:
  - data to keep:
    - climate
    - landuse\_100m
    - litter\_bags
    - mycorrhizae: numspores, sample\_sites, species
    - weather: station, uplload
    - land use history (these are already captured in 269 so no need to keep here)
    - pollen (these are already captured in 277 so no need to keep here)
    - also updated abstract and title
- 277: pollen -&gt; updated with improved abstract & pointer in abstract, and added temporal and geo coverages
- 276: buildings -&gt; updated with pointer in abstract, and added minimal keyword (CAP-specific and LTER core area)
- 274: neighborhood characteristics -&gt; updated with pointer in abstract, and added minimal keyword (CAP-specific and LTER core area)
- 272: landuse (MAG) -&gt; updated with pointer in abstract, and added minimal keyword (CAP-specific and LTER core area)
- 269: landuse history -&gt; no change
- 268: cacti -&gt; updated with pointer in abstract, and added minimal keyword (CAP-specific and LTER core area)
- 267: sweepnets -&gt; updated with pointer in abstract, no other changes
- 266: annuals -&gt; updated with pointer in abstract, and added minimal keyword (CAP-specific and LTER core area)
- 652: new, authoritative data set for ESCA *plots*, including 2015 data (but not survey year 2000 soils)
- 653: new, authoritative data set for ESCA *parcels*, including 2015 data

except for the new, authoritative data sets (knb-lter-cap.652 and knb-lter-cap.653), update means to expand the metadata to include a pointer to the new, authoritative data set, and to imporove the quality of the data and metadata if and as needed but as minimally as possible to generate a passing data set.

### data entities:

**plots:**

- human indicators
- landscape\_irrigation
- vegetation:
 - annuals
 - shrubs\_succulents
 - trees
 - counts
 - hedges
- sampling event and site details (bring general\_description, and the weather stuff from human\_indicators in here)
- arthropods
- buildings
- landuse
- neighborhoods
- soil:
 - center core (including texture 2005-2015)
 - texture 2000 (2000 as a separate data entity)
 - perimeter:
 - raw lachat: have N & P for 2015, and N for 2010
 - raw traacs: P for 2010

**parcels:**

- vegetation:
 - shrubs\_succulents
 - trees
 - counts
 - hedges
- sampling event and site details
- parcel characteristics survey
- landscape\_irrigation?
