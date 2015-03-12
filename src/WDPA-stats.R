library('ProjectTemplate')
load.project()
install.deps()

loginfo("Hello again, this time it's for real", logger=log.name)

install.deps()

con <- connect.WDPA()

query <- 'SELECT country, iucn_cat, COUNT(*), SUM(rep_area) AS area 
          FROM staging.wdpa_poly_jan2014 
          GROUP BY country, iucn_cat 
          ORDER BY country, iucn_cat;'

query_all  <- 'SELECT * FROM "WDPA_june2013"'
rs <- dbSendQuery(con, query)
dat <- fetch(rs, n=-1)

# Fix hectares to km2s
PA.cat.areas.per.country$area_km2 <- PA.cat.areas.per.country$area_ha / 100

dat.combined <- merge(dat, PA.cat.areas.per.country)
names(dat.combined) <- c("country", "iucn_cat", "count", "area_km2_reported",
                         "area_ha_calculated", "area_km2_calculated")

# Calculate difference reported - calculated
dat.combined$diff <- dat.combined$area_km2_reported - dat.combined$area_km2_calculated 
#dat.combined$diff.great <- abs(dat.combined$diff) > 1000
dat.combined$country.cat <- paste0(dat.combined$country, ", ", dat.combined$iucn_cat)
dat.combined$year <- 2014


library(googleVis)
p <- gvisMotionChart(dat.combined, idvar="country.cat", timevar="year",
                      xvar="area_km2_calculated", yvar="area_km2_reported",
                      colorvar="country", sizevar="count")
plot(p)
