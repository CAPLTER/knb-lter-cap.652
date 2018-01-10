
# parcel_characteristics --------------------------------------------------

get_parcel_characteristics <- function(research_focus) {
  
  parcel_characteristics_base_query <- "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    -- s.research_focus,
    -- hip.parcel_survey_id,
    -- hip.survey_id,
    hip.parcel_survey_type,
    hip.parcel_residence_type,
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
    JOIN survey200.human_indicators_parcels hip ON se.survey_id = hip.survey_id
    LEFT JOIN survey200.cv_parcel_landscape_type cvplt ON (cvplt.cv_landsc_type_id = hip.cv_landsc_type_id)
    LEFT JOIN survey200.cv_parcel_amount_grass cvpag ON (cvpag.cv_amount_grass_id = hip.cv_amount_grass_id)
    LEFT JOIN survey200.cv_parcel_weeds cvpwm ON (cvpwm.cv_weed_id = hip.cv_weed_grass_id)
    LEFT JOIN survey200.cv_parcel_weeds cvpwx ON (cvpwx.cv_weed_id = hip.cv_weed_xeric_id)
    LEFT JOIN survey200.cv_parcel_lawn_health cvplh ON (cvplh.cv_lawn_health_id = hip.cv_lawn_health_id)
    LEFT JOIN survey200.cv_parcel_lawn_quality cvplq ON (cvplq.cv_lawn_quality_id = hip.cv_lawn_quality_id)
  WHERE
    s.research_focus ~~* ?researchFocus
  ORDER BY 
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code;"

  parcel_characteristics_query <- sqlInterpolate(ANSI(),
                                                 parcel_characteristics_base_query,
                                                 researchFocus = research_focus)
  
  parcel_characteristics_data <- dbGetQuery(pg, parcel_characteristics_query)
  
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
    s.site_code;"
  
  human_indicators_query <- sqlInterpolate(ANSI(),
                                           human_indicators_base_query,
                                           researchFocus = research_focus)
  
  human_indicators_data <- dbGetQuery(pg, human_indicators_query)
  
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
    s.site_code;"
  
  landscape_irrigation_query <- sqlInterpolate(ANSI(),
                                               landscape_irrigation_base_query,
                                               researchFocus = research_focus)
  
  landscape_irrigation_data <- dbGetQuery(pg, landscape_irrigation_query)
  
  return(landscape_irrigation_data)
  
}


# annuals -----------------------------------------------------------------

get_annuals <- function() {
  
  annuals_base_query <- "
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
    -- vs.survey_type
    hi.vegetation_rope_length
    FROM survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.sampling_events_vegetation_samples sevs ON se.survey_id = sevs.survey_id
    JOIN survey200.vegetation_samples vs ON sevs.vegetation_sample_id = vs.vegetation_sample_id
    JOIN survey200.vegetation_taxon_list vtl ON vs.vegetation_taxon_id = vtl.vegetation_taxon_id
    JOIN survey200.human_indicators hi ON (hi.survey_id = se.survey_id)
  WHERE
    s.research_focus::text = 'survey200'::text AND
    vs.survey_type::text = 'annual'::text
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code;"
  
  annuals_query <- sqlInterpolate(ANSI(),
                                  annuals_base_query)
  
  annuals_data <- dbGetQuery(pg, annuals_query)
  
  return(annuals_data)
  
}


# shrubs_cacti_succulents -------------------------------------------------

get_shrubs_cacti_succulents <- function(research_focus) {
  
  shrubs_cacti_succulents_base_query <- "
  -- shrubs
  SELECT
    EXTRACT (YEAR FROM samp_date) AS year,
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
    cvvc.vegetation_classification_code,
    -- vssp.height,
    CASE
      WHEN vssp.height_distance IS NULL THEN vssp.height
      WHEN vssp.height_distance IS NOT NULL THEN NULL
    END AS height_measured,
    vssp.height_distance,
    vssp.height_degree_up,
    vssp.height_degree_down,
    vssp.width_ns,
    vssp.width_ew,
    vssp.stem_diameter,
    NULL AS stem_height --,
    -- vssp.distance_ns,
    -- vssp.direction_ns,
    -- vssp.distance_ew,
    -- vssp.direction_ew
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.sampling_events_vegetation_samples sevs ON se.survey_id = sevs.survey_id
    JOIN survey200.vegetation_samples vs ON sevs.vegetation_sample_id = vs.vegetation_sample_id
    JOIN survey200.vegetation_taxon_list vtl ON vs.vegetation_taxon_id = vtl.vegetation_taxon_id
    JOIN survey200.vegetation_survey_shrub_perennials vssp ON vs.vegetation_sample_id = vssp.vegetation_sample_id
    LEFT JOIN survey200.cv_vegetation_shapes cvvs ON vssp.vegetation_shape_id = cvvs.vegetation_shape_id
    LEFT JOIN survey200.cv_vegetation_classifications cvvc ON vssp.vegetation_classification_id = cvvc.vegetation_classification_id
  WHERE
    s.research_focus::text = ?researchFocus
    -- AND vs.survey_type::text = 'shrub'::text
  UNION ALL
  -- cacti_succulents
  SELECT
    EXTRACT (YEAR FROM samp_date) AS year,
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
    NULL AS vegetation_shape_code,
    cvvc.vegetation_classification_code,
    -- vscs.height,
    CASE
      WHEN vscs.height_distance IS NULL THEN vscs.height
      WHEN vscs.height_distance IS NOT NULL THEN NULL
    END AS height_measured,
    vscs.height_distance,
    vscs.height_degree_up,
    vscs.height_degree_down,
    vscs.width_ns,
    vscs.width_ew,
    vscs.stem_diameter,
    vscs.stem_height --,
    -- vscs.distance_ns,
    -- vscs.direction_ns,
    -- vscs.distance_ew,
    -- vscs.direction_ew
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.sampling_events_vegetation_samples sevs ON se.survey_id = sevs.survey_id
    JOIN survey200.vegetation_samples vs ON sevs.vegetation_sample_id = vs.vegetation_sample_id
    JOIN survey200.vegetation_taxon_list vtl ON vs.vegetation_taxon_id = vtl.vegetation_taxon_id
    JOIN survey200.vegetation_survey_cacti_succ vscs ON vs.vegetation_sample_id = vscs.vegetation_sample_id
    LEFT JOIN survey200.cv_vegetation_classifications cvvc ON vscs.vegetation_classification_id = cvvc.vegetation_classification_id
  WHERE
    s.research_focus::text = ?researchFocus
    -- AND vs.survey_type::text = 'cacti'::text
  ORDER BY
    year,
    site_code;"  
  
  shrubs_cacti_succulents_query  <- sqlInterpolate(ANSI(),
                                                   shrubs_cacti_succulents_base_query,
                                                   researchFocus = research_focus)
  
  shrubs_cacti_succulents_data <- dbGetQuery(pg, shrubs_cacti_succulents_query)
  
  return(shrubs_cacti_succulents_data)
  
}

# trees -------------------------------------------------------------------

get_trees <- function(research_focus) {
  
  trees_base_query <- "
  -- trees
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
    cvvc.vegetation_classification_code,
    -- vst.height_in_m AS height,
    CASE
      WHEN vst.height_distance IS NULL THEN vst.height_in_m
      WHEN vst.height_distance IS NOT NULL THEN NULL
    END AS height_measured,
    vst.height_distance,
    vst.height_degree_up,
    vst.height_degree_down,
    vst.bottom_canopy_height,
    vst.crown_deg_down,
    vst.crown_width_ns AS width_ns,
    vst.crown_width_ew AS width_ew,
    vst.stem_diameter,
    vst.stem_diameter_at AS stem_height,
    vst.stem_count,
    vst.missing_branches,
    vst.canopy_condition --,
    -- vst.distance_ns,
    -- vst.direction_ns,
    -- vst.distance_ew,
    -- vst.direction_ew
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.sampling_events_vegetation_samples sevs ON se.survey_id = sevs.survey_id
    JOIN survey200.vegetation_samples vs ON sevs.vegetation_sample_id = vs.vegetation_sample_id
    JOIN survey200.vegetation_taxon_list vtl ON vs.vegetation_taxon_id = vtl.vegetation_taxon_id
    JOIN survey200.vegetation_survey_trees vst ON vs.vegetation_sample_id = vst.vegetation_sample_id
    LEFT JOIN survey200.cv_vegetation_classifications cvvc ON vst.vegetation_classification_id = cvvc.vegetation_classification_id
    LEFT JOIN survey200.cv_vegetation_shapes cvvs ON vst.vegetation_shape_id = cvvs.vegetation_shape_id
  WHERE
    s.research_focus::text = ?researchFocus
    -- AND vs.survey_type::text = 'tree'::text
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code;"

  trees_query  <- sqlInterpolate(ANSI(),
                                 trees_base_query,
                                 researchFocus = research_focus)
  
  trees_data <- dbGetQuery(pg, trees_query)
  
  return(trees_data)

}



# number_perennials -------------------------------------------------------


get_number_perennials <- function(research_focus) {
  
  number_perennials_base_query <- "
  -- number_perennials
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    -- counts.survey_id,
    -- counts.vegetation_taxon_id,
    vtl.vegetation_scientific_name,
    vtl.common_name,
    counts.number_plants
  FROM
  (
    SELECT
      se.survey_id,
      vs.vegetation_taxon_id,
      SUM(vspc.count_survey_value) AS number_plants
    FROM
      survey200.sampling_events se
      JOIN survey200.sites s ON se.site_id = s.site_id
      JOIN survey200.sampling_events_vegetation_samples sevs ON se.survey_id = sevs.survey_id
      JOIN survey200.vegetation_samples vs ON sevs.vegetation_sample_id = vs.vegetation_sample_id
      JOIN survey200.vegetation_survey_plant_counts vspc ON (vspc.vegetation_sample_id = vs.vegetation_sample_id)
    WHERE
      s.research_focus::text = ?researchFocus
    GROUP BY
      se.survey_id,
      vs.vegetation_taxon_id
  ) AS counts
  LEFT JOIN survey200.vegetation_taxon_list vtl ON (vtl.vegetation_taxon_id = counts.vegetation_taxon_id)
  JOIN survey200.sampling_events se ON (se.survey_id = counts.survey_id)
  JOIN survey200.sites s ON se.site_id = s.site_id
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code,
    vtl.vegetation_scientific_name;"

  number_perennials_query  <- sqlInterpolate(ANSI(),
                                             number_perennials_base_query,
                                             researchFocus = research_focus)
  
  number_perennials_data <- dbGetQuery(pg, number_perennials_query)
  
  return(number_perennials_data)

}



# hedges ------------------------------------------------------------------

get_hedges <- function(research_focus) {
  
  hedges_base_query <- "
  -- hedges
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
      s.research_focus::text = ?researchFocus
    --AND vs.survey_type::text = 'hedge'::text
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code;"

  hedges_query <- sqlInterpolate(ANSI(),
                                 hedges_base_query,
                                 researchFocus = research_focus)
  
  hedges_data <- dbGetQuery(pg, hedges_query)
  
  return(hedges_data)

}


# landuse -----------------------------------------------------------------

get_landuse <- function(research_focus) {
  
  landuse_base_query <- "
  -- landuse 
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
    s.site_code;"
  

  landuse_query <- sqlInterpolate(ANSI(),
                                  landuse_base_query,
                                  researchFocus = research_focus)
  
  landuse_data <- dbGetQuery(pg, landuse_query)
  
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
    s.site_code;"
  

  neighborhood_characterization_query <- sqlInterpolate(ANSI(),
                                                        neighborhood_characterization_base_query,
                                                        researchFocus = research_focus)
  
  neighborhood_characterization_data <- dbGetQuery(pg, neighborhood_characterization_query)
  
  return(neighborhood_characterization_data)

}


# structures -------------------------------------------------

get_structures <- function(research_focus) {
  
  structures_base_query <- "
  -- structures
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    -- s.research_focus,
    hs.structure_use,
    -- hs.height,
    CASE
      WHEN hs.height_distance IS NULL THEN hs.height
      WHEN hs.height_distance IS NOT NULL THEN NULL
    END AS height_measured,
    hs.height_distance,
    hs.height_degree_up,
    hs.height_degree_down--,
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.human_structures_sampling_events hsse ON se.survey_id = hsse.survey_id
    JOIN survey200.human_structures hs ON hsse.structure_id = hs.structure_id
  WHERE
    s.research_focus::text = ?researchFocus
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code;"

  structures_query <- sqlInterpolate(ANSI(),
                                     structures_base_query,
                                     researchFocus = research_focus)
  
  structures_data <- dbGetQuery(pg, structures_query)
  
  return(structures_data)

}



# sampling_events -------------------------------------------------

get_sampling_events <- function(research_focus) {
  
  sampling_events_base_query <- "
  -- sampling events
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    s.elevation,
    s.slope,
    -- s.aspect,
    hi.weather_on_the_day,
    hi.weather_recent_rain_notes,
    hi.general_description
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.human_indicators hi ON se.survey_id = hi.survey_id
  WHERE
    s.research_focus::text = ?researchFocus
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code;"
  
  sampling_events_query <- sqlInterpolate(ANSI(),
                                          sampling_events_base_query,
                                          researchFocus = research_focus)
  
  sampling_events_data <- dbGetQuery(pg, sampling_events_query)
  
  return(sampling_events_data)
  
}



# soil_center_cores -------------------------------------------------------

get_soil_center_cores <- function() {
  
  soil_center_cores_base_query <- "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    /*
      CASE
    WHEN EXTRACT (YEAR FROM se.samp_date) < 2015 THEN ss.location_description
    WHEN EXTRACT (YEAR FROM se.samp_date) = 2015 THEN ss.location_description_center
    END AS core_location_description,
    */
    ss.sampling_notes,
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
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.soil_samples ss ON se.survey_id = ss.survey_id
    JOIN survey200.soil_center_cores scc ON ss.soil_sample_id = scc.soil_sample_id
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code;"
  
  soil_center_cores_query <- sqlInterpolate(ANSI(),
                                            soil_center_cores_base_query)
  
  soil_center_cores_data <- dbGetQuery(pg, soil_center_cores_query)
  
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
    s.site_code;"
  
  soil_texture_2000_query <- sqlInterpolate(ANSI(),
                                            soil_texture_2000_base_query)
  
  soil_texture_2000_data <- dbGetQuery(pg, soil_texture_2000_query)
  
  return(soil_texture_2000_data)
  
}


# soil_lachat -------------------------------------------------------------

get_soil_lachat <- function() {
  
  soil_lachat_base_query <- "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
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
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.soil_samples ss ON se.survey_id = ss.survey_id
    RIGHT JOIN survey200.soil_lachat sl ON (ss.soil_sample_id = sl.soil_sample_id)
  ORDER BY
    sl.detection_date,
    sl.detection_time;"
  
  soil_lachat_query <- sqlInterpolate(ANSI(),
                                      soil_lachat_base_query)
  
  soil_lachat_data <- dbGetQuery(pg, soil_lachat_query)
  
  return(soil_lachat_data)
  
}


# soil_traacs -------------------------------------------------------------

get_soil_traacs <- function() {
  
  soil_traacs_base_query <- "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    st.deep_core_type,
    st.sample_sequence,
    st.sample_id,
    st.sample_set,
    st.phos_mg_l
  FROM
    survey200.sampling_events se
    JOIN survey200.sites s ON se.site_id = s.site_id
    JOIN survey200.soil_samples ss ON se.survey_id = ss.survey_id
    RIGHT JOIN survey200.soil_traacs st ON (ss.soil_sample_id = st.soil_sample_id)
  ORDER BY
    st.sample_sequence;"
  
  soil_traacs_query <- sqlInterpolate(ANSI(),
                                      soil_traacs_base_query)
  
  soil_traacs_data <- dbGetQuery(pg, soil_traacs_query)
  
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
    s.site_code;"
  
  soil_perimeter_cores_query <- sqlInterpolate(ANSI(),
                                               soil_perimeter_cores_base_query)
  
  soil_perimeter_cores_data <- dbGetQuery(pg, soil_perimeter_cores_query)
  
  return(soil_perimeter_cores_data)
  
}
 

# arthropods --------------------------------------------------------------

# note that this query is throttled to not include 2015 results as those samples
# have not been complted at the time of publication. We will need to update the
# version when David et al. finish the 2015 arthropods.

get_arthropods <- function() {
  
  arthropods_base_query <- "
  SELECT
    se.samp_date AS sample_date,
    s.site_code,
    ss.sweepnet_sample_type,
    vtl.vegetation_scientific_name AS substratum,
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
  WHERE
    EXTRACT (YEAR FROM se.samp_date) <= 2010
  ORDER BY
    EXTRACT (YEAR FROM se.samp_date),
    s.site_code,
    vtl.vegetation_scientific_name;"  
  
  arthropods_query <- sqlInterpolate(ANSI(),
                                     arthropods_base_query)
  
  arthropods_data <- dbGetQuery(pg, arthropods_query)
  
  return(arthropods_data)
  
}
