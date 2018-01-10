# README ------------------------------------------------------------------

# Raw Lachat data for 2010 nitrogen have been added to the database per this
# workflow, as have 2010 phosphorus pieced together from traacs output.

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
                            EXTRACT (YEAR FROM se.samp_date) = 2010;") %>% 
  mutate(site_code = str_sub(site_code, 1, str_length(site_code) - 1)) # strip off the trailing 1


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

# processed data
perimeter_2010_n <- 
  dbGetQuery(pg, "
             SELECT
               sites.site_code,
               prc.soil_sample_id,
               prc.deep_core_type --,
               -- prc.n_extract_volume,
               --prc.soil_n_fw 
             FROM
               survey200.soil_perimeter_cores prc
               JOIN survey200.soil_samples ss ON (ss.soil_sample_id = prc.soil_sample_id)
               JOIN survey200.sampling_events se ON (se.survey_id = ss.survey_id)
               JOIN survey200.sites ON (sites.site_id = se.site_id)
             WHERE 
               EXTRACT (YEAR FROM se.samp_date) = 2010;") %>% 
  mutate(site_code = str_sub(site_code, 1, str_length(site_code) - 1)) # strip off the trailing 1

# import the raw N lachat data an bind to soil samples and processed data for upload
raw_lachat_nitrogen <- bind_rows(
  tidy_raw_lachat('Survey_200_NO3_NH4_3_27_2012-1.xls'),
  tidy_raw_lachat('Survey_200_NO3_NH4_3_28_2012_1.xls'),
  tidy_raw_lachat('Survey_200_NO3_NH4_3_28_2012_2.xls'),
  tidy_raw_lachat('Survey_200_NO3_NH4_3_29_2012.xls')
) %>%
  mutate(
    deep_core_type = case_when(
      grepl("top", deep_core_type, ignore.case = T) ~ 'top',
      grepl("bot", deep_core_type, ignore.case = T) ~ 'bottom'
    ),
    detection_time = as.character(detection_time, format = '%H:%M:%S')
  ) %>% 
  left_join(perimeter_2010_n,
            by = c("site_code", "deep_core_type")) %>%
  select(soil_sample_id, deep_core_type, sample_id:inject_to_peak_start)

dataname <- raw_lachat_nitrogen

if (dbExistsTable(pg, c('survey200', 'temp_lachat'))) dbRemoveTable(pg, c('survey200', 'temp_lachat')) # make sure tbl does not exist
dbWriteTable(pg, c('survey200', 'temp_lachat'), value = dataname, row.names = F)

insert_lachat_2010_query <- '
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
  -- units,
  detection_date,
  detection_time,
  user_name,
  run_file_name,
  description,
  channel_number,
  analyte_name,
  peak_concentration,
  -- determined_conc,
  concentration_units,
  peak_area,
  peak_height,
  calibration_equation,
  retention_time,
  inject_to_peak_start --,
  -- conc_x_adf,
  -- conc_x_mdf,
  -- conc_x_adf_x_mdf
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
    -- units,
    detection_date,
    detection_time,
    user_name,
    run_file_name,
    description,
    channel_number,
    analyte_name,
    peak_concentration,
    -- determined_conc,
    concentration_units,
    peak_area,
    peak_height,
    calibration_equation,
    retention_time,
    inject_to_peak_start --,
    -- conc_x_adf,
    -- conc_x_mdf,
    -- conc_x_adf_x_mdf
  FROM survey200.temp_lachat 
);'

# insert data
dbExecute(pg, insert_lachat_2010_query)

# clean up
if (dbExistsTable(pg, c('survey200', 'temp_lachat'))) dbRemoveTable(pg, c('survey200', 'temp_lachat')) # clean up
  
# add survey year - thought to add this post insert hence here as an update
dbExecute(pg, 'UPDATE survey200.soil_lachat SET survey_year = 2010')


# perimeter, raw traacs data ----------------------------------------------

raw_traacs_phosphorus <- bind_rows(
  read_excel('S200 2010 SRP Traacs raw data.xlsx', sheet = 1) %>% 
    mutate(sample_set = 1),
  read_excel('S200 2010 SRP Traacs raw data.xlsx', sheet = 2) %>% 
    mutate(sample_set = 2),
  read_excel('S200 2010 SRP Traacs raw data.xlsx', sheet = 3) %>% 
    mutate(sample_set = 3),
  read_excel('S200 2010 SRP Traacs raw data.xlsx', sheet = 4) %>% 
    mutate(sample_set = 4),
  read_excel('S200 2010 SRP Traacs raw data.xlsx', sheet = 5) %>% 
    mutate(sample_set = 5),
  read_excel('S200 2010 SRP Traacs raw data.xlsx', sheet = 6) %>% 
    mutate(sample_set = 6)
)
# set 7 was a small one tacked onto the end of set 6
raw_traacs_phosphorus[c(579:nrow(raw_traacs_phosphorus)),]$sample_set <- 7

raw_traacs_phosphorus <- raw_traacs_phosphorus %>% 
  mutate(code_layer = str_extract(Sample, '^(\\S{2,4})\\s(TOP|BOT)')) %>% 
  separate(code_layer, into = c("site_code", "deep_core_type"), sep = " ") %>% 
  rename_all(tolower) %>%
  mutate(
    deep_core_type = case_when(
      grepl("top", deep_core_type, ignore.case = T) ~ 'top',
      grepl("bot", deep_core_type, ignore.case = T) ~ 'bottom'
    ),
    sample_set = as.integer(sample_set),
    sample_sequence = seq_along(sample)
  ) %>% 
  left_join(perimeter_2010_n,
            by = c("site_code", "deep_core_type")) %>%
  select(soil_sample_id, deep_core_type, sample_sequence, sample_id = sample, sample_set, phos_mg_l = `mg p/l`)
  
dataname <- raw_traacs_phosphorus 

if (dbExistsTable(pg, c('survey200', 'temp_traacs'))) dbRemoveTable(pg, c('survey200', 'temp_traacs')) # make sure tbl does not exist
dbWriteTable(pg, c('survey200', 'temp_traacs'), value = dataname, row.names = F)

insert_traacs_2010_query <- '
INSERT INTO survey200.soil_traacs (
  soil_sample_id,
  deep_core_type,
  sample_sequence,
  sample_id,
  sample_set,
  phos_mg_l
)
(
  SELECT
    soil_sample_id,
    deep_core_type,
    sample_sequence,
    sample_id,
    sample_set,
    phos_mg_l
  FROM survey200.temp_traacs 
);'

# insert data
dbExecute(pg, insert_traacs_2010_query)

# clean up
if (dbExistsTable(pg, c('survey200', 'temp_traacs'))) dbRemoveTable(pg, c('survey200', 'temp_traacs')) # clean up
