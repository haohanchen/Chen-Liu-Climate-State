#######################################################
# Re: Data cleaning: Mosquito, conflict, nightlight
# Author: Haohan
# Created: 4/23/2018
#######################################################
rm(list=ls())

CUT_YR <- 2010

# Load package
######################
library(dplyr)
library(tidyr)
library(countrycode)
library(ggplot2)

# Nightlight, population, capital distance Data
################################################
prio_cs <- read.csv("../raw-data/prio-grid/PRIO-GRID Static Variables - 2018-04-24.csv")
prio_ts <- read.csv("../raw-data/prio-grid/PRIO-GRID Yearly Variables for 2010-2013 - 2018-04-29.csv")

names(prio_cs)[1] <- "priogrid_gid"
names(prio_ts)[1] <- "priogrid_gid"

prio_coord <- prio_cs[, c("priogrid_gid", "xcoord", "ycoord")]

# Clean population (use only 2015 data)
prio_ts_pop <- read.csv("../raw-data/prio-grid/PRIO-GRID Yearly Variables for 2005-2005 - 2018-05-01.csv")
names(prio_ts_pop)[1] <- "priogrid_gid"
d_pop <- prio_ts_pop %>% select(-year) %>% left_join(prio_coord, "priogrid_gid") %>% rename("population" = "pop_hyd_sum")

d_economy <- prio_ts %>% filter(year >= CUT_YR) %>% left_join(prio_coord, "priogrid_gid") %>% left_join(d_pop) %>%
  select(year, xcoord, ycoord, nlights_calib_mean, capdist, population) %>% 
  rename("nightlights"="nlights_calib_mean", "dist_to_capital"="capdist") %>% filter(year < 2013) %>% 
  arrange(xcoord, ycoord, year)

names(d_economy)
d_economy <- d_economy %>% rbind(., d_economy %>% filter(year == 2012) %>% mutate(year = 2013)) %>%
  rbind(., d_economy %>% filter(year == 2012) %>% mutate(year = 2014)) %>%
  rbind(., d_economy %>% filter(year == 2012) %>% mutate(year = 2015)) %>%
  rbind(., d_economy %>% filter(year == 2012) %>% mutate(year = 2016)) %>% 
  replace_na(list(nightlights = 0, population = 0)) %>%
  arrange(xcoord, ycoord, year)


save(d_economy, file = "Data/d_economy.Rdata")

# Conflict Data
######################
ged <- read.csv("../raw-data/ucdp/ged171.csv")

# Select only Africa events
ged <- ged %>% filter(region == "Africa")
# Aggregate
ged_grid <- ged %>% group_by(year, priogrid_gid) %>% 
  summarise(n_conflict = n(), n_deaths = sum(deaths_a) + sum(deaths_b), deaths_civilian = sum(deaths_civilians))
# Grid distribution by year
table(ged_grid$year)
# Filter years
ged_grid <- ged_grid %>% filter(year >= CUT_YR) 

# Subset years after 2010, merge coordinate
d_conflict <- ged_grid %>% 
  left_join(prio_coord, by = "priogrid_gid") %>% 
  select(year, xcoord, ycoord, n_conflict, n_deaths, deaths_civilian)

save(d_conflict, file = "Data/d_conflict.Rdata")

# Ugly plot
plot(d_conflict$xcoord, d_conflict$ycoord)


# Mosquito Data
######################
mos <- read.csv("Data/malaria-mosquito/Africa_Vectors_database_1898-2016.csv")
# country_id <- data.frame(Country = unique(mos$Country)) %>% mutate(iso3c = countrycode(Country, "country.name", "iso3n"))

# Var names of mosquito
names(mos)
var_mos_type <- names(mos)[10:36]
# Recode the mosquito variable
mos_r <- t(apply(mos[, var_mos_type], 1, function(x) c(mos_one = any(x =="Y"), mos_sum = sum(x == "Y"))))
mos_r2 <- cbind(mos[, c("Country", "Lat", "Long", "YeStart", "YeEnd")], mos_r)

# Note: Some coding error -- start year < end year (3 cases)
# mos[mos_r2$YeEnd - mos_r2$YeStart + 1 <= 0, ]

# Repeat observations spanning over years
mos_r3 <- mos_r2[rep(1:nrow(mos_r2), abs(mos_r2$YeEnd - mos_r2$YeStart) + 1), ]
mos_r3$year <- unlist(apply(mos_r2[, c("YeEnd", "YeStart")], 1, function(x) x["YeStart"]:x["YeEnd"]))

# Filter years
mos_r4 <- mos_r3 %>% select(-YeEnd, -YeStart) %>% filter(year >= 2010)

# Assign into grid.
names(mos_r4)
mos_r5 <- mos_r4 %>% 
  mutate( Lat_grid = (floor(abs(Lat)) + ifelse((abs(Lat) - floor(abs(Lat))) > 0.5, 0.75, 0.25)) * ((Lat > 0)*2-1),
          Long_grid = floor(abs(Long)) + ifelse((abs(Long) - floor(abs(Long))) > 0.5, 0.75, 0.25) * ((Long > 0)*2-1)) %>%
  group_by(year, Lat_grid, Long_grid) %>% summarise(mos_one = sum(mos_one), mos_sum = sum(mos_sum)) %>% mutate(mos_bin = 1)


# Final mosquito data
d_mosquito <- mos_r5

table(d_mosquito$mos_one)

# Save data file
save(d_mosquito, file = "Data/d_mosquito.Rdata")


# Malaria data (country)
#########################
rm(list=ls())

# Import data
# Number of malaria deaths
d_mal_deaths <- read.csv("Data/wmr2017/malaria-africa-deaths.csv", na = "-")
# Number of malaria cases, by different ways of calculation
d_mal_cases <- read.csv("Data/wmr2017/malaria-africa-cases.csv", na = "-")


# Clean cases dataset
d_mal_cases$country.name <- rep(d_mal_cases$country.name[d_mal_cases$country.name != ""], each = 6)
d_mal_cases2 <- d_mal_cases %>% reshape2::melt(id.vars = c("country.name", "var")) %>%
  mutate(year = as.numeric(substr(variable, 2, 5))) %>% select(-variable) %>% reshape2::dcast(country.name + year ~ var, value.var = "value")
names(d_mal_cases2)[-c(1, 2)] <- c("mal_case_confirmed_microscopy", "mal_case_confirmed_rdt", "mal_case_imported", 
                                   "mal_case_microscopy_examined", "mal_case_presumed_confirmed", "mal_case_rdt_exam")
d_mal_cases_f <- d_mal_cases2


# Clean death dataset
d_mal_deaths2 <- d_mal_deaths %>% reshape2::melt(id.vars = c("country.name")) %>%
  mutate(year = as.numeric(substr(variable, 2, 5))) %>% select(-variable) %>% rename("mal_deaths" = "value")

d_mal_deaths_f <- d_mal_deaths2

d_malaria <- merge(d_mal_cases_f, d_mal_deaths_f, by = c("country.name", "year")) %>%
  mutate(ISO3c = countrycode::countrycode(country.name, "country.name", "iso3c")) # %>%
  # select(-country.name)

save(d_malaria, file = "Data/d_malaria.Rdata")

