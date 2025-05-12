source("~/Documents/localSettings/pg_local.R")
pg <- pg_local_connect("caplter")

# THIRD

safe_get_ids <- purrr::possibly(
  .f        = taxadb::get_ids,
  otherwise = NULL
)

# first pass at matching VTL taxa to GBIF

matched_taxa <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
    SELECT
      vegetation_taxon_id,
      vegetation_scientific_name,
      archive
    FROM
      survey200.vegetation_taxon_list
;
"
) |>
  dplyr::mutate(
    taxa_db_id = safe_get_ids(
      names    = vegetation_scientific_name,
      provider = "gbif",
      format   = "bare",
      warn     = TRUE
    ),
    authority = dplyr::case_when(
      is.na(taxa_db_id) ~ NA,
      TRUE ~ "GBIF"
    )
  )


# FIRST

# address obvious cases of misidentification and misspellings from a first pass
# comparing VTL taxa to GBIF

recode_taxon <- function(
    old_code,
    new_code
    ) {

  recode_vs <- glue::glue_sql("
  UPDATE survey200.vegetation_samples
  SET vegetation_taxon_id = { new_code }
  WHERE vegetation_taxon_id = { old_code }
  ;
  ",
    .con = DBI::ANSI()
  )

  recode_ss <- glue::glue_sql("
  UPDATE survey200.sweepnet_samples
  SET vegetation_taxon_id = { new_code }
  WHERE vegetation_taxon_id = { old_code }
  ;
  ",
    .con = DBI::ANSI()
  )

  vtl_archive <- glue::glue_sql("
  UPDATE survey200.vegetation_taxon_list
  SET archive = TRUE
  WHERE vegetation_taxon_id = { old_code }
  ;
  ",
    .con = DBI::ANSI()
  )

  updates <- c(
    recode_vs,
    recode_ss,
    vtl_archive
  )

  DBI::dbWithTransaction(
    conn = pg,
    {
      purrr::walk(
        .x = updates,
        .f = ~ DBI::dbExecute(
          statement = .x,
          conn      = pg
        )
      )
    }
  )

}

recode_taxon(61,   2534) # Acacia constricta
recode_taxon(1383, 4064) # Amsinckia tessellata
recode_taxon(2683, 4213) # Aristida adscensionis
recode_taxon(2957, 3948) # Carpobrotus
recode_taxon(2775, 3780) # Citrus (??)
recode_taxon(3781, 3780) # Citrus (x)
recode_taxon(292,  4228) # Hardenbergia violacea
recode_taxon(4272, 4077) # Lycianthes rantonnetii
recode_taxon(3983, 3835) # Lycium A or B
recode_taxon(3984, 3835) # Lycium E or F
recode_taxon(4238, 1539) # Melilotus indicus
recode_taxon(180,  2903) # Myoporum parvifolium
recode_taxon(1835, 3895) # Pennisetum ciliare
recode_taxon(3960, 2772) # Vauquelinia californica
recode_taxon(2850, 4125) # Vitex agnus-castus
recode_taxon(3961, 4210) # Iceplant to Aizoaceae
recode_taxon(799,  4117) # Euphorbia tirucali to Euphorbia tirucalli

# formerly Vitex agnus-castus CHECK!
DBI::dbExecute(
  conn      = pg,
  statement = "
  UPDATE survey200.vegetation_taxon_list
  SET vegetation_scientific_name = 'Vitex agnus-castus'
  WHERE vegetation_taxon_id = 4125
  ;
  "
)

# formerly Euonymus japonica
DBI::dbExecute(
  conn      = pg,
  statement = "
  UPDATE survey200.vegetation_taxon_list
  SET vegetation_scientific_name = 'Euonymus japonicus'
  WHERE vegetation_taxon_id = 21
  ;
  "
)

# FOURTH

# a second pass of matching VTL taxa to GBIF having addressed some obvious
# spelling errors and misidentifications

matched_taxa_II <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
    SELECT
      vegetation_taxon_id,
      vegetation_scientific_name,
      archive
    FROM
      survey200.vegetation_taxon_list
    WHERE
      archive = FALSE AND
      vegetation_scientific_name !~ '[0-9]' AND
      vegetation_scientific_name !~* 'cf'
;
"
) |>
  dplyr::mutate(
    taxa_db_id = safe_get_ids(
      names    = vegetation_scientific_name,
      provider = "gbif",
      format   = "bare",
      warn     = TRUE
    ),
    authority = dplyr::case_when(
      is.na(taxa_db_id) ~ NA,
      TRUE ~ "GBIF"
    )
  ) |>
  dplyr::filter(is.na(taxa_db_id))

safe_filter_name <- purrr::possibly(
  .f        = taxadb::filter_name,
  otherwise = NULL
)

# a third pass of matching VTL taxa to GBIF this time using the taxadb::filter_name function 
# spelling errors and misidentifications

VTL <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    vegetation_taxon_id,
    vegetation_scientific_name,
    archive
  FROM
    survey200.vegetation_taxon_list
  WHERE
    archive = FALSE AND
    authority_id IS NULL
  ;
  "
)

VTL_gbif <- VTL |>
  split(VTL$vegetation_taxon_id) |>
  {
    \(df) purrr::map_dfr(
      .x = df,
      .f = ~ safe_filter_name(
        name     = .x$vegetation_scientific_name,
        provider = "gbif"
      ) |>
        dplyr::mutate(
          authority  = "GBIF",
          taxa_db_id = stringr::str_extract(taxonID, "\\d+")
        ) |>
        dplyr::filter(
          taxonomicStatus == "accepted",
          kingdom         == "Plantae"
        ) |>
        dplyr::select(
          vegetation_scientific_name = scientificName,
          taxa_db_id,
          authority
        )
    )
  }()

# add taxa authority ids to the VTL taxa table

add_authority <- VTL |>
  dplyr::left_join(
    y  = VTL_gbif,
    by = c("vegetation_scientific_name" = "vegetation_scientific_name")
  ) |>
  dplyr::filter(!is.na(taxa_db_id)) |>
  glue::glue_data_sql("
    UPDATE survey200.vegetation_taxon_list
    SET authority_id = { taxa_db_id },
    authority = { authority }
    WHERE vegetation_taxon_id = { vegetation_taxon_id }
    ;
    ",
    .con = DBI::ANSI()
  )

# all_resolved_taxa <- VTL |>
#   dplyr::left_join(
#     dplyr::bind_rows(
#       matched_taxa |>
#         dplyr::filter(!is.na(taxa_db_id)) |>
#         dplyr::select(
#           vegetation_scientific_name,
#           taxa_db_id,
#           authority
#         ),
#       matched_taxa_II_gbif
#     ),
#     by = c("vegetation_scientific_name" = "vegetation_scientific_name")
#   )


# add_authority <- all_resolved_taxa |>
#   glue::glue_data_sql("
#     UPDATE survey200.vegetation_taxon_list
#     SET archive = { archive }::boolean,
#     authority_id = { taxa_db_id },
#     authority = { authority }
#     WHERE vegetation_taxon_id = { vegetation_taxon_id }
#     ;
#     ",
#     .con = DBI::ANSI()
#   )

DBI::dbWithTransaction(
  conn = pg,
  {
    purrr::walk(
      .x = add_authority,
      .f = ~ DBI::dbExecute(
        statement = .x,
        conn = pg
      )
    )
  }
)


# SECOND

recode_iterative_taxons <- function(
    old_code,
    new_code
    ) {

  old_note_query <- glue::glue_sql("
  SELECT
  vegetation_scientific_name
  FROM survey200.vegetation_taxon_list
  WHERE vegetation_taxon_id = { old_code }
  ;
  ",
    .con = DBI::ANSI()
  )

  old_note <- DBI::dbGetQuery(
    conn      = pg,
    statement = old_note_query
  )

  add_note <- glue::glue_sql("
  UPDATE survey200.vegetation_samples
  SET tablet_taxon_note = { old_note$vegetation_scientific_name }
  WHERE vegetation_taxon_id = { old_code }
  ;
  ",
    .con = DBI::ANSI()
  )

  recode_vs <- glue::glue_sql("
  UPDATE survey200.vegetation_samples
  SET vegetation_taxon_id = { new_code }
  WHERE vegetation_taxon_id = { old_code }
  ;
  ",
    .con = DBI::ANSI()
  )

  recode_ss <- glue::glue_sql("
  UPDATE survey200.sweepnet_samples
  SET vegetation_taxon_id = { new_code }
  WHERE vegetation_taxon_id = { old_code }
  ;
  ",
    .con = DBI::ANSI()
  )

  vtl_archive <- glue::glue_sql("
  UPDATE survey200.vegetation_taxon_list
  SET archive = TRUE
  WHERE vegetation_taxon_id = { old_code }
  ;
  ",
    .con = DBI::ANSI()
  )

  updates <- c(
    add_note,
    recode_vs,
    recode_ss,
    vtl_archive
  )

  DBI::dbWithTransaction(
    conn = pg,
    {
      purrr::walk(
        .x = updates,
        .f = ~ DBI::dbExecute(
          statement = .x,
          conn      = pg
        )
      )
    }
  )

}

# Acacia
recode_iterative_taxons(4191, 3372)
recode_iterative_taxons(4192, 3372)
# Agave
recode_iterative_taxons(4148, 2944)
recode_iterative_taxons(4149, 2944)
recode_iterative_taxons(4151, 2944)
recode_iterative_taxons(4152, 2944)
recode_iterative_taxons(4153, 2944)
recode_iterative_taxons(4154, 2944)
# Aloe
recode_iterative_taxons(4155, 2962)
recode_iterative_taxons(4156, 2962)
recode_iterative_taxons(4157, 2962)
# Bougainvillea
recode_iterative_taxons(4054, 3583)
# Cactaceae
recode_iterative_taxons(4113, 4218)
recode_iterative_taxons(4114, 4218)
recode_iterative_taxons(4115, 4218)
recode_iterative_taxons(3902, 4218)
recode_iterative_taxons(3904, 4218)
# Cereus
recode_iterative_taxons(4119, 3236)
recode_iterative_taxons(4120, 3236)
# Crassulaceae
recode_iterative_taxons(4181, 4086)
recode_iterative_taxons(4182, 4086)
# Cupressaceae
recode_iterative_taxons(4082, 3985)
recode_iterative_taxons(4081, 3985)
# Cylindropuntia
recode_iterative_taxons(4163, 3241)
recode_iterative_taxons(4164, 3241)
# Eucalyptus
recode_iterative_taxons(4188, 3571)
recode_iterative_taxons(4189, 3571)
# Ferocactus
recode_iterative_taxons(4140, 3246)
recode_iterative_taxons(4141, 3246)
# Jasminum
recode_iterative_taxons(4169, 3590)
recode_iterative_taxons(4170, 3590)
# Lycium
recode_iterative_taxons(4073, 3835)
recode_iterative_taxons(4074, 3835)
recode_iterative_taxons(4075, 3835)
# Opuntia
recode_iterative_taxons(4048, 3255)
recode_iterative_taxons(4049, 3255)
# Poaceae
recode_iterative_taxons(4100, 3888)
recode_iterative_taxons(4101, 3888)
recode_iterative_taxons(4102, 3888)
recode_iterative_taxons(4103, 3888)
recode_iterative_taxons(4208, 3888)
# Sphaeralcea
recode_iterative_taxons(4058, 3553)
recode_iterative_taxons(4059, 3553)
# Yucca
recode_iterative_taxons(4196, 2955)
recode_iterative_taxons(4197, 2955)
# unknown
recode_iterative_taxons(3906, 4376)
recode_iterative_taxons(3890, 4376)
recode_iterative_taxons(3891, 4376)
recode_iterative_taxons(3892, 4376)
recode_iterative_taxons(3940, 4376)
recode_iterative_taxons(3964, 4376)
recode_iterative_taxons(4201, 4376)
recode_iterative_taxons(4055, 4376)
recode_iterative_taxons(4056, 4376)