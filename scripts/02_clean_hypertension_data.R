# Project:Edmonton Health Equity
# Script 02_clean_hypertension_data
# Date: 2026-03-05
# Purpose: Clean raw hypertension prevalence data and filter for Edmonton; prepare for a crosswalk to bridge both datasets
# Data source: http://www.ahw.gov.ab.ca/IHDA_Retrieval/selectSubCategoryParameters.do

#### Read data ####
library(tidyverse)
library(janitor)
lga_raw <- read_csv("data/data_raw/2016_lga_standardized_hypertension_prevalence.csv") |> 
  clean_names()
str(lga_raw)
head(lga_raw)

#### Filter for Edmonton zones correctly label zones ####
look_up_table <- tribble(
  ~ geography,      ~ geography_label,
  "Z4.1.A.01",     "Edmonton - Woodcroft East",
  "Z4.1.B.02",     "Edmonton - Woodcroft West",
  "Z4.1.C.03",     "Edmonton - Jasper Place",
  "Z4.1.D.04",     "Edmonton - West Jasper Plac",
  "Z4.2.A.01",     "Edmonton - Castle Downs",
  "Z4.2.B.02",     "Edmonton - Northgate",
  "Z4.2.C.03",     "Edmonton - Eastwood",
  "Z4.2.D.04",     "Edmonton - Abbottsfield",
  "Z4.2.E.05",     "Edmonton - NE",
  "Z4.3.A.01",     "Edmonton - Bonnie Doon",
  "Z4.3.B.02",     "Edmonton - Mill Woods West",
  "Z4.3.C.03",     "Edmonton - Mill Woods South",
  "Z4.4.A.01",     "Edmonton - Duggan",
  "Z4.4.B.02",     "Edmonton - Twin Brooks",
  "Z4.4.C.03",     "Edmonton - Rutherford"
)

lga_edmonton_labeled <- lga_raw |> 
  left_join(
    look_up_table, by = "geography"
  ) |>
  filter(!is.na(geography_label))

write_rds(lga_edmonton_labeled, "data/data_clean/clean_2016_lga_edmonton_hypertension.rds")

