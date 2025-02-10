#install.packages(c("tidycensus", "tigris", "sf", "dplyr", "ggplot2", "readr"))

# Load required libraries
library(tidycensus)   # Census API data retrieval
library(tigris)       # Geographic boundary data
library(sf)           # Spatial operations
library(dplyr)        # Data manipulation
library(ggplot2)      # Visualization (optional)
library(readr)        # CSV writing

# Set Census API Key (get one at https://api.census.gov/data/key_signup.html)
census_api_key("946625c67cbce4cbdeb8b831281b8b15345b3a0d", install = TRUE, overwrite = TRUE)

# Define year for data retrieval
year <- 2023  # Use latest available year

# Step 1: Download Congressional District shapefile for all states
cd_sf <- congressional_districts(year = year, cb = TRUE)

# Step 2: Download Official State Names & FIPS Codes from Census API
states_sf <- states(cb = TRUE) %>% 
  select(STATEFP, NAME, geometry) %>%
  st_drop_geometry

# Step 3: Perform a spatial join to add State Names to Congressional Districts
cd_sf_join <- cd_sf %>%
  left_join(states_sf, by = "STATEFP") %>% 
  rename(STATE_NAME = NAME) %>%  # Rename for clarity
  select(GEOID, NAMELSAD, STATEFP, STATE_NAME, geometry) %>% # Retain necessary columns
  arrange(STATEFP)

# Save data for Tableau
write_csv(cd_sf_join %>% 
            st_drop_geometry() %>% 
            mutate(
              STATEFP = as.character(STATEFP),  # Ensure STATEFP remains a string
              GEOID = as.character(GEOID)  # Ensure GEOID remains a string
            ), 
          "files/congressional_districts.csv", 
          quote = "all")  # Optionally wrap text in quotes to prevent auto-conversion

st_write(cd_sf_join, "files/congressional_districts.geojson", driver = "GeoJSON", append = TRUE)  # Spatial data for Tableau

# Quick map preview
ggplot(cd_sf_join) +
  geom_sf(aes(fill = STATE_NAME), color = "black") +
  theme_minimal() +
  labs(title = "U.S. Congressional Districts", caption = paste0("Source: Census ", year))

# Print completion message
message("Data saved! 'congressional_districts.csv' and 'congressional_districts.geojson' are ready for Tableau.")
