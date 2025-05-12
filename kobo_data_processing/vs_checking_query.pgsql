-- hedges

\COPY (
SELECT
    sites.site_code,
    sites.research_focus,
    sampling_events.samp_date,
    EXTRACT (YEAR FROM sampling_events.samp_date) AS year,
    vegetation_samples.survey_type,
    vegetation_survey_hedges.*,
    vegetation_taxon_list.vegetation_scientific_name
FROM survey200.sampling_events
JOIN survey200.sampling_events_vegetation_samples ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.vegetation_samples ON (sampling_events_vegetation_samples.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sites ON (sampling_events.site_id = sites.site_id)
JOIN survey200.vegetation_survey_hedges ON (vegetation_survey_hedges.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
LEFT JOIN survey200.vegetation_taxon_list ON (vegetation_taxon_list.vegetation_taxon_id = vegetation_samples.vegetation_taxon_id)
) TO '/tmp/vs_checking_query.csv' WITH DELIMITER ',' csv header
;

-- shrubs

\COPY (
SELECT
    sites.site_code,
    sites.research_focus,
    sampling_events.samp_date,
    EXTRACT (YEAR FROM sampling_events.samp_date) AS year,
    vegetation_samples.survey_type,
    survey200.vegetation_survey_shrub_perennials.*,
    vegetation_taxon_list.vegetation_scientific_name
FROM survey200.sampling_events
JOIN survey200.sampling_events_vegetation_samples ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.vegetation_samples ON (sampling_events_vegetation_samples.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sites ON (sampling_events.site_id = sites.site_id)
JOIN survey200.vegetation_survey_shrub_perennials ON (vegetation_survey_shrub_perennials.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
LEFT JOIN survey200.vegetation_taxon_list ON (vegetation_taxon_list.vegetation_taxon_id = vegetation_samples.vegetation_taxon_id)
) TO '/tmp/vs_checking_query.csv' WITH DELIMITER ',' csv header
;



-- HOW ARE SHRUBS COUNTED IN PARCELS AND PLOTS?

-- there are not any parcel data in the vegetation_survey_hedges table; there
-- are only 144 records in the hedges table and all are plots

-- hedges are recorded as survey_type count in the vegetation_samples table with
-- a count of 0, however, this is the case only for 2010, where are the 2015
-- data?

\COPY (
SELECT
    sites.site_code,
    sites.research_focus,
    sampling_events.samp_date,
    vegetation_samples.survey_type,
    vegetation_survey_hedges.*
FROM survey200.sampling_events
JOIN survey200.sampling_events_vegetation_samples ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.vegetation_samples ON (sampling_events_vegetation_samples.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sites ON (sampling_events.site_id = sites.site_id)
JOIN survey200.vegetation_survey_hedges ON (vegetation_survey_hedges.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
-- ) to '/tmp/hedges.csv' with DELIMITER ',' csv header
;


\COPY (
SELECT
    sites.site_code,
    sites.research_focus,
    sampling_events.samp_date,
    vegetation_samples.survey_type,
    vegetation_samples.vegetation_sample_id AS vs_vsi,
    vegetation_survey_plant_counts.vegetation_sample_id AS vspc_vsi,
    vegetation_survey_plant_counts.plant_count_type_id,
    cv_plant_count_survey_types.plant_count_type_code,
    vegetation_survey_plant_counts.count_survey_value,
    vegetation_samples.vegetation_taxon_id,
    vegetation_taxon_list.vegetation_scientific_name
FROM survey200.sampling_events
JOIN survey200.sampling_events_vegetation_samples ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.vegetation_samples ON (sampling_events_vegetation_samples.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sites ON (sampling_events.site_id = sites.site_id)
LEFT JOIN survey200.vegetation_survey_plant_counts ON (vegetation_survey_plant_counts.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.cv_plant_count_survey_types ON (cv_plant_count_survey_types.plant_count_type_id = vegetation_survey_plant_counts.plant_count_type_id)
LEFT JOIN survey200.vegetation_taxon_list ON (vegetation_taxon_list.vegetation_taxon_id = vegetation_samples.vegetation_taxon_id)
) TO '/tmp/vs_checking_query.csv' WITH DELIMITER ',' CSV HEADER
;

SELECT
    sites.site_code,
    sites.research_focus,
    sampling_events.samp_date,
    vegetation_samples.survey_type,
    vegetation_survey_plant_counts.plant_count_id,
    vegetation_samples.vegetation_sample_id AS vs_vsi,
    vegetation_survey_plant_counts.vegetation_sample_id AS vspc_vsi,
    vegetation_survey_plant_counts.count_survey_value,
    vegetation_survey_plant_counts.plant_count_type_id,
    cv_plant_count_survey_types.plant_count_type_code,
    vegetation_samples.vegetation_taxon_id,
    vegetation_taxon_list.vegetation_scientific_name
FROM survey200.sampling_events
JOIN survey200.sampling_events_vegetation_samples ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.vegetation_samples ON (sampling_events_vegetation_samples.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sites ON (sampling_events.site_id = sites.site_id)
LEFT JOIN survey200.vegetation_survey_plant_counts ON (vegetation_survey_plant_counts.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.cv_plant_count_survey_types ON (cv_plant_count_survey_types.plant_count_type_id = vegetation_survey_plant_counts.plant_count_type_id)
LEFT JOIN survey200.vegetation_taxon_list ON (vegetation_taxon_list.vegetation_taxon_id = vegetation_samples.vegetation_taxon_id)
WHERE
    sites.research_focus = 'parcel'
    AND EXTRACT (YEAR FROM sampling_events.samp_date) = 2010
    AND cv_plant_count_survey_types.plant_count_type_code = 'hedge'
    AND vegetation_survey_plant_counts.count_survey_value = 0
;

-- left off here, modify the below query to delete the above 707 records
-- vegetation_survey_plant_counts is the problematic table
-- the below is no final and addresses the 2010 data problem

DELETE FROM survey200.vegetation_survey_plant_counts WHERE plant_count_id IN (
    SELECT
        vegetation_survey_plant_counts.plant_count_id
    FROM survey200.sampling_events
    JOIN survey200.sampling_events_vegetation_samples ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
    JOIN survey200.vegetation_samples ON (sampling_events_vegetation_samples.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
    JOIN survey200.sites ON (sampling_events.site_id = sites.site_id)
    LEFT JOIN survey200.vegetation_survey_plant_counts ON (vegetation_survey_plant_counts.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
    JOIN survey200.cv_plant_count_survey_types ON (cv_plant_count_survey_types.plant_count_type_id = vegetation_survey_plant_counts.plant_count_type_id)
    WHERE
        sites.research_focus = 'parcel'
        AND EXTRACT (YEAR FROM sampling_events.samp_date) = 2010
        AND cv_plant_count_survey_types.plant_count_type_code = 'hedge'
        AND vegetation_survey_plant_counts.count_survey_value = 0
)
;
-- should delete 707


-- why are there so many years*sites when there are shrubs but not counts?
-- there are quite a few but i seem have just been unlucky in the sites that i
-- selected as there are not really that many
-- comparison of these pulls addressed in visidata

\COPY (
SELECT
    sites.site_code,
    sampling_events.samp_date,
    vegetation_samples.survey_type,
    count(*) AS counts_count
FROM survey200.sampling_events
JOIN survey200.sampling_events_vegetation_samples ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.vegetation_samples ON (sampling_events_vegetation_samples.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sites ON (sampling_events.site_id = sites.site_id)
LEFT JOIN survey200.vegetation_survey_plant_counts ON (vegetation_survey_plant_counts.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.cv_plant_count_survey_types ON (cv_plant_count_survey_types.plant_count_type_id = vegetation_survey_plant_counts.plant_count_type_id)
LEFT JOIN survey200.vegetation_taxon_list ON (vegetation_taxon_list.vegetation_taxon_id = vegetation_samples.vegetation_taxon_id)
WHERE
    sites.research_focus = 'survey200'
GROUP BY
    sites.site_code,
    sampling_events.samp_date,
    vegetation_samples.survey_type
) TO '/tmp/counts_counts.csv' WITH DELIMITER ',' CSV HEADER
;

\COPY (
SELECT
    sites.site_code,
    sampling_events.samp_date,
    vegetation_samples.survey_type,
    count(*) AS hedges_count
FROM survey200.sampling_events
JOIN survey200.sampling_events_vegetation_samples ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.vegetation_samples ON (sampling_events_vegetation_samples.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sites ON (sampling_events.site_id = sites.site_id)
JOIN survey200.vegetation_survey_hedges ON (vegetation_survey_hedges.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
GROUP BY
    sites.site_code,
    sampling_events.samp_date,
    vegetation_samples.survey_type
) TO '/tmp/hedges_counts.csv' WITH DELIMITER ',' CSV HEADER
;

-- SCRATCH

DROP VIEW IF EXISTS 
survey200.public_lens_survey200_vegetation_annuals,
survey200.public_lens_survey200_vegetation_cacti_succs,
survey200.public_lens_survey200_vegetation_hedges,
survey200.public_lens_survey200_vegetation_shrub_perennials,
survey200.public_lens_survey200_vegetation_trees
;

UPDATE survey200.vegetation_samples
SET herbarium_voucher_code = 
  CASE
    WHEN herbarium_voucher_code = 'true' THEN 'TRUE'
    WHEN herbarium_voucher_code = 'yes' THEN 'TRUE'
    WHEN herbarium_voucher_code = 'no' THEN 'FALSE'
    ELSE herbarium_voucher_code
END
;

ALTER TABLE survey200.vegetation_samples
ALTER COLUMN herbarium_voucher_code TYPE BOOLEAN USING 
  CASE
    WHEN herbarium_voucher_code = 'TRUE' THEN TRUE
    WHEN herbarium_voucher_code = 'FALSE' THEN FALSE
    ELSE NULL
  END
;

-- \COPY (
SELECT
    sites.site_code,
    sampling_events.samp_date,
    vegetation_samples.survey_type,
    -- vegetation_survey_shrub_perennials.*
    -- cv_vegetation_classifications.vegetation_classification_id,
    -- cv_vegetation_classifications.vegetation_classification_code,
    -- cv_vegetation_shapes.vegetation_shape_id,
    -- cv_vegetation_shapes.vegetation_shape_code
FROM survey200.sampling_events
JOIN survey200.sampling_events_vegetation_samples ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.vegetation_samples ON (sampling_events_vegetation_samples.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sites ON (sampling_events.site_id = sites.site_id)
-- JOIN survey200.vegetation_survey_shrub_perennials ON (vegetation_survey_shrub_perennials.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
-- LEFT JOIN survey200.cv_vegetation_classifications ON (cv_vegetation_classifications.vegetation_classification_id = vegetation_survey_shrub_perennials.vegetation_classification_id)
-- JOIN survey200.cv_vegetation_shapes ON (cv_vegetation_shapes.vegetation_shape_id = vegetation_survey_shrub_perennials.vegetation_shape_id)
WHERE vegetation_samples.vegetation_sample_id = 30680
-- ) TO '/tmp/shrub_survey.csv' WITH DELIMITER ',' CSV HEADER
;


\COPY (
SELECT
    sites.site_code,
    sites.research_focus,
    sampling_events.samp_date,
    EXTRACT (YEAR FROM sampling_events.samp_date)::INTEGER AS year,
    vegetation_samples.survey_type,
    vegetation_samples.vegetation_sample_id,
    vegetation_survey_plant_counts.plant_count_id,
    vegetation_survey_plant_counts.hedge,
    vegetation_survey_plant_counts.count_survey_value,
    cv_plant_count_survey_types.plant_count_type_code,
    vegetation_taxon_list.vegetation_scientific_name
FROM survey200.sampling_events
JOIN survey200.sampling_events_vegetation_samples ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.vegetation_samples ON (sampling_events_vegetation_samples.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sites ON (sampling_events.site_id = sites.site_id)
JOIN survey200.vegetation_survey_plant_counts ON (vegetation_survey_plant_counts.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.cv_plant_count_survey_types ON (cv_plant_count_survey_types.plant_count_type_id = vegetation_survey_plant_counts.plant_count_type_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_taxon_list.vegetation_taxon_id = vegetation_samples.vegetation_taxon_id)
) TO '/tmp/counts.csv' WITH DELIMITER ',' CSV HEADER
;


\COPY (
SELECT
    sampling_events.samp_date,
    sites.site_code,
    sites.research_focus,
    survey200.vegetation_survey_trees.*,
    vegetation_taxon_list.vegetation_scientific_name
FROM survey200.sampling_events
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
JOIN survey200.sampling_events_vegetation_samples ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.vegetation_survey_trees ON (vegetation_survey_trees.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_taxon_list.vegetation_taxon_id = vegetation_samples.vegetation_taxon_id)
WHERE EXTRACT (YEAR FROM sampling_events.samp_date) = 2023
) TO '/tmp/fromdb.csv' WITH DELIMITER ',' CSV HEADER
;

-- BEGIN VTL WORK

WITH Used_taxa AS (
SELECT 
DISTINCT vegetation_taxon_id
FROM (
  SELECT
    vegetation_taxon_id
  FROM survey200.vegetation_samples
  UNION
  SELECT
    vegetation_taxon_id
  FROM survey200.sweepnet_samples
)
)
SELECT
  used_taxa.vegetation_taxon_id,
  vegetation_taxon_list.vegetation_scientific_name
FROM used_taxa
RIGHT JOIN survey200.vegetation_taxon_list ON (
  used_taxa.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id
)
WHERE 
used_taxa.vegetation_taxon_id IS NULL
;

-- only two records in the VTL are not used
-- vegetation_taxon_id vegetation_scientific_name
-- null	              Thymophylla tenuiloba
-- null	              Paraglomus


SELECT
  max(samp_date)
  -- vegetation_survey_cacti_succ.*,
  -- DISTINCT (vegetation_taxon_list.vegetation_scientific_name)
FROM survey200.vegetation_survey_cacti_succ
JOIN survey200.vegetation_samples ON (survey200.vegetation_samples.vegetation_sample_id = survey200.vegetation_survey_cacti_succ.vegetation_sample_id)
JOIN survey200.vegetation_taxon_list ON (survey200.vegetation_taxon_list.vegetation_taxon_id = survey200.vegetation_samples.vegetation_taxon_id)
JOIN survey200.sampling_events_vegetation_samples ON (survey200.sampling_events_vegetation_samples.vegetation_sample_id = survey200.vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (survey200.sampling_events.survey_id = survey200.sampling_events_vegetation_samples.survey_id)
-- ORDER BY vegetation_scientific_name
;

-- cacti were last added in 2010

SELECT
  sampling_events.samp_date,
  vegetation_samples.tablet_taxon_note
FROM survey200.vegetation_samples
JOIN survey200.sampling_events_vegetation_samples ON (survey200.sampling_events_vegetation_samples.vegetation_sample_id = survey200.vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (survey200.sampling_events.survey_id = survey200.sampling_events_vegetation_samples.survey_id)
WHERE tablet_taxon_note IS NOT NULL
;

SELECT
  sampling_events.samp_date,
  vegetation_samples.tablet_taxon_note
FROM survey200.vegetation_samples
JOIN survey200.sampling_events_vegetation_samples ON (survey200.sampling_events_vegetation_samples.vegetation_sample_id = survey200.vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (survey200.sampling_events.survey_id = survey200.sampling_events_vegetation_samples.survey_id)
WHERE tablet_taxon_note = ''
;

-- tablet_taxon_note first added in 2010
-- note that there are some empty string values in that return