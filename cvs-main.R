library(rvest)
library(stringi)
library(progress)
library(future)
library(furrr)
library(tidyverse)

readr::local_edition(1) # b/c it's been broked on M1 for a while

dir.create("data/raw", showWarnings = FALSE)

# get states ----------------------------------------------------------------------------------

# robots.txt says `Allow: /store-locator/`

pg <- read_html("https://www.cvs.com/store-locator/cvs-pharmacy-locations")

# grab all the state links

html_nodes(pg, xpath = ".//a[contains(., 'Pharmacies in')]/@href") %>% 
  html_text() %>% 
  sprintf("https://www.cvs.com%s", .) -> state_urls

state_urls %>% 
  map(~{
    writeLines(.x) # where are we?
    Sys.sleep(2) # THIS NEEDS TO CHANGE TO AVOID IP BANNING; NOT SURE WHAT TO SET
    read_html(.x)
  }) -> state_pgs

# get munis/towns -----------------------------------------------------------------------------

state_pgs %>% 
  walk(~{

    # each state page has a list of municipalities/towns
    
    html_nodes(.x, xpath = ".//a[contains(@href, 'store-locator/cvs-pharmacy-locations')]/@href") %>% 
      html_text() %>% 
      sprintf("https://www.cvs.com%s", .) %>% 
      gsub(";jse.*", "", .) %>% # session info broke some things in a trial run so we get rid of it
      tail(-1) -> town_urls
    
    # each muni/town has a list of stores
    town_urls %>% 
      map(~{
        writeLines(.x) # where are we?
        res <- read_html(.x)
        # we're saving a local HTML copy of each store in the event something 
        # goes wrong so we can startup again and not lose all our work
        writeLines(as.character(res), file.path("~/Data/tmp", ulid_generate()))
        Sys.sleep(2) # THIS NEEDS TO CHANGE TO AVOID IP BANNING; NOT SURE WHAT TO SET
      })
    
  }) 

# post-process downloaded HTML ----------------------------------------------------------------

# the irony with this is that it's not even necessary on the M1 Max
plan(multisession)

# all our files we grabbed above
fils <- list.files("data/raw", full.names = TRUE)

pb <- progress_bar$new(total = length(fils))

fils %>% 
  future_map(
    ~read_html(.x) %>% 
      html_nodes("div.each-store") %>% # a convenient <div> <3 template-driven sites
      map(as.character) %>% # cld just keep it the opaque binary object rly
      unlist() %>% 
      { pb$tick() ; . }
  ) %>% 
  unlist() -> store_pages

pb <- progress_bar$new(total = length(store_pages))

store_pages %>% 
  future_map_dfr(~{
    
    pg <- read_html(.x)
    
    # the pages are template-driven so these are the node targets we need to get
    
    tibble(
      amenities = html_nodes(pg, "div#sp-amenities") %>% html_text(trim=FALSE),
      address = html_nodes(pg, "p.store-address") %>% html_text(trim=TRUE),
      phone = html_nodes(pg, "p.phone-number") %>% html_text(trim=TRUE),
      id = html_nodes(pg, "span.store-number") %>% html_text(trim=TRUE),
      target = html_nodes(pg, "div.targetSwitch") %>% html_text(trim=TRUE)
    ) %>% 
      { pb$tick() ; . }
    
  }) -> stores

# do some cleanup on a cpl columns

scrape_date <- as.character(Sys.Date())

stores %>% 
  mutate(
    amenities = stri_trim_both(amenities) %>% 
      stri_replace_all_regex("\n+", "|"),
    phone = stri_replace_all_regex(phone, "[\t\n]", "") %>% 
      stri_replace_all_regex("^#.*", ""),
    id = stri_replace_all_regex(id, "^#[[:space:]]", ""),
    target = (target == 1)
  ) %>% 
  distinct() %>% # b/c I had to restart scraping and didn't track dups
  mutate(
    scraped = scrape_date
  ) %>% 
  write_csv("data/cvs.csv") -> stores

# for geocodio processing ---------------------------------------------------------------------

write_csv(select(stores, address), "data/cvs-address.csv")

# data/cvs-address_geocodio_10effd70f9b9148ff2beccb58e8bf1b924fce9a4.csv
