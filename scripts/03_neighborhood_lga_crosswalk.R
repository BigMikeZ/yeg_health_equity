# Project: Edmonton Health Equity
# Script: 03_neighborhood_lga_crosswalk
# Date: 2026-03-06
# Purpose: Create a "crosswalk" to bridge income and lga zone datasets

library(tidyverse)
library(sf)
library(tmap)

#### Calculate weighted mid-points as a proxy of average income for each neightborhood ####
yeg_income <- read_rds("data_clean/tidy_2016_yeg_census_household_income.rds")
yeg_weighted_income <- yeg_income |> 
  filter(income != "No response" & n_person > 0) |> 
  mutate(
    neighbourhood_name = neighbourhood_name |> 
      str_to_lower() |> 
      str_squish(),   # standardize name 
    income_midpoint = case_when(
      income == "<$30,000"               ~ 30000 / 2,
      income == "$30,000 to <$60,000"    ~ (30000 + 60000) / 2,
      income == "$60,000 to <$100,000"   ~ (60000 + 100000) / 2,
      income == "$100,000 to <$125,000"  ~ (100000 + 125000) / 2,
      income == "$125,000 to <$150,000"  ~ (125000 + 150000) / 2,
      income == "$150,000 to <$200,000"  ~ (150000 + 200000) / 2,
      income == "$200,000 to <$250,000"  ~ (200000 + 250000) / 2,
      income == ">$250,000"              ~ 250000 * 1.25,
    )
  ) |> 
  group_by(neighbourhood_name) |>
  summarize(
    weighted_average_income = sum(income_midpoint * n_person) / sum(n_person)
  ) |>
  arrange(desc(weighted_average_income))

#### Build Look-up table for neighborhoods and slga####
neigh <- st_read("geojson_files/yeg_neigh.geojson")
slga  <- st_read("geojson_files/yeg_slga.geojson")
names(neigh)
names(slga)
st_crs(neigh)    # check coord systems
st_crs(slga)

yeg_spatial_joined <- neigh |>  # join two geojson files
  st_join(slga)

look_up_table <- yeg_spatial_joined |>
  st_drop_geometry() |> 
  select(SLGA_Name, LOCAL_CODE) |>
  mutate(
    neighbourhood_name = SLGA_Name |> 
      str_to_lower() |> 
      str_squish()
  ) |> 
  select(-SLGA_Name)

setdiff(                                    # Inspect discrepancy between neighborhood names
  sort(unique(yeg_weighted_income$neighbourhood_name)),
  sort(unique(look_up_table$neighbourhood_name))
)        
setdiff(                                    
  sort(unique(look_up_table$neighbourhood_name)),
  sort(unique(yeg_weighted_income$neighbourhood_name))
)                                          # Identified the problem is mostly with " and "& " in the look_up_table  

look_up_table_cleaned <- look_up_table |> 
  mutate(
    neighbourhood_name = neighbourhood_name |> 
      str_replace_all("&", ",") |> 
      str_squish()
  ) |> 
  separate_rows(neighbourhood_name, sep = ",") |> 
  mutate(
    neighbourhood_name = neighbourhood_name |>
      str_squish() |> 
      str_remove_all("^ah\\s+") |> 
      str_squish()
  )

setdiff(                                   
  sort(unique(yeg_weighted_income$neighbourhood_name)),
  sort(unique(look_up_table_cleaned$neighbourhood_name))
)        
setdiff(                                    
  sort(unique(look_up_table_cleaned$neighbourhood_name)),
  sort(unique(yeg_weighted_income$neighbourhood_name))
)                  # Identified certain fuzzy prefixes and suffixes as another problem

look_up_table_cleaned <- look_up_table_cleaned |> 
  mutate(
    neighbourhood_name = str_remove_all(neighbourhood_name, "\\bedmonton\\b|^the\\s+|\\s+area$") |> 
    str_squish()
  )

yeg_weighted_income_cleaned <- yeg_weighted_income |> 
  mutate(
    neighbourhood_name = str_remove_all(neighbourhood_name, "\\bedmonton\\b|^the\\s+|\\s+area$") |> 
    str_squish()
  )
  
setdiff(                                   
  sort(unique(yeg_weighted_income_cleaned$neighbourhood_name)),
  sort(unique(look_up_table_cleaned$neighbourhood_name))
)        
setdiff(                                    
  sort(unique(look_up_table_cleaned$neighbourhood_name)),
  sort(unique(yeg_weighted_income_cleaned$neighbourhood_name))
) 

write_rds(look_up_table_cleaned, "data_clean/yeg_neigh_slga_lookup.rds") # write for future reference 

#### Join by mapping keys ####


