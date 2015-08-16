library(dplyr)
library(magrittr)
library(readr)

fin_ovelaps <- read_csv("data/WDPA/fin_pa_intersects_area.csv")
fin_ovelaps$perc %<>% round(1)

# Print unique areas
length(unique(fin_ovelaps$f1_id))
