source("~/Documents/localSettings/pg_local.R")

pg    <- pg_local_connect("caplter")
pgOLD <- pg_local_connect()

base_query <- "
  SELECT
    sampling_events.samp_date AS sample_date,
    sites.site_code,
    sweepnet_samples.sweepnet_sample_type,
    vegetation_taxon_list.vegetation_scientific_name,
    insect_taxon_list.insect_scientific_name,
    sweepnet_sample_insect_counts.count_of_insect,
    sweepnet_sample_insect_counts.insect_count_id,
    sweepnet_sample_insect_counts.immature, -- remove from old
    sweepnet_samples.notes
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  JOIN survey200.sweepnet_samples ON (sweepnet_samples.survey_id = sampling_events.survey_id)
  LEFT JOIN survey200.vegetation_taxon_list ON (vegetation_taxon_list.vegetation_taxon_id = sweepnet_samples.vegetation_taxon_id)
  JOIN survey200.sweepnet_sample_insect_counts ON (sweepnet_sample_insect_counts.sweepnet_sample_id = sweepnet_samples.sweepnet_sample_id)
  JOIN survey200.insect_taxon_list ON (sweepnet_sample_insect_counts.insect_taxon_id = insect_taxon_list.insect_taxon_id)
  -- WHERE
  --   EXTRACT (YEAR FROM se.samp_date) <= 2010
  ORDER BY
    EXTRACT (YEAR FROM sampling_events.samp_date),
    sites.site_code,
    vegetation_taxon_list.vegetation_scientific_name
  ;
  "  

current <- DBI::dbGetQuery(pg, base_query)
old     <- DBI::dbGetQuery(pgOLD, base_query)

dplyr::full_join(
  current |> 
    dplyr::count(sample_date, site_code) |> 
    dplyr::mutate(source = "current"),
  old |> 
    dplyr::count(sample_date, site_code) |> 
    dplyr::mutate(
      source = "old",
      site_code = gsub("1$", "", site_code)
    ),
  by = c("sample_date", "site_code"),
  suffix = c("_x", "_y")
) |> 
  readr::write_csv("/tmp/current_old.csv")

readr::write_csv(current, "/tmp/current.csv")
readr::write_csv(old, "/tmp/old.csv")

dplyr::full_join(
  current |> 
    dplyr::mutate(source = "current"),
  old |> 
    dplyr::mutate(
      source = "old",
      site_code = gsub("1$", "", site_code)
    ),
  by = c("insect_count_id"),
  suffix = c("_x", "_y")
) |> 
  readr::write_csv("/tmp/current_old_id.csv")
