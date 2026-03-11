# Project: Edmonton Health Equity
# Script: 05_data_visuaization_modeling
# Date: 2026-03-10
# Purpose: Visualizle and analyze data

library(tidyverse)
library(scales)
library(lme4)
library(lmtest)

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
  geom_jitter(aes(alpha = population, size = population, color = geography), height = 0.05) +
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
    weighted_average_income = mean(weighted_average_income)
  ) |> 
  ungroup()

yeg_model_aggregate <- lm(age_standardize_rate ~ weighted_average_income, data = yeg_joined_aggregated)
summary(yeg_model_aggregate)
png("output/aggregate_diagnostic_plots.png", width = 800, height = 600)
par(mfrow = c(nrow = 2, ncol = 2))
yeg_aggregate_model_diagnostics <- plot(yeg_model_aggregate)
dev.off()
par(mfrow = c(1, 1))         # Diagnostics look funky (heteroskedasticity)

# Use robust SE method on the original nested data (neighborhoods within SLGAs)
yeg_model <- lm(age_standardize_rate ~ weighted_average_income, data = yeg_joined)
summary(yeg_model)
png("output/original_diagnostic_plots.png")
par(mfrow = c(nrow = 2, ncol = 2))
yeg_model_diagnostics <- plot(yeg_model)
dev.off()
par(mfrow = c(1, 1)) # Diagnostics look much better but still some heteroskedasticity concern
yeg_model_robust <- coeftest(yeg_model, vcov = vcovCL, cluster = ~ geography)  # robust SE
print(yeg_model_robust)

# Save Scatterplot
ggsave("output/final_correlation_plot.png", plot = yeg_plot)
png("output/aggregate_diagnostic_plots.png")

