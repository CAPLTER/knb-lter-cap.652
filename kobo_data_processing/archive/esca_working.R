# vim: set foldmethod=marker:

# configuration {{{

source("~/Documents/localSettings/pg_local.R")
# keyring::keyring_unlock("postgres")
pg <- pg_local_connect(db = "caplter")

source("helper_load_schema.R")
# helper_reload_schema(connection = pg)

# }}}

# sampling events {{{


## pull sites from db with trailing 1 removed

sites_db <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT *
  FROM survey200.sites
  ;
  "
) |>
  dplyr::mutate(site_code = gsub("1$", "", site_code))

## read main surveys plot data file

se_plot_data <- readr::read_csv("ESCA_plot_2024-04-22-18-29-03-ESCA_plot.csv") |>
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names()

## add site id and format as appropriate

se_plot_data <- se_plot_data |>
  dplyr::left_join(
    y = sites_db |>
      dplyr::select(
        site_id,
        site_code,
        research_focus
      ) |>
      dplyr::filter(grepl("survey", research_focus, ignore.case = TRUE)),
    by = c("site" = "site_code")
  ) |> 
  dplyr::mutate(
    start = format(start, "%H:%M:%S"),
    end   = format(end, "%H:%M:%S")
  )

# DBI::dbGetQuery(
#   conn      = pg,
#   statement = "
#   SELECT
#     column_name,
#     data_type
#   FROM
#     information_schema.columns
#   WHERE
#     table_schema = 'survey200' AND
#     table_name = 'sampling_events'
#   ;
#   "
# )

#  column_name                   data_type
#    survey_id                     integer
#      site_id                     integer
#    samp_date                        date
#   start_time      time without time zone
#     end_time      time without time zone
# crew_members           character varying
#   created_at timestamp without time zone
#   updated_at timestamp without time zone

# DBI::dbExecute(
#   conn      = pg,
#   statement = "
#   DELETE
#   FROM survey200.sampling_events
#   WHERE EXTRACT(year FROM samp_date) = 2023
#   ;
#   "
# )

DBI::dbExecute(
  conn      = pg,
  statement = "
  ALTER TABLE survey200.sampling_events
  ADD COLUMN kobo_uuid TEXT ;
  ;
  "
)

add_plot_surveys <- se_plot_data |> 
  glue::glue_data_sql("
    INSERT INTO survey200.sampling_events (
      site_id,
      samp_date,
      start_time,
      end_time,
      crew_members,
      kobo_uuid
    )
    VALUES
    (
      { site_id },
      { date },
      { start },
      { end },
      { crew_members_for_this_survey },
      { uuid }
    )
    ;
    ",
    .con = DBI::ANSI()
  )

# ses_from_db <- DBI::dbGetQuery(pg, "select * from survey200.sampling_events ;")

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_plot_surveys,
      .f = ~ DBI::dbExecute(statement = .x, conn = pg)
    )
  }
)

# }}}

# vegetation taxon list (initial) {{{

# prepare vegetation_taxon_list to receive new taxa sensu arthros --------------

# Table "arthropods.arthropod_taxonomy"
#        Column        |           Type           | Collation | Nullable |                          Default                          | Storage  | Compression | Stats target |                                                 Description                                                 
# ---------------------+--------------------------+-----------+----------+-----------------------------------------------------------+----------+-------------+--------------+-------------------------------------------------------------------------------------------------------------
#  id                  | integer                  |           | not null | nextval('arthropods.arthropod_taxonomy_id_seq'::regclass) | plain    |             |              | 
#  code                | text                     |           |          |                                                           | extended |             |              | artefact of old taxonomic system
#  arth_class          | text                     |           |          |                                                           | extended |             |              | artefact of old taxonomic system
#  arth_order          | text                     |           |          |                                                           | extended |             |              | artefact of old taxonomic system
#  arth_family         | text                     |           |          |                                                           | extended |             |              | artefact of old taxonomic system
#  arth_genus_subgenus | text                     |           |          |                                                           | extended |             |              | artefact of old taxonomic system
#  old_name            | text                     |           |          |                                                           | extended |             |              | artefact of old taxonomic system
#  display_name        | text                     |           |          |                                                           | extended |             |              | the finest taxonomic resolution for display
#  archive             | boolean                  |           |          |                                                           | plain    |             |              | indicates if the taxa was part of the old taxonomic system and has been archived
#  key_name            | text                     |           |          |                                                           | extended |             |              | finest taxonomic resolution including sub classifictions (e.g. subgenus) for resolving to taxonomic systems
#  taxa_raw            | text                     |           |          |                                                           | extended |             |              | taxonomyCleanr
#  taxa_trimmed        | text                     |           |          |                                                           | extended |             |              | taxonomyCleanr
#  taxa_replacement    | text                     |           |          |                                                           | extended |             |              | taxonomyCleanr
#  taxa_removed        | text                     |           |          |                                                           | extended |             |              | taxonomyCleanr
#  rank                | text                     |           |          |                                                           | extended |             |              | taxonomyCleanr
#  authority           | text                     |           |          |                                                           | extended |             |              | 
#  authority_id        | text                     |           |          |                                                           | extended |             |              | 
#  score               | double precision         |           |          |                                                           | plain    |             |              | taxonomyCleanr
#  difference          | double precision         |           |          |                                                           | plain    |             |              | taxonomyCleanr
#  created_at          | timestamp with time zone |           | not null | now()                                                     | plain    |             |              | 
#  updated_at          | timestamp with time zone |           | not null | now()                                                     | plain    |             |              | 
# Indexes:
#     "arthropod_taxonomy_pkey" PRIMARY KEY, btree (id)
#     "unique_arthropod_taxonomy_authority_authority_id_archive" UNIQUE CONSTRAINT, btree (authority, authority_id, archive)
#     "unique_arthropod_taxonomy_display_name_archive" UNIQUE CONSTRAINT, btree (display_name, archive)
# Referenced by:
#     TABLE "arthropods.plant_specimens" CONSTRAINT "plant_specimens_fk_arthropod_taxon_id" FOREIGN KEY (arthropod_taxon_id) REFERENCES arthropods.arthropod_taxonomy(id)
#     TABLE "arthropods.trap_specimens" CONSTRAINT "trap_specimens_fk_arthropod_taxon_id" FOREIGN KEY (arthropod_taxon_id) REFERENCES arthropods.arthropod_taxonomy(id)
# Access method: heap

DBI::dbExecute(
  conn      = pg,
  statement = "
  ALTER TABLE survey200.vegetation_taxon_list
  ADD COLUMN taxa_raw         TEXT,
  ADD COLUMN taxa_trimmed     TEXT,
  ADD COLUMN taxa_replacement TEXT,
  ADD COLUMN taxa_removed     TEXT,
  ADD COLUMN rank             TEXT,
  ADD COLUMN authority        TEXT,
  ADD COLUMN authority_id     TEXT,
  ADD COLUMN score            DOUBLE PRECISION,
  ADD COLUMN difference       DOUBLE PRECISION
  ;
  "
)

DBI::dbExecute(conn = pg, statement = "COMMENT ON COLUMN survey200.vegetation_taxon_list.taxa_raw         IS 'taxonomyCleanr' ;")
DBI::dbExecute(conn = pg, statement = "COMMENT ON COLUMN survey200.vegetation_taxon_list.taxa_trimmed     IS 'taxonomyCleanr' ;")
DBI::dbExecute(conn = pg, statement = "COMMENT ON COLUMN survey200.vegetation_taxon_list.taxa_replacement IS 'taxonomyCleanr' ;")
DBI::dbExecute(conn = pg, statement = "COMMENT ON COLUMN survey200.vegetation_taxon_list.taxa_removed     IS 'taxonomyCleanr' ;")
DBI::dbExecute(conn = pg, statement = "COMMENT ON COLUMN survey200.vegetation_taxon_list.rank             IS 'taxonomyCleanr' ;")
DBI::dbExecute(conn = pg, statement = "COMMENT ON COLUMN survey200.vegetation_taxon_list.score            IS 'taxonomyCleanr' ;")
DBI::dbExecute(conn = pg, statement = "COMMENT ON COLUMN survey200.vegetation_taxon_list.difference       IS 'taxonomyCleanr' ;")

DBI::dbExecute(
  conn      = pg,
  statement = "
  CREATE OR REPLACE FUNCTION trigger_set_timestamp()
  RETURNS TRIGGER AS $$
  BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
  END;
  $$ LANGUAGE plpgsql;
  "
)

databaseDevelopmentTools::add_timestamping(
  schema = "survey200",
  table  = "vegetation_taxon_list"
)

# UNMATCHED TAXA:
# ENTRY                 # ACTION
# Ambrosia salsola      # add to db taxa list
# Atriplex polycarpa    # add to db taxa list
# Eromophilla           # recoded in kobo data to Eremophila
# Moringa oleifera      # add to db taxa list
# Oncosiphon pilulifer  # wrongly coded as piluliferum in db; fix db spelling

DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT *
  FROM survey200.vegetation_taxon_list
  WHERE vegetation_scientific_name ~~* '%Oncosiphon%'
  ;"
)

DBI::dbExecute(
  conn      = pg,
  statement = "
  UPDATE survey200.vegetation_taxon_list
  SET vegetation_scientific_name = 'Oncosiphon pilulifer'
  WHERE vegetation_scientific_name ~~* '%Oncosiphon%'
  ;
  "
)
# Pyrus calleryana      # add to db taxa list
# Quercus polymorpha    # add to db taxa list
# Suadea nigra          # fix spelling (Suaeda nigra) and add to db taxa list

new_taxa <- tibble::tibble(
  tax_name = c(
    "Ambrosia salsola",
    "Atriplex polycarpa",
    "Moringa oleifera",
    "Pyrus calleryana",
    "Quercus polymorpha",
    "Suaeda nigra"
  )
)

my_path <- getwd()

taxonomyCleanr::create_taxa_map(
  path = my_path,
  x    = new_taxa,
  col  = "tax_name"
)

# taxonomyCleanr::view_taxa_authorities()

taxonomyCleanr::resolve_sci_taxa(
  path         = my_path,
  data.sources = c(3, 11)
) 

new_taxa_refs <- readr::read_csv("taxa_map.csv")

new_taxa_query <- new_taxa_refs |> 
  glue::glue_data_sql("
    INSERT INTO survey200.vegetation_taxon_list (
      vegetation_scientific_name,
      taxa_trimmed,
      taxa_replacement,
      taxa_removed,
      rank,
      authority,
      authority_id,
      score,
      difference
    ) VALUES (
      { taxa_raw },
      { taxa_trimmed },
      { taxa_replacement },
      { taxa_removed },
      { rank },
      { authority },
      { authority_id },
      { score },
      { difference }
    )
    ;",
    .con = DBI::ANSI()
  )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = new_taxa_query,
      .f = ~ DBI::dbExecute(
        conn      = pg,
        statement = .x
      )
    )
  }
)

}}}

# sweepnet samples {{{

sweepnet_samples_data <- readr::read_csv("ESCA_plot_2024-04-22-18-29-03-sweepnet_samples_repeat.csv") |>
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names()

vegetation_taxon_list <- DBI::dbGetQuery(
  conn      = pg,
  statement = "SELECT * FROM survey200.vegetation_taxon_list ;"
)

sweepnet_samples_data <- sweepnet_samples_data |> 
  dplyr::mutate(
    new_sweepnet_vegetation_taxon = gsub("sp.", "", new_sweepnet_vegetation_taxon),
    new_sweepnet_vegetation_taxon = stringr::str_trim(new_sweepnet_vegetation_taxon, side = c("both")),
    notes_regarding_sweepnet_sample = dplyr::case_when(
      grepl("Eromophilla", new_sweepnet_vegetation_taxon, ignore.case = TRUE) ~ "Entered as Eromophilla; assumed to be Eremophila",
      TRUE ~ notes_regarding_sweepnet_sample
    ),
    new_sweepnet_vegetation_taxon = dplyr::case_when(
      grepl("Suadea", new_sweepnet_vegetation_taxon, ignore.case = TRUE) ~ "Suaeda nigra",
      TRUE ~ new_sweepnet_vegetation_taxon
    ),
    plant_taxon_from_which_arthropods_were_collected = dplyr::case_when(
      grepl("Eromophilla", new_sweepnet_vegetation_taxon, ignore.case = TRUE) ~ "Eremophila",
      grepl("null", plant_taxon_from_which_arthropods_were_collected, ignore.case = TRUE) ~ new_sweepnet_vegetation_taxon,
      sweepnet_sample_type == "ground_sweep" ~ "ground sweep",
      TRUE ~ plant_taxon_from_which_arthropods_were_collected
    ),
    sweepnet_sample_type = gsub("_", " ", sweepnet_sample_type)
  ) |> 
  dplyr::left_join(
    y  = vegetation_taxon_list |> 
      dplyr::mutate(vsn = vegetation_scientific_name) |> 
      dplyr::select(
        vegetation_taxon_id,
        vegetation_scientific_name,
        vsn
      ),
    by = c("plant_taxon_from_which_arthropods_were_collected" = "vegetation_scientific_name")
  ) |> 
  pointblank::col_vals_not_null(
    columns = c("vegetation_taxon_id")
  )

se_plot_db <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sampling_events.survey_id,
    sampling_events.site_id,
    sampling_events.samp_date,
    sampling_events.kobo_uuid,
    sites.site_code
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  WHERE EXTRACT(year FROM samp_date) = 2023
  ;
  "
) |>
  dplyr::mutate(site_code = gsub("1$", "", site_code))

sweepnet_samples_data <- sweepnet_samples_data |> 
  dplyr::left_join(
    y  = se_plot_db,
    by = c("submission_uuid" = "kobo_uuid")
  ) |> 
  pointblank::col_vals_not_null(
    columns = c("survey_id")
  )

sweepnet_samples_query <- sweepnet_samples_data |> 
  glue::glue_data_sql("
    INSERT INTO survey200.sweepnet_samples (
      survey_id,
      sweepnet_sample_type,
      vegetation_taxon_id,
      notes
    ) VALUES (
      { survey_id },
      { sweepnet_sample_type },
      { vegetation_taxon_id },
      { notes_regarding_sweepnet_sample }
    )
    ;",
    .con = DBI::ANSI()
  )

# DBI::dbGetQuery(pg, "SELECT * FROM survey200.sweepnet_samples WHERE EXTRACT (YEAR FROM timestamp_val) = 2024 ;")
# DBI::dbExecute(pg, "DELETE FROM survey200.sweepnet_samples WHERE EXTRACT (YEAR FROM timestamp_val) = 2024 ;")

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = sweepnet_samples_query,
      .f = ~ DBI::dbExecute(
        conn      = pg,
        statement = .x
      )
    )
  }
)

# }}}

# arthropod taxa {{{

taxa_david_edits <- readr::read_csv("ESCA Taxonomic Thesaurus - ESCA datasheet.csv")

# taxa_david_edits |> 
#   dplyr::count(display_name) |> 
#   dplyr::filter(n > 1)


# taxa_db |> 
#   dplyr::count(insect_scientific_name) |> 
#   dplyr::filter(n > 1)

# dplyr::full_join(
#   x  = taxa_david_edits,
#   y  = taxa_db,
#   by = c("display_name" = "insect_scientific_name")
# )

recorded_taxa <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    insect_taxon_list.insect_taxon_id,
    insect_taxon_list.insect_scientific_name,
    -- count(*)
    count(sweepnet_sample_insect_counts.insect_count_id)
  FROM survey200.sweepnet_sample_insect_counts
  RIGHT JOIN survey200.insect_taxon_list ON (insect_taxon_list.insect_taxon_id = sweepnet_sample_insect_counts.insect_taxon_id)
  GROUP BY insect_taxon_list.insect_taxon_id
  ;
  "
)

unused_taxa <- recorded_taxa |> 
  dplyr::filter(count == 0)

# unused_taxa <- dplyr::full_join(
#   x  = taxa_db,
#   y  = recorded_taxa,
#   by = c("insect_taxon_id")
# ) |> 
#   dplyr::filter(is.na(count))

# refence of existing content
arthros_reference <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    ss.sweepnet_sample_type,
    vtl.vegetation_scientific_name AS substratum,
    itl.insect_taxon_id,
    itl.insect_scientific_name AS arthropod_scientific_name,
    ssic.count_of_insect AS number_of_arthropods,
    ss.notes
  FROM
    survey200.sampling_events se
  JOIN survey200.sites s ON se.site_id = s.site_id
  JOIN survey200.sweepnet_samples ss ON se.survey_id = ss.survey_id
  LEFT JOIN survey200.vegetation_taxon_list vtl ON ss.vegetation_taxon_id = vtl.vegetation_taxon_id
  JOIN survey200.sweepnet_sample_insect_counts ssic ON ss.sweepnet_sample_id = ssic.sweepnet_sample_id
  JOIN survey200.insect_taxon_list itl ON ssic.insect_taxon_id = itl.insect_taxon_id
  -- WHERE
  --   EXTRACT (YEAR FROM se.samp_date) <= 2010
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code,
    vtl.vegetation_scientific_name
  ;
  "
)

# dump arthro data before making any changes for post-process testing
readr::write_csv(arthros_reference, "arthros_reference.csv")

## redo unused taxa after all the updates to do a bulk delete (with a sanity
## check) instead of deleting modified taxa one-by-one

# database structural changes

## add timestamping to ITL and SSIC
# databaseDevelopmentTools::add_timestamping(
#   schema = "survey200",
#   table  = "insect_taxon_list"
# )

# databaseDevelopmentTools::add_timestamping(
#   schema = "survey200",
#   table  = "sweepnet_sample_insect_counts"
# )

# DBI::dbExecute(
#   conn      = pg,
#   statement = "
#   ALTER TABLE survey200.sweepnet_sample_insect_counts
#   ADD COLUMN immature BOOLEAN
#   ;
#   "
# )

## Miridae (adults)
DBI::dbExecute(
  conn      = pg,
  statement = "
  UPDATE survey200.sweepnet_sample_insect_counts
  SET insect_taxon_id = 44
  WHERE insect_taxon_id = 45
  ;
  "
)

## immature
DBI::dbExecute(
  conn      = pg,
  statement = "
  UPDATE survey200.sweepnet_sample_insect_counts
  SET insect_taxon_id = 44
  WHERE insect_taxon_id = 46
  ;
  "
)

## Fannidae
DBI::dbExecute(
  conn      = pg,
  statement = "
  UPDATE survey200.sweepnet_sample_insect_counts
  SET insect_taxon_id = 716
  WHERE insect_taxon_id = 827
  ;
  "
)

## Coccoidea
DBI::dbExecute(
  conn      = pg,
  statement = "
  UPDATE survey200.sweepnet_sample_insect_counts
  SET insect_taxon_id = 80
  WHERE insect_taxon_id IN (206, 213)
  ;
  "
)

## Araneida to Arachnida
## this one just a ITL name change
DBI::dbExecute(
  conn      = pg,
  statement = "
  UPDATE survey200.insect_taxon_list
  SET insect_scientific_name = 'Arachnida'
  WHERE insect_taxon_id = 265
  ;
  "
)

## Scaphytopius
DBI::dbExecute(
  conn      = pg,
  statement = "
  UPDATE survey200.sweepnet_sample_insect_counts
  SET insect_taxon_id = 668
  WHERE insect_taxon_id = 319
  ;
  "
)

## Coanthanus
DBI::dbExecute(
  conn      = pg,
  statement = "
  UPDATE survey200.sweepnet_sample_insect_counts
  SET insect_taxon_id = 157
  WHERE insect_taxon_id = 639
  ;
  "
)

# ## add immature flag to all taxa classified as `(immature)`
# DBI::dbGetQuery(
#   conn      = pg,
#   statement = "
#   SELECT *
#   FROM survey200.sweepnet_sample_insect_counts
#   WHERE insect_taxon_id IN (
#     SELECT insect_taxon_id
#     FROM survey200.insect_taxon_list
#     WHERE insect_scientific_name ~~* '%immature%'
#   )
#   ;
#   "
# )

# DBI::dbExecute(
#   conn      = pg,
#   statement = "
#   UPDATE survey200.sweepnet_sample_insect_counts
#   SET immature = TRUE
#   WHERE insect_taxon_id IN (
#     SELECT insect_taxon_id
#     FROM survey200.insect_taxon_list
#     WHERE insect_scientific_name ~~* '%immature%'
#   )
#   ;
#   "
# )

insect_taxon_edits <- tibble::tribble(
  ~new, ~old, ~details,
  44,   45,  "Miridae adults; David edit",
  716,  827, "Fanniidae; David edit",
  80,   213, "Coccoidea; David edit",
  206,  213, "Coccoidea; David edit",
  668,  319, "Scaphytopius; David edit",
  157,  639, "Coanthanus; David edit",
) |> 
  glue::glue_data_sql("
    UPDATE survey200.sweepnet_sample_insect_counts
      SET insect_taxon_id = { new }
      WHERE insect_taxon_id IN { old } ;
    UPDATE survey200.insect_taxon_list
      SET archive = TRUE
      WHERE insect_taxon_id = { old } ;
    ",
    .con = DBI::ANSI()
  )

taxa_db <- DBI::dbGetQuery(
  conn      = pg,
  statement = "SELECT * FROM survey200.insect_taxon_list ;"
)

taxa_db[c("name", "flag")] <- stringr::str_split_fixed(
  string  = taxa_db[["insect_scientific_name"]],
  pattern = "\\(",
  n       = 2
)

taxa_immature <- taxa_db |> 
  dplyr::mutate(name = stringr::str_trim(name, side = c("both"))) |> 
  dplyr::filter(grepl("immature", flag, ignore.case = TRUE)) |> 
  dplyr::select(
    id_immature = insect_taxon_id,
    insect_scientific_name,
    name_immature = name,
    flag
  ) |> 
  dplyr::left_join(
    y = taxa_db |> 
      dplyr::select(
        insect_taxon_id,
        insect_scientific_name,
      ),
    by = c("name_immature" = "insect_scientific_name")
  )

# insect counts flagged as immature in an earlier step so just drop immature
# from the name
rename_immatures <- taxa_immature |> 
  dplyr::filter(is.na(insect_taxon_id)) |> 
  glue::glue_data_sql("
    UPDATE survey200.sweepnet_sample_insect_counts
    SET insect_scientific_name = { name_immature }
    WHERE insect_taxon_id IN { id_immature } ;
    ",
    .con = DBI::ANSI()
  )

recode_immatures <- taxa_immature |> 
  dplyr::filter(!is.na(insect_taxon_id)) |> 
  glue::glue_data_sql("
    UPDATE survey200.sweepnet_sample_insect_counts
      SET insect_taxon_id = { insect_taxon_id }
      WHERE insect_taxon_id IN { id_immature } ;
    UPDATE survey200.insect_taxon_list
      SET archive = TRUE
      WHERE insect_taxon_id = { id_immature } ;
    ",
    .con = DBI::ANSI()
  )

# unresolved taxa --------------------------------------------------------------

# There are about 27 taxa that GBIF is unable to resolve, which is odd because
# they seem legitimate. We will have to go with what we have until, hopefully,
# ITIS is back on line and the resolution improves. Note that this applies to
# plants also. All new plants that needed to be added because they were part of
# the sweepnet sampling were resolved by GBIF but that surely will not be the
# case for all new plants when we get to that part of the survey, and, also,
# ITIS is the first-choice authority. 


# unresolved <- readr::read_csv("taxa_map.insects.csv") |> 
#   dplyr::filter(is.na(authority_id))

unresolved <- readr::read_csv("taxa_map.insects.itis.csv") |> 
  dplyr::filter(
    is.na(authority_id),
    !grepl("unknown", taxa_raw, ignore.case = TRUE)
  )

my_path <- getwd()

taxonomyCleanr::create_taxa_map(
  path = my_path,
  x    = unresolved,
  col  = "taxa_raw"
)

# taxonomyCleanr::view_taxa_authorities()

taxonomyCleanr::resolve_sci_taxa(
  path         = my_path,
  data.sources = c(3, 11)
) 

## merge the round II results into the round I results

round_i <- readr::read_csv("taxa_map.insects.itis.csv")

araneae <- readr::read_csv("taxa_map.csv") |> 
  dplyr::filter(!is.na(authority_id))

round_ii <- readr::read_csv("taxa_map.insects.ii.csv") |> 
  # dplyr::filter(!grepl("Araneida", taxa_raw, ignore.case = TRUE)) |> 
  dplyr::bind_rows(araneae) |> 
  dplyr::mutate(
    rank = dplyr::case_when(
      taxa_raw == "Toryminae" ~ "Family",
      TRUE ~ rank
    ),
    authority = dplyr::case_when(
      taxa_raw == "Toryminae" ~ "https://bugguide.net",
      TRUE ~ authority
    ),
    authority_id = dplyr::case_when(
      taxa_raw == "Toryminae" ~ 12618,
      TRUE ~ authority_id
    )
  )

final_taxa <- round_i |> 
  dplyr::filter(!taxa_raw %in% c(round_ii$taxa_raw)) |> 
  dplyr::bind_rows(
    round_ii |> 
      dplyr::filter(!grepl("Araneida", taxa_raw, ignore.case = TRUE))
  )

still_unresolved <- tibble::tribble(
  ~taxa_raw,
  "Araneae",
  "Toryminae"
)

my_path <- getwd()

taxonomyCleanr::create_taxa_map(
  path = my_path,
  x    = still_unresolved,
  col  = "taxa_raw"
)

# taxonomyCleanr::view_taxa_authorities()

taxonomyCleanr::resolve_sci_taxa(
  path         = my_path,
  data.sources = c(3, 11)
) 

# }}}

# will have to REVISIT THIS as the crew has indicated parcel sites of AC20 and
# V18, which are not parcel sites; first check audit log lat longs to confirm
# that they are not just miscoded sites
# added these sites to the sites table!

# ANOTHER ISSUE: why are so many plot human indicators data empty ???
# its a kobo thing, the data are there

# parcel events {{{

se_parcel_data <- readr::read_csv("kobo/ESCA_parcel_2024-04-22-18-38-10-ESCA_parcel.csv") |>
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names()

se_parcel_data <- se_parcel_data |>
  dplyr::left_join(
    y = sites_db |>
      dplyr::select(
        site_id,
        site_code,
        research_focus
      ) |>
      dplyr::filter(grepl("parcel", research_focus, ignore.case = TRUE)),
    by = c("site" = "site_code")
  ) |> 
  dplyr::mutate(
    start = format(start, "%H:%M:%S"),
    end   = format(end, "%H:%M:%S")
  )

add_parcel_surveys <- se_parcel_data |> 
  glue::glue_data_sql("
    INSERT INTO survey200.sampling_events (
      site_id,
      samp_date,
      start_time,
      end_time,
      kobo_uuid
    )
    VALUES
    (
      { site_id },
      { date },
      { start },
      { end },
      { uuid }
    )
    ;
    ",
    .con = DBI::ANSI()
  )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_parcel_surveys,
      .f = ~ DBI::dbExecute(statement = .x, conn = pg)
    )
  }
)

# }}}

# empty plot vars {{{

se_plot_data <- readr::read_csv("kobo/ESCA_plot_2024-04-22-18-29-03-ESCA_plot.csv") |>
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names()



# }}}

# ANOTHER ISSUE: aspect, slope are static in the sites table but we record this
# data each survey !?!
# addressed in sites_geography

# sites geography {{{

sampling_events <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    survey_id,
    kobo_uuid
  FROM survey200.sampling_events 
  WHERE
    EXTRACT (YEAR from samp_date) = 2023
  ;
  "
)

se_plot_data <- readr::read_csv("kobo/ESCA_plot_2024-04-22-18-29-03-ESCA_plot.csv") |>
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names() |> 
  dplyr::select(
    tidyselect::starts_with("position"),
    slope,
    aspect,
    uuid
  )

sites_geography <- dplyr::right_join(
  x  = sampling_events,
  y  = se_plot_data,
  by = c("kobo_uuid" = "uuid")
) |> 
  dplyr::mutate(
    id = NA_integer_,
    id = seq_along(survey_id)
  ) |> 
  dplyr::select(
    id,
    survey_id,
    position_of_plot_center_latitude,
    position_of_plot_center_longitude,
    position_of_plot_center_altitude,
    position_of_plot_center_precision,
    slope,
    aspect
  )

databaseDevelopmentTools::r_pg_table(
  schema = "survey200",
  table  = "sites_geography",
  # owner  = this_configuration$owner
  owner  = "srearl"
)

databaseDevelopmentTools::add_timestamping(
  schema = "survey200",
  table  = "sites_geography"
)

DBI::dbExecute(pg, "
  ALTER TABLE survey200.sites_geography
    ADD CONSTRAINT sites_geography_fk_sampling_events_survey_id
      FOREIGN KEY (survey_id) REFERENCES survey200.sampling_events(survey_id)
  ;
  "
)
# }}}

# Human Indicators {{{

human_indicators <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT *
  FROM survey200.human_indicators
  -- LIMIT 10 
  ;
  "
)

human_indicators_bak <- human_indicators
human_indicators <- human_indicators_bak

nas <- human_indicators |> 
  dplyr::select(
    tidyselect::where(
      ~ any(
        grepl(
          pattern     = "do not know",
          x           = .x,
          ignore.case = TRUE
        )
      )
    )
  )

nas_to_null <- tibble::tibble(
  nas_cols = colnames(nas)
) |> 
  glue::glue_data_sql("
    UPDATE survey200.human_indicators
    SET { nas_cols } = 'do_not_know'
    WHERE { nas_cols } = 'do not know'
    ;",
    .con = DBI::ANSI()
  ) |> 
  gsub(
    pattern     = "'",
    replacement = "",
    x           = _
  ) |> 
  gsub(
    pattern     = "do_not_know",
    replacement = "'do_not_know'",
    x           = _
  ) |> 
  gsub(
    pattern     = "do not know",
    replacement = "'do not know'",
    x           = _
  )

readr::write_csv(human_indicators, "/tmp/hi_edit.csv")
readr::write_csv(human_indicators_bak, "/tmp/hi_oe.csv")

# nas_to_null <- gsub(
#   pattern     = "'",
#   replacement = "",
#   x           = nas_to_null
# )

# nas_to_null <- gsub(
#   pattern     = "n/a",
#   replacement = "'n/a'",
#   x           = nas_to_null
# )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = nas_to_null,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn      = pg
      )
    )
  }
)

# DBI::dbGetQuery(
#   conn      = pg,
#   statement = "
#   SELECT
#     human_footprints
#   FROM
#     survey200.human_indicators
#   WHERE
#     human_footprints ~~* '%/%'
#   ;
#   "
# )

# DBI::dbExecute(
#   conn      = pg,
#   statement = "
#   UPDATE survey200.human_indicators
#   SET human_footprints = NULL
#   WHERE human_footprints ~~* '%/%'
#   ;
#   "
# )

# DBI::dbExecute(
#   conn      = pg,
#   statement = "
#   ALTER TABLE survey200.human_indicators
#   ADD CONSTRAINT check_human_footprints
#   CHECK (human_footprints IN ('none', 'some', 'many'))
#   ;
#   "
# )

sampling_events <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    survey_id,
    kobo_uuid
  FROM survey200.sampling_events 
  WHERE
    EXTRACT (YEAR from samp_date) = 2023
  ;
  "
)

plot_data <- readr::read_csv("kobo/ESCA_plot_2024-04-22-18-29-03-ESCA_plot.csv") |>
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names() |> 
  dplyr::select(tidyselect::where(~ any(!is.na(.x))))

plot_data <- plot_data |> 
  dplyr::left_join(
    y  = sampling_events,
    by = c("uuid" = "kobo_uuid")
  ) |> 
  pointblank::col_vals_not_null(
    columns = c(survey_id),
    actions = pointblank::stop_on_fail()
  ) |> 
  pointblank::row_count_match(
    count   = nrow(plot_data),
    actions = pointblank::stop_on_fail()
  )


plot_data <- plot_data |> 
  dplyr::mutate(
    dplyr::across(
      tidyselect::where(
        ~ any(
          grepl(
            pattern     = "many or heavy",
            x           = .x,
            ignore.case = TRUE
          )
        )
      ), ~ dplyr::case_when(
        . == "many or heavy" ~ "many",
        TRUE ~ .
      )
    )
  )

plot_data <- plot_data |> 
  dplyr::mutate(
    dplyr::across(
      tidyselect::where(
        ~ any(
          grepl(
            pattern     = "do not know",
            x           = .x,
            ignore.case = TRUE
          )
        )
      ), ~ dplyr::case_when(
        . == "do not know" ~ "do_not_know",
        TRUE ~ .
      )
    )
  )

# # had to cast insert anyway so not sure this was needed...try without
# plot_data <- plot_data |> 
#   dplyr::mutate(
#     dplyr::across(
#       .cols = c(
#         indicate_visible_signs_of_human_cultivation_presence_of_open_ground,
#         indicate_visible_signs_of_human_cultivation_presence_of_trees,
#         indicate_visible_signs_of_human_cultivation_presence_of_shrubs,
#         indicate_visible_signs_of_human_cultivation_presence_of_cacti_or_succulents,
#         indicate_visible_signs_of_human_cultivation_presence_of_lawn,
#         indicate_visible_signs_of_human_cultivation_presence_of_herbaceous_ground_cover,
#         indicate_visible_signs_of_human_cultivation_presence_of_other_vegetation_types,
#         indicate_visible_signs_of_human_added_irrigation_presence_of_hand_water,
#         indicate_visible_signs_of_human_added_irrigation_presence_of_drip_water,
#         indicate_visible_signs_of_human_added_irrigation_presence_of_overhead_water,
#         indicate_visible_signs_of_human_added_irrigation_presence_of_flood_water,
#         indicate_visible_signs_of_human_added_irrigation_presence_of_subterranean_water,
#         indicate_visible_signs_of_human_added_irrigation_no_water,
#         indicate_visible_signs_of_human_added_irrigation_presence_of_pervious_irrigation
#       ),
#       .fns = as.logical
#     )
#   )

readr::write_csv(alpha |> dplyr::select(survey_id, indicate_visible_signs_of_human_cultivation_presence_of_open_ground), "/tmp/alpha.csv")
readr::write_csv(plot_data |> dplyr::select(survey_id, indicate_visible_signs_of_human_cultivation_presence_of_open_ground), "/tmp/pd.csv")

DBI::dbExecute(
  conn      = pg,
  statement = "DROP VIEW IF EXISTS survey200.public_lens_survey200_human_indicators CASCADE ;"
)

DBI::dbExecute(
  conn      = pg,
  statement = "
  ALTER TABLE survey200.human_indicators
    ALTER COLUMN human_social_class TYPE TEXT USING human_social_class :: TEXT
  ;
  "
)

# DBI::dbExecute(
#   conn      = pg,
#   statement = "
#   ALTER TABLE survey200.human_indicators
#     ALTER COLUMN human_social_class   TYPE TEXT USING human_social_class   :: TEXT ;
#     -- ALTER COLUMN appears_maintained   TYPE TEXT USING appears_maintained   :: TEXT,
#     -- ALTER COLUMN appears_professional TYPE TEXT USING appears_professional :: TEXT,
#     -- ALTER COLUMN appears_healthy      TYPE TEXT USING appears_healthy      :: TEXT,
#     -- ALTER COLUMN appears_injured      TYPE TEXT USING appears_injured      :: TEXT
#   ;
#   "
# )

add_plots_data <- plot_data |> 
  glue::glue_data_sql("
    INSERT INTO survey200.human_indicators (
      survey_id,
      general_description,
      weather_on_the_day,
      weather_recent_rain_notes,
      vegetation_rope_length,
      human_presence_of_path,
      human_footprints,
      human_bike_tracks,
      human_off_road_vehicle,
      human_small_litter,
      human_dumped_trash_bags,
      human_abandoned_vehicles,
      human_graffiti,
      human_injured_plants,
      human_informal_play,
      human_informal_recreation,
      human_informal_living,
      human_sports_equipment,
      human_number_cars,
      human_number_motorcycles,
      human_number_bycicles,
      human_number_houses,
      human_number_rvs,
      appears_maintained,
      appears_professional,
      appears_injured,
      appears_healthy,
      presence_of_open_ground,
      presence_of_trees,
      presence_of_shrubs,
      presence_of_cacti_succ,
      presence_of_lawn,
      presence_of_herbacous_ground,
      presence_of_other,
      presence_of_hand_water,
      presence_of_drip_water,
      presence_of_overhead_water,
      presence_of_flood_water,
      presence_of_subterranean_water,
      presence_of_no_water,
      presence_of_pervious_irrigation,
      human_social_class
    ) VALUES (
      { survey_id },
      { brief_description_of_the_plot },
      { the_weather_today },
      { has_it_rained_recently_when_how_much_what_evidence },
      { rope_intersection },
      { path_through_the_plot },
      { footprints_in_plot },
      { bike_tracks },
      { off_road_vehicle_tracks },
      { small_litter },
      { dumped_trash_bags },
      { abandoned_vehicles },
      { graffiti },
      { injured_plants },
      { informal_play_spaces_e_g_play_houses },
      { informal_recreation_sites_e_g_broken_bottles_shooting_targets },
      { informal_living_site_e_g_homeless_camps_bottles_bonfires_privies },
      { sports_equipment_or_facilities },
      { number_of_cars },
      { number_of_motorcycles },
      { number_of_bicycles },
      { number_of_houses },
      { number_of_recreational_vehicles },
      { does_the_landscape_appear_well_maintained },
      { is_the_landscape_maintained_professionally },
      { are_there_symptoms_or_signs_of_abiotic_or_biotic_injury },
      { are_the_plants_healthy_and_vigorous },
      { indicate_visible_signs_of_human_cultivation_presence_of_open_ground }::boolean,
      { indicate_visible_signs_of_human_cultivation_presence_of_trees }::boolean,
      { indicate_visible_signs_of_human_cultivation_presence_of_shrubs }::boolean,
      { indicate_visible_signs_of_human_cultivation_presence_of_cacti_or_succulents }::boolean,
      { indicate_visible_signs_of_human_cultivation_presence_of_lawn }::boolean,
      { indicate_visible_signs_of_human_cultivation_presence_of_herbaceous_ground_cover }::boolean,
      { indicate_visible_signs_of_human_cultivation_presence_of_other_vegetation_types }::boolean,
      { indicate_visible_signs_of_human_added_irrigation_presence_of_hand_water }::boolean,
      { indicate_visible_signs_of_human_added_irrigation_presence_of_drip_water }::boolean,
      { indicate_visible_signs_of_human_added_irrigation_presence_of_overhead_water }::boolean,
      { indicate_visible_signs_of_human_added_irrigation_presence_of_flood_water }::boolean,
      { indicate_visible_signs_of_human_added_irrigation_presence_of_subterranean_water }::boolean,
      { indicate_visible_signs_of_human_added_irrigation_no_water }::boolean,
      { indicate_visible_signs_of_human_added_irrigation_presence_of_pervious_irrigation }::boolean,
      { approximate_perceived_social_class_of_the_neighborhood }
    )
    ;",
    .con = DBI::ANSI()
  )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_plots_data,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn      = pg
      )
    )
  }
)

data_check <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sampling_events.survey_id,
    sites.site_code,
    -- sampling_events.site_id,
    sampling_events.samp_date,
    sampling_events.kobo_uuid,
    -- human_indicators.*,
    human_indicators_neighborhoods.*
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  JOIN survey200.human_indicators ON (human_indicators.survey_id = sampling_events.survey_id)
  JOIN survey200.human_indicators_neighborhoods ON (human_indicators_neighborhoods.survey_id = sampling_events.survey_id)
  WHERE EXTRACT(year FROM samp_date) = 2023
  ;
  "
)

# tibble::tribble(
#   ~survey_id, ~B,
#   1, 2,
#   4, 3,
#   4, 5
# ) |> 
#   pointblank::col_vals_not_null(
#     columns = c(survey_id),
#     actions = pointblank::stop_on_fail()
#   ) |> 
#   pointblank::row_count_match(count = 4)

plots_empty_cols <- readr::read_csv("kobo/ESCA_plot_2024-04-22-18-29-03-ESCA_plot.csv") |>
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names() |> 
  dplyr::select(tidyselect::where(~ all(is.na(.x))))

# plots_data_cols <- se_plot_data |> 
#   dplyr::select(tidyselect::where(~ any(!is.na(.x))))

# dplyr::right_join(
#   x  = sampling_events,
#   y  = se_plot_data,
#   by = c("kobo_uuid" = "uuid")
# ) |> nrow()

# }}}

# HIN {{{

HIN <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT *
  FROM survey200.human_indicators_neighborhoods
  ;
  "
)

sampling_events <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    survey_id,
    kobo_uuid
  FROM survey200.sampling_events 
  WHERE
    EXTRACT (YEAR from samp_date) = 2023
  ;
  "
)

plot_data <- readr::read_csv("kobo/ESCA_plot_2024-04-22-18-29-03-ESCA_plot.csv") |>
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names() |> 
  dplyr::select(tidyselect::where(~ any(!is.na(.x))))

plot_data <- plot_data |> 
  dplyr::left_join(
    y  = sampling_events,
    by = c("uuid" = "kobo_uuid")
  ) |> 
  pointblank::col_vals_not_null(
    columns = c(survey_id),
    actions = pointblank::stop_on_fail()
  ) |> 
  pointblank::row_count_match(
    count   = nrow(plot_data),
    actions = pointblank::stop_on_fail()
  )

add_hin_data <- plot_data |> 
  glue::glue_data_sql("
    INSERT INTO survey200.human_indicators_neighborhoods (
      survey_id,
      neigh_buildings_residential,
      neigh_buildings_commercial,
      neigh_buildings_institutional,
      neigh_buildings_industrial,
      neigh_residence_apartments,
      neigh_residence_multi_family,
      neigh_residence_single_family,
      neigh_irrigation_drip_trickle,
      neigh_irrigation_flood_hand,
      neigh_irrigation_overhead_spray,
      neigh_yard_upkeep_good,
      neigh_yard_upkeep_poor,
      neigh_yard_upkeep_professionally_maintained,
      neigh_landscape_mesic,
      neigh_landscape_mixed,
      neigh_landscape_xeric,
      neigh_landscape_turf_present,
      neigh_traffic_collector_street,
      neigh_traffic_cul_de_sac,
      neigh_traffic_dirt_road,
      neigh_traffic_freeway_expressway,
      neigh_traffic_highway,
      neigh_traffic_major_city_road,
      neigh_traffic_none,
      neigh_traffic_paved_local_street,
      neigh_notes
    ) VALUES (
      { survey_id },
      { note_all_the_building_types_in_the_neighborhood_neighborhood_buildings_include_residential }::boolean,
      { note_all_the_building_types_in_the_neighborhood_neighborhood_buildings_include_commercial }::boolean,
      { note_all_the_building_types_in_the_neighborhood_neighborhood_buildings_include_institutional }::boolean,
      { note_all_the_building_types_in_the_neighborhood_neighborhood_buildings_include_industrial }::boolean,
      { note_all_the_residence_types_in_the_neighborhood_neighborhood_residences_include_apartments }::boolean,
      { note_all_the_residence_types_in_the_neighborhood_neighborhood_residences_include_multi_family_dwellings }::boolean,
      { note_all_the_residence_types_in_the_neighborhood_neighborhood_residences_include_single_family_dwellings }::boolean,
      { note_all_the_irrigation_types_in_the_neighborhood_neighborhood_irrigation_features_drip_or_trickle }::boolean,
      { note_all_the_irrigation_types_in_the_neighborhood_neighborhood_irrigation_features_flood_or_hand_watering }::boolean,
      { note_all_the_irrigation_types_in_the_neighborhood_neighborhood_irrigation_features_overhead_spraying }::boolean,
      { note_the_general_upkeep_of_the_landscape_in_the_neighborhood_neighborhood_yard_upkeep_is_good }::boolean,
      { note_the_general_upkeep_of_the_landscape_in_the_neighborhood_neighborhood_yard_upkeep_is_poor }::boolean,
      { note_the_general_upkeep_of_the_landscape_in_the_neighborhood_neighborhood_yard_upkeep_is_professionally_maintained }::boolean,
      { note_the_landscape_types_in_the_neighborhood_neighborhood_landscape_is_mesic }::boolean,
      { note_the_landscape_types_in_the_neighborhood_neighborhood_landscape_is_mixed }::boolean,
      { note_the_landscape_types_in_the_neighborhood_neighborhood_landscape_is_xeric }::boolean,
      { note_the_landscape_types_in_the_neighborhood_neighborhood_landscape_features_turf }::boolean,
      { note_the_types_of_roadways_in_the_neighborhood_neighborhood_traffic_features_a_collector_street_99 }::boolean,
      { note_the_types_of_roadways_in_the_neighborhood_neighborhood_traffic_features_a_cul_de_sac_100 }::boolean,
      { note_the_types_of_roadways_in_the_neighborhood_neighborhood_traffic_features_a_dirt_road_101 }::boolean,
      { note_the_types_of_roadways_in_the_neighborhood_neighborhood_traffic_features_a_freeway_or_expressway_102 }::boolean,
      { note_the_types_of_roadways_in_the_neighborhood_neighborhood_traffic_features_a_highway_103 }::boolean,
      { note_the_types_of_roadways_in_the_neighborhood_neighborhood_traffic_features_a_major_city_road_104 }::boolean,
      { note_the_types_of_roadways_in_the_neighborhood_neighborhood_traffic_does_not_feature_roads_of_any_type_105 }::boolean,
      { note_the_types_of_roadways_in_the_neighborhood_neighborhood_traffic_features_a_paved_local_street_106 }::boolean,
      { note_any_unusual_features_such_as_if_the_plot_is_surrounded_by_notably_different_neighborhoods }
    )
    ;",
    .con = DBI::ANSI()
  )


DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_hin_data,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn      = pg
      )
    )
  }
)


# }}}

# soil samples {{{

sampling_events <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    survey_id,
    kobo_uuid
  FROM survey200.sampling_events 
  WHERE
    EXTRACT (YEAR from samp_date) = 2023
  ;
  "
)

plot_data <- readr::read_csv("kobo/ESCA_plot_2024-04-22-18-29-03-ESCA_plot.csv") |>
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names() |> 
  dplyr::select(tidyselect::where(~ any(!is.na(.x))))

plot_data <- plot_data |> 
  dplyr::left_join(
    y  = sampling_events,
    by = c("uuid" = "kobo_uuid")
  ) |> 
  pointblank::col_vals_not_null(
    columns = c(survey_id),
    actions = pointblank::stop_on_fail()
  ) |> 
  pointblank::row_count_match(
    count   = nrow(plot_data),
    actions = pointblank::stop_on_fail()
  )

add_ss_data <- plot_data |> 
  glue::glue_data_sql("
    INSERT INTO survey200.soil_samples (
      survey_id,
      location_description_north,
      north_utm_lat,
      north_utm_long,
      north_utm_altitude,
      north_utm_accuracy,
      location_description_south,
      south_utm_lat,
      south_utm_long,
      south_utm_altitude,
      south_utm_accuracy,
      location_description_west,
      west_utm_lat,
      west_utm_long,
      west_utm_altitude,
      west_utm_accuracy,
      location_description_east,
      east_utm_lat,
      east_utm_long,
      east_utm_altitude,
      east_utm_accuracy,
      location_description_center,
      center_utm_lat,
      center_utm_long,
      center_utm_altitude,
      center_utm_accuracy,
      sampling_notes
    ) VALUES (
      { survey_id },
      { soil_core_location_description_north },
      { soil_core_location_position_north_latitude },
      { soil_core_location_position_north_longitude },
      { soil_core_location_position_north_altitude },
      { soil_core_location_position_north_precision },
      { soil_core_location_description_south },
      { soil_core_location_position_south_latitude },
      { soil_core_location_position_south_longitude },
      { soil_core_location_position_south_altitude },
      { soil_core_location_position_south_precision },
      { soil_core_location_description_west },
      { soil_core_location_position_west_latitude },
      { soil_core_location_position_west_longitude },
      { soil_core_location_position_west_altitude },
      { soil_core_location_position_west_precision },
      { soil_core_location_description_east },
      { soil_core_location_position_east_latitude },
      { soil_core_location_position_east_longitude },
      { soil_core_location_position_east_altitude },
      { soil_core_location_position_east_precision },
      { soil_core_location_description_center },
      { soil_core_location_position_center_latitude },
      { soil_core_location_position_center_longitude },
      { soil_core_location_position_center_altitude },
      { soil_core_location_position_center_precision },
      { notes_regarding_sampling_of_soils }
    )
    ;",
    .con = DBI::ANSI()
  )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_ss_data,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn      = pg
      )
    )
  }
)


# }}}

# photos: plot, syn {{{


sampling_events <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    survey_id,
    kobo_uuid
  FROM survey200.sampling_events 
  WHERE
    EXTRACT (YEAR from samp_date) = 2023
  ;
  "
)

synoptic_data <- readr::read_csv("kobo/ESCA_plot_2024-04-22-18-29-03-synoptic_photos_repeat.csv") |> 
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names() |> 
  dplyr::select(tidyselect::where(~ any(!is.na(.x))))

synoptic_data <- synoptic_data |> 
  dplyr::left_join(
    y  = sampling_events,
    by = c("submission_uuid" = "kobo_uuid")
  ) |> 
  pointblank::col_vals_not_null(
    columns = c(survey_id),
    actions = pointblank::stop_on_fail()
  ) |> 
  pointblank::row_count_match(
    count   = nrow(synoptic_data),
    actions = pointblank::stop_on_fail()
  )

synoptic_data <- synoptic_data |> 
  dplyr::mutate(research_scope = "synoptic") |> 
  dplyr::select(
    survey_id,
    uuid           = submission_uuid,
    media_title    = synoptic_photo_of_the_plot,
    research_scope
  )

add_rm_synoptic <- synoptic_data |> 
  glue::glue_data_sql("
    INSERT INTO survey200.research_media (
      media_title,
      uuid,
      media_type_id
    ) VALUES (
      { media_title },
      { uuid },
      2023
    )
    ;",
    .con = DBI::ANSI()
  )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_rm_synoptic,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn      = pg
      )
    )
  }
)

research_media <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    media_id,
    media_title,
    uuid
  FROM survey200.research_media
  WHERE media_type_id = 2023
  ;
  "
)

add_rmse_synoptic <- dplyr::inner_join(
  x  = synoptic_data,
  y  = reserach_media,
  by = c("uuid", "media_title")
) |> 
  pointblank::col_vals_not_null(
    columns = c(
      survey_id,
      media_id
    ),
    actions = pointblank::stop_on_fail()
  ) |> 
  pointblank::row_count_match(
    count   = nrow(synoptic_data),
    actions = pointblank::stop_on_fail()
  ) |> 
  glue::glue_data_sql("
    INSERT INTO survey200.research_media_sampling_events (
      media_id,
      survey_id,
      research_scope
    ) VALUES (
      { media_id },
      { survey_id },
      { research_scope }
    )
    ;",
    .con = DBI::ANSI()
  )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_rmse_synoptic,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn      = pg
      )
    )
  }
)




plot_data <- readr::read_csv("kobo/ESCA_plot_2024-04-22-18-29-03-ESCA_plot.csv") |>
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names() |> 
  dplyr::select(tidyselect::where(~ any(!is.na(.x))))

plot_data <- plot_data |> 
  dplyr::left_join(
    y  = sampling_events,
    by = c("uuid" = "kobo_uuid")
  ) |> 
  pointblank::col_vals_not_null(
    columns = c(survey_id),
    actions = pointblank::stop_on_fail()
  ) |> 
  pointblank::row_count_match(
    count   = nrow(plot_data),
    actions = pointblank::stop_on_fail()
  )

plot_data <- plot_data |> 
  dplyr::select(
    survey_id,
    uuid,
    contains("center_photo")
  ) |> 
  dplyr::select(!contains("url")) |> 
  tidyr::pivot_longer(
    cols      = contains("photo"),
    names_to  = "context",
    values_to = "media_title"
  ) |> 
  dplyr::mutate(
    research_scope = dplyr::case_when(
      context == "plot_center_photo_north" ~ "plot center north",
      context == "plot_center_photo_south" ~ "plot center south",
      context == "plot_center_photo_west"  ~ "plot center west",
      context == "plot_center_photo_east"  ~ "plot center east"
    )
  ) |> 
  dplyr::filter(!is.na(media_title))

add_rm_plot_center <- plot_data |> 
  glue::glue_data_sql("
    INSERT INTO survey200.research_media (
      media_title,
      uuid,
      media_type_id
    ) VALUES (
      { media_title },
      { uuid },
      2023
    )
    ;",
    .con = DBI::ANSI()
  )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_rm_plot_center,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn      = pg
      )
    )
  }
)


DBI::dbExecute(
  conn      = pg,
  statement = "
  ALTER TABLE survey200.research_media_sampling_events
  ADD CONSTRAINT check_research_scope
  CHECK (research_scope IN (
  'plot center west',
  'synoptic',
  'prokariotic',
  'plot center south',
  'plot center north',
  'plot center east'
  ))
  ;
  "
)

research_media <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    media_id,
    media_title,
    uuid
  FROM survey200.research_media
  WHERE media_type_id = 2023
  ;
  "
)

add_rmse_plot_center <- dplyr::inner_join(
  x  = plot_data,
  y  = reserach_media,
  by = c("uuid", "media_title")
) |> 
  pointblank::col_vals_not_null(
    columns = c(
      survey_id,
      media_id
    ),
    actions = pointblank::stop_on_fail()
  ) |> 
  pointblank::row_count_match(
    count   = nrow(plot_data),
    actions = pointblank::stop_on_fail()
  ) |> 
  glue::glue_data_sql("
    INSERT INTO survey200.research_media_sampling_events (
      media_id,
      survey_id,
      research_scope
    ) VALUES (
      { media_id },
      { survey_id },
      { research_scope }
    )
    ;",
    .con = DBI::ANSI()
  )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_rmse_plot_center,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn      = pg
      )
    )
  }
)

# DBI::dbExecute(conn = pg,
#   statement = "
#   select * from survey200.research_media
#   where extract (year from timestamp_val) = 2024 ;
#   ")

# DBI::dbExecute(conn = pg,
#   statement = "
#   update survey200.research_media
#   set media_type_id = 2023
#   where extract (year from timestamp_val) = 2024 ;
#   ")


# }}}

# plots structures {{{

kobo_fetch <- function(subject) {

  if (!exists("sampling_events")) {

    sampling_events <- DBI::dbGetQuery(
      conn      = pg,
      statement = "
      SELECT
        survey_id,
        kobo_uuid
      FROM survey200.sampling_events 
      WHERE
        EXTRACT (YEAR from samp_date) = 2023
      ;
      "
    )

  }

  subject_data <- readr::read_csv(config::get(subject)) |> 
    dplyr::mutate(
      across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
      across(where(is.character), ~ gsub("[\r\n]", "", .))
    ) |>
    janitor::clean_names() |> 
    dplyr::select(tidyselect::where(~ any(!is.na(.x))))


  if ("uuid" %in% colnames(subject_data)) {

    key_col <- "uuid"

  } else if ("submission_uuid" %in% colnames(subject_data)) {

    key_col <- "submission_uuid"

  } else {

    stop("could not identify uuid col")

  }

  this_by <- dplyr::join_by(!!key_col == kobo_uuid)

  subject_data <- subject_data |> 
    dplyr::left_join(
      y  = sampling_events,
      by = this_by
    ) |> 
    pointblank::col_vals_not_null(
      columns = c(survey_id),
      actions = pointblank::stop_on_fail()
    ) |> 
    pointblank::row_count_match(
      count   = nrow(subject_data),
      actions = pointblank::stop_on_fail()
    )

  return(subject_data)

}


# kobo_fetch("plots")
plot_hs <- kobo_fetch("plot_hs")

DBI::dbExecute(
  conn      = pg,
  statement = "
  ALTER TABLE survey200.human_structures
  ADD COLUMN index INTEGER
  ;
  "
)

add_plot_hs <- plot_hs |> 
  glue::glue_data_sql("
    INSERT INTO survey200.human_structures (
      structure_use,
      height_distance,
      height_degree_up,
      height_degree_down,
      height,
      survey_id,
      index             
    ) VALUES (
      { structure_type },
      { clinometer_distance_m },
      { top_of_building_degree },
      { base_of_building_degree },
      { measured_height_if_not_using_clinometer_m },
      { survey_id },
      { index }
    )
    ;",
    .con = DBI::ANSI()
  )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_plot_hs,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn      = pg
      )
    )
  }
)

hs_db <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT *
  FROM survey200.human_structures
  WHERE EXTRACT (YEAR FROM timestamp_val) = 2024
  ;
  "
)

add_hsse <- dplyr::inner_join(
  x  = plot_hs,
  y  = hs_db,
  by = c("survey_id", "index")
) |> 
  pointblank::col_vals_not_null(
    columns = c(
      survey_id
    ),
    actions = pointblank::stop_on_fail()
  ) |> 
  pointblank::row_count_match(
    count   = nrow(plot_hs),
    actions = pointblank::stop_on_fail()
  ) |> 
  glue::glue_data_sql("
    INSERT INTO survey200.human_structures_sampling_events (
      survey_id,
      structure_id
    ) VALUES (
      { survey_id },
      { structure_id }
    )
    ;",
    .con = DBI::ANSI()
  )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_hsse,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn      = pg
      )
    )
  }
)


# }}}

# plots land use {{{

sampling_events <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    survey_id,
    kobo_uuid
  FROM survey200.sampling_events 
  WHERE
    EXTRACT (YEAR from samp_date) = 2023
  ;
  "
)

lse_classes <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    landuse_classification_id,
    landuse_label
  FROM survey200.landuse_classification 
  ;
  "
)

lse_plots <- readr::read_csv("kobo/ESCA_plot_2024-04-22-18-29-03-lse_repeat.csv") |>
  dplyr::mutate(
    across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
    across(where(is.character), ~ gsub("[\r\n]", "", .))
  ) |>
  janitor::clean_names() |> 
  dplyr::select(tidyselect::where(~ any(!is.na(.x))))

lse_plots <- lse_plots |> 
  dplyr::left_join(
    y  = sampling_events,
    by = c("submission_uuid" = "kobo_uuid")
  ) |> 
  pointblank::col_vals_not_null(
    columns = c(survey_id),
    actions = pointblank::stop_on_fail()
  ) |> 
  pointblank::row_count_match(
    count   = nrow(lse_plots),
    actions = pointblank::stop_on_fail()
  )

lse_plots <- lse_plots |> 
  dplyr::left_join(
    y  = lse_classes,
    by = c("land_use_class" = "landuse_label")
  ) |> 
  dplyr::filter(!is.na(land_use_class_percent))

add_lse_plots <- lse_plots |> 
  glue::glue_data_sql("
    INSERT INTO survey200.landuses_sampling_events (
      survey_id,
      landuse_classification_id,
      landuse_percent
    ) VALUES (
      { survey_id },
      { landuse_classification_id },
      { land_use_class_percent }
    )
    ;",
    .con = DBI::ANSI()
  )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_lse_plots,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn      = pg
      )
    )
  }
)


# }}}

# data check {{{

data_check_new <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sampling_events.survey_id,
    sites.site_code,
    sites.research_focus,
    sampling_events.samp_date,
    human_indicators.human_social_class,
    human_indicators_parcels.parcel_social_class
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  LEFT JOIN survey200.human_indicators ON (human_indicators.survey_id = sampling_events.survey_id)
  LEFT JOIN survey200.human_indicators_parcels ON (human_indicators_parcels.survey_id = sampling_events.survey_id)
  -- WHERE EXTRACT(year FROM samp_date) = 2023
  ;
  "
)

alpha <- dplyr::inner_join(
  x = data_check_old |>
    dplyr::select(
      survey_id,
      human_social_class_oe = human_social_class,
      parcel_social_class_oe = parcel_social_class
    ),
  y = data_check_new,
  by = c("survey_id")
)

data_check <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sampling_events.survey_id,
    sites.site_code,
    sites.research_focus,
    -- sampling_events.site_id,
    sampling_events.samp_date,
    sampling_events.kobo_uuid,
    -- human_indicators.*
    -- human_indicators_neighborhoods.*
    human_indicators_parcels.*
    -- soil_samples.*
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  JOIN survey200.human_indicators ON (human_indicators.survey_id = sampling_events.survey_id)
  JOIN survey200.human_indicators_parcels ON (human_indicators_parcels.survey_id = sampling_events.survey_id)
  -- WHERE EXTRACT(year FROM samp_date) = 2023
  ;
  "
)

data_check <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sampling_events.survey_id,
    sites.site_code,
    sites.research_focus,
    -- sampling_events.site_id,
    sampling_events.samp_date,
    sampling_events.kobo_uuid,
    human_indicators.*,
    -- human_indicators_neighborhoods.*
    human_indicators_parcels.*
    -- soil_samples.*
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  LEFT JOIN survey200.human_indicators ON (human_indicators.survey_id = sampling_events.survey_id)
  LEFT JOIN survey200.human_indicators_neighborhoods ON (human_indicators_neighborhoods.survey_id = sampling_events.survey_id)
  LEFT JOIN survey200.human_indicators_parcels ON (human_indicators_parcels.survey_id = sampling_events.survey_id)
  LEFT JOIN survey200.soil_samples ON (soil_samples.survey_id = sampling_events.survey_id)
  -- WHERE EXTRACT(year FROM samp_date) = 2023
  ;
  "
)

readr::write_csv(data_check, "/tmp/check.csv")

DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    table_name,
    column_name
  FROM information_schema.columns
  WHERE
    column_name LIKE '%residence%'
  ;
  "
)

soil_locs <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sampling_events.samp_date,
    location_description,
    location_description_north,
    location_description_south,
    location_description_west,
    location_description_east,
    location_description_center
  FROM survey200.soil_samples
  JOIN survey200.sampling_events ON (sampling_events.survey_id = soil_samples.survey_id)
  ORDER BY samp_date
  ;
  "
)

media <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sampling_events.survey_id,
    sites.site_code,
    sites.research_focus,
    sampling_events.samp_date,
    sampling_events.kobo_uuid,
    research_media_sampling_events.*,
    research_media.*
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  JOIN survey200.research_media_sampling_events ON (research_media_sampling_events.survey_id = sampling_events.survey_id)
  JOIN survey200.research_media ON (research_media.media_id = research_media_sampling_events.media_id)
  -- WHERE EXTRACT(year FROM samp_date) = 2023
  ;
  "
)

media <- DBI::dbGetQuery(pg, "select * from survey200.research_media ;")

readr::write_csv(media, "/tmp/media.csv")

people <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sampling_events.survey_id,
    sites.site_code,
    sites.research_focus,
    sampling_events.samp_date,
    sampling_events.crew_members,
    sampling_events.kobo_uuid
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  WHERE EXTRACT(year FROM samp_date) = 2023
  ;
  "
)


lse_plots <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sampling_events.survey_id,
    sampling_events.samp_date,
    sites.site_code,
    sites.research_focus,
    landuse_classification.landuse_label,
    landuses_sampling_events.landuse_percent,
    sampling_events.kobo_uuid
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  JOIN survey200.landuses_sampling_events ON (landuses_sampling_events.survey_id = sampling_events.survey_id)
  JOIN survey200.landuse_classification ON (landuse_classification.landuse_classification_id = landuses_sampling_events.landuse_classification_id)
  WHERE EXTRACT(year FROM samp_date) = 2023
  ;
  "
)

readr::write_csv(lse_plots, "/tmp/lse_db.csv")

dplyr::inner_join(
  x  = plot_data,
  y  = lse_plots,
  by = c("uuid" = "submission_uuid")
) |> 
  readr::write_csv("/tmp/lse_kobo.csv")

hs <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sampling_events.survey_id,
    sampling_events.samp_date,
    sites.site_code,
    sites.research_focus,
    sampling_events.kobo_uuid,
    human_structures.*
    -- human_structures.height_distance,
    -- human_structures.height_degree_up,
    -- human_structures.height_degree_down,
    -- human_structures.height
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  LEFT JOIN survey200.human_structures_sampling_events ON (human_structures_sampling_events.survey_id = sampling_events.survey_id)
  LEFT JOIN survey200.human_structures ON (human_structures.structure_id = human_structures_sampling_events.structure_id)
  -- WHERE EXTRACT(year FROM samp_date) = 2023
  ;
  "
)

parcels_synoptic <- dplyr::inner_join(
  x  = kobo_fetch("parcels"),
  y  = kobo_fetch("parcel_synoptic"),
  by = c("uuid" = "submission_uuid")
)

parcel_with_hs <- dplyr::inner_join(
  x  = parcel_data,
  y  = parcel_hs,
  by = c("uuid" = "submission_uuid")
)

# }}}

# scratch {{{

# config

this_config <- config::get(config = "default")
this_config$user
readr::read_csv(this_config$plots)

subject <- "plots"
config::get("plots")
config::get(subject)

indicator_data <- DBI::dbGetQuery(
  conn = pg,
  statement = "
  SELECT
    sampling_events.site_id,
    sites.site_code,
    sites.research_focus,
    sampling_events.samp_date,
    sampling_events.start_time,
    sampling_events.end_time,
    human_indicators.human_bike_tracks
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  JOIN survey200.human_indicators ON (human_indicators.survey_id = sampling_events.survey_id)
  /*
  WHERE
    EXTRACT (YEAR from samp_date) = 2023 AND
    sites.research_focus = 'parcel'
  */
  ;
  "
)




# se_plot_data |> 
#   dplyr::mutate(
#     today = stringr::str_trim(today, side = c("both")),
#     today2 = today
#   ) |> 
#   dplyr::select(
#     site,
#     site_id,
#     today,
#     today2
#   ) |> 
#   dplyr::full_join(
#     y  = se_plot_db |>
#       dplyr::mutate(
#         samp_date = stringr::str_trim(samp_date, side = c("both")),
#         samp_date2 = samp_date
#       ),
#     by = c(
#       "site" = "site_code",
#       "site_id",
#       "today" = "samp_date" # why does this act as a filter?
#     )
#   ) |> readr::write_csv("/tmp/join.csv")

query_sampling_events <- function() {

  base_query <- glue::glue_sql("
    SELECT
      sampling_events.survey_id,
      sampling_events.site_id,
      sampling_events.samp_date,
      sites.site_code
    FROM survey200.sampling_events
    JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
    WHERE
      EXTRACT (YEAR FROM sampling_events.samp_date) > 2016 AND
      sites.research_focus = 'survey200'
    ORDER BY
      sites.site_code DESC
    ;
    ",
    .con = DBI::ANSI()
  )

  sampling_events <- DBI::dbGetQuery(
    conn      = pg,
    statement = base_query
  )

  return(sampling_events)

}

(
  sites <- query_sampling_events() |> 
    # dplyr::mutate(site_code = gsub("1$", "", site_code)) |> 
    dplyr::arrange(site_code) # |> 
    # dplyr::pull(site_code)
)

DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sweepnet_samples.sweepnet_sample_id,
    sweepnet_samples.sweepnet_sample_type,
    sweepnet_samples.vegetation_taxon_id,
    sweepnet_samples.notes,
    vegetation_taxon_list.vegetation_scientific_name
  FROM survey200.sweepnet_samples
  JOIN survey200.vegetation_taxon_list ON (
    vegetation_taxon_list.vegetation_taxon_id = sweepnet_samples.vegetation_taxon_id
    )
  WHERE survey_id = { }
  ;
  "
)


}}}
