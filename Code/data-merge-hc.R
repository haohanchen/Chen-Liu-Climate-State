rm(list=ls())

library(dplyr)
library(tidyr)

load("Data/d_country.Rdata")
load("Data/d_conflict.Rdata")
load("Data/d_economy.Rdata")
load("Data/d_mosquito.Rdata")

# Yanlan cleaned
load("Data/d_climate.Rdata")
load("Data/d_water.Rdata")
load("Data/d_ndvi.Rdata")

# Paramter
YR_START <- 2010
YR_END <- 2016


###############################
# Grid level data
###############################

# Augment a panel data template

d_country_yr <- data.frame(year = rep(YR_START:YR_END, nrow(d_country)) , 
                           d_country[rep(1:nrow(d_country), each = (YR_END - YR_START)+1), ])

save(d_country_yr, file = "Data/d_country_yr.Rdata")

# Aggregate NDVI into yearly data
d_ndvi_yr <- d_ndvi %>% group_by(Lon, Lat, Year) %>% summarise(NDVI_50 = mean(NDVI_50), NDVI_75 = mean(NDVI_75), NDVI_90 = mean(NDVI_90))
# Aggregate Climate data into yearly data
d_climate_yr <- d_climate %>% group_by(Lon, Lat, Year) %>% 
  summarise(Tair_mean = mean(Tair), Qair_mean = mean(Qair), Rain_mean = mean(Rain),
            Tair_sd = sd(Tair), Qair_sd = sd(Qair), Rain_sd = sd(Rain))


d_grid <- d_country_yr %>% 
  left_join(d_conflict, by = c("year" = "year", "lat" = "ycoord", "lon" = "xcoord")) %>%
  left_join(d_economy, by = c("year" = "year", "lat" = "ycoord", "lon" = "xcoord")) %>%
  left_join(d_mosquito, by = c("year" = "year", "lat" = "Lat_grid", "lon" = "Long_grid")) %>%
  left_join(d_ndvi_yr, by = c("year" = "Year", "lat" = "Lat", "lon" = "Lon")) %>%
  left_join(d_climate_yr, by = c("year" = "Year", "lat" = "Lat", "lon" = "Lon")) %>%
  left_join(d_water, by = c("lat" = "Lat", "lon" = "Lon"))

summary(d_grid)

d_grid <- d_grid %>% 
  replace_na(list(Water_permanent = 0, Water_temporary = 0, 
                  n_conflict = 0, n_deaths = 0, deaths_civilian = 0,
                  NDVI_50 = mean(d_grid$NDVI_50, na.rm=T), NDVI_75 = mean(d_grid$NDVI_75, na.rm=T), NDVI_90 = mean(d_grid$NDVI_90, na.rm=T),
                  Tair_mean = mean(d_grid$Tair_mean, na.rm=T), Qair_mean = mean(d_grid$Qair_mean, na.rm=T), Rain_mean = mean(d_grid$Rain_mean, na.rm=T),
                  Tair_sd = mean(d_grid$Tair_sd, na.rm=T), Qair_sd = mean(d_grid$Qair_sd, na.rm=T), Rain_sd = mean(d_grid$Rain_sd, na.rm=T)
                  ))

summary(d_grid)


save(d_grid, file = "Data/d_grid.Rdata")


###############################
# Country level data
###############################

rm(list=ls())

load("Data/d_grid_mos.Rdata")
load("Data/d_malaria.Rdata")

d_grid_agg <- d_grid %>% group_by(ISO3n, ISO3c, country.name, year) %>% select(-lon, -lat) %>% 
  summarise(conflict_n_sum = sum(n_conflict, na.rm = T), conflict_deaths_sum = sum(n_deaths, na.rm = T), conflict_deaths_civil_sum = sum(deaths_civilian, na.rm = T),
            nightlights_sum = sum(nightlights), nightlights_mean = mean(nightlights), nightlights_sd = sd(nightlights),
            population = sum(population),    
            
            mos_one_sum = sum(mos_one, na.rm = T), mos_sum_sum = sum(mos_sum, na.rm = T), mos_bin_sum = sum(mos_bin, na.rm = T),
            mos_one_est_sum = sum(mos_one_estimate),
            
            NDVI_50_mean = mean(NDVI_50, na.rm = T), NDVI_75_mean = mean(NDVI_75, na.rm = T), NDVI_90_mean = mean(NDVI_90, na.rm = T),
            
            Tair_mean_mean = mean(Tair_mean, na.rm = T), Qair_mean_mean = mean(Qair_mean, na.rm = T), Rain_mean_mean = mean(Rain_mean, na.rm = T), 
            Tair_sd_mean = mean(Tair_sd, na.rm = T), Qair_sd_mean = mean(Qair_sd, na.rm = T), Rain_sd_mean = mean(Rain_sd, na.rm = T), 
            
            Water_permanent_sum = sum(Water_permanent, na.rm = T), Water_temporary_sum = sum(Water_temporary, na.rm = T))

# Check match
# d_grid_agg$country.name[which(!d_grid_agg$ISO3c %in% d_malaria$ISO3c)]
# d_malaria$country.name[which(!d_malaria$ISO3c %in% d_grid_agg$ISO3c)]

d_areal <- d_grid_agg %>% left_join((d_malaria %>% select(-country.name)), by = c("ISO3c", "year")) %>%
  rename("mal_cases" = "mal_case_presumed_confirmed") %>%
  mutate(mal_cases_pc = mal_cases / population, mal_deaths_pc = mal_deaths / population)

save(d_areal, file = "Data/d_areal.Rdata")


# Make sf data
#################

rm(list=ls())
load("Data/polygons_africa.Rdata")
load("Data/d_areal.Rdata")

d_areal_sf <- list()

for (i in 2010:2016){
  d_areal_sf[[as.character(i)]] <- st_as_sf(polygons_africa %>% left_join(d_areal %>% filter(year == i), by = c("iso3c" = "ISO3c")))
}


# plot(d_areal_sf[["2010"]])
# plot(d_areal_sf[["2011"]])
# plot(d_areal_sf[["2012"]])
# plot(d_areal_sf[["2013"]])
# plot(d_areal_sf[["2014"]])
# plot(d_areal_sf[["2015"]])
# plot(d_areal_sf[["2016"]])

save(d_areal_sf, file = "Data/d_areal_sf.Rdata")
