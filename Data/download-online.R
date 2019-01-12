library(rvest)
library(stringr)

main_url <- "https://e4ftl01.cr.usgs.gov/MOLA/MYD13C2.006/2010.01.01/"

main_html <- read_html(main_url)

links <- html_nodes(main_html, "a") %>% html_attr("href") 
links[str_detect(links, ".hdf")]

