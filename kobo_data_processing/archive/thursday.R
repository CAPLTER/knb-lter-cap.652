shrub_survey <- readr::read_csv(config::get("shrub_survey")) |> 
    dplyr::mutate(
        across(where(is.character), ~ stringr::str_trim(., side = c("both"))),
        across(where(is.character), ~ gsub("[\r\n]", "", .))
    ) |>
    janitor::clean_names() |>
    dplyr::select(tidyselect::where(~ any(!is.na(.x))))

sites_db <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT *
  FROM survey200.sites
  ;
  "
)

se_db <- DBI::dbGetQuery(
  conn      = pg,
  statement = "
  SELECT
    sampling_events.survey_id,
    sampling_events.site_id,
    sampling_events.samp_date,
    sites.site_code,
    sites.research_focus
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  WHERE EXTRACT(year FROM samp_date) = 2023
  ;
  "
)

shrub_survey <- shrub_survey |>
    dplyr::left_join(
        y = se_db |>
            dplyr::select(
                survey_id,
                site_id,
                site_code,
                research_focus
            ) |>
            dplyr::mutate(
                research_focus = dplyr::case_when(
                    grepl(
                        pattern     = "survey200",
                        x           = research_focus,
                        ignore.case = TRUE
                    ) ~ "plot",
                    TRUE ~ research_focus
                ),
                # sanity checks
                se_db_site_code = site_code,
                se_db_research_focus = research_focus
            ),
        by = c(
            "site" = "site_code",
            "survey_type" = "research_focus"
        )
    ) |>
    dplyr::mutate(
        start = format(start, "%H:%M:%S"),
        end   = format(end, "%H:%M:%S")
    )

dates_shrubs <- shrub_survey |>
    dplyr::mutate(
        ss_date = date,
        ss_site = site,
        ss_focus = survey_type
    ) |>
    dplyr::select(
        site,
        date,
        date,
        survey_type,
        ss_date,
        ss_site,
        ss_focus
    )
    

dates_se <- se_db |>
    dplyr::mutate(
        research_focus = dplyr::case_when(
            grepl(
                pattern     = "survey200",
                x           = research_focus,
                ignore.case = TRUE
            ) ~ "plot",
            TRUE ~ research_focus
        )
    )

mismatched_dates_sites <- dplyr::full_join(
    x = dates_shrubs,
    y = dates_se,
    by = c(
        "site" = "site_code",
        "survey_type" = "research_focus"
    )
) |>
    dplyr::filter(date != samp_date) |>
    dplyr::distinct(site)

dates_from_soils <- readr::read_csv("~/Dropbox/development/esca_working/dates_from_soils.csv") |>
    janitor::clean_names() |>
    dplyr::mutate(
        coll_date = as.Date(
            x      = coll_date,
            format = "%m/%d/%Y"
        )
    ) |>
    dplyr::select(
        site,
        coll_date
    ) |>
    dplyr::right_join(
        y  = mismatched_dates_sites,
        by = "site"
    )

# the soil data did not have a date for AD19 so we will add it from the tech
# calendar

dates_from_soils <- dates_from_soils |>
    dplyr::mutate(
        coll_date = dplyr::case_when(
            site == "AD19" ~ as.Date("2023-06-01"),
            TRUE ~ coll_date
        )
    )

# they are all plots so do not need to distinguish between plots and parcels

old_date_query <- glue::glue_sql("
  SELECT
    sampling_events.survey_id,
    sampling_events.site_id,
    sampling_events.samp_date AS old_date,
    sites.site_code,
    sites.research_focus
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  WHERE
    site_code IN ({ dates_from_soils$site* })
    AND EXTRACT(year FROM samp_date) = 2023
",
    .con = DBI::ANSI()
)

old_dates <- DBI::dbGetQuery(
    conn      = pg,
    statement = old_date_query
) |>
    dplyr::inner_join(
        y  = dates_from_soils,
        by = c("site_code" = "site")
    ) |>
    dplyr::filter(site_code != "F12") # db value is the correct



update_sites_query <- glue::glue_sql("
  UPDATE survey200.sampling_events
SET samp_date = { dates_from_soils$coll_date }
WHERE 

  SELECT
    sampling_events.survey_id,
    sampling_events.site_id,
    sampling_events.samp_date,
    sites.site_code,
    sites.research_focus
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  WHERE
    site_code IN ({ dates_from_soils$site* })
    AND EXTRACT(year FROM samp_date) = 2023
",
    .con = DBI::ANSI()
)
