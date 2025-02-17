#' Uncomment and run the two line below to resume development of this script
# orderly::orderly_develop_start("process_all-data")
# setwd("src/process_all-data")

priority_iso3 <- multi.utils::priority_iso3()
analysis_level <- multi.utils::analysis_level()

#' Merge all of the area datasets
areas <- lapply(priority_iso3, function(x) read_sf(paste0("depends/", tolower(x), "_areas.geojson")))
areas[[9]]$epp_level <- as.numeric(areas[[9]]$epp_level) #' Fix non-conforming column type
areas <- bind_rows(areas)

pdf("areas.pdf", h = 11, w = 6.25)
plot(areas$geometry)
dev.off()

#' Check on the number of areas in each country
areas_df <- areas %>%
  st_drop_geometry() %>%
  select(area_id, area_level, area_level_label) %>%
  mutate(iso3 = substr(area_id, 1, 3)) %>%
  left_join(
    as.data.frame(analysis_level) %>%
      tibble::rownames_to_column("iso3"),
    by = "iso3"
  ) %>%
  filter(area_level == analysis_level) %>%
  group_by(iso3) %>%
  summarise(
    n = n(),
    analysis_level = analysis_level[1],
    area_level_label = area_level_label[1]
  ) %>%
  mutate(
    country = fct_recode(iso3,
      "Botswana" = "BWA",
      "Cameroon" = "CMR",
      "Kenya" = "KEN",
      "Lesotho" = "LSO",
      "Mozambique" = "MOZ",
      "Malawi" = "MWI",
      "Namibia" = "NAM",
      "Eswatini" = "SWZ",
      "Tanzania" = "TZA",
      "Uganda" = "UGA",
      "South Africa" = "ZAF",
      "Zambia" = "ZMB",
      "Zimbabwe" = "ZWE"
    )
  )

areas_df %>%
  select(Country = country, "Number of areas" = n, "Analysis level" = area_level_label) %>%
  gt::gt() %>%
  gt::cols_align(
    align = "left",
    columns = Country
  ) %>%
  gt::as_latex() %>%
  as.character() %>%
  cat(file = "area-levels.txt")

saveRDS(areas, "areas.rds")

#' Merge all of the indicator datasets
ind <- lapply(priority_iso3, function(x) read_csv(paste0("depends/", tolower(x), "_survey_indicators_sexbehav.csv"))) %>%
  bind_rows()

write_csv(ind, "survey_indicators_sexbehav.csv")

pdf("survey_indicators_sexbehav.pdf", h = 10, w = 6.25)

ind %>%
  filter(indicator %in% c("nosex12m", "sexcohab", "sexnonregplus", "sexcohabspouse", "sexnonregspouseplus")) %>%
  group_by(indicator, survey_id) %>%
  summarise(estimate = mean(estimate)) %>%
  mutate(
    iso3 = substr(survey_id, 1, 3),
    year = as.numeric(substr(survey_id, 4, 7)),
    type = substr(survey_id, 8, 11)
  ) %>%
  ggplot(aes(x = year, y = estimate, col = type)) +
  geom_point() +
  facet_grid(iso3 ~ indicator) +
  theme_minimal()

dev.off()

pdf("spouse-comparison.pdf", h = 5, w = 4)

ind %>%
  filter(
    area_id %in% priority_iso3,
    indicator %in% c("sexcohab", "sexcohabspouse", "sexnonreg", "sexnonregspouse")
  ) %>%
  mutate(
    spouse_indicator = grepl("spouse", indicator, fixed = TRUE)
  ) %>%
  split(.$area_id) %>%
  lapply(function(x)
    ggplot(x, aes(x = spouse_indicator, y = estimate, group = spouse_indicator, fill = indicator)) +
    geom_bar(stat = "identity", alpha = 0.8, width = 0.5) +
    facet_grid(age_group ~ survey_id, space = "free_x", scales = "free_x", switch = "x") +
    scale_color_manual(values = multi.utils::cbpalette()) +
    lims(y = c(0, 1)) +
    labs(x = "") +
    theme_minimal() +
    theme(
      axis.text.x = element_blank(),
      plot.title = element_text(face = "bold"),
      legend.position = "bottom",
      strip.placement = "outside"
    )
  )

dev.off()

pdf("spouse-livesaway.pdf", h = 4, w = 6.25)

spouselivesaway <- ind %>%
  filter(
    area_id %in% priority_iso3,
    indicator %in% c("sexcohab", "sexcohabspouse", "sexnonreg", "sexnonregspouse"),
    age_group == "Y015_024"
  ) %>%
  pivot_wider(
    names_from = indicator,
    id_cols = c("survey_id", "area_id", "age_group"),
    values_from = estimate
  ) %>%
  select(survey_id, area_id, age_group, sexcohab:sexnonregspouse) %>%
  mutate(
    spouselivesaway = sexcohabspouse - sexcohab,
    spouselivesaway2 = sexnonreg - sexnonregspouse
  )

ggplot(spouselivesaway, aes(x = survey_id, y = spouselivesaway, col = area_id)) +
  geom_point() +
  theme_minimal() +
  theme(axis.text.x = element_text(angle = -90, hjust = 0))

ggplot(spouselivesaway, aes(x = spouselivesaway, y = spouselivesaway2, col = area_id)) +
  geom_point() +
  lims(x = c(0, 0.2), y = c(0, 0.2)) +
  theme_minimal()

dev.off()

pdf("mwi-dhs-phia-comparison.pdf", h = 6, w = 6.25)

ind %>%
  filter(
    survey_id %in% c("MWI2015DHS", "MWI2016PHIA"),
    indicator %in% c("sexcohab", "sexnonreg")
  ) %>%
  pivot_wider(
    names_from = c("indicator", "survey_id"),
    id_cols = c("area_id", "age_group"),
    values_from = estimate
  ) %>%
  mutate(
    diff_sexcohab = sexcohab_MWI2015DHS - sexcohab_MWI2016PHIA,
    diff_sexnonreg = sexnonreg_MWI2015DHS - sexnonreg_MWI2016PHIA
  ) %>%
  left_join(
    select(areas, area_id, geometry),
    by = "area_id"
  ) %>%
  st_as_sf() %>%
  select(area_id, age_group, starts_with("diff")) %>%
  pivot_longer(
    cols = starts_with("diff_"),
    names_to = "indicator",
    values_to = "estimate"
  ) %>%
  ggplot(aes(fill = estimate)) +
    geom_sf() +
    facet_grid(indicator ~ age_group) +
    scale_fill_viridis_c() +
    labs(title = "MWI2015DHS - MWI2016PHIA") +
    theme_minimal()

dev.off()

#' Merge all of the HIV datasets
hiv <- lapply(priority_iso3, function(x) read_csv(paste0("depends/", tolower(x), "_hiv_indicators_sexbehav.csv"))) %>%
  bind_rows()

write_csv(hiv, "hiv_indicators_sexbehav.csv")

#' Merge all of the population datasets (aaa_scale_pop reports from Oli's fertility repo)
pop <- lapply(priority_iso3, function(x) read_csv(paste0("depends/", tolower(x), "_interpolated-population.csv"))) %>%
  bind_rows()

write_csv(pop, "interpolated_population.csv")

naomi_extract <- readRDS("naomi_extract.rds")

naomi <- naomi_extract %>%
  select(
    iso3, area_id, area_level, age_group = age_group_label,
    indicator = indicator_label, estimate = mean
  )

saveRDS(naomi, "naomi.rds")

pop <- naomi %>%
  filter(indicator == "Population") %>%
  select(-indicator) %>%
  rename(population = estimate) %>%
  pivot_wider(
    names_from = age_group,
    values_from = population
  ) %>%
  mutate(
    `25-49` = `25-29` + `30-34` + `35-39` + `40-44` + `45-49`,
    `15-29` = `15-19` + `20-24` + `25-29`,
  ) %>%
  pivot_longer(
    cols = -c(iso3, area_id, area_level),
    names_to = "age_group",
    values_to = "population"
  )

saveRDS(pop, "naomi_pop.rds")
