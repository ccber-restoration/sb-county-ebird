
#official documentation: https://cornelllabofornithology.github.io/auk/

#Longer best practices documentation: https://ebird.github.io/ebird-best-practices/ebird.html

#note that the CRAN version of auk is not up to date with the 2025 taxonomy, so I installed the development version from github
#remotes::install_github("CornellLabofOrnithology/auk")

library(auk)
library(dplyr)
library(ggplot2)
library(gridExtra)
library(lubridate)
library(readr)
library(sf)

#check auk version
auk_version()

#define filepath to sampling event data
f_sed <- "ebd_US-CA-083_smp_relDec-2025/ebd_US-CA-083_smp_relDec-2025_sampling.txt"

#read in the sampling event data
checklists <- read_sampling(f_sed)

#208,000 checklists! 

#filter to just ncos (only checklists that used the hotspot location)
ncos_checklists <- checklists %>% 
  filter(locality == "UCSB North Campus Open Space (formerly Ocean Meadows Golf Course)")

#5435 checklists, as of December 2025


#define filepath
f_in <- "ebd_US-CA-083_smp_relDec-2025/ebd_US-CA-083_smp_relDec-2025.txt"

#define output filepath (after filtering)
f_out <- "ebd_filtered_south_coast.txt" 

#define bounding box for the south coast

#format is left longitude, bottom latitude, right longitude, top latitude
south_coast_bbox <- c(-120.2, 34.3, -119.4, 34.45)

ebird_data <- f_in |> 
  # 1. reference file
  auk_ebd() |> 
  # 2. define filters
  #try not filtering
  #auk_species(species = "Snowy Egret") |>
  #filter by bounding box
  auk_bbox(bbox = south_coast_bbox) |>
  # 3. run filtering
  auk_filter(file = f_out, overwrite = TRUE) |> 
  # 4. read text file into r data frame
  #do not "roll up" species
  read_ebd(rollup = FALSE)


ncos_data <- ebird_data %>% 
  filter(locality == "UCSB North Campus Open Space (formerly Ocean Meadows Golf Course)")

ncos_species_df <- ncos_data %>% 
  #when there is subspecies, make the common name the subspecies_common name
  mutate(new_common_name = case_when(
    !is.na(subspecies_common_name) ~ subspecies_common_name,
    .default = common_name
  ))

ncos_full_list <- ncos_species_df %>% 
  select(new_common_name) %>% 
  unique()
  
#load ebird_taxonomy (from within package)
data("ebird_taxonomy")

ncos_ebird_taxonomy <- ncos_full_list %>% 
  inner_join(ebird_taxonomy, by = join_by("new_common_name" == "common_name")) %>% 
  #sort by taxonomy
  arrange(taxonomic_order)

write_csv(ncos_ebird_taxonomy, file = "data-processed/ncos_ebird_list.csv")


