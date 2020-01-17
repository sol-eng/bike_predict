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


#' Get Bike Training Data
#'
#' @param con db connection
#' @param split_date date to split data (on or before is training, after is test)
#'
#' @return training dataset
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(odbc::odbc(), "Content DB")
#' bike_train_dat(con, "2019-12-05")
bike_train_dat <- function(con, split_date) {
  print(glue::glue("Using data on or before {split_date} for training."))

  dplyr::tbl(con, "bike_model_data") %>%
    dplyr::filter(date <= lubridate::ymd(split_date)) %>%
    dplyr::collect()
}


#' Get bike test data
#'
#' @inheritParams bike_train_dat
#'
#' @return test bike data
#' @export
#'
#' @examples
#' con <- DBI::dbConnect(odbc::odbc(), "Content DB")
#' bike_test_dat(con, Sys.Date() - 2)
bike_test_dat <- function(con, split_date) {
  df <- dplyr::tbl(con, "bike_model_data") %>%
    dplyr::filter(date > lubridate::ymd(split_date)) %>%
    dplyr::collect()

  dates <- df %>% dplyr::count(date) %>% dplyr::pull(date) %>% paste0(collapse = " and ")

  print(glue::glue("Using {dates} as test data."))

  df
}

#' Get Bike Model Results
#'
#' @param mod Mode, fed to predict
#' @param mod_name model name for storage
#' @param test_df data frame of test data
#' @param pred_mat_func function to convert from test_df into prediction matrix for mod
#'
#' @return None
#' @export
bike_mod_results <- function(mod, mod_name, test_df, pred_mat_func) {
  # Get predictions and write to db
  pred_df <- bike_get_mod_preds(mod, mod_name, test_df, pred_mat_func)

  print("Saving test data to db.")
  pred_df %>%
    dplyr::mutate(upload_time = Sys.time(),
                  id = as.integer(id)) %>%
    DBI::dbWriteTable(con, "bike_pred_data", ., append = TRUE)

  # Keep only newest uploaded
  id_vars <- c("model", "train_date", "id", "hour", "date") %>%
    paste(collapse = ", ")
  DBI::dbExecute(
    con,
    glue::glue(
      "DELETE
    FROM bike_pred_data
    WHERE ({id_vars}, upload_time) NOT IN (
      SELECT {id_vars}, max(upload_time) as upload_time
      FROM bike_pred_data
      GROUP BY {id_vars}
    );"
    )
  )


  print("Writing Goodness of Fit Pin.")
  # Create OOS Goodness of Fit and pin
  curr_time <- Sys.time()
  dplyr::bind_cols(
    tibble::tibble(
      train_date = mod_params$train_date,
      mod = mod_name,
      time = curr_time
    ),
    oos_metrics(test_df$n_bikes, pred_df$preds)
  ) %>%
    # Bind in old
    dplyr::bind_rows(pins::pin_get("bike_err", board = "rsconnect")) %>%
    dplyr::mutate(time = ifelse(is.na(time), curr_time - 1, time)) %>%
    # If re-running today, keep only new
    dplyr::group_by(train_date, mod) %>%
    dplyr::filter(time == max(time, na.rm = TRUE)) %>%
    dplyr::ungroup() %>%
    dplyr::select(-time) %>%
    # pin back
    pins::pin("bike_err", "Goodness of Fit Metrics for Bike Prediction", board = "rsconnect")

}

#' Generate metrics for a model
#'
#' @param real vector of real
#' @param pred vector of predictions
#'
#' @return tibble of goodness-of-fit metrics
#' @export
#'
#' @examples
#' oos_metrics(1:3, 4:6)
oos_metrics <- function(real, pred) {
  tibble::tibble(
    rmse = yardstick::rmse_vec(real, pred),
    mae = yardstick::mae_vec(real, pred),
    ccc = yardstick::ccc_vec(real, pred),
    r2 = yardstick::rsq_trad_vec(real, pred)
  )
}



#' Turn test df into prediction matrix for R XGBoost model
#'
#' @param df test data frame
#'
#' @return a matrix
#' @export
prep_r_xgb_mat <- function(df) {
  df %>%
    dplyr::select(-n_bikes, -id, -date) %>%
    as.matrix()
}

#' Generate model predictions from a model
#'
#' @inheritParams bike_mod_results
#'
#' @return the test dataframe with predictions and residuals rbind-ed in
#' @export
bike_get_mod_preds <- function(mod, mod_name, test_df, pred_mat_func = NULL) {
  pred_mat <- test_df
  if (!is.null(pred_mat_func)) pred_mat <- pred_mat_func(pred_mat)

  test_df %>%
    dplyr::transmute(
      # Model metdata
      model = mod_name,
      train_date = mod$train_date,
      # ID pred to test data
      id = id,
      hour = hour,
      date = date,
      # Predictions
      n_bikes,
      preds = predict(mod$model, newdata = pred_mat),
      resid = test_df$n_bikes - preds)
}


