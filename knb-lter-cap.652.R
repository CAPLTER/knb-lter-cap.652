
# README ----

# knb-lter-cap.652 is the authoritative data package for the ESCA plot data
# (note knb-lter-cap.653 houses the parcel data). Some exceptions include soils
# collected in the 2000 survey year, which are housed in knb-lter-cap.281, and
# one-off data, such as mycorhizae (see knb-lter-cap.652 repository README for a
# detailed catalog of ESCA data and data packagaes). This file documents the
# workflow for most ESCA data save those mentioned above. As this is is
# considered the authoritative repo. for ESCA data, additional documentation are
# included in this repository. Additional items that are not strictly relevant
# to the workflow (but to ESCA broadly) include a work-up of the correct
# calcuations to use for the clinomter (noted in the directory titled
# clinometer_calibration), and all processed soil data and all available raw
# maching output - note that raw machine output is avaialable only for the 2010
# and 2015 survey years (N & P on Lachat in 2015; N on Lachat in 2010; P on
# TRAACS in 2010) - the 2010 TRAACS P data are not actually raw machine output
# but were pieced together from machine reports and are a reasonable surrogate.

# libraries ----
library(EML)
library(RPostgreSQL)
library(RMySQL)
library(tidyverse)
library(tools)
library(readxl)
# library(magrittr)
library(aws.s3)

# reml-helper-functions ----
# source('~/localRepos/reml-helper-tools/createdataTableFn.R')
source('~/localRepos/reml-helper-tools/writeAttributesFn.R')
source('~/localRepos/reml-helper-tools/createDataTableFromFileFn.R')
source('~/localRepos/reml-helper-tools/createKMLFn.R')
source('~/localRepos/reml-helper-tools/address_publisher_contact_language_rights.R')
source('~/localRepos/reml-helper-tools/createOtherEntityFn.R')
source('~/localRepos/reml-helper-tools/createPeople.R')
source('~/localRepos/reml-helper-tools/createFactorsDataframe.R')

# quick function to print unique values of all fields (except date)
unique_values <- function(dataframe) {
  apply(dataframe[,-which(names(dataframe) == "sample_date")], 2, function(x) { unique(x) })
}


# connections ----

# Amazon
source('~/Documents/localSettings/aws.s3')
  
# postgres
source('~/Documents/localSettings/pg_prod.R')
source('~/Documents/localSettings/pg_local.R')
  
pg <- pg_prod
pg <- pg_local

# mysql
source('~/Documents/localSettings/mysql_prod.R')
prod <- mysql_prod

# dataset details to set first ----
projectid <- 652
packageIdent <- 'knb-lter-cap.652.2'
pubDate <- '2018-02-16'

# data processing ---------------------------------------------------------
source('esca_sql_queries.R')


# human_indicators --------------------------------------------------------

human_indicators <- get_human_indicators('survey200')

# empty strings to NA (skip the sample_date field [1])
human_indicators[,-1][human_indicators[,-1] == ''] <- NA

# review unique values
unique_values(human_indicators)

human_indicators <- human_indicators %>% 
  mutate(
    human_presence_of_path = as.factor(human_presence_of_path),
    human_footprints = as.factor(human_footprints),
    human_bike_tracks = as.factor(human_bike_tracks),
    human_off_road_vehicle = as.factor(human_off_road_vehicle),
    human_small_litter = as.factor(human_small_litter),
    human_dumped_trash_bags = as.factor(human_dumped_trash_bags),
    human_abandoned_vehicles = as.factor(human_abandoned_vehicles),
    human_graffiti = as.factor(human_graffiti),
    human_injured_plants = as.factor(human_injured_plants),
    human_informal_play = as.factor(human_informal_play),
    human_informal_recreation = as.factor(human_informal_recreation),
    human_informal_living = as.factor(human_informal_living),
    human_sports_equipment = as.factor(human_sports_equipment),
    human_social_class = as.factor(human_social_class)
  )

writeAttributes(human_indicators) # write data frame attributes to a csv in current dir to edit metadata
human_indicators_desc <- "The presence of features or characteristics that are reflective of human presence or activity at the study plot."

factorsToFrame(human_indicators)

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
human_indicators_DT <- createDTFF(dfname = human_indicators,
                                  description = human_indicators_desc,
                                  dateRangeField = 'sample_date')


# landscape_irrigation ----------------------------------------------------

landscape_irrigation <- get_landscape_irrigation('survey200')

# empty strings to NA (skip the sample_date field [1])
landscape_irrigation[,-1][landscape_irrigation[,-1] == ''] <- NA

# review unique values
unique_values(landscape_irrigation)

# standardize responses (note na is not applicable (not NA sensu R))
landscape_irrigation[,-1][landscape_irrigation[,-1] == 'dont know'] <- 'do_not_know'
landscape_irrigation[,-1][landscape_irrigation[,-1] == 'na'] <- 'n/a'

landscape_irrigation <- landscape_irrigation %>% 
  mutate(
    appears_maintained = as.factor(appears_maintained),
    appears_professional = as.factor(appears_professional),
    appears_healthy = as.factor(appears_healthy),
    appears_injured = as.factor(appears_injured),
    presence_of_open_ground = as.factor(presence_of_open_ground),
    presence_of_trees = as.factor(presence_of_trees),
    presence_of_shrubs = as.factor(presence_of_shrubs),
    presence_of_cacti_succ = as.factor(presence_of_cacti_succ),
    presence_of_lawn = as.factor(presence_of_lawn),
    presence_of_herbaceous_ground = as.factor(presence_of_herbaceous_ground),
    presence_of_other = as.factor(presence_of_other),
    presence_of_hand_water = as.factor(presence_of_hand_water),
    presence_of_drip_water = as.factor(presence_of_drip_water),
    presence_of_overhead_water = as.factor(presence_of_overhead_water),
    presence_of_flood_water = as.factor(presence_of_flood_water),
    presence_of_subterranean_water = as.factor(presence_of_subterranean_water),
    presence_of_no_water = as.factor(presence_of_no_water),
    presence_of_pervious_irrigation = as.factor(presence_of_pervious_irrigation)
  )

writeAttributes(landscape_irrigation) # write data frame attributes to a csv in current dir to edit metadata

factorsToFrame(landscape_irrigation)

landscape_irrigation_desc <- "Characteristics reflective of the landscape type, health, and quality at the plot."

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
landscape_irrigation_DT <- createDTFF(dfname = landscape_irrigation,
                                      description = landscape_irrigation_desc,
                                      dateRangeField = 'sample_date')



# annuals -----------------------------------------------------------------

annuals <- get_annuals()

# empty strings to NA (skip the sample_date field [1])
annuals[,-1][annuals[,-1] == ''] <- NA
annuals[,-1][annuals[,-1] == ' '] <- NA

# review unique values
unique_values(annuals)

writeAttributes(annuals) # write data frame attributes to a csv in current dir to edit metadata
annuals_desc <- "Catalog of all annual plants identified within the study plot."

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
annuals_DT <- createDTFF(dfname = annuals,
                         description = annuals_desc,
                         dateRangeField = 'sample_date')



# shrubs_cacti_succulents -------------------------------------------------

shrubs_cacti_succulents <- get_shrubs_cacti_succulents('survey200') %>% 
  select(-year) %>% 
  mutate(
    vegetation_shape_code = as.factor(vegetation_shape_code),
    vegetation_classification_code = as.factor(vegetation_classification_code)
  )

# empty strings to NA (skip the sample_date field [1])
shrubs_cacti_succulents[,-1][shrubs_cacti_succulents[,-1] == ''] <- NA
# shrubs_cacti_succulents[,-1][shrubs_cacti_succulents[,-1] == ' '] <- NA

# review unique values
unique_values(shrubs_cacti_succulents)

writeAttributes(shrubs_cacti_succulents) # write data frame attributes to a csv in current dir to edit metadata
shrubs_cacti_succulents_desc <- "Biovolume and characteristics of shrubs and succulent plants within study plots; up to five plants of each type are surveyed."

factorsToFrame(shrubs_cacti_succulents)

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
shrubs_cacti_succulents_DT <- createDTFF(dfname = shrubs_cacti_succulents,
                                         description = shrubs_cacti_succulents_desc,
                                         dateRangeField = 'sample_date')

# trees -------------------------------------------------------------------

trees <- get_trees('survey200') %>% 
  mutate(
    vegetation_shape_code = as.factor(vegetation_shape_code),
    vegetation_classification_code = as.factor(vegetation_classification_code),
    canopy_condition = tolower(canopy_condition),
    canopy_condition = as.factor(canopy_condition)
  )

# empty strings to NA (skip the sample_date field [1])
trees[,-1][trees[,-1] == ''] <- NA
# shrubs_cacti_succulents[,-1][shrubs_cacti_succulents[,-1] == ' '] <- NA

# review unique values
unique_values(trees)

writeAttributes(trees) # write data frame attributes to a csv in current dir to edit metadata
trees_desc <- "Size and characteristics of trees and Saguaros (Carnegiea gigantea) within study plots. Unlike shrubs and smaller plants where the characteristics of up to five individuals of each type are measured, characteristics of all trees and Saguaros in a plot are assessed. As such, these data also reflect the total number of trees and Saguaros in the study plot. An exception to this is seedlings, where trees less than 1 meter in height are simply counted (and not measured); counts of these plants are available in the number_perennials data that is part of this data set."

factorsToFrame(trees)

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
trees_DT <- createDTFF(dfname = trees,
                       description = trees_desc,
                       dateRangeField = 'sample_date')


# number_perennials -------------------------------------------------------

number_perennials <- get_number_perennials('survey200') 

# empty strings to NA (skip the sample_date field [1])
number_perennials[,-1][number_perennials[,-1] == ''] <- NA
# shrubs_cacti_succulents[,-1][shrubs_cacti_succulents[,-1] == ' '] <- NA

# review unique values
unique_values(number_perennials)

writeAttributes(number_perennials) # write data frame attributes to a csv in current dir to edit metadata
number_perennials_desc <- "The number of perennial plants in the study plot, except Saguaros and mature trees, the numbers of which are available in the trees data that are part of this data set."

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
number_perennials_DT <- createDTFF(dfname = number_perennials,
                                   description = number_perennials_desc,
                                   dateRangeField = 'sample_date')


# hedges ------------------------------------------------------------------

hedges <- get_hedges('survey200') %>% 
  mutate(
    vegetation_shape_code = as.factor(vegetation_shape_code),
    hedge_condition = tolower(hedge_condition),
    hedge_condition = as.factor(hedge_condition)
  )

# empty strings to NA (skip the sample_date field [1])
hedges[,-1][hedges[,-1] == ''] <- NA
hedges[,-1][hedges[,-1] == ' '] <- NA

# review unique values
unique_values(hedges)

writeAttributes(hedges) # write data frame attributes to a csv in current dir to edit metadata

hedges_desc <- "Biovolume and characteristics of hedges within study plots; up to five hedges of each type are surveyed."

factorsToFrame(hedges)

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
hedges_DT <- createDTFF(dfname = hedges,
                        description = hedges_desc,
                        dateRangeField = 'sample_date')


# landuse -----------------------------------------------------------------

landuse <- get_landuse('survey200')

# empty strings to NA (skip the sample_date field [1])
landuse[,-1][landuse[,-1] == ''] <- NA

# review unique values
unique_values(landuse)

writeAttributes(landuse) # write data frame attributes to a csv in current dir to edit metadata

landuse_desc <- "Estimated land use or land cover in the study plot. Plots may consist of multiple land use or land cover types, with the approximate percentage of each estimated. Land use or land cover types/labels are adapted from land use/land cover designations employed by the Maricopa County Association of Governments."

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
landuse_DT <- createDTFF(dfname = landuse,
                         description = landuse_desc,
                         dateRangeField = 'sample_date')

# neighborhood_characteristics --------------------------------------------

neighborhood_characteristics <- get_neighborhood_characteristics('survey200') %>% mutate(
  neigh_social_class_poor = as.factor(neigh_social_class_poor),
  neigh_social_class_rich = as.factor(neigh_social_class_rich),
  neigh_social_class_upper_middle = as.factor(neigh_social_class_upper_middle),
  neigh_social_class_working_lower = as.factor(neigh_social_class_working_lower),
  neigh_buildings_residential = as.factor(neigh_buildings_residential),
  neigh_buildings_commercial = as.factor(neigh_buildings_commercial),
  neigh_buildings_institutional = as.factor(neigh_buildings_institutional),
  neigh_buildings_industrial = as.factor(neigh_buildings_industrial),
  neigh_residence_apartments = as.factor(neigh_residence_apartments),
  neigh_residence_multi_family = as.factor(neigh_residence_multi_family),
  neigh_residence_single_family = as.factor(neigh_residence_single_family),
  neigh_irrigation_drip_trickle = as.factor(neigh_irrigation_drip_trickle),
  neigh_irrigation_flood_hand = as.factor(neigh_irrigation_flood_hand),
  neigh_irrigation_overhead_spray = as.factor(neigh_irrigation_overhead_spray),
  neigh_yard_upkeep_good = as.factor(neigh_yard_upkeep_good),
  neigh_yard_upkeep_poor = as.factor(neigh_yard_upkeep_poor),
  neigh_yard_upkeep_professionally_maintained = as.factor(neigh_yard_upkeep_professionally_maintained),
  neigh_landscape_mesic = as.factor(neigh_landscape_mesic),
  neigh_landscape_mixed = as.factor(neigh_landscape_mixed),
  neigh_landscape_xeric = as.factor(neigh_landscape_xeric),
  neigh_landscape_turf_present = as.factor(neigh_landscape_turf_present),
  neigh_traffic_collector_street = as.factor(neigh_traffic_collector_street),
  neigh_traffic_cul_de_sac = as.factor(neigh_traffic_cul_de_sac),
  neigh_traffic_dirt_road = as.factor(neigh_traffic_dirt_road),
  neigh_traffic_freeway_expressway = as.factor(neigh_traffic_freeway_expressway),
  neigh_traffic_highway = as.factor(neigh_traffic_highway),
  neigh_traffic_major_city_road = as.factor(neigh_traffic_major_city_road),
  neigh_traffic_none = as.factor(neigh_traffic_none),
  neigh_traffic_paved_local_street = as.factor(neigh_traffic_paved_local_street)
)

# empty strings to NA (skip the sample_date field [1])
neighborhood_characteristics[,-1][neighborhood_characteristics[,-1] == ''] <- NA

# review unique values
unique_values(neighborhood_characteristics)

writeAttributes(neighborhood_characteristics) # write data frame attributes to a csv in current dir to edit metadata

neighborhood_characteristics_desc <- "General characteristics, such as those relating to perceived social class, types of buildings (if present), landscape quality and features, and traffic of the immediate area surrounding the study plot."

factorsToFrame(neighborhood_characteristics)

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
neighborhood_characteristics_DT <- createDTFF(dfname = neighborhood_characteristics,
                                              description = neighborhood_characteristics_desc,
                                              dateRangeField = 'sample_date')


# structures --------------------------------------------------------------

structures <- get_structures('survey200') %>% 
  mutate(structure_use = replace(structure_use, grepl("agave", structure_use, ignore.case = T), 'house'))

# empty strings to NA (skip the sample_date field [1])
structures[,-1][structures[,-1] == ''] <- NA

# review unique values
unique_values(structures)

writeAttributes(structures) # write data frame attributes to a csv in current dir to edit metadata

structures_desc <- "Type and height of any structures within the study plot."

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
structures_DT <- createDTFF(dfname = structures,
                            description = structures_desc,
                            dateRangeField = 'sample_date')


# sampling_events ---------------------------------------------------------

sampling_events <- get_sampling_events('survey200')

# empty strings to NA (skip the sample_date field [1])
sampling_events[,-1][sampling_events[,-1] == ''] <- NA

# review unique values
unique_values(sampling_events)

writeAttributes(sampling_events) # write data frame attributes to a csv in current dir to edit metadata

sampling_events_desc <- "Date of survey and general characteristics of the study plot, including the elevation, slope, a description of the plot, and a description of weather on the date of sampling."

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
sampling_events_DT <- createDTFF(dfname = sampling_events,
                                 description = sampling_events_desc,
                                 dateRangeField = 'sample_date')



# soil_center_cores -------------------------------------------------------

soil_center_cores <- get_soil_center_cores()

# empty strings to NA (skip the sample_date field [1])
soil_center_cores[,which(!grepl("date", names(soil_center_cores), ignore.case = T))][soil_center_cores[,which(!grepl("date", names(soil_center_cores), ignore.case = T))] == ''] <- NA

# review unique values
unique_values(soil_center_cores)

# write data frame attributes to a csv in current dir to edit metadata
writeAttributes(soil_center_cores) 

soil_center_cores_desc <- "Physical and chemical properties of soils, including bulk density, particle size fraction, plant matter, pH and conductivity, moisture content, and texture. Measurements are made on a single core (2-inch diameter, 6-inch depth) taken near the survey plot center."

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
soil_center_cores_DT <- createDTFF(dfname = soil_center_cores,
                                   description = soil_center_cores_desc,
                                   dateRangeField = 'sample_date')



# soil_lachat -------------------------------------------------------------

# need to change all concentration-related fields to text as the concentration
# can vary depending on the analyte (e.g., Cl/P), so unable to assign a unit to
# these fields.
soil_lachat <- get_soil_lachat() %>% 
  mutate(
    analyte_name = as.factor(analyte_name),
    deep_core_type = as.factor(deep_core_type),
    sample_type = as.factor(sample_type),
    peak_concentration = as.character(peak_concentration),
    determined_conc = as.character(determined_conc),
    conc_x_adf = as.character(conc_x_adf),
    conc_x_mdf = as.character(conc_x_mdf),
    conc_x_adf_x_mdf = as.character(conc_x_adf_x_mdf)
  )

# empty strings to NA (skip the sample_date field [1])
soil_lachat[,which(!grepl("date", names(soil_lachat), ignore.case = T))][soil_lachat[,which(!grepl("date", names(soil_lachat), ignore.case = T))] == ''] <- NA

# review unique values
unique_values(soil_lachat)

writeAttributes(soil_lachat) # write data frame attributes to a csv in current dir to edit metadata

soil_lachat_desc <- "Raw soil core chemistry (nitrate-nitrogen, ammonium-nitrogen, phosphate). Analyses performed on a Lachat QC8000. Analyses data are available for years 2010 (nitrogen) and 2015 (nitrogen and phosphorus)."

factorsToFrame(soil_lachat)

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
soil_lachat_DT <- createDTFF(dfname = soil_lachat,
                             description = soil_lachat_desc,
                             dateRangeField = 'sample_date')


# soil_traacs -------------------------------------------------------------

soil_traacs <- get_soil_traacs() %>% 
  mutate(
    deep_core_type = as.factor(deep_core_type)
  )

# empty strings to NA (skip the sample_date field [1])
soil_traacs[,which(!grepl("date", names(soil_traacs), ignore.case = T))][soil_traacs[,which(!grepl("date", names(soil_traacs), ignore.case = T))] == ''] <- NA

# review unique values
unique_values(soil_traacs)

writeAttributes(soil_traacs) # write data frame attributes to a csv in current dir to edit metadata

soil_traacs_desc <- "Raw soil phosphate data as analyzed by Traacs for soil samples collected in 2010."

factorsToFrame(soil_traacs)

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
soil_traacs_DT <- createDTFF(dfname = soil_traacs,
                             description = soil_traacs_desc,
                             dateRangeField = 'sample_date')


# soil_perimeter_core -----------------------------------------------------

soil_perimeter_cores <- get_soil_perimeter_cores() %>% 
  mutate(deep_core_type = as.factor(deep_core_type))

# empty strings to NA (skip the sample_date field [1])
soil_perimeter_cores[,which(!grepl("date", names(soil_perimeter_cores), ignore.case = T))][soil_perimeter_cores[,which(!grepl("date", names(soil_perimeter_cores), ignore.case = T))] == ''] <- NA

# review unique values
unique_values(soil_perimeter_cores)

# write data frame attributes to a csv in current dir to edit metadata
writeAttributes(soil_perimeter_cores) 

soil_perimeter_cores_desc <- "Chemical properties of soils, including nitrate-nitrogen, ammonium-nitrogen, and phosphate, and moisture content. Measurements are made from four cores (1-inch diameter) collected approximately 10-m in each cardinal direction from the survey plot center. Cores from each cardinal direction are split into two depths: 0-10cm and 10-30cm, and homogenized."

factorsToFrame(soil_perimeter_cores)

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
soil_perimeter_cores_DT <- createDTFF(dfname = soil_perimeter_cores,
                                      description = soil_perimeter_cores_desc,
                                      dateRangeField = 'sample_date')


# arthropods --------------------------------------------------------------

# this pull is currently restricted (in the SQL) to surveys prior to 2015 - need
# to update when the 2015 arthropods have been processed.

arthropods <- get_arthropods() %>% 
  mutate(sweepnet_sample_type = as.factor(sweepnet_sample_type))

# empty strings to NA (skip the sample_date field [1])
arthropods[,which(!grepl("date", names(arthropods), ignore.case = T))][arthropods[,which(!grepl("date", names(arthropods), ignore.case = T))] == ''] <- NA

# review unique values
unique_values(arthropods)

# write data frame attributes to a csv in current dir to edit metadata
writeAttributes(arthropods) 

arthropods_desc <- "Arthropods collected in sweepnet samples at survey plots. Sweepnet samples are collected on up to three plants, typically of different types. Organisms are identified to the finest possible taxonomic resolution and enumerated. At plots lacking shrubs, trees, or other large plants, samples are typically collected from sweeps of the ground."

factorsToFrame(arthropods)

# create data table based on metadata provided in the companion csv
# use createdataTableFn() if attributes and classes are to be passed directly
arthropods_DT <- createDTFF(dfname = arthropods,
                            description = arthropods_desc,
                            dateRangeField = 'sample_date')










# end data processing -----------------------------------------------------




# title and abstract ----
title <- 'Ecological Survey of Central Arizona: a survey of key ecological indicators in the greater Phoenix metropolitan area and surrounding Sonoran desert, ongoing since 1999'

# abstract from file or directly as text
abstract <- as(set_TextType("abstract.md"), "abstract")


# people ----

danChilders <- addCreator('d', 'childers')
nancyGrimm <- addCreator('n', 'grimm')
dianeHope <- addCreator('d', 'hope')
jasonKaye <- addCreator('j', 'kaye')
chrisMartin <- addCreator('chr', 'martin')
nancyMcIntyre <- addCreator('n', 'mcintyre')
jeanStutz <- addCreator('j', 'stutz')

creators <- c(as(danChilders, 'creator'),
              as(nancyGrimm, 'creator'),
              as(dianeHope, 'creator'),
              as(jasonKaye, 'creator'),
              as(chrisMartin, 'creator'),
              as(nancyMcIntyre, 'creator'),
              as(jeanStutz, 'creator'))

lauraDugan <- addMetadataProvider('l', 'dugan')
stevanEarl <- addMetadataProvider('s', 'earl')
royErickson <- addMetadataProvider('r', 'erickson')
davidFleming <- addMetadataProvider('d', 'fleming')
corinnaGries <- addMetadataProvider('c', 'gries')
quincyStewart <- addMetadataProvider('q', 'stewart')
maggieTseng <- addMetadataProvider('m', 'tseng')
sallyWittlinger <- addMetadataProvider('s', 'wittlinger')

metadataProvider <-c(as(lauraDugan, 'metadataProvider'),
                     as(stevanEarl, 'metadataProvider'),
                     as(royErickson, 'metadataProvider'),
                     as(davidFleming, 'metadataProvider'),
                     as(corinnaGries, 'metadataProvider'),
                     as(quincyStewart, 'metadataProvider'),
                     as(maggieTseng, 'metadataProvider'),
                     as(sallyWittlinger, 'metadataProvider'))

# keywords ----

# CAP IRTs for reference: https://sustainability.asu.edu/caplter/research/
# be sure to include these as appropriate

keywordSet <-
  c(new("keywordSet",
        keywordThesaurus = "LTER controlled vocabulary",
        keyword =  c("soil",
                     "soil bulk density",
                     "soil moisture",
                     "soil nutrients",
                     "soil chemistry",
                     "soil carbon",
                     "soil nitrogen",
                     "soil organic matter",
                     "soil ph",
                     "soil phosphorus",
                     "soil properties",
                     "soil texture",
                     "soluble reactive phosphorus",
                     "agriculture",
                     "urban",
                     "carbon",
                     "ammonium",
                     "nitrate",
                     "nitrogen",
                     "nutrients",
                     "inorganic nitrogen",
                     "inorganic nutrients",
                     "phosphate",
                     "phosphorus",
                     "percent carbon",
                     "percent nitrogen",
                     "insects",
                     "arthropods",
                     "trees",
                     "shrubs",
                     "vegetation",
                     "plants",
                     "plant biomass",
                     "plant communities",
                     "plant cover",
                     "plant height",
                     "plant species composition",
                     "plant species",
                     "community composition",
                     "land use",
                     "long term monitoring",
                     "land cover",
                     "buildings")),
    new("keywordSet",
        keywordThesaurus = "LTER core areas",
        keyword =  c("movement of organic matter",
                     "movement of inorganic matter",
                     "disturbance patterns",
                     "land use and land cover change",
                     "water and fluxes",
                     "adapting to city life")),
    new("keywordSet",
        keywordThesaurus = "Creator Defined Keyword Set",
        keyword =  c("survey200",
                     "survey 200",
                     "phoenix",
                     "maricopa county",
                     "ecological survey of central arizona",
                     "sonoran desert",
                     "desert",
                     "suburban",
                     "neighborhood",
                     "yard",
                     "mesic",
                     "xeric",
                     "city")),
    new("keywordSet",
        keywordThesaurus = "CAPLTER Keyword Set List",
        keyword =  c("cap lter",
                     "cap",
                     "caplter",
                     "central arizona phoenix long term ecological research",
                     "arizona",
                     "az",
                     "arid land"))
    )

# methods and coverages ----
methods <- set_methods("esca_methods.md")

# if relevant, pulling dates from a DB is nice
# begindate <- dbGetQuery(con, "SELECT MIN(sample_date) AS date FROM database.table;")
# begindate <- begindate$date

begindate <- as.character(min(sampling_events$sample_date))
enddate <- as.character(max(sampling_events$sample_date))
geographicDescription <- "CAP LTER study area"
coverage <- set_coverage(begin = begindate,
                         end = enddate,
                         geographicDescription = geographicDescription,
                         west = -112.783, east = -111.579,
                         north = +33.8267, south = +33.2186)

# see esca_taxonomic_coverage.R in this repo for taxonomic coverage
coverage@taxonomicCoverage <- c(escaTaxa)

# construct the dataset ----

# address, publisher, contact, and rights come from a sourced file

# XML DISTRUBUTION
  xml_url <- new("online",
                 onlineDescription = "CAPLTER Metadata URL",
                 url = paste0("https://sustainability.asu.edu/caplter/data/data-catalog/view/", packageIdent, "/xml/"))
metadata_dist <- new("distribution",
                 online = xml_url)

# DATASET
dataset <- new("dataset",
               title = title,
               creator = creators,
               pubDate = pubDate,
               metadataProvider = metadataProvider,
               # associatedParty = associatedParty,
               intellectualRights = rights,
               abstract = abstract,
               keywordSet = keywordSet,
               coverage = coverage,
               contact = contact,
               methods = methods,
               distribution = metadata_dist,
               dataTable = c(human_indicators_DT,
                             landscape_irrigation_DT,
                             annuals_DT,
                             shrubs_cacti_succulents_DT,
                             trees_DT,
                             number_perennials_DT,
                             hedges_DT,
                             landuse_DT,
                             neighborhood_characteristics_DT,
                             structures_DT,
                             sampling_events_DT,
                             soil_center_cores_DT,
                             soil_lachat_DT,
                             soil_traacs_DT,
                             soil_perimeter_cores_DT,
                             arthropods_DT))

# ls(pattern= "_DT") # can help to pull out DTs

# assembly line flow that would be good to incorporate - build the list of DTs at creation
# data_tables_stored <- list()
# data_tables_stored[[i]] <- data_table
# dataset@dataTable <- new("ListOfdataTable",
#                      data_tables_stored)

# construct the eml ----

# ACCESS
allow_cap <- new("allow",
                 principal = "uid=CAP,o=LTER,dc=ecoinformatics,dc=org",
                 permission = "all")
allow_public <- new("allow",
                    principal = "public",
                    permission = "read")
lter_access <- new("access",
                   authSystem = "knb",
                   order = "allowFirst",
                   scope = "document",
                   allow = c(allow_cap,
                             allow_public))

# CUSTOM UNITS
# standardUnits <- get_unitList()
# unique(standardUnits$unitTypes$id) # unique unit types

custom_units <- rbind(
  data.frame(id = "voltSecond",
             unitType = "unknown",
             parentSI = "unknown",
             multiplierToSI = "unknown",
             description = "Lachat output area under the curve as volts*second")
# data.frame(id = "nephelometricTurbidityUnit",
#            unitType = "unknown",
#            parentSI = "unknown",
#            multiplierToSI = 1,
#            description = "(NTU) ratio of the amount of light transmitted straight through a water sample with the amount scattered at an angle of 90 degrees to one side")
)
unitList <- set_unitList(custom_units)

# note schemaLocation is new, not yet tried!
eml <- new("eml",
           schemaLocation = "eml://ecoinformatics.org/eml-2.1.1  http://nis.lternet.edu/schemas/EML/eml-2.1.1/eml.xsd",
           packageId = packageIdent,
           scope = "system",
           system = "knb",
           access = lter_access,
           dataset = dataset,
           additionalMetadata = as(unitList, "additionalMetadata"))


# write the xml to file   ----
write_eml(eml, "knb-lter-cap.652.1.xml")


# amazon ------------------------------------------------------------------

# data file to S3
dataToAmz <- function(fileToUpload) {
  
  put_object(file = fileToUpload,
             object = paste0('/datasets/cap/', basename(fileToUpload)),
             bucket = 'gios-data') 
  
}

# example
dataToAmz('652_human_indicators_d26842ef4fe8a4dc45e453f6a1a5090d.csv')
dataToAmz('652_landscape_irrigation_d7f0a19d05b3a8c04f20ec2e61292adb.csv')
dataToAmz('652_annuals_69842b489f6147e3dcb107ce6b3e0ab8.csv')
dataToAmz('652_shrubs_cacti_succulents_b0d9e621091e658ba87846c325f3388a.csv')
dataToAmz('652_trees_2a3f070887702331017ff5173a5fa0af.csv')
dataToAmz('652_number_perennials_a3c4b916bee0181650526a0bd5124963.csv')
dataToAmz('652_hedges_cadb4d593069eecae3246198b0238e0d.csv')
dataToAmz('652_landuse_fc380621290eadce6798174a56fe32b5.csv')
dataToAmz('652_neighborhood_characteristics_0ebb6977ff6a20ebef9ea5a843326f98.csv')
dataToAmz('652_structures_e254142a972c35c14c5b62cfe586bf5f.csv')
dataToAmz('652_sampling_events_127265c75731f5922b61210dd0f9fc63.csv')
dataToAmz('652_soil_center_cores_3f4963a5d816a1bc2b3bdf284c43006e.csv')
dataToAmz('652_soil_lachat_58b545a08d2c80fdbafdfa0ff02edb0a.csv')
dataToAmz('652_soil_traacs_79fc5d2b402e71e86a9f6240dc6967c2.csv')
dataToAmz('652_soil_perimeter_cores_62e57ec1a9c312c51df16a0462eb9843.csv')
dataToAmz('652_arthropods_7c0b907f7f33d7b5c3ab0873ff8a9486.csv')


# metadata file to S3
emlToAmz <- function(fileToUpload) {
  
  put_object(file = fileToUpload,
             object = paste0('/metadata/', basename(fileToUpload)),
             bucket = 'gios-data') 
  
}

# example
emlToAmz('knb-lter-cap.652.1.xml')
