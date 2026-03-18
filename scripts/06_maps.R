# Project: Edmonton Health Equity
# Title: 06_maps
# Date: 2026-03-12
# Purpose: generate side-by-side comparison for income and hypertension prevalence

library(tidyverse)
library(sf)
library(patchwork)

# 1. Read datasets
neigh <- st_read("geojson_files/yeg_neigh.geojson") 
joined_data <- read_rds("data/data_clean/yeg_joined.rds") |> 
  mutate(
    neighbourhood_number = as.character(neighbourhood_number)
  )

# 2. Join spatial data
map_data <- neigh |> 
  left_join(joined_data, by = "neighbourhood_number")
str(map_data)

# 3. Generate both neighborhood-level income map and zone-level hypertension map 
p1 <- map_data |> 
  ggplot() +
  geom_sf(aes(fill = weighted_average_income), color = "white", size = 0.05) +
  scale_fill_viridis_c(
    option = "mako", 
    name = "Household Income($)", 
    labels = scales::label_dollar(),
    na.value = "grey90") +
  labs(title = "Average Neighborhood Household Income") +
  theme_void()
p1
p2 <- map_data |> 
  mutate(
    age_standardize_rate = age_standardize_rate / 100
  ) |> 
  ggplot() +
  geom_sf(aes(fill = age_standardize_rate), color = "white", size = 0.05) +
  scale_fill_viridis_c(
    option = "rocket", 
    direction = -1, 
    name = "Hypertension (%)", 
    labels = scales::label_percent(),
    na.value = "grey90"
    ) +
  labs(title = "Zone-level Hypertension Prevalence") +
  theme_void()
p2
  #  Combine both maps side-by-side for clearer comparison
p1 + p2 + 
  plot_annotation(
    title = "Side-by-Side Comparison of Average Household Income and Hypertension 
    Prevalence in Edmonton",
    caption = "Data sources: City of Edmonton & Alberta IHDA"
  )
ggsave("output/side_comparison.png")

# 4. Generate residual spatial map to spot neighborhoods that are doing better or worse than expected
  #  Read the original neighborhood-level lm model previously created
yeg_model <- read_rds("output/yeg_model.rds")
  #  Create a cleaned map that only has the 260 neighborhoods in the income dataset
map_residuals <- map_data |> 
  right_join(joined_data, by = "neighbourhood_name") |> 
  mutate(residuals = residuals(yeg_model)) |> 
  st_drop_geometry()
map_residuals <- map_data |> 
  left_join(map_residuals)

  # Create cut breaks for residuals
sd_residuals <- sd(map_residuals$residuals, na.rm = TRUE)
map_residuals_binned <- map_residuals |> 
  mutate(
    residuals_binned = cut(
      residuals, 
      breaks = c(-Inf, -sd_residuals , sd_residuals , Inf),
      labels = c("Lower than Expected", "As Expected", "Higher than Expected")
    ) 
  ) |> 
  mutate(
    residuals_binned = addNA(residuals_binned)
  )
levels(map_residuals_binned$residuals_binned)[is.na(levels(map_residuals_binned$residuals_binned))] <- "No Data"
write_rds(map_residuals_binned, "data/data_clean/residuals_data")
  # Plot the residual map
p3 <- map_residuals_binned |> 
  ggplot() +
  geom_sf(aes(fill = residuals_binned), color = "white", size = 0.1) +
  scale_fill_manual(
    values = c(
      "Lower than Expected" = "#2c7bb6",  
      "As Expected" = "#ffffbf",         
      "Higher than Expected" = "#d7191c", 
      "No Data" = "#d3d3d3"
    ),
    name = "Hypertension Prevalence"
  ) +
  theme_void() +
  labs(
    title = "Model Performance Map by Edmonton Neighborhoods",
    caption = "As expected defined as within ± 1% prevalence"
  )
ggsave("output/residual_map.png", plot = p3, bg = "white")


