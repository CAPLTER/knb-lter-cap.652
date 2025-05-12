
# parcel_characteristics --------------------------------------------------

get_parcel_characteristics <- function(research_focus) {
  
  parcel_characteristics_base_query <- "
    SELECT
      se.samp_date AS sample_date,
      s.site_code,
      hip.parcel_survey_type,
      human_indicators.residence_type,
      hip.parcel_social_class,
      hip.parcel_appearance,
      hip.parcel_orderliness,
      hip.presence_of_bird_feeder,
      hip.presence_of_water_feature,
      hip.presence_of_porch_patio,
      hip.presence_of_cats,
      hip.presence_of_dogs,
      hip.presence_of_pet_waste,
      hip.presence_of_statues,
      hip.presence_of_flagpole,
      hip.presence_of_cars_yard,
      hip.presence_of_potted_plant,
      hip.presence_of_play_equip,
      hip.presence_of_lawn_ornaments,
      hip.presence_of_furniture,
      hip.presence_of_river_bed,
      hip.presence_of_yard_topography,
      hip.presence_of_litter,
      hip.presence_of_veg_litter,
      hip.presence_of_yard_tools,
      hip.presence_of_light_post,
      hip.presence_of_other,
      hip.presence_of_irrigation_flood,
      hip.presence_of_irrigation_drip,
      hip.presence_of_irrigation_hose,
      hip.presence_of_irrigation_sprinklers,
      -- hip.cv_landsc_type_id,
      cvplt.cv_landsc_type_code AS landscape_type,
      -- hip.cv_amount_grass_id,
      cvpag.cv_amount_grass_code AS amount_grass,
      -- hip.cv_weed_grass_id,
      cvpwm.cv_weed_code AS weed_quantity_mesic, 
      -- hip.cv_weed_xeric_id,
      cvpwx.cv_weed_code AS weed_quantity_xeric, 
      hip.presence_of_weeds_other,
      hip.parcel_pruning_trees,
      hip.parcel_pruning_shrubs,
      hip.parcel_grass_patchiness,
      hip.parcel_percent_living_grass,
      hip.parcel_percent_bare,
      hip.parcel_percent_dead,
      hip.parcel_percent_weeds,
      hip.parcel_percent_other,
      hip.parcel_percent_no_stress,
      hip.parcel_percent_little_stress,
      hip.parcel_percent_some_stress,
      hip.parcel_percent_moderate_stress,
      hip.parcel_percent_severe_stress,
      -- hip.cv_lawn_health_id,
      cvplh.cv_lawn_health_code AS lawn_health, 
      -- hip.cv_lawn_quality_id,
      cvplq.cv_lawn_quality_description AS lawn_quality,
      hip.presence_of_lawn_trimmed,
      hip.presence_of_recent_cut,
      hip.parcel_grass_height,
      hip.parcel_weed_height,
      hip.parcel_feature_comments
    FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.human_indicators_parcels hip ON (se.survey_id = hip.survey_id)
    JOIN survey200.human_indicators ON (se.survey_id = human_indicators.survey_id)
    LEFT JOIN survey200.cv_parcel_landscape_type cvplt ON (cvplt.cv_landsc_type_id = hip.cv_landsc_type_id)
    LEFT JOIN survey200.cv_parcel_amount_grass cvpag ON (cvpag.cv_amount_grass_id = hip.cv_amount_grass_id)
    LEFT JOIN survey200.cv_parcel_weeds cvpwm ON (cvpwm.cv_weed_id = hip.cv_weed_grass_id)
    LEFT JOIN survey200.cv_parcel_weeds cvpwx ON (cvpwx.cv_weed_id = hip.cv_weed_xeric_id)
    LEFT JOIN survey200.cv_parcel_lawn_health cvplh ON (cvplh.cv_lawn_health_id = hip.cv_lawn_health_id)
    LEFT JOIN survey200.cv_parcel_lawn_quality cvplq ON (cvplq.cv_lawn_quality_id = hip.cv_lawn_quality_id)
    WHERE
      s.research_focus ~~*?researchFocus 
    ORDER BY 
      EXTRACT (YEAR FROM se.samp_date),
      s.site_code
    ;
    "

  parcel_characteristics_query <- DBI::sqlInterpolate(
    conn          = DBI::ANSI(),
    sql           = parcel_characteristics_base_query,
    researchFocus = research_focus
  )

  parcel_characteristics_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = parcel_characteristics_query
  )
  
  return(parcel_characteristics_data)
  
}

# human_indicators --------------------------------------------------------

get_human_indicators <- function(research_focus) {
  human_indicators_base_query <- "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    -- s.research_focus,
    hi.human_presence_of_path,
    hi.human_footprints,
    hi.human_bike_tracks,
    hi.human_off_road_vehicle,
    hi.human_small_litter,
    hi.human_dumped_trash_bags,
    hi.human_abandoned_vehicles,
    hi.human_graffiti,
    hi.human_injured_plants,
    hi.human_informal_play,
    hi.human_informal_recreation,
    hi.human_informal_living,
    hi.human_sports_equipment,
    hi.human_number_cars,
    hi.human_number_motorcycles,
    hi.human_number_bycicles AS human_number_bicycles,
    hi.human_number_houses,
    hi.human_number_rvs,
    hi.human_social_class --,
    -- hi.weather_on_the_day,
    -- hi.weather_recent_rain_notes --,
    -- hi.general_description
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.human_indicators hi ON se.survey_id = hi.survey_id
  WHERE
    s.research_focus ~~* ?researchFocus
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code
    ;
    "

  human_indicators_query <- DBI::sqlInterpolate(
    conn          = DBI::ANSI(),
    sql           = human_indicators_base_query,
    researchFocus = research_focus
  )

  human_indicators_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = human_indicators_query
  )
  
  human_indicators_data |>
    pointblank::col_vals_equal(
      columns       = n,
      value         = 1,
      preconditions = \(x) x |> dplyr::count(sample_date, site_code),
      actions       = pointblank::warn_on_fail()
    )
  
  return(human_indicators_data)
  
}

# landscape_irrigation ----------------------------------------------------

get_landscape_irrigation <- function(research_focus) {
  
  landscape_irrigation_base_query <- "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    -- s.research_focus,
    hi.appears_maintained,
    hi.appears_professional,
    hi.appears_healthy,
    hi.appears_injured,
    hi.presence_of_open_ground,
    hi.presence_of_trees,
    hi.presence_of_shrubs,
    hi.presence_of_cacti_succ,
    hi.presence_of_lawn,
    hi.presence_of_herbacous_ground AS presence_of_herbaceous_ground,
    hi.presence_of_other,
    hi.presence_of_hand_water,
    hi.presence_of_drip_water,
    hi.presence_of_overhead_water,
    hi.presence_of_flood_water,
    hi.presence_of_subterranean_water,
    hi.presence_of_no_water,
    hi.presence_of_pervious_irrigation --,
    -- hi.weather_on_the_day,
    -- hi.weather_recent_rain_notes --,
    -- hi.general_description
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.human_indicators hi ON se.survey_id = hi.survey_id
  WHERE
    s.research_focus ~~* ?researchFocus
  ORDER BY 
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code
    ;
    "
  
  landscape_irrigation_query <- DBI::sqlInterpolate(
    conn          = DBI::ANSI(),
    sql           = landscape_irrigation_base_query,
    researchFocus = research_focus
  )
  
  landscape_irrigation_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = landscape_irrigation_query
  )
  
  landscape_irrigation_data |>
    pointblank::col_vals_equal(
      columns       = n,
      value         = 1,
      preconditions = \(x) x |> dplyr::count(sample_date, site_code),
      actions       = pointblank::warn_on_fail()
    )
  
  return(landscape_irrigation_data)
  
}


# annuals -----------------------------------------------------------------

get_annuals <- function() {

  get_annuals_base_query <- glue::glue_sql("
  WITH unique_annuals AS (
  SELECT DISTINCT
    sampling_events.survey_id,
    sampling_events.samp_date AS sample_date,
    sites.site_code,
    vegetation_taxon_list.vegetation_scientific_name
  FROM survey200.vegetation_samples 
  JOIN survey200.sampling_events_vegetation_samples ON (vegetation_samples.vegetation_sample_id = sampling_events_vegetation_samples.vegetation_sample_id)
  JOIN survey200.sampling_events ON (sampling_events.survey_id = sampling_events_vegetation_samples.survey_id)
  JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
  JOIN survey200.vegetation_taxon_list ON (vegetation_samples.vegetation_taxon_id = vegetation_taxon_list.vegetation_taxon_id)
  LEFT JOIN survey200.human_indicators ON (human_indicators.survey_id = sampling_events.survey_id)
  WHERE
    sites.research_focus::TEXT = 'survey200' AND
    vegetation_samples.survey_type::TEXT = 'annual'
  )
  SELECT
    unique_annuals.sample_date,
    unique_annuals.site_code,
    unique_annuals.vegetation_scientific_name,
    human_indicators.vegetation_rope_length
  FROM unique_annuals
  LEFT JOIN survey200.human_indicators ON (human_indicators.survey_id = unique_annuals.survey_id) 
  ;
  ",
    .con = DBI::ANSI()
  )

  annuals <- DBI::dbGetQuery(
    conn      = pg,
    statement = get_annuals_base_query
  )
 
  annuals |>
    pointblank::col_vals_equal(
      columns       = n,
      value         = 1,
      preconditions = \(x) x |> dplyr::count(sample_date, site_code),
      actions       = pointblank::warn_on_fail()
    )

  return(annuals)

}


# shrub surveys ----------------------------------------------------------------

get_shrub_surveys <- function() {

  get_shrub_surveys_base_query <- glue::glue_sql("
    SELECT
      sites.site_code,
      -- sites.research_focus,
      sampling_events.samp_date AS sample_date,
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
    ORDER BY
      EXTRACT (YEAR FROM sampling_events.samp_date),
      sites.site_code,
      vegetation_taxon_list.vegetation_scientific_name
    ",
    .con = DBI::ANSI()
  )

  shrub_surveys <- DBI::dbGetQuery(
    conn      = pg,
    statement = get_shrub_surveys_base_query
  ) |>
    pointblank::col_vals_equal(
      columns       = n,
      value         = 1,
      preconditions = \(x) x |> dplyr::count(shrub_perennial_id),
      actions       = pointblank::warn_on_fail(),
      label         = "checking for unique shrub_perennial_id" # label works?
    )

  return(shrub_surveys)

}


# trees -------------------------------------------------------------------

get_trees <- function(research_focus = "survey200") {

  get_trees_base_query <- glue::glue_sql("
    SELECT
      sites.site_code,
      sites.research_focus,
      sampling_events.samp_date AS sample_date,
      vegetation_taxon_list.vegetation_scientific_name,
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
    WHERE
      sites.research_focus = { research_focus }
    ORDER BY
      EXTRACT (YEAR FROM sampling_events.samp_date),
      sites.site_code,
      vegetation_taxon_list.vegetation_scientific_name
    ",
    .con = DBI::ANSI()
  )

  trees <- DBI::dbGetQuery(
    conn      = pg,
    statement = get_trees_base_query
  ) |>
    # confirm unique tree_id
    pointblank::col_vals_equal(
      columns       = n,
      value         = 1,
      preconditions = \(x) x |> dplyr::count(tree_id),
      actions       = pointblank::warn_on_fail()
    )

  return(trees)

}


# number_perennials -------------------------------------------------------

get_perennials <- function() {

  # we will need to know the plant_count_type_id for parcels so this query will
  # work only for plots
  
  number_perennials_base_query <- "
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
        EXTRACT (YEAR FROM sampling_events.samp_date),
        sites.site_code
    ;
    "

  number_perennials_query <- DBI::sqlInterpolate(
    conn          = DBI::ANSI(),
    sql           = number_perennials_base_query
  )
  
  number_perennials_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = number_perennials_query
  ) |>
    # confirm unique: site_code, sample_date, vegetation_scientific_name
    pointblank::col_vals_equal(
      columns       = n,
      value         = 1,
      preconditions = \(x) x |> dplyr::count(site_code, sample_date, vegetation_scientific_name),
      actions       = pointblank::warn_on_fail()
    )

  return(number_perennials_data)

}


# hedges ------------------------------------------------------------------

get_hedges <- function() {
  
  hedges_base_query <- "
  SELECT
    sites.site_code,
    -- sites.research_focus,
    sampling_events.samp_date AS sample_date,
    vegetation_taxon_list.vegetation_scientific_name,
    vegetation_survey_hedges.height,
    vegetation_survey_hedges.width,
    vegetation_survey_hedges.length,
    -- vegetation_survey_hedges.crown_height,
    vegetation_survey_hedges.percent_missing,
    vegetation_survey_hedges.hedge_condition,
    vegetation_survey_hedges.number_of_plants,
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
  ORDER BY
    EXTRACT (YEAR FROM sampling_events.samp_date),
    sites.site_code ASC
  ;
  "

  hedges_query <- DBI::sqlInterpolate(
    conn          = DBI::ANSI(),
    sql           = hedges_base_query,
    researchFocus = research_focus
  )
  
  hedges_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = hedges_query
  )
  
  return(hedges_data)

}


# landuse -----------------------------------------------------------------

get_landuse <- function(research_focus) {
  
  landuse_base_query <- "
  SELECT
    -- se.survey_id,
    se.samp_date AS sample_date,
    s.site_code,
    -- s.research_focus,
    lc.landuse_label,
    lse.landuse_percent
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.landuses_sampling_events lse ON (lse.survey_id = se.survey_id)
    JOIN survey200.landuse_classification lc ON (lc.landuse_classification_id = lse.landuse_classification_id)
  WHERE
    s.research_focus::text = ?researchFocus
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code
    ;
    "
  

  landuse_query <- DBI::sqlInterpolate(
    conn          = DBI::ANSI(),
    sql           = landuse_base_query,
    researchFocus = research_focus
  )
  
  landuse_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = landuse_query
  )
  
  return(landuse_data)

}


# neighborhood_characteristics -------------------------------------------

get_neighborhood_characteristics <- function(research_focus) {
  
  neighborhood_characterization_base_query <- "
  -- neighborhood_characterization  
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    -- s.research_focus,
    hin.neigh_social_class_poor,
    hin.neigh_social_class_rich,
    hin.neigh_social_class_upper_middle,
    hin.neigh_social_class_working_lower,
    hin.neigh_buildings_residential,
    hin.neigh_buildings_commercial,
    hin.neigh_buildings_institutional,
    hin.neigh_buildings_industrial,
    hin.neigh_residence_apartments,
    hin.neigh_residence_multi_family,
    hin.neigh_residence_single_family,
    hin.neigh_irrigation_drip_trickle,
    hin.neigh_irrigation_flood_hand,
    hin.neigh_irrigation_overhead_spray,
    hin.neigh_yard_upkeep_good,
    hin.neigh_yard_upkeep_poor,
    hin.neigh_yard_upkeep_professionally_maintained,
    hin.neigh_landscape_mesic,
    hin.neigh_landscape_mixed,
    hin.neigh_landscape_xeric,
    hin.neigh_landscape_turf_present,
    hin.neigh_traffic_collector_street,
    hin.neigh_traffic_cul_de_sac,
    hin.neigh_traffic_dirt_road,
    hin.neigh_traffic_freeway_expressway,
    hin.neigh_traffic_highway,
    hin.neigh_traffic_major_city_road,
    hin.neigh_traffic_none,
    hin.neigh_traffic_paved_local_street,
    hin.neigh_notes
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.human_indicators_neighborhoods hin ON (hin.survey_id = se.survey_id)
  WHERE
    s.research_focus::text = ?researchFocus
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code
    ;
    "

  neighborhood_characterization_query <- DBI::sqlInterpolate(
    conn          = DBI::ANSI(),
    sql           = neighborhood_characterization_base_query,
    researchFocus = research_focus
  )
  
  neighborhood_characterization_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = neighborhood_characterization_query
  )
  
  neighborhood_characterization_data |>
    pointblank::col_vals_equal(
      columns       = n,
      value         = 1,
      preconditions = \(x) x |> dplyr::count(site_code, sample_date),
      actions       = pointblank::warn_on_fail()
    )
  
  return(neighborhood_characterization_data)

}


# structures -------------------------------------------------

get_structures <- function(research_focus) {
  structures_base_query <- "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    -- s.research_focus,
    hs.structure_use --,
    -- hs.height,
    -- CASE
    --   WHEN hs.height_distance IS NULL THEN hs.height
    --   WHEN hs.height_distance IS NOT NULL THEN NULL
    -- END AS height_measured,
    -- hs.height_distance,
    -- hs.height_degree_up,
    -- hs.height_degree_down
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.human_structures_sampling_events hsse ON se.survey_id = hsse.survey_id
    JOIN survey200.human_structures hs ON hsse.structure_id = hs.structure_id
  WHERE
    s.research_focus::text = ?researchFocus
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code
    ;
    "

  structures_query <- DBI::sqlInterpolate(
    conn          = DBI::ANSI(),
    sql           = structures_base_query,
    researchFocus = research_focus
  )
  
  structures_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = structures_query
  )
  
  return(structures_data)

}



# sampling_events -------------------------------------------------

get_sampling_events <- function(research_focus) {
  
  sampling_events_base_query <- "
  SELECT
    sampling_events.samp_date AS sample_date,
    sites.site_code,
    sites.elevation,
    sites_geography.slope,
    sites_geography.aspect,
    hi.weather_on_the_day,
    hi.weather_recent_rain_notes,
    hi.general_description
  FROM survey200.sampling_events
  JOIN survey200.sites ON (sampling_events.site_id = sites.site_id)
  JOIN survey200.human_indicators hi ON (sampling_events.survey_id = hi.survey_id)
  LEFT JOIN survey200.sites_geography ON (sites_geography.survey_id = sampling_events.survey_id)
  WHERE
    sites.research_focus::text = ?researchFocus
  ORDER BY
    EXTRACT (YEAR FROM sampling_events.samp_date),
    sites.site_code
    ;
    "
  
  sampling_events_query <- DBI::sqlInterpolate(
    conn          = DBI::ANSI(),
    sql           = sampling_events_base_query,
    researchFocus = research_focus
  )
  
  sampling_events_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = sampling_events_query
  )
  
  return(sampling_events_data)
  
}


# soil_center_cores -------------------------------------------------------

get_soil_center_cores <- function() {
  
  soil_center_cores_base_query <- "
    SELECT
      sampling_events.samp_date AS sample_date,
      sites.site_code,
      -- CASE
      --  WHEN EXTRACT (YEAR FROM se.samp_date) < 2015 THEN ss.location_description
      --  WHEN EXTRACT (YEAR FROM se.samp_date) = 2015 THEN ss.location_description_center
      -- END AS core_location_description,
      -- */
      soil_samples.sampling_notes,
      scc.core_height_cm,
      scc.soil_bulkdensity_fw,
      scc.dw_more_2_mm,
      scc.dw_less_2_mm,
      scc.plant_matter,
      scc.conductivity,
      scc.ph_value,
      scc.pan,
      scc.pan_plus_fw,
      scc.pan_plus_dw60,
      scc.pan_plus_dw105,
      scc.soil_texture_fw,
      scc.temperature,
      scc.r05,
      scc.r1,
      scc.t1,
      scc.r90,
      scc.t90,
      scc.r1440,
      scc.t1440,
      scc.notes,
      scc.cal_texture_fw,
      scc.cal_temp,
      scc.cal_r05,
      scc.cal_r1,
      scc.cal_t1,
      scc.cal_r90,
      scc.cal_t90,
      scc.cal_r1440,
      scc.cal_t1440,
      scc.cal_run_date
    FROM
      survey200.soil_samples
    JOIN survey200.sampling_events ON (sampling_events.survey_id = soil_samples.survey_id)
    JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
    JOIN survey200.soil_center_cores scc ON (scc.soil_sample_id = soil_samples.soil_sample_id)
    ORDER BY
      EXTRACT (YEAR FROM sampling_events.samp_date),
      sites.site_code
    ;
    "
  
  soil_center_cores_query <- DBI::sqlInterpolate(
    conn = DBI::ANSI(),
    sql  = soil_center_cores_base_query
  )

  soil_center_cores_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = soil_center_cores_query
  )

  return(soil_center_cores_data)
  
}


# soil_texture_2000 -------------------------------------------------------

get_soil_texture_2000 <- function() {
  
  soil_texture_2000_base_query <- "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    CAST (st2.analysis_date AS date),
    st2.temperature,
    st2.r05,
    st2.rl05,
    st2.r1,
    st2.rl1,
    st2.t1,
    st2.r90,
    st2.rl90,
    st2.t90,
    st2.r1440,
    st2.rl1440,
    st2.t1440,
    st2.clay_percentoriginal,
    st2.sand_percentoriginal,
    st2.silt_percentoriginal,
    st2.claypercentcorrected,
    st2.sandpercentcorrected,
    st2.siltpercentcorrected,
    st2.notes
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.soil_texture_2000 st2 ON se.survey_id = st2.survey_id
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code
    ;
    "
  
  soil_texture_2000_query <- DBI::sqlInterpolate(
    conn = DBI::ANSI(),
    sql  = soil_texture_2000_base_query
  )
  
  soil_texture_2000_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = soil_texture_2000_query
  )
  
  return(soil_texture_2000_data)
  
}


# soil_lachat -------------------------------------------------------------

get_soil_lachat <- function() {
  
  soil_lachat_base_query <- "
    SELECT
      sampling_events.samp_date AS sample_date,
      sites.site_code,
      sl.deep_core_type,
      sl.sample_id,
      sl.sample_type,
      sl.replicate_number,
      sl.repeat_number,
      sl.cup_number,
      sl.manual_dilution_factor,
      sl.auto_dilution_factor,
      sl.weight_units,
      sl.weight,
      sl.units,
      sl.detection_date,
      sl.detection_time,
      sl.user_name,
      sl.run_file_name,
      sl.description,
      sl.channel_number,
      sl.analyte_name,
      sl.peak_concentration,
      sl.determined_conc,
      sl.concentration_units,
      sl.peak_area,
      sl.peak_height,
      sl.calibration_equation,
      sl.retention_time,
      sl.inject_to_peak_start,
      sl.conc_x_adf,
      sl.conc_x_mdf,
      sl.conc_x_adf_x_mdf
    FROM
      survey200.soil_samples
    JOIN survey200.sampling_events ON (sampling_events.survey_id = soil_samples.survey_id)
    JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
    RIGHT JOIN survey200.soil_lachat sl ON (soil_samples.soil_sample_id = sl.soil_sample_id)
    WHERE
      sample_type ~~* 'unknown' AND
      sample_id !~~* '%blank%'
    ORDER BY
      sl.detection_date,
      sl.detection_time
    ;
    "
  
  soil_lachat_query <- DBI::sqlInterpolate(
    conn = DBI::ANSI(),
    sql  = soil_lachat_base_query
  )
  
  soil_lachat_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = soil_lachat_query
  )
  
  return(soil_lachat_data)
  
}


# soil_traacs -------------------------------------------------------------

get_soil_traacs <- function() {
  
  soil_traacs_base_query <- "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    st.deep_core_type,
    -- st.sample_sequence,
    st.sample_id,
    st.sample_set,
    st.conc_mg_l,
    st.survey_year,
    st.analyte
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.soil_samples ss ON se.survey_id = ss.survey_id
    RIGHT JOIN survey200.soil_traacs st ON (ss.soil_sample_id = st.soil_sample_id)
  ORDER BY
    st.sample_sequence
    ;
    "
  
  soil_traacs_query <- DBI::sqlInterpolate(
    conn = DBI::ANSI(),
    sql  = soil_traacs_base_query
  )
  
  soil_traacs_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = soil_traacs_query
  )
  
  return(soil_traacs_data)
  
}

# soil_perimeter_core -----------------------------------------------------

get_soil_perimeter_cores <- function() {
  
  soil_perimeter_cores_base_query <- "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    spc.deep_core_type,
    spc.pan,
    spc.pan_plus_fw,
    spc.pan_plus_dw60,
    spc.pan_plus_aw,
    spc.soil_n_fw,
    spc.n_extract_volume,
    spc.nh4_n,
    spc.no3_n,
    spc.soil_p_fw,
    spc.p_extract_volume,
    spc.po4_p,
    spc.percent_total_c,
    spc.percent_inorg_c,
    spc.percent_total_n
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON (se.site_id = s.site_id)
    JOIN survey200.soil_samples ss ON (se.survey_id = ss.survey_id)
    JOIN survey200.soil_perimeter_cores spc ON (ss.soil_sample_id = spc.soil_sample_id)
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code
    ;
    "
  
  soil_perimeter_cores_query <- DBI::sqlInterpolate(
    conn = DBI::ANSI(),
    sql  = soil_perimeter_cores_base_query
  )
  
  soil_perimeter_cores_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = soil_perimeter_cores_query
  )
  
  return(soil_perimeter_cores_data)
  
}


# arthropods --------------------------------------------------------------

# Note that this query is throttled to not include 2023 results as those
# samples have not been completed at the time of publication.

get_arthropods <- function() {
  
  arthropods_base_query <- "
    SELECT
      sampling_events.samp_date AS sample_date,
      sites.site_code,
      sweepnet_samples.sweepnet_sample_type,
      vegetation_taxon_list.vegetation_scientific_name AS substratum,
      itl.insect_scientific_name AS arthropod_scientific_name,
      ssic.count_of_insect AS number_of_arthropods,
      sweepnet_samples.notes
    FROM
      survey200.sweepnet_samples
    JOIN survey200.sampling_events ON (sampling_events.survey_id = sweepnet_samples.survey_id)
    JOIN survey200.sites ON (sites.site_id = sampling_events.site_id)
    LEFT JOIN survey200.vegetation_taxon_list ON (vegetation_taxon_list.vegetation_taxon_id = sweepnet_samples.vegetation_taxon_id)
    JOIN survey200.sweepnet_sample_insect_counts ssic ON (sweepnet_samples.sweepnet_sample_id = ssic.sweepnet_sample_id)
    JOIN survey200.insect_taxon_list itl ON (itl.insect_taxon_id = ssic.insect_taxon_id)
    WHERE
      EXTRACT (YEAR FROM sampling_events.samp_date) < 2023
    ORDER BY
      EXTRACT (YEAR FROM sampling_events.samp_date),
      sites.site_code,
      vegetation_taxon_list.vegetation_scientific_name
    ;
    "

  arthropods_query <- DBI::sqlInterpolate(
    conn = DBI::ANSI(),
    sql  = arthropods_base_query
  )
  
  arthropods_data <- DBI::dbGetQuery(
    conn      = pg,
    statement = arthropods_query
  )
  
  return(arthropods_data)
  
}
