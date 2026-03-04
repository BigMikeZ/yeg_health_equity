# Project: Edmonton Health Equity
# Script: 01_tidy_income_data
# Author: Mike Zhang
# Date: 2024-05-20
# Purpose: Clean wide-format 2016 Census income data and engineer poverty metrics.
# data source: https://data.edmonton.ca/Census/2016-Census-Population-by-Household-Income-Neighbo/jkjx-2hix/about_data

#### .gitignore setup ####
library(usethis)
git_vaccinate()

#### Read data####
library(tidyverse)
library(janitor)
yeg_raw <- read_csv("data_raw/2016_yeg_census_household_income.csv", 
                    na = c("", "NA", ".", "x", "..")) |> 
  clean_names()

#### Sanity checks ####
# 1. Check data type and first few rows
glimpse(yeg_raw)
head(yeg_raw)
# 2. Check missing values
colSums(is.na(yeg_raw)) 
# 3. Check duplicates
yeg_raw |>
  count(neighbourhood_name) |>
  filter(n > 1)
yeg_raw |>
  count(neighbourhood_name) |> 
  filter(n > 1)

#### Data tidying ####
yeg_tidy <- yeg_raw |>
  pivot_longer(
    cols = 4:12,
    names_to = "income",
    values_to = "n_person"
  ) |> 
  mutate(
    income = case_when(
    income == "less_than_30_000" ~ "<$30,000",
    income == "x30_000_to_less_than_60_000" ~ "$30,000 to <$60,000",
    income == "x60_000_to_less_than_100_000" ~ "$60,000 to <$100,000",
    income == "x100_000_to_less_than_125_000" ~ "$100,000 to <$125,000",
    income == "x125_000_to_less_than_150_000" ~ "$125,000 to <$150,000",
    income == "x150_000_to_less_than_200_000" ~ "$150,000 to <$200,000",
    income == "x200_000_to_less_than_250_000" ~ "$200,000 to <$250,000",
    income == "x250_000_or_more" ~ ">$250,000",
    income == "no_response" ~ "No response",
    TRUE ~ income
    ) 
  )
head(yeg_tidy, 10)

write_rds(yeg_tidy, "data_clean/tidy_2016_yeg_census_household_income.rds")
