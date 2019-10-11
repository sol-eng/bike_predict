# Get data from a particular feed
clean_feeds <- function(x, lang = "en") {
  stopifnot(lang %in% names(x$data))

  list(
    last_updated = as.POSIXct(x$last_updated, origin = "1970-01-01 00:00:00 UTC"),
    data = x$data[[lang]]$feeds %>% map_df(as.tibble)
  )
}

# Get URL based on feed name
get_feed_url <- function(which, feeds) {
  stopifnot(which %in% feeds$data$name)

  dplyr::filter(feeds$data, name == which) %>%
    dplyr::pull(url)
}

# Clean data from a particular feed
clean_data <- function(x, is_sys_info = FALSE) {
  # Create data object with metadata
  dat <- list(last_updated = as.POSIXct(x$last_updated,
                                        origin = "1970-01-01 00:00:00 UTC"),
              ttl = x$ttl)
  class(dat) <- "bike_data"

  # Add actual bike data
  if (is_sys_info) {
    dat$data <- x$data %>% as.list() %>% as_tibble()
  } else {
    dat$data <- x$data[[1]] %>% map_df(as.tibble)
  }
  dat
}

# Print method
print.bike_data <- function(x) {
  print(x$data)
}

# Download data from a feed
get_data <- function(which, feeds) {
  url <- get_feed_url(which, feeds)
  content <-  url %>%
    httr::GET() %>%
    httr::content()

  if (grepl("system_information", url)) {
    clean_data(content, is_sys_info = TRUE)
  } else {
    clean_data(content)
  }
}
