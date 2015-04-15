library('ProjectTemplate')
load.project()

source("config/config.R")

wdpa_db <- src_postgres(dbname = DBNAME, host = HOST, port = PORT, user = USER,
                        password = PASSWORD, options="-c search_path=wdpa")

wdpa <- tbl(wdpa_db, "wdpa_poly")

pa_per_iso3 <- wdpa %>%
  group_by(iso3, iucn_cat) %>%
  summarise(
    count = n(),
    area_km = sum(rep_area)
  ) %>%
  arrange(iso3, iucn_cat) %>%
  as.data.frame()
