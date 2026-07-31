\set ON_ERROR_STOP on
\pset pager off

\if :{?apply}
\else
  \set apply false
\endif

\echo 'Beginning Ball Lab 2023 arthropod import.'
\echo 'Database: ' :DBNAME
\echo 'Apply changes: ' :apply

BEGIN;

SET LOCAL lock_timeout = '10s';
SET LOCAL statement_timeout = '5min';
SET LOCAL idle_in_transaction_session_timeout = '5min';

DO $$
BEGIN
  IF to_regnamespace('survey200') IS NULL THEN
    RAISE EXCEPTION 'Required schema survey200 is unavailable';
  END IF;
END
$$;

-- This public-lens view is retired. Dropping it also permits the notes column
-- to be widened without preserving unused view metadata.
DROP VIEW IF EXISTS
  survey200.public_lens_survey200_insect_sweepnet_samples;

ALTER TABLE survey200.sweepnet_samples
  ALTER COLUMN notes TYPE text;

CREATE TEMP TABLE ball_lab_prepared (
  source_row                  integer PRIMARY KEY,
  original_date               date NOT NULL,
  corrected_date              date NOT NULL,
  site_code                   text NOT NULL,
  sweepnet_sample_type        text NOT NULL,
  original_substratum         text NOT NULL,
  vegetation_scientific_name  text NOT NULL,
  original_insect_name        text NOT NULL,
  insect_scientific_name      text NOT NULL,
  count_of_insect             integer NOT NULL,
  number_immature             integer,
  number_winged               integer,
  original_notes              text,
  replicate_number            integer,
  selected_rank               integer NOT NULL
) ON COMMIT DROP;

\copy ball_lab_prepared FROM 'database_imports/arthropods_2023_ball_lab/.prepared_arthropods_2023_ball_lab.csv' WITH (FORMAT csv, HEADER true, ENCODING 'UTF8')

DO $$
BEGIN
  IF (SELECT count(*) FROM ball_lab_prepared) <> 384
     OR (SELECT count(DISTINCT source_row) FROM ball_lab_prepared) <> 384 THEN
    RAISE EXCEPTION 'Expected 384 unique prepared rows';
  END IF;

  IF (SELECT sum(count_of_insect) FROM ball_lab_prepared) <> 5098 THEN
    RAISE EXCEPTION 'Expected total abundance 5098';
  END IF;

  IF (
    SELECT count(*)
    FROM ball_lab_prepared
    WHERE selected_rank < 1
       OR selected_rank > 3
       OR count_of_insect < 0
  ) <> 0 THEN
    RAISE EXCEPTION 'Prepared data contains invalid rank or count values';
  END IF;
END
$$;

INSERT INTO survey200.vegetation_taxon_list (
  vegetation_scientific_name
)
VALUES ('Encelia virginensis')
ON CONFLICT (vegetation_scientific_name) DO NOTHING;

INSERT INTO survey200.insect_taxon_list (
  insect_scientific_name
)
VALUES
  ('Heteroptera'),
  ('Opiliones'),
  ('Trombidiformes')
ON CONFLICT (insect_scientific_name) DO NOTHING;

-- Locate the AB10 sample by stable attributes, not by its serial ID.
CREATE TEMP TABLE ball_lab_ab10_encelia ON COMMIT DROP AS
SELECT sw.sweepnet_sample_id
FROM survey200.sweepnet_samples sw
JOIN survey200.sampling_events se USING (survey_id)
JOIN survey200.sites s USING (site_id)
JOIN survey200.vegetation_taxon_list v USING (vegetation_taxon_id)
WHERE s.site_code = 'AB10'
  AND s.research_focus = 'survey200'
  AND se.samp_date = DATE '2023-04-25'
  AND sw.sweepnet_sample_type = 'plant'
  AND v.vegetation_scientific_name IN (
    'Encelia',
    'Encelia virginensis'
  );

DO $$
BEGIN
  IF (SELECT count(*) FROM ball_lab_ab10_encelia) <> 1 THEN
    RAISE EXCEPTION
      'Expected exactly one AB10 Encelia sample on 2023-04-25';
  END IF;
END
$$;

UPDATE survey200.sweepnet_samples sw
SET vegetation_taxon_id = v.vegetation_taxon_id
FROM ball_lab_ab10_encelia target
CROSS JOIN survey200.vegetation_taxon_list v
WHERE sw.sweepnet_sample_id = target.sweepnet_sample_id
  AND v.vegetation_scientific_name = 'Encelia virginensis'
  AND sw.vegetation_taxon_id IS DISTINCT FROM v.vegetation_taxon_id;

CREATE TEMP TABLE ball_lab_taxonomy ON COMMIT DROP AS
SELECT
  p.source_row,
  v.vegetation_taxon_id,
  i.insect_taxon_id
FROM ball_lab_prepared p
LEFT JOIN survey200.vegetation_taxon_list v
  ON v.vegetation_scientific_name = p.vegetation_scientific_name
LEFT JOIN survey200.insect_taxon_list i
  ON i.insect_scientific_name = p.insect_scientific_name;

DO $$
BEGIN
  IF (
    SELECT count(*)
    FROM ball_lab_taxonomy
    WHERE vegetation_taxon_id IS NULL
       OR insect_taxon_id IS NULL
  ) <> 0 THEN
    RAISE EXCEPTION 'One or more prepared taxa failed exact resolution';
  END IF;
END
$$;

-- research_focus is part of the site natural key. It distinguishes survey200
-- sites from parcel sites that use the same visible site code.
CREATE TEMP TABLE ball_lab_events ON COMMIT DROP AS
SELECT
  p.source_row,
  se.survey_id
FROM ball_lab_prepared p
JOIN survey200.sites s
  ON s.site_code = p.site_code
 AND s.research_focus = 'survey200'
JOIN survey200.sampling_events se
  ON se.site_id = s.site_id
 AND se.samp_date = p.corrected_date;

DO $$
BEGIN
  IF (
    SELECT count(*)
    FROM (
      SELECT
        p.source_row,
        count(e.survey_id) AS matches
      FROM ball_lab_prepared p
      LEFT JOIN ball_lab_events e USING (source_row)
      GROUP BY p.source_row
      HAVING count(e.survey_id) <> 1
    ) problems
  ) <> 0 THEN
    RAISE EXCEPTION
      'One or more prepared rows failed exact sampling-event resolution';
  END IF;
END
$$;

CREATE TEMP TABLE ball_lab_sample_candidates ON COMMIT DROP AS
SELECT
  p.source_row,
  sw.sweepnet_sample_id,
  row_number() OVER (
    PARTITION BY p.source_row
    ORDER BY sw.sweepnet_sample_id
  ) AS candidate_rank,
  count(*) OVER (
    PARTITION BY p.source_row
  ) AS candidate_count
FROM ball_lab_prepared p
JOIN ball_lab_events e USING (source_row)
JOIN ball_lab_taxonomy t USING (source_row)
JOIN survey200.sweepnet_samples sw
  ON sw.survey_id = e.survey_id
 AND sw.sweepnet_sample_type = p.sweepnet_sample_type
 AND sw.vegetation_taxon_id = t.vegetation_taxon_id;

CREATE TEMP TABLE ball_lab_mapped ON COMMIT DROP AS
SELECT
  p.*,
  t.vegetation_taxon_id,
  t.insect_taxon_id,
  c.sweepnet_sample_id,
  c.candidate_count
FROM ball_lab_prepared p
JOIN ball_lab_taxonomy t USING (source_row)
JOIN ball_lab_sample_candidates c
  ON c.source_row = p.source_row
 AND c.candidate_rank = p.selected_rank;

DO $$
BEGIN
  IF (SELECT count(*) FROM ball_lab_mapped) <> 384
     OR (SELECT count(DISTINCT source_row) FROM ball_lab_mapped) <> 384 THEN
    RAISE EXCEPTION
      'Expected all 384 prepared rows to map exactly once';
  END IF;

  IF (
    SELECT count(*)
    FROM ball_lab_mapped
    WHERE site_code = 'AC19'
      AND vegetation_scientific_name = 'Nerium oleander'
      AND (
        (original_notes = 'Oleander#2' AND selected_rank <> 2)
        OR
        (original_notes IS DISTINCT FROM 'Oleander#2'
          AND selected_rank <> 1)
      )
  ) <> 0 THEN
    RAISE EXCEPTION 'AC19 Nerium assignment rule failed';
  END IF;
END
$$;

-- Combine indistinguishable source rows that resolve to the same sample/taxon.
CREATE TEMP TABLE ball_lab_counts ON COMMIT DROP AS
SELECT
  sweepnet_sample_id,
  insect_taxon_id,
  insect_scientific_name,
  sum(count_of_insect)::integer AS count_of_insect,
  count(*) AS contributing_source_rows
FROM ball_lab_mapped
GROUP BY
  sweepnet_sample_id,
  insect_taxon_id,
  insect_scientific_name;

DO $$
DECLARE
  collision_count integer;
BEGIN
  IF (SELECT count(*) FROM ball_lab_counts) <> 380 THEN
    RAISE EXCEPTION
      'Expected 380 aggregated count rows; found %',
      (SELECT count(*) FROM ball_lab_counts);
  END IF;

  IF (SELECT count(DISTINCT sweepnet_sample_id) FROM ball_lab_counts) <> 111 THEN
    RAISE EXCEPTION
      'Expected 111 target samples; found %',
      (SELECT count(DISTINCT sweepnet_sample_id) FROM ball_lab_counts);
  END IF;

  IF (SELECT sum(count_of_insect) FROM ball_lab_counts) <> 5098 THEN
    RAISE EXCEPTION 'Aggregated abundance no longer equals 5098';
  END IF;

  IF (
    SELECT count(*)
    FROM ball_lab_mapped
    WHERE site_code = 'AB22'
      AND original_date = DATE '2022-05-31'
      AND vegetation_scientific_name = 'Lactuca serriola'
      AND insect_scientific_name = 'Unknown'
      AND count_of_insect = 0
  ) <> 1 THEN
    RAISE EXCEPTION
      'Required AB22 zero-organism observation is absent or changed';
  END IF;

  SELECT count(*)
  INTO collision_count
  FROM ball_lab_counts c
  JOIN survey200.sweepnet_sample_insect_counts existing
    ON existing.sweepnet_sample_id = c.sweepnet_sample_id
   AND existing.insect_taxon_id = c.insect_taxon_id;

  IF collision_count <> 0 THEN
    RAISE EXCEPTION
      'Import collides with % existing sample/taxon count rows',
      collision_count;
  END IF;
END
$$;

CREATE TEMP TABLE ball_lab_note_components (
  sweepnet_sample_id integer NOT NULL,
  component_order integer NOT NULL,
  component text NOT NULL
) ON COMMIT DROP;

-- NA values were converted to NULL by R and are omitted. Numeric zeroes remain.
INSERT INTO ball_lab_note_components
  (sweepnet_sample_id, component_order, component)
SELECT
  sweepnet_sample_id,
  10,
  'Ball Lab 2023 insect details: '
    || string_agg(
      insect_scientific_name
        || ' [count=' || total_count
        || CASE
             WHEN immature_values > 0
               THEN ', immature=' || immature_count
             ELSE ''
           END
        || CASE
             WHEN winged_values > 0
               THEN ', winged=' || winged_count
             ELSE ''
           END
        || ']',
      '; '
      ORDER BY insect_scientific_name
    )
    || '.'
FROM (
  SELECT
    sweepnet_sample_id,
    insect_scientific_name,
    sum(count_of_insect) AS total_count,
    count(number_immature) AS immature_values,
    sum(number_immature) AS immature_count,
    count(number_winged) AS winged_values,
    sum(number_winged) AS winged_count
  FROM ball_lab_mapped
  GROUP BY sweepnet_sample_id, insect_scientific_name
) taxon_notes
GROUP BY sweepnet_sample_id;

INSERT INTO ball_lab_note_components
  (sweepnet_sample_id, component_order, component)
SELECT
  sweepnet_sample_id,
  20,
  'Ball Lab 2023 source notes: '
    || string_agg(original_notes, ' | ' ORDER BY first_source_row)
    || '.'
FROM (
  SELECT
    sweepnet_sample_id,
    original_notes,
    min(source_row) AS first_source_row
  FROM ball_lab_mapped
  WHERE original_notes IS NOT NULL
  GROUP BY sweepnet_sample_id, original_notes
) distinct_notes
GROUP BY sweepnet_sample_id;

INSERT INTO ball_lab_note_components
  (sweepnet_sample_id, component_order, component)
SELECT
  sweepnet_sample_id,
  30,
  string_agg(
    'Ball Lab 2023 date correction: incoming '
      || original_date
      || ' mapped to sampling event '
      || corrected_date
      || '.',
    ' '
    ORDER BY original_date
  )
FROM (
  SELECT DISTINCT
    sweepnet_sample_id,
    original_date,
    corrected_date
  FROM ball_lab_mapped
  WHERE original_date <> corrected_date
) corrected_dates
GROUP BY sweepnet_sample_id;

INSERT INTO ball_lab_note_components
  (sweepnet_sample_id, component_order, component)
SELECT DISTINCT
  sweepnet_sample_id,
  40,
  'Ball Lab 2023 taxon mapping: incoming Salvia rosmarinus mapped to Rosmarinus officinalis.'
FROM ball_lab_mapped
WHERE original_substratum = 'Salvia rosmarinus';

-- All unnumbered rows use the first matching sample. The resolved serial ID is
-- included only as an audit note; it is never used to locate the sample.
INSERT INTO ball_lab_note_components
  (sweepnet_sample_id, component_order, component)
SELECT DISTINCT
  sweepnet_sample_id,
  50,
  'Ball Lab 2023 sample ambiguity: incoming '
    || vegetation_scientific_name
    || ' rows did not identify which of '
    || candidate_count
    || ' matching sweep samples was used; all unnumbered rows were assigned to resolved sweepnet_sample_id '
    || sweepnet_sample_id
    || '.'
FROM ball_lab_mapped
WHERE candidate_count > 1
  AND replicate_number IS NULL
  AND NOT (
    site_code = 'AC19'
    AND vegetation_scientific_name = 'Nerium oleander'
  );

INSERT INTO ball_lab_note_components
  (sweepnet_sample_id, component_order, component)
SELECT DISTINCT
  sweepnet_sample_id,
  50,
  CASE selected_rank
    WHEN 1 THEN
      'Ball Lab 2023 sample ambiguity: all AC19 Nerium oleander rows except the lone Oleander#2 row were assigned to this resolved sample.'
    WHEN 2 THEN
      'Ball Lab 2023 sample ambiguity: only the lone AC19 Nerium oleander row labeled Oleander#2 was assigned to this resolved sample.'
  END
FROM ball_lab_mapped
WHERE site_code = 'AC19'
  AND vegetation_scientific_name = 'Nerium oleander';

INSERT INTO ball_lab_note_components
  (sweepnet_sample_id, component_order, component)
SELECT DISTINCT
  m.sweepnet_sample_id,
  55,
  'Ball Lab 2023 consolidation: indistinguishable AA19 Caesalpinia pulcherrima counts were assigned to one sample; same-taxon counts were summed.'
FROM ball_lab_mapped m
JOIN ball_lab_counts c USING (sweepnet_sample_id, insect_taxon_id)
WHERE m.site_code = 'AA19'
  AND m.vegetation_scientific_name = 'Caesalpinia pulcherrima'
  AND c.contributing_source_rows > 1;

INSERT INTO ball_lab_note_components
  (sweepnet_sample_id, component_order, component)
SELECT DISTINCT
  sweepnet_sample_id,
  60,
  'No organisms were found in this collected sample.'
FROM ball_lab_mapped
WHERE site_code = 'AB22'
  AND original_date = DATE '2022-05-31'
  AND vegetation_scientific_name = 'Lactuca serriola'
  AND insect_scientific_name = 'Unknown'
  AND count_of_insect = 0;

CREATE TEMP TABLE ball_lab_note_updates ON COMMIT DROP AS
WITH additions AS (
  SELECT
    sweepnet_sample_id,
    string_agg(component, E'\n' ORDER BY component_order, component)
      AS added_notes
  FROM ball_lab_note_components
  GROUP BY sweepnet_sample_id
)
SELECT
  sw.sweepnet_sample_id,
  sw.notes AS old_notes,
  CASE
    WHEN nullif(trim(sw.notes), '') IS NULL THEN additions.added_notes
    ELSE sw.notes || E'\n' || additions.added_notes
  END AS new_notes
FROM additions
JOIN survey200.sweepnet_samples sw USING (sweepnet_sample_id);

DO $$
BEGIN
  IF (SELECT count(*) FROM ball_lab_note_updates) <> 111 THEN
    RAISE EXCEPTION
      'Expected 111 note updates; found %',
      (SELECT count(*) FROM ball_lab_note_updates);
  END IF;
END
$$;

UPDATE survey200.sweepnet_samples sw
SET notes = updates.new_notes
FROM ball_lab_note_updates updates
WHERE sw.sweepnet_sample_id = updates.sweepnet_sample_id
  AND sw.notes IS DISTINCT FROM updates.new_notes;

CREATE TEMP TABLE ball_lab_inserted_counts ON COMMIT DROP AS
WITH inserted AS (
  INSERT INTO survey200.sweepnet_sample_insect_counts (
    sweepnet_sample_id,
    insect_taxon_id,
    count_of_insect
  )
  SELECT
    sweepnet_sample_id,
    insect_taxon_id,
    count_of_insect
  FROM ball_lab_counts
  ORDER BY sweepnet_sample_id, insect_scientific_name
  RETURNING
    insect_count_id,
    sweepnet_sample_id,
    insect_taxon_id,
    count_of_insect
)
SELECT *
FROM inserted;

DO $$
BEGIN
  IF (SELECT count(*) FROM ball_lab_inserted_counts) <> 380
     OR (SELECT sum(count_of_insect) FROM ball_lab_inserted_counts) <> 5098 THEN
    RAISE EXCEPTION 'Final inserted counts failed reconciliation';
  END IF;
END
$$;

\echo
\echo '=== Reconciliation summary ==='
SELECT
  current_database() AS database,
  (SELECT count(*) FROM ball_lab_prepared) AS source_rows,
  (SELECT count(*) FROM ball_lab_inserted_counts) AS inserted_count_rows,
  (SELECT count(DISTINCT sweepnet_sample_id)
   FROM ball_lab_inserted_counts) AS samples_receiving_counts,
  (SELECT sum(count_of_insect)
   FROM ball_lab_inserted_counts) AS inserted_arthropod_total,
  (SELECT max(length(new_notes))
   FROM ball_lab_note_updates) AS longest_resulting_note;

\echo
\echo '=== Resolved serial IDs for database-specific audit only ==='
SELECT
  site_code,
  corrected_date,
  vegetation_scientific_name,
  selected_rank,
  sweepnet_sample_id,
  count(*) AS source_rows
FROM ball_lab_mapped
WHERE candidate_count > 1
GROUP BY
  site_code,
  corrected_date,
  vegetation_scientific_name,
  selected_rank,
  sweepnet_sample_id
ORDER BY site_code, vegetation_scientific_name, selected_rank;

\echo
\echo '=== Aggregated source rows ==='
SELECT
  sweepnet_sample_id,
  insect_scientific_name,
  contributing_source_rows,
  count_of_insect
FROM ball_lab_counts
WHERE contributing_source_rows > 1
ORDER BY sweepnet_sample_id, insect_scientific_name;

\if :apply
  COMMIT;
  \echo 'COMMITTED: Ball Lab 2023 arthropod import was applied.'
\else
  ROLLBACK;
  \echo 'DRY RUN: all transactional database changes were rolled back.'
\endif
