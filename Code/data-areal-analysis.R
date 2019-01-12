# Load Library
################
library(sf)
library(spdep)
library(dplyr)
library(ggplot2)

# Load dataset
#################
rm(list=ls())
load("Data/d_areal_sf.Rdata")


# Work on one year data
########################

d <- d_areal_sf[["2012"]] %>% filter(!iso3c %in% c("MDG", "CPV", "COM")) 


# Descriptive plots
########################

fig_areal_mal <- list()

# DV: Malaria Cases
ggplot(d) + geom_sf(aes(fill = mal_cases)) + ggtitle("Number of Malaria Cases")
ggplot(d) + geom_sf(aes(fill = mal_cases_pc)) + ggtitle("Number of Malaria Cases Per Capita")

# DV: Malaria Death
ggplot(d) + geom_sf(aes(fill = mal_deaths)) + ggtitle("Number of Malaria Deaths")
ggplot(d) + geom_sf(aes(fill = mal_deaths_pc)) + ggtitle("Number of Malaria Deaths Per Capita")




# Create Weight Matrix
#######################

W <- st_touches(d, sparse = F)
listW <- mat2listw(W)

# Alternative Weight Matrix
#############################
# W <- st_distance(d)
# Somehow takes forever to calculate


# Fit poisson model with offset
################################
names(d)

fit_pois <- list()

fit_pois <- glm(mal_cases ~ offset(log(population)) + mos_one_sum + conflict_n_sum + Qair_mean_mean + Qair_sd_mean, family = "poisson", data = d)
summary(fit_pois[[1]])


# Tests Spatial Autocorrelation
################################

# Deaths
moran.test(d$mal_deaths, listW)
geary.test(d$mal_deaths, listW)

moran.test(d$mal_deaths_pc, listW)
geary.test(d$mal_deaths_pc, listW)


# Cases
moran.test(d$mal_cases, listW)
geary.test(d$mal_cases, listW)

moran.test(d$mal_cases_pc, listW)
geary.test(d$mal_cases_pc, listW)


# Fit model: Number of cases
#############################

fit_cases <- list()


fit_cases[[1]] <- spautolm(formula = mal_cases_pc ~ 1, data = d, listw = listW, family = "CAR")
summary(fit_cases[[1]])
fit_cases[[1]]$lambda


fit_cases[[2]] <- spautolm(formula = mal_cases_pc ~ mos_one_sum, data = d, listw = listW, family = "CAR")
summary(fit_cases[[2]])
fit_cases[[2]]$lambda


# Fit model: Death
#############################


fit_car <- spautolm(formula = mal_deaths ~ 1, data = d, listw = listW, family = "CAR")
summary(fit_car)
fit_car$lambda

fit_car <- spautolm(formula = mal_deaths ~ mos_sum_sum, data = d, listw = listW, family = "CAR")
summary(fit_car)
fit_car$lambda


fit_sar <- spautolm(formula = mal_deaths ~ 1, data = d, listw = listW, family = "SAR")
summary(fit_sar)
fit_sar$lambda



# Fit Bayesian CAR Model
##########################

# Create Weight Matrix
#######################

W <- st_touches(d, sparse = F)
listW <- mat2listw(W)

m_glm <- glm(mal_deaths ~ offset(log(population)) + mos_one_est_sum, family = poisson, data = d)
summary(m_glm)
m_glm$coefficients
vcov(m_glm)

D = diag(rowSums(W))
X = model.matrix(~scale(d$mos_one_est_sum))
log_offset = log(d$population)
y = d$mal_cases

car_model = "model{
  for(i in 1:length(y)) {
    y[i] ~ dpois(lambda[i])
    y_pred[i] ~ dpois(lambda[i])
    log(lambda[i]) = log_offset[i] + X[i,] %*% beta + omega[i]
  }

  for(i in 1:2) {
    beta[i] ~ dnorm(0,1)
  }

  omega ~ dmnorm(rep(0,length(y)), tau * (D - phi*W))
  sigma2 = 1/tau
  tau ~ dgamma(2, 2)
  phi ~ dunif(0,0.99)
}"

if (!file.exists("Model/areal_car_bayes.Rdata")) {
  m = rjags::jags.model(
    textConnection(car_model), 
    data = list(
      D = D,
      y = y,
      X = X,
      W = W,
      log_offset = log_offset
    ),
    n.adapt=25000
  )
  
  update(m, n.iter=200000)#, progress.bar="none")
  
  areal_car_bayes = rjags::coda.samples(
    m, variable.names=c("sigma2","tau", "beta", "omega", "phi", "y_pred"),
    n.iter=500000, thin=100
  )
  save(areal_car_bayes, m, file="areal_car_bayes.Rdata")
} else {
  load("areal_car_bayes.Rdata")
}

beta_params = tidybayes::gather_samples(areal_car_bayes,beta[i]) %>%
  ungroup() %>%
  mutate(term = paste0(term,"[",i,"]"))

ar_params = tidybayes::gather_samples(areal_car_bayes,sigma2,phi)

omega = tidybayes::gather_samples(areal_car_bayes,omega[i])
y_pred = tidybayes::gather_samples(areal_car_bayes,y_pred[i])

ggplot(beta_params, aes(x=.iteration, y=estimate, color=term)) +
  geom_line() +
  facet_grid(term~., scales="free_y") +
  guides(color=FALSE)

table(beta_params$term)
