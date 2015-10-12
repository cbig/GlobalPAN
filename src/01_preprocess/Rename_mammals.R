
# Description -------------------------------------------------------------

# This is a script for renaming the mammal range models so that the
# original names based on the IUCN Red List IDs are changed to names based
# on species scientific names. NOTE: the file paths are specific to my CSC
# working environment.

# Funcionality ------------------------------------------------------------

#load model names and list of ID-codes and names
Code_names <- list.files("/wrk/pkullber/Data/mammal_data/exp_mam_models2")
Code_names_path <- list.files("/wrk/pkullber/Data/mammal_data/exp_mam_models2",
                             full.names = T)
Endings <-  strsplit(Code_names, split="[[:digit:]]")
Endings <- sapply(Endings, function(x) last(x))
Species_names <- read.csv("/wrk/pkullber/Data/mammal_data/Sant_disp_models_2015_10.csv")

#remove all other signs than digits form the names
Codes <- gsub("[^[:digit:]]", "", Code_names)

#search matching names
spp <- match(Codes, Species_names[,1] )
spp <- spp[!is.na(spp)]
name1 <- gsub(" ", "", Species_names[spp,5])

#rename files
file.rename(Code_names_path, paste(rep("/wrk/pkullber/Data/mammal_data/exp_mam_models2/",
                                    length(Code_names_path)), name1, Endings ,sep=""))

