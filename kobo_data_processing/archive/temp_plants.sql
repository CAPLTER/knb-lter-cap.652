
-- 1431 Carnegiea gigantea; 3235 Carnegiea
-- but gigantea is the only species of Carnegiea
SELECT *
from survey200.vegetation_taxon_list
WHERE vegetation_scientific_name ~~* '%carneg%'
;

SELECT *
FROM survey200.vegetation_samples
WHERE vegetation_taxon_id IN (3235)
;

-- n = 167
SELECT *
FROM survey200.vegetation_survey_cacti_succ
WHERE vegetation_sample_id IN (
  SELECT vegetation_sample_id
  FROM survey200.vegetation_samples
  WHERE vegetation_taxon_id = 1431
  )
  ;

-- n = 2456
SELECT *
FROM survey200.vegetation_survey_cacti_succ
WHERE vegetation_sample_id IN (
  SELECT vegetation_sample_id
  FROM survey200.vegetation_samples
  WHERE vegetation_taxon_id != 1431
  )
  ;


-- 2623
SELECT count(*) FROM survey200.vegetation_survey_cacti_succ ;

-- \copy (select * from survey200.vegetation_survey_cacti_succ) to '/tmp/cacti.csv' csv header ;

-- cacti except Carniegea gigantea and not parcels (a 2010 issue) to shrubs (n = 2268)
INSERT INTO survey200.vegetation_survey_shrub_perennials (
  vegetation_sample_id,
  vegetation_classification_id,
  height,
  height_distance,
  height_degree_up,
  height_degree_down,
  width_ns,
  width_ew,
  distance_ns,
  direction_ns,
  distance_ew,
  direction_ew
)
SELECT
  vegetation_sample_id,
  vegetation_classification_id,
  height,
  height_distance,
  height_degree_down,
  height_degree_up,
  width_ns,
  width_ew,
  distance_ns,
  direction_ns,
  distance_ew,
  direction_ew
FROM survey200.vegetation_survey_cacti_succ
WHERE cacti_id IN (
  SELECT
    vegetation_survey_cacti_succ.cacti_id
  FROM
    survey200.vegetation_survey_cacti_succ
  JOIN survey200.vegetation_samples ON (vegetation_survey_cacti_succ.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
  JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
  JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
  WHERE
    vegetation_taxon_list.vegetation_taxon_id != 1431 AND
    sites.research_focus ~~* 'survey200'
  )
;

-- cacti only Carniegea gigantea to trees (n = 158)
INSERT INTO survey200.vegetation_survey_trees (
  vegetation_sample_id,
  vegetation_classification_id,
  stem_diameter_at,
  stem_diameter,
  height_distance,
  height_degree_down,
  height_degree_up,
  height_in_m,
  crown_width_ns,
  crown_width_ew,
  distance_ns,
  direction_ns,
  distance_ew,
  direction_ew
)
SELECT
  vegetation_sample_id,
  vegetation_classification_id,
  stem_height,
  stem_diameter,
  height_distance,
  height_degree_down,
  height_degree_up,
  height,
  width_ns,
  width_ew,
  distance_ns,
  direction_ns,
  distance_ew,
  direction_ew
FROM survey200.vegetation_survey_cacti_succ
WHERE cacti_id IN (
  SELECT
    vegetation_survey_cacti_succ.cacti_id
  FROM
    survey200.vegetation_survey_cacti_succ
  JOIN survey200.vegetation_samples ON (vegetation_survey_cacti_succ.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
  JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
  JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
  WHERE
    vegetation_taxon_list.vegetation_taxon_id = 1431 AND
    sites.research_focus ~~* 'survey200'
  )
;


-- survey200.vegetation_survey_cacti_succ
\COPY (
SELECT
  sites.site_code,
  sites.research_focus,
  sampling_events.samp_date,
  vegetation_samples.vegetation_taxon_id,
  vegetation_taxon_list.vegetation_scientific_name,
  vegetation_survey_cacti_succ.*
FROM
  survey200.vegetation_survey_cacti_succ
JOIN survey200.vegetation_samples ON (vegetation_survey_cacti_succ.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
) TO '/tmp/cacti.csv' CSV HEADER
;


-- survey200.vegetation_survey_shrub_perennials
\COPY (
SELECT
  sites.site_code,
  sites.research_focus,
  sampling_events.samp_date,
  vegetation_taxon_list.vegetation_scientific_name,
  vegetation_survey_shrub_perennials.*,
  vegetation_samples.survey_type
FROM
  survey200.vegetation_survey_shrub_perennials
JOIN survey200.vegetation_samples ON (vegetation_survey_shrub_perennials.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
) TO '/tmp/shrubs.csv' CSV HEADER
;

-- survey200.vegetation_survey_shrub_perennials FOR THE REPO
\COPY (
SELECT
  sites.site_code,
  sites.research_focus,
  sampling_events.samp_date,
  vegetation_taxon_list.vegetation_scientific_name,
  vegetation_survey_shrub_perennials.*,
  cv_vegetation_classifications.vegetation_classification_code,
  cv_vegetation_shapes.vegetation_shape_code
FROM
  survey200.vegetation_survey_shrub_perennials
JOIN survey200.vegetation_samples ON (vegetation_survey_shrub_perennials.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
LEFT JOIN survey200.cv_vegetation_classifications ON (vegetation_survey_shrub_perennials.vegetation_classification_id = cv_vegetation_classifications.vegetation_classification_id)
LEFT JOIN survey200.cv_vegetation_shapes ON (vegetation_survey_shrub_perennials.vegetation_shape_id = cv_vegetation_shapes.vegetation_shape_id)
WHERE
  sites.research_focus = 'survey200'
) TO '/tmp/shrubs.csv' CSV HEADER
;

-- survey200.vegetation_survey_shrub_perennials
\COPY (
WITH shrubs AS (
SELECT
  sites.site_code,
  sites.research_focus,
  sampling_events.samp_date,
  EXTRACT (YEAR FROM sampling_events.samp_date) AS year,
  vegetation_taxon_list.vegetation_scientific_name,
  vegetation_survey_shrub_perennials.*
FROM
  survey200.vegetation_survey_shrub_perennials
JOIN survey200.vegetation_samples ON (vegetation_survey_shrub_perennials.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
)
SELECT DISTINCT
  site_code,
  research_focus,
  year,
  vegetation_scientific_name
FROM shrubs
) TO '/tmp/unique_shrubs.csv' CSV HEADER
;


-- survey200.vegetation_survey_trees
\COPY (
SELECT
  sites.site_code,
  sites.research_focus,
  sampling_events.samp_date,
  vegetation_taxon_list.vegetation_scientific_name,
  vegetation_survey_trees.*
FROM
  survey200.vegetation_survey_trees
JOIN survey200.vegetation_samples ON (vegetation_survey_trees.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
) TO '/tmp/trees.csv' CSV HEADER
;

-- survey200.vegetation_survey_trees for the REPO
\COPY (
SELECT
  sites.site_code,
  sites.research_focus,
  sampling_events.samp_date,
  vegetation_taxon_list.vegetation_scientific_name,
  vegetation_samples.vegetation_taxon_id,
  vegetation_survey_trees.*,
  cv_vegetation_classifications.vegetation_classification_code,
  cv_vegetation_shapes.vegetation_shape_code
FROM
  survey200.vegetation_survey_trees
JOIN survey200.vegetation_samples ON (vegetation_survey_trees.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
LEFT JOIN survey200.cv_vegetation_classifications ON (vegetation_survey_trees.vegetation_classification_id = cv_vegetation_classifications.vegetation_classification_id)
LEFT JOIN survey200.cv_vegetation_shapes ON (vegetation_survey_trees.vegetation_shape_id = cv_vegetation_shapes.vegetation_shape_id)
) TO '/tmp/trees.csv' CSV HEADER
;

-- survey200.vegetation_survey_plant_counts
\COPY (
SELECT
  sites.site_code,
  sites.research_focus,
  sampling_events.samp_date,
  vegetation_taxon_list.vegetation_scientific_name,
  vegetation_survey_plant_counts.*,
  cv_plant_count_survey_types.plant_count_type_code
FROM
  survey200.vegetation_survey_plant_counts
JOIN survey200.vegetation_samples ON (vegetation_survey_plant_counts.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
LEFT JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
LEFT JOIN survey200.cv_plant_count_survey_types ON (cv_plant_count_survey_types.plant_count_type_id = vegetation_survey_plant_counts.plant_count_type_id)
) TO '/tmp/counts.csv' CSV HEADER
;

-- we will need to know the plant_count_type_id for parcels so this will only work for plots
\COPY (
WITH count_sums AS (
SELECT
  sampling_events.survey_id,
  vegetation_samples.vegetation_taxon_id,
  SUM(vegetation_survey_plant_counts.count_survey_value) AS number_plants
FROM
  survey200.vegetation_survey_plant_counts
JOIN survey200.vegetation_samples ON (vegetation_survey_plant_counts.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
WHERE
  vegetation_survey_plant_counts.vegetation_sample_id NOT IN (
    28952,
    28951,
    28949,
    28950,
    28944,
    28946,
    28943,
    28953,
    28947,
    28948,
    28945,
    28587,
    28586,
    28028,
    28025,
    28031,
    28027,
    28023,
    28026,
    28024,
    29344,
    28032,
    28029
)
GROUP BY
  sampling_events.survey_id,
  vegetation_samples.vegetation_taxon_id
)
SELECT
  sites.site_code,
  sampling_events.samp_date AS sample_date,
  vegetation_taxon_list.vegetation_scientific_name,
  count_sums.number_plants
FROM count_sums
JOIN survey200.sampling_events ON (sampling_events.survey_id = count_sums.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_taxon_list.vegetation_taxon_id = count_sums.vegetation_taxon_id)
WHERE
  sites.research_focus = 'survey200' AND
  count_sums.number_plants > 0
ORDER BY
  sampling_events.samp_date,
  sites.site_code
) TO '/tmp/plot_counts.csv' CSV HEADER
;


-- distinct survey200.vegetation_survey_plant_counts
\COPY (
WITH counts AS (
  SELECT
    sites.site_code,
    sites.research_focus,
    sampling_events.samp_date,
    EXTRACT (YEAR FROM sampling_events.samp_date) AS year,
    vegetation_taxon_list.vegetation_scientific_name,
    vegetation_survey_plant_counts.*,
    cv_plant_count_survey_types.plant_count_type_code
  FROM
    survey200.vegetation_survey_plant_counts
  JOIN survey200.vegetation_samples ON (vegetation_survey_plant_counts.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
  JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
  JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
  JOIN survey200.cv_plant_count_survey_types ON (cv_plant_count_survey_types.plant_count_type_id = vegetation_survey_plant_counts.plant_count_type_id)
)
SELECT DISTINCT
  site_code,
  research_focus,
  year,
  vegetation_scientific_name
FROM counts
) TO '/tmp/unique_counts.csv' CSV HEADER
;

 
-- hedges FROM repo
SELECT
  se.samp_date AS sample_date,
  s.site_code,
  -- s.research_focus,
  -- vs.vegetation_sample_id,
  -- vs.herbarium_voucher_code,
  -- vs.sample_identified,
  -- vs.vegetation_taxon_id,
  vtl.vegetation_scientific_name,
  vtl.common_name,
  -- vs.survey_type,
  cvvs.vegetation_shape_code,
  vsh.stem_diam,
  -- vsh.height,
  CASE
    WHEN vsh.height_distance IS NULL THEN vsh.height
    WHEN vsh.height_distance IS NOT NULL THEN NULL
  END AS height_measured,
  vsh.height_distance,
  vsh.height_degree_up,
  vsh.height_degree_down,
  vsh.width,
  vsh.length,
  vsh.crown_height,
  vsh.percent_missing,
  vsh.hedge_condition,
  vsh.number_of_plants --,
-- vsh.distance_ns,
-- vsh.direction_ns,
-- vsh.distance_ew,
-- vsh.direction_ew
FROM
survey200.sampling_events se
JOIN survey200.sites s ON se.site_id = s.site_id
JOIN survey200.sampling_events_vegetation_samples sevs ON se.survey_id = sevs.survey_id
JOIN survey200.vegetation_samples vs ON sevs.vegetation_sample_id = vs.vegetation_sample_id
LEFT JOIN survey200.vegetation_taxon_list vtl ON vs.vegetation_taxon_id = vtl.vegetation_taxon_id
JOIN survey200.vegetation_survey_hedges vsh ON vs.vegetation_sample_id = vsh.vegetation_sample_id
LEFT JOIN survey200.cv_vegetation_shapes cvvs ON vsh.vegetation_shape_id = cvvs.vegetation_shape_id
WHERE
s.research_focus::text = 'survey200'
-- s.research_focus::text = ?researchFocus
--AND vs.survey_type::text = 'hedge'::text
ORDER BY
EXTRACT (YEAR FROM se.samp_date),
s.site_code
;


-- ## hedges

-- hedges table
\COPY (
SELECT
  sites.site_code,
  sites.research_focus,
  sampling_events.samp_date,
  vegetation_taxon_list.vegetation_scientific_name,
  vegetation_survey_hedges.*,
  cv_vegetation_classifications.vegetation_classification_code,
  cv_vegetation_shapes.vegetation_shape_code
FROM
  survey200.vegetation_survey_hedges
JOIN survey200.vegetation_samples ON (vegetation_survey_hedges.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
LEFT JOIN survey200.cv_vegetation_classifications ON (vegetation_survey_hedges.vegetation_classification_id = cv_vegetation_classifications.vegetation_classification_id)
LEFT JOIN survey200.cv_vegetation_shapes ON (vegetation_survey_hedges.vegetation_shape_id = cv_vegetation_shapes.vegetation_shape_id)
) TO '/tmp/hedges_table.csv' CSV HEADER
;


-- vs hedges
\COPY (
SELECT
  sites.site_code,
  sites.research_focus,
  sampling_events.samp_date,
  vegetation_taxon_list.vegetation_scientific_name,
  vegetation_samples.*
FROM
  survey200.vegetation_samples
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
WHERE
  vegetation_samples.survey_type = 'hedge'
) TO '/tmp/hedges_vs.csv' CSV HEADER
;


-- counts hedges
\COPY (
SELECT
  sites.site_code,
  sites.research_focus,
  sampling_events.samp_date,
  vegetation_taxon_list.vegetation_scientific_name,
  vegetation_survey_plant_counts.*,
  cv_plant_count_survey_types.plant_count_type_code
FROM
  survey200.vegetation_survey_plant_counts
JOIN survey200.vegetation_samples ON (vegetation_survey_plant_counts.vegetation_sample_id = vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
LEFT JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
LEFT JOIN survey200.cv_plant_count_survey_types ON (cv_plant_count_survey_types.plant_count_type_id = vegetation_survey_plant_counts.plant_count_type_id)
WHERE
  vegetation_survey_plant_counts.hedge IS TRUE
) TO '/tmp/hedges_counts.csv' CSV HEADER
;


-- how do data in individual tables compare to VS?
\COPY (SELECT * FROM survey200.vegetation_samples) TO '/tmp/vs.csv' CSV HEADER ;

\COPY (
SELECT
  vegetation_sample_id,
  'hedge' AS source
FROM survey200.vegetation_survey_hedges
UNION
SELECT
  vegetation_sample_id,
  'count' AS source
FROM survey200.vegetation_survey_plant_counts
UNION
SELECT
  vegetation_sample_id,
  'shrub' AS source
FROM survey200.vegetation_survey_shrub_perennials
UNION
SELECT
  vegetation_sample_id,
  'tree' AS source
FROM survey200.vegetation_survey_trees
) TO '/tmp/surveys.csv' CSV HEADER
;

-- all survey table entries have a vs_id; of the vs records without a
-- corresponding survey table entry, most are annuals and cacti, which is
-- expected since annuals do not have a survey table and cacti were moved to
-- shrubs and trees

SURVEY_TYPE ,COUNT
annual      ,11042
cacti       ,197
count       ,24
shrub       ,20
hedge       ,1


vegetation_sample_id,source,survey_type
453,,count
7564,,count
7865,,count
7866,,count
8192,,count
15276,,count
15747,,count
15749,,count
15750,,count
15751,,count
15752,,count
15753,,count
16150,,count
17433,,count
17628,,count
19859,,count
20023,,count
21993,,count
22507,,count
22737,,count
22738,,count
23411,,count
30294,,shrub
30535,,shrub
30678,,shrub
30934,,shrub
30936,,shrub
30937,,shrub
30938,,shrub
30939,,shrub
30949,,shrub
30950,,shrub
30961,,shrub
30962,,shrub
30963,,shrub
30964,,shrub
30965,,shrub
30966,,shrub
30967,,shrub
31221,,shrub
31547,,shrub
31548,,shrub
31581,,hedge
32688,,count
33276,,count

-- In the case of Lycium W19 plot 2023-03-08, for example, this plant count had
-- an id in vs but not a corresponding record in the counts table as the count
-- value was null.

-- \COPY (
SELECT
  sites.site_code,
  sites.research_focus,
  sampling_events.samp_date,
  vegetation_taxon_list.vegetation_scientific_name,
  vegetation_samples.vegetation_sample_id,
  vegetation_samples.survey_type
FROM
  survey200.vegetation_samples
JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
JOIN survey200.sampling_events ON (sampling_events_vegetation_samples.survey_id = sampling_events.survey_id)
JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
WHERE
  vegetation_samples.vegetation_sample_id IN (
    453,
    7564,
    7865,
    7866,
    8192,
    15276,
    15747,
    15749,
    15750,
    15751,
    15752,
    15753,
    16150,
    17433,
    17628,
    19859,
    20023,
    21993,
    22507,
    22737,
    22738,
    23411,
    30294,
    30535,
    30678,
    30934,
    30936,
    30937,
    30938,
    30939,
    30949,
    30950,
    30961,
    30962,
    30963,
    30964,
    30965,
    30966,
    30967,
    31221,
    31547,
    31548,
    31581,
    32688,
    33276
  )
ORDER BY
  samp_date,
  site_code,
  research_focus
-- ) TO '/tmp/cacti.csv' CSV HEADER
;

