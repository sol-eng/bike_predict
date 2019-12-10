library(plumber)
library(pins)
library(tibble)
library(xgboost)
library(bikeHelpR)
library(lubridate)
library(dplyr)

pins::board_register_rsconnect(server = "https://colorado.rstudio.com/rsc",
                               key = Sys.getenv("RSTUDIOCONNECT_API_KEY"))
mods <- list(r_xgb = pins::pin_get("alex.gold/bike_model_rxgb", board = "rsconnect"))
stats <- pins::pin_get("alex.gold/bike_station_info", board = "rsconnect")


#* @apiTitle Bike Prediction API

#* Return the predicted number of bikes available at a station in 10 minutes
#* @param station_id the id number of (a) station(s) in the Capitol Bikeshare program
#* @param max_time time to stop predictions
#* @param interval prediction interval
#* @param which which model, defaults to rxgb
#* @get /pred
function(station_id, max_time = 86400, interval = 600, which = "r_xgb") {
  # sanitize inputs
  station_id <- as.numeric(station_id)
  if (!all(station_id %in% stats$station_id)) stop("That station does not exist.")

  max_time <- as.numeric(max_time)
  interval <- as.numeric(interval)

  times <- Sys.time() + seq(0, max_time, by = interval)

  df <- tidyr::crossing(times, station_id = as.character(station_id)) %>%
    dplyr::left_join(stats) %>%
    dplyr::select(-name)

  pred_mat <- df %>%
    dplyr::transmute(id = station_id,
              hour = hour(times),
              month = month(times),
              date = date(times),
              dow = weekdays(times),
              lat,
              lon,
              n_bikes = NA) %>%
    recipes::bake(mods[[which]]$recipe, .) %>%
    prep_r_xgb_mat()

  df %>%
    dplyr::mutate(pred = predict(mods[[which]]$model, newdata = pred_mat) %>% round())
}
