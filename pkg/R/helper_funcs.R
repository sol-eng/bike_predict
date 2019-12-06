#' Get dataframe of bikeshare feeds and URLs
#'
#' @param url url of feeds json, has default
#' @param lang which language, defaults to english, "en"
#'
#' @return A dataframe of feed names and URLs
#' @export
#'
#' @examples
#' if (interactive()) {
#'   feeds_urls()
#' }
feeds_urls <- function(url = "https://gbfs.capitalbikeshare.com/gbfs/gbfs.json", lang = "en") {
  tryCatch({
    feeds <- httr::GET(url) %>%
      httr::content()

    feeds$data[[lang]]$feeds %>%
      purrr::map_df(tibble::as_tibble) %>%
      dplyr::mutate(last_updated = as.POSIXct(feeds$last_updated, origin = "1970-01-01 00:00:00 UTC"))
  },
  error = function(e) glue::glue("Failure in feed retrieval: {e}"))
}

#' Print bike data
#'
#' @param x object of class "bike_data"
#'
#' @return dataframe of data, invisibly
#' @export
#'
#' @examples
#' if(interactive()) {
#' feeds_urls() %>%
#' dplyr::filter(name == "system_information") %>%
#' dplyr::pull("url") %>%
#' get_data()
#' }
print.bike_data <- function(x) {
  print(x$data)
}

#' Get bikeshare data for a particular URL
#'
#' @param url URL for data, get from \code{\link{feeds_urls}}
#'
#' @return dataframe of data
#' @export
#'
#' @examples
#' if(interactive()) {
#' feeds_urls() %>%
#' dplyr::filter(name == "system_information") %>%
#' dplyr::pull("url") %>%
#' get_data()
#' }
get_data <- function(url) {
  tryCatch({
    httr::GET(url) %>%
      httr::content() %>%
      clean_data(is_sys_info = grepl("system_information", url))
  },
  error = function(e) {
    message(glue::glue("Data access failure: {e}"))
    return(NULL)
  })
}

# Clean feed data, not exported
clean_data <- function(x, is_sys_info = FALSE) {
  # Create data object with metadata
  dat <- list(last_updated = as.POSIXct(x$last_updated,
                                        origin = "1970-01-01 00:00:00 UTC"),
              ttl = x$ttl)
  class(dat) <- "bike_data"

  # Add actual bike data
  if (is_sys_info) {
    dat$data <- x$data %>% as.list() %>% tibble::as_tibble()
  } else {
    dat$data <- x$data[[1]] %>% map_df(tibble::as.tibble)
  }
  dat
}


bike_train_dat <- function(split_date) {
  print(glue::glue("Using data from prior to {split_date} for training."))

  tbl(con, "bike_model_data") %>%
    filter(date < lubridate::ymd(split_date)) %>%
    collect()
}
bike_test_dat <- function(split_date) {
  print(glue::glue("Testing data is {split_date} to end."))

  tbl(con, "bike_model_data") %>%
    filter(date >= lubridate::ymd(split_date)) %>%
    collect()
}




