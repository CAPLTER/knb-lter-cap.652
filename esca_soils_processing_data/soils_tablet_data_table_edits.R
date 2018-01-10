# README ------------------------------------------------------------------

# Soil sampling information from the tablets was not transferred to the
# survey200 database during the large, post-survey transfer. We address that
# transfer here, and address edits to the soils tables to accomodate the new
# data, including adding a soils_lachat table to house raw lachat output, and a
# soils_traacs table to house raw phos data from 2010. The latter are not actual
# machine output but are the raw values pieced together from the original
# output.

# Edits have been implemented on prod as of 2017-12-29.

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


# soil samples 2015 from tablet -------------------------------------------

# delete existing columns that are insufficient to store tablet-derived data
dbExecute(pg, '
          ALTER TABLE survey200.soil_samples
          DROP COLUMN center_utm,
          DROP COLUMN north_utm,
          DROP COLUMN south_utm,
          DROP COLUMN west_utm,
          DROP COLUMN east_utm
          ;')

# add relevant columns to capture tablet descriptions and spatial details
dbExecute(pg, '
          ALTER TABLE survey200.soil_samples
          ADD COLUMN location_description_north character varying (127),
          ADD COLUMN location_description_south character varying (127),
          ADD COLUMN location_description_west character varying (127),
          ADD COLUMN location_description_east character varying (127),
          ADD COLUMN location_description_center character varying (127),
          ADD COLUMN north_utm_lat double precision,
          ADD COLUMN north_utm_long double precision,
          ADD COLUMN north_utm_altitude real,
          ADD COLUMN north_utm_accuracy real,
          ADD COLUMN south_utm_lat double precision,
          ADD COLUMN south_utm_long double precision,
          ADD COLUMN south_utm_altitude real,
          ADD COLUMN south_utm_accuracy real,
          ADD COLUMN west_utm_lat double precision,
          ADD COLUMN west_utm_long double precision,
          ADD COLUMN west_utm_altitude real,
          ADD COLUMN west_utm_accuracy real,
          ADD COLUMN east_utm_lat double precision,
          ADD COLUMN east_utm_long double precision,
          ADD COLUMN east_utm_altitude real,
          ADD COLUMN east_utm_accuracy real,
          ADD COLUMN center_utm_lat double precision,
          ADD COLUMN center_utm_long double precision,
          ADD COLUMN center_utm_altitude real,
          ADD COLUMN center_utm_accuracy real;')

# insert relevant data from gpi form
dbExecute(pg, "
          INSERT INTO survey200.soil_samples
          (
          survey_id,
          location_description_north,
          location_description_south,
          location_description_west,
          location_description_east,
          location_description_center,
          north_utm_lat,
          north_utm_long,
          north_utm_altitude,
          north_utm_accuracy,
          south_utm_lat,
          south_utm_long,
          south_utm_altitude,
          south_utm_accuracy,
          west_utm_lat,
          west_utm_long,
          west_utm_altitude,
          west_utm_accuracy,
          east_utm_lat,
          east_utm_long,
          east_utm_altitude,
          east_utm_accuracy,
          center_utm_lat,
          center_utm_long,
          center_utm_altitude,
          center_utm_accuracy
          )
          (
          SELECT
          survey_id,
          soil_samples_location_description_north,
          soil_samples_location_description_south,
          soil_samples_location_description_west,
          soil_samples_location_description_east,
          soil_samples_location_description_center,
          soil_samples_north_utm_latitude,
          soil_samples_north_utm_longitude,
          soil_samples_north_utm_altitude,
          soil_samples_north_utm_accuracy,
          soil_samples_south_utm_latitude,
          soil_samples_south_utm_longitude,
          soil_samples_south_utm_altitude,
          soil_samples_south_utm_accuracy,
          soil_samples_west_utm_latitude,
          soil_samples_west_utm_longitude,
          soil_samples_west_utm_altitude,
          soil_samples_west_utm_accuracy,
          soil_samples_east_utm_latitude,
          soil_samples_east_utm_longitude,
          soil_samples_east_utm_altitude,
          soil_samples_east_utm_accuracy,
          soil_samples_center_utm_latitude,
          soil_samples_center_utm_longitude,
          soil_samples_center_utm_altitude,
          soil_samples_center_utm_accuracy
          FROM s200_tablet.gpi
          WHERE s_research_focus = 'survey200');")


# soils table edits -------------------------------------------------------

# create table to house raw lachat data
dbExecute(pg, '
          CREATE TABLE survey200.soil_lachat
          (
          id serial,
          soil_sample_id integer,
          deep_core_type text,
          sample_id text,
          sample_type text,
          replicate_number integer,
          repeat_number integer,
          cup_number text,
          manual_dilution_factor integer,
          auto_dilution_factor integer,
          weight_units text,
          weight text,
          units text,
          detection_date date,
          detection_time text,
          user_name text,
          run_file_name text,
          description text,
          channel_number integer,
          analyte_name text,
          peak_concentration double precision,
          determined_conc double precision,
          concentration_units text,
          peak_area double precision,
          peak_height double precision,
          calibration_equation text,
          retention_time double precision,
          inject_to_peak_start double precision,
          conc_x_adf double precision,
          conc_x_mdf double precision,
          conc_x_adf_x_mdf double precision
          )
          WITH (
          OIDS=FALSE
          );')


# David has very finely prescribed the size of the database fields, which is
# creating an acute problem here where there are 5-digit conductivity value,
# which is larger than David's asssigned numeric(4,3) type for conductivity.
# Change to type double to resolve this. In order to do this, however, we need
# to drop a view that references that field as you cannot change a field type
# when there is a view employing that field. The create view statement is saved
# and the view can be recreated if needed (though hard to imagine that
# scenario). A similar situtation for phosphate data in the perimeter cores
# data. The SQL behind these base lenses was preserved for posterity but the
# views are now dropped from the database.
dbExecute(pg,'DROP VIEW survey200.public_lens_survey200_soil_physical_properties;')
dbExecute(pg,'
          ALTER TABLE survey200.soil_center_cores 
            ALTER COLUMN conductivity TYPE DOUBLE PRECISION;')

dbExecute(pg,'DROP VIEW survey200.public_lens_survey200_soil_chemical_properties;')
dbExecute(pg,'
          ALTER TABLE survey200.soil_perimeter_cores 
            ALTER COLUMN po4_p TYPE DOUBLE PRECISION;')
dbExecute(pg,'
          ALTER TABLE survey200.soil_perimeter_cores 
            ALTER COLUMN no3_n TYPE DOUBLE PRECISION;')

# add a field to note the survey year for the new soil_lachat table that houses
# raw soil lachat data
dbExecute(pg,'
          ALTER TABLE survey200.soil_lachat 
            ADD COLUMN survey_year integer;')


# create table to house unearthed 2010 TRAACS data. These are not machine output
# but are the raw phos data from 2010 pieced together by Roy

dbExecute(pg,'
CREATE TABLE survey200.soil_traacs
(

  id serial,
  soil_sample_id integer,
  deep_core_type text,
  sample_sequence integer,
  sample_id text,
  sample_set integer,
  phos_mg_l double precision
)
WITH (
  OIDS=FALSE
);')

dbExecute(pg,'comment on table survey200.soil_traacs is \'raw 2010 phosphorus pieced together from traacs output\';')
