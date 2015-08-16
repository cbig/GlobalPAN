library(dplyr)
library(ggplot2)
library('ProjectTemplate')
library(tidyr)

load.project()
options(scipen = 999)
source("config/config.R")

wdpa_db <- src_postgres(dbname = DBNAME, host = HOST, port = PORT, user = USER,
                        password = PASSWORD, options="-c search_path=wdpa")

wdpa <- tbl(wdpa_db, "wdpa_pa_extents")

# Calculate extent y centroid and plot that in a histogram
plot_data <- wdpa %>% 
  mutate(y_centroid = (y_min + y_max) / 2) %>%
  as.data.frame(n = -1) %>% 
  mutate(lat_group = cut(y_centroid, breaks = seq(-90, 90, 10))) 
  
p1 <- ggplot(plot_data, aes(x = y_centroid)) + geom_histogram(binwidth = 10) + 
  coord_flip() + xlim(c(-90, 90)) + scale_x_discrete(limits = seq(-90, 90, 10)) + 
  xlab("Latitude\n")

# Create latitude group manually
plot_grouped_data <- plot_data %>% 
  group_by(lat_group) %>% 
  summarise(
    area = sum(area)
  ) %>% 

p2 <- ggplot(plot_grouped_data, aes(x = lat_group, y = area)) + 
  geom_bar(stat = "identity") + coord_flip() + xlab("Latitude\n") + 
  ylab(expression("\nArea (km2)"))

