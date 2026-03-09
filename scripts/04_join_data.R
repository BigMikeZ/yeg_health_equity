# Project: Edmonton Health Equity
# Script: 04_join_data
# Date: 2026-03-09
# Purpose: Join income and hypertension datasets with the help of the crosswalk

library(tidyverse)

#### Perform data join ####
yeg_weighted_income_cleaned <- read_rds("data/data_clean/yeg_weighted_income_cleaned.rds")
look_up_table_cleaned <- read_rds("data/data_clean/yeg_neigh_slga_lookup.rds") 
slga_hypertension <- read_rds("data/data_clean/clean_2016_lga_edmonton_hypertension.rds")

head(yeg_weighted_income_cleaned)
head(look_up_table_cleaned)
head(slga_hypertension)

yeg_joined <- yeg_weighted_income_cleaned |> 
  inner_join(look_up_table_cleaned, by = "neighbourhood_name") |> 
  inner_join(slga_hypertension, by = "geography") |> 
  select(-c(year, sex))


