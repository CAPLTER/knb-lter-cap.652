# README ------------------------------------------------------------------

# Raw Lachat data for 2010 nitrogen have been added to the database per this
# workflow, as have 2010 phosphorus pieced together from traacs output.

# Raw 2005 phos TRAACS data have been added to the database.

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


# update existing traacs database table -----------------------------------

# had not realized that 2005 raw data would become available, so need some extra
# info to help distinguish raw data from one year to another
dbExecute(pg, '
          ALTER TABLE survey200.soil_traacs
            ADD COLUMN survey_year integer;
          
          UPDATE survey200.soil_traacs
            SET survey_year = 2010;')

dbExecute(pg, '
          ALTER TABLE survey200.soil_traacs
            ADD COLUMN analyte text;
          
          UPDATE survey200.soil_traacs 
            SET analyte = \'phosphorus\';')


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
                            EXTRACT (YEAR FROM se.samp_date) = 2005;") %>% 
  mutate(site_code = ifelse(site_code == 'L71', 'L7', site_code))
  # mutate(site_code = str_sub(site_code, 1, str_length(site_code) - 1)) # strip off the trailing 1


# perimeter, raw traacs data ----------------------------------------------

raw_traacs_phosphorus <- bind_rows(
  read_excel('./esca_soils_processing_data/soils2005/S200 2005 SRP Traacs raw data.xls', sheet = 1) %>% 
    mutate(sample_set = 1),
  read_excel('./esca_soils_processing_data/soils2005/S200 2005 SRP Traacs raw data.xls', sheet = 2) %>% 
    mutate(sample_set = 2),
  read_excel('./esca_soils_processing_data/soils2005/S200 2005 SRP Traacs raw data.xls', sheet = 3) %>% 
    mutate(sample_set = 3),
  read_excel('./esca_soils_processing_data/soils2005/S200 2005 SRP Traacs raw data.xls', sheet = 4) %>% 
    mutate(sample_set = 4),
  read_excel('./esca_soils_processing_data/soils2005/S200 2005 SRP Traacs raw data.xls', sheet = 5) %>% 
    mutate(sample_set = 5),
  read_excel('./esca_soils_processing_data/soils2005/S200 2005 SRP Traacs raw data.xls', sheet = 6) %>% 
    mutate(sample_set = 6),
  read_excel('./esca_soils_processing_data/soils2005/S200 2005 SRP Traacs raw data.xls', sheet = 7) %>% 
    mutate(sample_set = 7),
  read_excel('./esca_soils_processing_data/soils2005/S200 2005 SRP Traacs raw data.xls', sheet = 8) %>% 
    mutate(sample_set = 8),
  read_excel('./esca_soils_processing_data/soils2005/S200 2005 SRP Traacs raw data.xls', sheet = 9) %>% 
    mutate(sample_set = 9),
  read_excel('./esca_soils_processing_data/soils2005/S200 2005 SRP Traacs raw data.xls', sheet = 10) %>% 
    mutate(sample_set = 10)
) %>% 
  select(-X__1) %>% 
  mutate(
    survey_year = 2005,
    analyte = 'phosphorus'
  )

raw_traacs_phosphorus <- raw_traacs_phosphorus %>% 
  mutate(code_layer = str_extract(Sample, '^(\\S{2,5})\\s(TOP|BOT)')) %>% 
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
  left_join(soilSamples[,c("soil_sample_id", "site_code")],
            by = c("site_code")) %>%
  select(soil_sample_id, deep_core_type, sample_sequence, sample_id = sample, sample_set, phos_mg_l = `mg p/l`, survey_year, analyte)
  
dataname <- raw_traacs_phosphorus 

if (dbExistsTable(pg, c('survey200', 'temp_traacs'))) dbRemoveTable(pg, c('survey200', 'temp_traacs')) # make sure tbl does not exist
dbWriteTable(pg, c('survey200', 'temp_traacs'), value = dataname, row.names = F)

insert_traacs_2005_query <- '
INSERT INTO survey200.soil_traacs (
  soil_sample_id,
  deep_core_type,
  sample_sequence,
  sample_id,
  sample_set,
  phos_mg_l,
  survey_year,
  analyte
)
(
  SELECT
    soil_sample_id,
    deep_core_type,
    sample_sequence,
    sample_id,
    sample_set,
    phos_mg_l,
    survey_year,
    analyte
  FROM survey200.temp_traacs 
);'

# insert data
dbExecute(pg, insert_traacs_2005_query)

# clean up
if (dbExistsTable(pg, c('survey200', 'temp_traacs'))) dbRemoveTable(pg, c('survey200', 'temp_traacs')) # clean up
