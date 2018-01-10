# README

# steps to identify mislabeled data

# lachat nitrogen
lachat_n_sites <- unique(bind_rows(
  tidy_raw_lachat('OM_6-8-2016_09-51-57AM.csv'),
  tidy_raw_lachat('OM_6-16-2016_10-50-00AM.csv')
)$site_code) %>%
  as.data.frame() %>% 
  set_names('site_code') %>%
  mutate(site_code = as.character(site_code)) %>% 
  filter(!is.na(site_code)) %>% 
  mutate(lachat_n = 'lachat_n') %>% 
  mutate(site_code = gsub("017", "O17", site_code))

# lachat phosphorus
lachat_p_sites <- unique(bind_rows(
  tidy_raw_lachat('OM_9-27-2016_10-33-40AM.csv'),
  tidy_raw_lachat('OM_9-28-2016_09-55-27AM.csv'),
  tidy_raw_lachat('OM_9-29-2016_09-27-40AM.csv')
)$site_code) %>%
  as.data.frame() %>% 
  set_names('site_code') %>%
  mutate(site_code = as.character(site_code)) %>% 
  filter(!is.na(site_code)) %>% 
  mutate(lachat_p = 'lachat_p') %>% 
  mutate(site_code = replace(site_code, site_code == 'J6', 'J9'))

# samples
sample_sites <- unique(soilSamples$site_code) %>% 
  as.data.frame() %>% 
  set_names('site_code') %>%
  mutate(site_code = as.character(site_code)) %>% 
  filter(!is.na(site_code)) %>% 
  mutate(samples = "samples")

# Roy's reported N data
reported_n_sites <- unique(availableNitrogen$site_code) %>% 
  as.data.frame() %>% 
  set_names("site_code") %>%
  mutate(site_code = as.character(site_code)) %>% 
  filter(!is.na(site_code)) %>% 
  mutate(reported_n = "reported_n") %>% 
  filter(!grepl("blk", site_code, ignore.case = T))

# Roy's reported P data
reported_p_sites <- unique(phosphorus$site_code) %>% 
  as.data.frame() %>% 
  set_names("site_code") %>%
  mutate(site_code = as.character(site_code)) %>% 
  filter(!is.na(site_code)) %>% 
  mutate(reported_p = "reported_p") %>% 
  filter(!grepl("blk|bla", site_code, ignore.case = T)) %>% 
  mutate(site_code = replace(site_code, site_code == 'J6', 'J9'))

# nitrogen summary
# write_csv(
#   full_join(lachat_n_sites, sample_sites, by = c("site_code")) %>% 
#     full_join(reported_n_sites, by = c("site_code")) %>% 
#     arrange(site_code) %>% 
#     select(site_code, samples_marker, lachat_marker, reported_marker),
#   '~/Desktop/sample_incongruence.csv'
# )

# phosphorus summary
# write_csv(
#   full_join(lachat_p_sites, sample_sites, by = c("site_code")) %>% 
#     full_join(reported_p_sites, by = c("site_code")) %>% 
#     arrange(site_code) %>% 
#     select(site_code, samples_marker, lachat_marker, reported_marker),
#   '~/Desktop/sample_incongruence_phos.csv'
# )


# perimeter moisture
perimeter_moisture_sites <- unique(perimeterMoistureContent$site_code) %>% 
  as.data.frame() %>% 
  set_names("site_code") %>%
  mutate(site_code = as.character(site_code)) %>% 
  filter(!is.na(site_code)) %>% 
  mutate(perim_moisture = "perim_moisture") %>% 
  filter(!grepl("blk", site_code, ignore.case = T))

# carbon nitrogen
carbon_nitrogen_sites <- unique(perimeterMoistureContent$site_code) %>% 
  as.data.frame() %>% 
  set_names("site_code") %>%
  mutate(site_code = as.character(site_code)) %>% 
  filter(!is.na(site_code)) %>% 
  mutate(cn = "cn") %>% 
  filter(!grepl("blk|bla", site_code, ignore.case = T))

# perimeter core summary
write_csv(
  full_join(lachat_n_sites, sample_sites, by = c("site_code")) %>% 
    full_join(lachat_p_sites, by = c("site_code")) %>% 
    full_join(reported_n_sites, by = c("site_code")) %>% 
    full_join(reported_p_sites, by = c("site_code")) %>% 
    full_join(perimeter_moisture_sites, by = c("site_code")) %>% 
    full_join(carbon_nitrogen_sites, by = c("site_code")) %>% 
    arrange(site_code) %>% 
    select(site_code, samples, lachat_n, lachat_p, reported_n, reported_p, perim_moisture, cn),
  '~/Desktop/perimeter_cores.csv'
)