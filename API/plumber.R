library(plumber)
library(pins)
library(tibble)
library(xgboost)
library(lubridate)
library(dplyr)
library(tidyr)
library(tidymodels)

board_register_rsconnect(server = "https://colorado.rstudio.com/rsc",
                               key = Sys.getenv("RSTUDIOCONNECT_API_KEY"))
model_details <- pin_get("bike_model_rxgb", board = "rsconnect")
stations <- pin_get("bike_station_info", board = "rsconnect")


#* @apiTitle Bike Prediction API

#* Return the predicted number of bikes available at a station in 10 minutes

#* @param station_id the id number of (a) station(s) in the Capitol Bikeshare program (try 75)
#* @param max_time time to stop predictions in seconds, defaults to 86,400 (24 hours)
#* @param interval prediction interval in seconds, defaults to 600 (10 minutes)
#* @get /pred
function(station_id, max_time = 86400, interval = 600) {
  # sanitize inputs
  station_id <- as.numeric(station_id)
  if (!all(station_id %in% stations$station_id)) stop("That station does not exist.")

  # select model from pin
  model <- model_details$mod

  # create interval for prediction
  max_time <- as.numeric(max_time)
  interval <- as.numeric(interval)

  times <- Sys.time() + seq(0, max_time, by = interval)

  df <- crossing(times, station_id = as.character(station_id)) %>%
    left_join(stations) %>%
    select(-name)

  # apply format and recipe model expects as input
  pred_mat <- df %>%
    transmute(id = station_id,
              hour = hour(times),
              month = month(times),
              date = date(times),
              dow = weekdays(times),
              lat,
              lon,
              n_bikes = NA) %>%
    bake(model_details$recipe, .) %>%
    # transform to matrix for xgboost
    select(-id, -date, -n_bikes) %>%
    as.matrix()

  preds <- predict(model, newdata = pred_mat)

  # return results with predictions
  df$pred = preds
  df
}
