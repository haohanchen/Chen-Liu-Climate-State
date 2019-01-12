rm(list=ls())

load("Data/polygons_africa.Rdata")
load("Data/d_areal.Rdata")

d_s <- d_areal %>% filter(year == 2012)

polygons_africa$iso3c %in% d_s$ISO3c

d_s2 <- st_as_sf(polygons_africa %>% left_join(d_s, by = c("iso3c" = "ISO3c")))

names(d_s2)

plot(d_s2[, "ID"])
plot(d_s2[, 18:23])
plot(d_s2[, "conflict_n_sum"])
plot(d_s2[, "conflict_deaths_sum"])

