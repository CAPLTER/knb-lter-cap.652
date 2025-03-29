## CAP LTER Ecological Survey of Central Arizona (ESCA)

### version history

- knb-lter-cap.652.5 2025-0x-xx
  + updated with 2023 survey data, except arthropod and soils data, which are
  not yet available
  + revised arthropod taxonomy
  + revised vegetation taxonomy; this taxonomy still needs a lot of work with
  the guidance of a botanist but we were able to improve it greatly with this
  version by addressing things like misspelled taxa, collapsing synonyms, and
  splitting taxa from iterations of taxa (e.g., with something like aloe1,
  aloe2, aloe3, moving the number to a notes field)
  + deprecated the cacti table, reclassifying Saguaros as trees and all others
  as shrubs
  + omitted all clinometer-related data; will revisit, especially for 2023 data,
  which uses the laser range finder, but, as of this version, we are not
  confident in the clinometer-related data

- knb-lter-cap.652.4 2022-07-12
  + Fix an error that Rebecca M. identified with the soil perimeter data in
  which 2015 phosphorus concentrations were presented as ppb but should have
  been presented as ppm in keeping with phosphorus data from 2005 and 2010, and
  in accordance with the metadata. Though, only the soil perimeter data were
  updated, this update used a newer [capeml](https://caplter.github.io/capeml/)
  workflow and thus a `config.yaml` file was added as well.

### ESCA-related dataset inventory:

- [knb-lter-cap.652](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=652): ESCA plots
- [knb-lter-cap.653](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=653): ESCA parcels

The following datasets are historic, reflecting a prior configuration of these
data in which the individual data topics (e.g. trees, arthropods) were presented
as unique data packages. All data are now presented in one of two datasets,
plots or parcels, noted above.

- [knb-lter-cap.282](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=282): trees
- [knb-lter-cap.281](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=281): soils
  + modified and updated to house only 2000 soil data, including:
    - 27\_soil\_1.csv
    - 27\_soilbulkdensity\_1.csv
    - 27\_soil\_samples\_1.csv
    - 27\_soil\_texture\_1.csv
    - 27\_soilchemconc\_1.csv
    - 27\_soilchemmass\_1.csv
    - 27\_soilncphconduct\_1.csv
- [knb-lter-cap.280](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=280): shrubs
- [knb-lter-cap.278](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=278):
one-off, snapshot data that are not part of the long-term effort, including:
  + climate
  + landuse\_100m
  + litter\_bags
  + mycorrhizae
  + weather
  + land use history (and see knb-lter-cap.269)
  + pollen (and see knb-lter-cap.277)
- [knb-lter-cap.277](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=277): pollen (and see knb-cap-lter.278)
- [knb-lter-cap.276](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=276): buildings
- [knb-lter-cap.274](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=274): neighborhood characteristics
- [knb-lter-cap.272](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=278): landuse (MAG)
- [knb-lter-cap.269](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=269): landuse history
- [knb-lter-cap.268](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=268): cacti
- [knb-lter-cap.267](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=267): sweepnets
- [knb-lter-cap.266](https://portal.edirepository.org/nis/mapbrowse?scope=knb-lter-cap&identifier=266): annuals


### data entities:

**plots:**

- annuals
- arthropods
- hedges
- human indicators
- land use
- landscape irrigation
- neighborhood characteristics
- number of perennials
- sampling event and site details
- shrub surveys
- soil perimeter cores (nutrients)
- soil center cores (texture, bulk density, conductivity, pH)
- structures
- trees