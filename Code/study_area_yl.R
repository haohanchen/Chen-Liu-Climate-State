# Find study area by country names
library(rworldmap)
library(sp)
library(countrycode)
setwd("C:/Users/yl299/Dropbox/Courses/SpatialTemporal/Project/Code")
theCountries <- c("DEU", "COD", "BFA")

countries <- read.csv("../Data/ISO3dictionary.csv")
AF <- data.frame(country=countries$ISO3)

cv <- as.vector(AF$country)
for (i in seq(length(cv))){
  cv[i] <- substr(cv[i],1,3)
}
AF$iso3n <- countrycode(cv, origin="iso3c",destination="iso3n")

data(gridCountriesDegreesHalf)
d_country <- data.frame(coordinates(gridCountriesDegreesHalf),gridCountriesDegreesHalf$ISO_N3)

colnames(d_country) <- c("lon","lat","ISO3n")
d_country <- d_country[d_country$ISO3n %in% AF$iso3n,]
d_country$ISO3c <- countrycode(d_country$ISO3n, origin="iso3n",destination="iso3c")
d_country$country.name <- countrycode(d_country$ISO3n, origin="iso3n",destination="country.name")

save(d_country, file="../Data/d_country.Rdata")


