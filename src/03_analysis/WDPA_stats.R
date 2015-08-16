library('ProjectTemplate')

load.project()
options(scipen=999)
source("config/config.R")

wdpa_db <- src_postgres(dbname = DBNAME, host = HOST, port = PORT, user = USER,
                        password = PASSWORD, options="-c search_path=wdpa")

wdpa <- tbl(wdpa_db, "wdpa_poly")

# IUCN categories ---------------------------------------------------------

pa_per_iso3 <- wdpa %>%
  group_by(iso3, iucn_cat) %>%
  summarise(
    count = n(),
    area_km = sum(rep_area)
  ) %>%
  arrange(iso3, iucn_cat) %>%
  as.data.frame()

pa_per_iso3 <- pa_per_iso3 %>% 
  group_by(iso3) %>% 
  mutate(area_tot_km = sum(area_km), 
         perc = round(area_km / area_tot_km * 100, 2)) %>% 
  ungroup()

percs <- pa_per_iso3 %>%
  filter(iucn_cat == "Not Reported") %>%
  select(iso3, perc, area_tot_km)

percs <- percs$perc
percs[is.nan(percs)] <- NA

mean(percs, na.rm = TRUE)


# Designation -------------------------------------------------------------

status_per_iso3 <- wdpa %>%
  group_by(iso3, status) %>%
  summarise(
    count = n(),
    area_km = sum(rep_area)
  ) %>%
  arrange(iso3, status) %>%
  as.data.frame()

status_per_iso3 <- status_per_iso3 %>% 
  group_by(iso3) %>% 
  mutate(area_tot_km = sum(area_km), 
         perc = round(area_km / area_tot_km * 100, 2)) %>% 
  ungroup()

status_percs <- status_per_iso3 %>%
  filter(status == "Designated") %>%
  select(iso3, perc, area_tot_km)
