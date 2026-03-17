# Project: Edmonton Health Equity
# Script: 05_data_visuaization_modeling
# Date: 2026-03-10
# Purpose: Visualize and analyze data

library(tidyverse)
library(scales)
library(lme4)
library(lmtest)
library(sandwich)

yeg_joined <- read_rds("data/data_clean/yeg_joined.rds") |> 
  mutate(
    age_standardize_rate = age_standardize_rate / 100, # Convert to decimals 
    geography = factor(geography )
  ) |> 
  ungroup()
head(yeg_joined)
str(yeg_joined)
colSums(is.na(yeg_joined)) 

summary(yeg_joined$weighted_average_income)
summary(yeg_joined$age_standardize_rate)

yeg_joined |> 
  ggplot(aes(x = weighted_average_income)) +
  geom_density() +
  geom_histogram(binwidth = 5000) 

yeg_joined |> 
  ggplot(aes(x = age_standardize_rate)) +
  geom_histogram(binwidth = 0.002)

yeg_plot <- yeg_joined |> 
  ggplot(aes(x = weighted_average_income, y = age_standardize_rate)) + 
  geom_jitter(aes(alpha = population, size = population, color = geography), height = 0.002) +
  geom_smooth(method = "lm", se = FALSE) +
  scale_x_continuous(
    breaks = seq(25000, 200000, by = 25000),
    labels = label_dollar()
  ) +
  scale_y_continuous(
    labels = label_percent()
  ) +
  theme(legend.position = "none") +
  labs(
    title = "Relationship between Household Income and Hypertension Prevalanece 
    in Edmonton Neighborhoods",
    x = "Weighted average household income",
    y = "Age and sex standardized hypertension prevalence", 
    caption = "Data sources: City of Edmonton & Alberta IHDA"
  ) 

#### Modeling ####
# Can't run lm without aggregating the data
yeg_joined_aggregated <- yeg_joined |> 
  group_by(geography) |> 
  summarize(
    age_standardize_rate = mean(age_standardize_rate),
    weighted_average_income = weighted.mean(weighted_average_income, population),
    population = sum(population)
  ) |> 
  ungroup()

yeg_weighted_aggregated_model <- lm(age_standardize_rate ~ weighted_average_income, 
                          data = yeg_joined_aggregated,
                          weights = population 
                         )
summary(yeg_weighted_aggregated_model)
png("output/weighted_aggregate_diagnostic_plots.png", width = 800, height = 600)
par(mfrow = c(2, 2))
yeg_aggregate_model_diagnostics <- plot(yeg_weighted_aggregated_model)
dev.off()
par(mfrow = c(1, 1))         # Diagnostics look funky (heteroskedasticity)

# Use robust SE method on the original nested data (neighborhoods within SLGAs)
yeg_model <- lm(age_standardize_rate ~ weighted_average_income, data = yeg_joined)
summary(yeg_model)
png("output/original_diagnostic_plots.png")
par(mfrow = c(2, 2))
yeg_model_diagnostics <- plot(yeg_model)
dev.off()
par(mfrow = c(1, 1)) # Diagnostics look much better but still some heteroskedasticity concern
yeg_model_robust <- coeftest(yeg_model, vcov = vcovCL, cluster = ~ geography)  # robust SE
print(yeg_model_robust)

# Save Scatterplot & models 
write_rds(yeg_joined_aggregated, "data/data_clean/yeg_joined_aggregated.rds")
write_rds(yeg_weighted_aggregated_model, "output/yeg_model_weighted_aggregate.rds")
write_rds(yeg_model_robust, "output/yeg_model_robust.rds")
write_rds(yeg_model, "output/yeg_model.rds")
ggsave("output/final_correlation_plot.png", plot = yeg_plot)
