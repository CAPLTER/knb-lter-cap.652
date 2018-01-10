# README ------------------------------------------------------------------

# 2018-01-04

# All available raw data, including Lachat (2015: N & P; 2010: N) and TRAACS
# (2010: P), have been added to the database. Seems that I have not yet added
# the 2015 processed center or perimeter core data.

# Processed center core and perimeter core data added to the database. Unable to
# resolve the true identifies of AB12 and F18, so those samples had to be
# omitted

# 2017-12-27

# Left off having completed the query for the center core data (in ...281.R) but
# did not write attr table as all data base adjustment (e.g., new data, table
# mods) have been done only in localhost; finished stitching together processed
# perimeter core data, now need to work on the insert and extract queries for
# perimeter - for both the processed and raw (unless we can actually do the
# blank correction).

# Found problems at AB12 and F18 where we have perimeter core data for those
# sites but they are not actual sites - not sure to which sites those data truly
# belong. Waiting on input from Roy but if he does not know, we may have to cull
# those data else risk asigning values to the wrong site.

# Note the correction of J6 -> J9 on phos data. All perimeter core data save
# phos have the site id of J9 whereas only phos has the site id of J6 - that
# coupled with the fact that there is not a site J6 indicates strongly that the
# J9 phos. data were mislabeled as J6. Need to make a note of this in the
# database when you get to prod. 

# mutate(site_code = replace(site_code, site_code == 'J6', 'J9')) %>%


# libraries ----
library(readxl)
library(stringr)
library(tidyverse)
library(RPostgreSQL)
library(zoo)
library(tools)

# postgres ----
source('~/Documents/localSettings/pg_prod.R')
source('~/Documents/localSettings/pg_local.R')

pg <- pg_prod
pg <- pg_local

# soil samples ids ----

# get soil sample data and strip trailing 1 from site codes
soilSamples <- dbGetQuery(pg, "
                          SELECT
                            ss.soil_sample_id,
                            ss.survey_id,
                            se.samp_date,
                            sites.site_code,
                            ss.location_description,
                            ss.sampling_notes, 
                            ss.location_description_center
                          FROM
                            survey200.soil_samples ss
                            JOIN survey200.sampling_events se ON (se.survey_id = ss.survey_id)
                            JOIN survey200.sites ON (sites.site_id = se.site_id)
                          WHERE 
                            EXTRACT (YEAR FROM se.samp_date) = 2015;") %>% 
  mutate(site_code = str_sub(site_code, 1, str_length(site_code) - 1)) # strip off the trailing 1


# center ------------------------------------------------------------------

# center core data to pg --------------------------------------------------

# center core soil data
bulkDensity <- read_excel('s200 2015 bulk density.xlsx', sheet = 1, skip = 1) %>% # sheet E
  mutate(site = replace(site, site == 'Z9', 'V9')) # V9 presumably mislabeled as Z9
coreMoistureContent <- read_excel('s200 2015 bulk density.xlsx', sheet = 2, skip = 1) %>% # sheet F
  mutate(site = replace(site, site == 'Z9', 'V9')) # V9 presumably mislabeled as Z9
phCond <- read_excel('s200 2015 soil pH and conductivity.xls', skip = 2) %>% # sheet G
  mutate(Site = replace(Site, Site == 'Z9', 'V9')) # V9 presumably mislabeled as Z9

# need to deal with the TEXTURE BLANKS

# add the values in the blank row to the blank columns
texture <- read_excel('S200 2015 Soil Texture Analysis.xlsx') %>% # sheet I
  mutate(`Sample#` = replace(`Sample#`, `Sample#` == 'Z9', 'V9')) %>% # V9 presumably mislabeled as Z9
  mutate(cal_texture_fw = case_when(grepl("blk", `Bottle#`) ~ `Weight g`)) %>% 
  mutate(cal_temp = case_when(grepl("blk", `Bottle#`) ~ `C°`)) %>% 
  mutate(cal_r05 = case_when(grepl("blk", `Bottle#`) ~ R0.5)) %>% 
  mutate(cal_r1 = case_when(grepl("blk", `Bottle#`) ~ R1)) %>% 
  mutate(cal_t1 = case_when(grepl("blk", `Bottle#`) ~ T1)) %>% 
  mutate(cal_r90 = case_when(grepl("blk", `Bottle#`) ~ R90)) %>% 
  mutate(cal_t90 = case_when(grepl("blk", `Bottle#`) ~ T90)) %>% 
  mutate(cal_r1440 = case_when(grepl("blk", `Bottle#`) ~ R1440)) %>% 
  mutate(cal_t1440 = case_when(grepl("blk", `Bottle#`) ~ T1440)) %>% 
  mutate(cal_run_date = case_when(grepl("blk", `Bottle#`) ~ `Date Analyzed`))

# fill NAs between blanks
texture <- texture %>%
  mutate(cal_texture_fw = zoo::na.locf(cal_texture_fw, fromLast = T)) %>% 
  mutate(cal_temp = zoo::na.locf(cal_temp, fromLast = T)) %>% 
  mutate(cal_r05 = zoo::na.locf(cal_r05, fromLast = T)) %>% 
  mutate(cal_r1 = zoo::na.locf(cal_r1, fromLast = T)) %>% 
  mutate(cal_t1 = zoo::na.locf(cal_t1, fromLast = T)) %>% 
  mutate(cal_r90 = zoo::na.locf(cal_r90, fromLast = T)) %>% 
  mutate(cal_t90 = zoo::na.locf(cal_t90, fromLast = T)) %>% 
  mutate(cal_r1440 = zoo::na.locf(cal_r1440, fromLast = T)) %>% 
  mutate(cal_t1440 = zoo::na.locf(cal_t1440, fromLast = T)) %>% 
  mutate(cal_run_date = zoo::na.locf(cal_run_date, fromLast = T))

# now we can remove the blank rows
texture <- texture %>%
  filter(!grepl("blank", `Sample#`))

# end TEXTURE BLANKS

# stitch it all of the center data together
center_cores <- 
  inner_join(soilSamples[,c("soil_sample_id", "site_code")], bulkDensity[,c(1,3:7)], by = c("site_code" = "site")) %>% 
  inner_join(phCond[,c(1,3:4)], by = c("site_code" = "Site")) %>% 
  inner_join(coreMoistureContent[,c(1:6)], by = c("site_code" = "site")) %>%  
  inner_join(texture[,c(1,3:24)], by = c("site_code" = "Sample#"))

# send data to a temp table in pg
if (dbExistsTable(pg, c('survey200', 'center_cores'))) dbRemoveTable(pg, c('survey200', 'center_cores')) 
dbWriteTable(pg, c('survey200', 'center_cores'), value = center_cores, row.names = F) 

# insert core samples data from temp table to the production table
insert_center_cores_query <-
'INSERT INTO survey200.soil_center_cores
(
  soil_sample_id,
  core_height_cm,
  soil_bulkdensity_fw, 
  dw_more_2_mm,
  dw_less_2_mm,
  plant_matter,
  conductivity,
  ph_value, 
  pan,
  pan_plus_fw,
  pan_plus_dw60,
  pan_plus_dw105,
  soil_texture_fw, 
  temperature,
  r05,
  r1,
  t1,
  r90,
  t90,
  r1440,
  t1440,
  notes,
  cal_texture_fw, 
  cal_temp,
  cal_r05,
  cal_r1,
  cal_t1,
  cal_r90,
  cal_t90,
  cal_r1440, 
  cal_t1440,
  cal_run_date
)
(
  SELECT
    soil_sample_id,
    "height (cm)",
    "fresh wt (g)",
    "dry wt (>2mm)",
    "dry wt (<2mm)", 
    "veg matter (g)",
    "conductivity (mS)", 
    "pH",
    "pan tare (g)",
    "pan + soil wt (g)",
    "pan + dry soil (g)", 
    "pan + dry soil (g)__1",
    "Weight g",
    "C°", 
    "R0.5",
    "R1",
    "T1",
    "R90",
    "T90",
    "R1440",
    "T1440",
    "Notes", 
    cal_texture_fw,
    cal_temp,
    cal_r05,
    cal_r1,
    cal_t1,
    cal_r90,
    cal_t90, 
    cal_r1440,
    cal_t1440,
    cal_run_date
  FROM survey200.center_cores
);'

  dbSendQuery(pg, insert_center_cores_query)
  
  # clean up
  if (dbExistsTable(pg, c('survey200', 'center_cores'))) dbRemoveTable(pg, c('survey200', 'center_cores')) 
  

# perimeter ---------------------------------------------------------------
  
# processed 2015 perimeter data -------------------------------------------
  
  # perimeter cores soil data - these are Roy's processed data
  perimeterMoistureContent <- read_excel('s200 2015 core samples.xls', sheet = 2, skip = 2) %>% # sheet A
    separate(col = sample, into = c("site_code", "deep_core_type"), sep = " ") %>% 
    select(-`pan #`, -contains("%"), -contains(":")) %>% 
    rename(
      pan_weight = `pan wt`,
      pan_fresh_soil = `pan +  fr soil`,
      pan_dry_soil = `pan + dry soil`,
      pan_ashed_soil = `pan + dry soil__1`
    )
  
  availableNitrogen <- read_excel('s200 2015 avail N.xlsx') %>% # sheet D
    separate(col = `Sample ID`, into = c("site_code", "deep_core_type"), sep = " ") %>% 
    rename(
      soil_fresh_weight_n = `Soil fresh wt (g)`,
      extract_volume_n = `Extractant vol (ml)`,
      nitrate_nitrogen = `Nitrate/Nitrite (mg/L)`,
      ammonia = `Ammonia (mg/L)`
    )
  
  phosphorus <- read_excel('S200 2015 SRP.xlsx') %>% # sheet J
    separate(col = Sample, into = c("site_code", "deep_core_type"), sep = " ") %>% 
    rename(
      soil_fresh_weight_p = `Weight (g)`,
      extract_volume_p = `Extractant Vol (ml)`,
      phosphate = `ug P/L`
    ) %>% 
    mutate(site_code = replace(site_code, site_code == 'J6', 'J9')) # see README
  
  carbonNitrogen <- read_excel('S200 2015 CN.xlsx') %>% # sheet H
    mutate(`Sample ID` = str_replace(`Sample ID`, "\\*", "")) %>% 
    separate(col = `Sample ID`, into = c("site_code", "deep_core_type"), sep = " ") %>% 
    mutate(deep_core_type = trimws(deep_core_type, which = "both")) %>% 
    select(-contains("X")) %>% 
    rename(
      soil_fresh_weight_cn = `Weight (mg)`,
      percent_total_c = `% Total C`,
      percent_inorganic_c = `% Inorg C`,
      percent_total_n = `% Total N`
    )
  
# perimeter, raw lachat data ----------------------------------------------
  
  # function to import raw lachat data and perform minor processing
  tidy_raw_lachat <- function(datafile) {
    
    if(grepl("x", file_ext(datafile))) {
      lachatData <- read_excel(datafile)
    } else {
      lachatData <- read_csv(datafile)
    }
    
    lachatData <- lachatData %>% 
      mutate(
        `Detection Date` = as.Date(`Detection Date`, format = '%m/%d/%Y'),
        code_layer = str_extract(`Sample ID`, '^(\\S{2,4})\\s(TOP|BOT)')
      ) %>% 
      separate(code_layer, into = c("site_code", "deep_core_type"), sep = " ") %>% 
      rename_all(tolower) %>%
      rename(weight_units = `weight (units)`)
    colnames(lachatData) <- gsub(" ", "\\_", colnames(lachatData)) # sp to underscore
    
    return(lachatData)
    
  }
  
  # 2015
  # import the raw N lachat data and bind to soil samples and processed data for upload
  raw_lachat_nitrogen <- bind_rows(
    tidy_raw_lachat('OM_6-8-2016_09-51-57AM.csv'),
    tidy_raw_lachat('OM_6-16-2016_10-50-00AM.csv')
  ) %>% 
    mutate(site_code = gsub("017", "O17", site_code)) %>% 
    left_join(availableNitrogen[,c("site_code", "deep_core_type", "soil_fresh_weight_n", "extract_volume_n")],
              by = c("site_code", "deep_core_type")) %>%
    left_join(soilSamples[,c("soil_sample_id", "site_code")], 
              by = c("site_code")) %>% 
    select(soil_sample_id, deep_core_type, sample_id:conc_x_adf_x_mdf) %>% 
    rename(determined_conc = determined_conc.)
  
  
  # import the raw P lachat data an bind to soil samples and processed data for upload
  raw_lachat_phosphorus <- bind_rows(
    tidy_raw_lachat('OM_9-27-2016_10-33-40AM.csv'),
    tidy_raw_lachat('OM_9-28-2016_09-55-27AM.csv'),
    tidy_raw_lachat('OM_9-29-2016_09-27-40AM.csv')
  ) %>% 
    mutate(site_code = replace(site_code, site_code == 'J6', 'J9')) %>% 
    left_join(phosphorus[,c("site_code", "deep_core_type", "soil_fresh_weight_p", "extract_volume_p")],
              by = c("site_code", "deep_core_type")) %>%
    left_join(soilSamples[,c("soil_sample_id", "site_code")], 
              by = c("site_code")) %>% 
    select(soil_sample_id, deep_core_type, sample_id:conc_x_adf_x_mdf) %>% 
    rename(determined_conc = determined_conc.)
  
  # have not yet tried this query with the survey_year having been added 
  # query to insert data into newly created table to house raw lachat data
  insert_lachat_2015_query <- '
  INSERT INTO survey200.soil_lachat (
    soil_sample_id,
    deep_core_type,
    sample_id,
    sample_type,
    replicate_number,
    repeat_number,
    cup_number,
    manual_dilution_factor,
    auto_dilution_factor,
    weight_units,
    weight,
    units,
    detection_date,
    detection_time,
    user_name,
    run_file_name,
    description,
    channel_number,
    analyte_name,
    peak_concentration,
    determined_conc,
    concentration_units,
    peak_area,
    peak_height,
    calibration_equation,
    retention_time,
    inject_to_peak_start,
    conc_x_adf,
    conc_x_mdf,
    conc_x_adf_x_mdf,
    survey_year
  )
  (
    SELECT
      soil_sample_id,
      deep_core_type,
      sample_id,
      sample_type,
      replicate_number,
      repeat_number,
      cup_number,
      manual_dilution_factor,
      auto_dilution_factor,
      weight_units,
      weight,
      units,
      detection_date,
      detection_time,
      user_name,
      run_file_name,
      description,
      channel_number,
      analyte_name,
      peak_concentration,
      determined_conc,
      concentration_units,
      peak_area,
      peak_height,
      calibration_equation,
      retention_time,
      inject_to_peak_start,
      conc_x_adf,
      conc_x_mdf,
      conc_x_adf_x_mdf,
      2015
    FROM survey200.temp_lachat 
  );'
  
  dataname <- raw_lachat_nitrogen
  dataname <- raw_lachat_phosphorus
  
  if (dbExistsTable(pg, c('survey200', 'temp_lachat'))) dbRemoveTable(pg, c('survey200', 'temp_lachat')) # make sure tbl does not exist
  dbWriteTable(pg, c('survey200', 'temp_lachat'), value = dataname, row.names = F)
  
  # insert data
  dbExecute(pg, insert_lachat_2015_query)
  
  # clean up
  if (dbExistsTable(pg, c('survey200', 'temp_lachat'))) dbRemoveTable(pg, c('survey200', 'temp_lachat')) # clean up
  
  
# perimeter, processed data -----------------------------------------------
  
  # stitch it all of the perimeter data together
  perimeter_cores <- 
    right_join(soilSamples[,c("soil_sample_id", "site_code")], perimeterMoistureContent, by = c("site_code")) %>% 
    inner_join(availableNitrogen, by = c("site_code", "deep_core_type")) %>% 
    inner_join(phosphorus, by = c("site_code", "deep_core_type")) %>% 
    inner_join(carbonNitrogen, by = c("site_code", "deep_core_type")) %>% 
    mutate(deep_core_type = ifelse(grepl("B", deep_core_type, ignore.case = T), "bottom", "top")) %>% 
    filter(!site_code %in% c('F18', 'AB12')) # unable to resolve the true identity of F18 and AB12 so they will have to be removed
  
  # send center core data to a temp table in pg
  if (dbExistsTable(pg, c('survey200', 'perimeter_cores'))) dbRemoveTable(pg, c('survey200', 'perimeter_cores')) 
  dbWriteTable(pg, c('survey200', 'perimeter_cores'), value = perimeter_cores, row.names = F) 
  
  insert_perimeter_cores_query <-
  'INSERT INTO survey200.soil_perimeter_cores
  (
    soil_sample_id,
    deep_core_type,
    pan,
    pan_plus_fw,
    pan_plus_dw60,
    pan_plus_aw,
    soil_n_fw,
    n_extract_volume,
    nh4_n,
    no3_n,
    soil_p_fw,
    p_extract_volume,
    po4_p,
    percent_total_c,
    percent_inorg_c,
    percent_total_n
  )
  (
    SELECT
      soil_sample_id,
      deep_core_type,
      pan_weight,
      pan_fresh_soil,
      pan_dry_soil,
      pan_ashed_soil,
      soil_fresh_weight_n,
      extract_volume_n,
      ammonia,
      nitrate_nitrogen,
      soil_fresh_weight_p,
      extract_volume_p,
      phosphate,
      percent_total_c,
      percent_inorganic_c,
      percent_total_n
    FROM survey200.perimeter_cores
  );'

  dbSendQuery(pg, insert_perimeter_cores_query)
  
  # clean up
  if (dbExistsTable(pg, c('survey200', 'center_cores'))) dbRemoveTable(pg, c('survey200', 'center_cores'))
  