library(plumber)
library(pins)
library(tibble)
library(xgboost)

pins::board_register_rsconnect(server = "https://colorado.rstudio.com/rsc",
                               key = Sys.getenv("RSTUDIOCONNECT_API_KEY"))
pins::board_connect("rsconnect")
mod <- pin_get("alex.gold/bike_available_model", board = "rsconnect")
stats <- pin_get("alex.gold/bike_rental_stations", board = "rsconnect")


#* @apiTitle Bike Prediction API

#* Return the predicted number of bikes available at a station in 10 minutes
#* @param station_id the id number of a station in the Capitol Bikeshare program
#* @param min_time time to start predictions
#* @param max_time time to stop predictions
#* @param interval prediction interval
#* @get /pred
a <- function(station_id, min_time = 600, max_time = 600, interval = 600) {
  # sanitize inputs
  station_id <- as.numeric(station_id)
  min_time <- as.numeric(min_time)
  max_time <- as.numeric(max_time)
  interval <- as.numeric(interval)

  times <- seq(min_time, max_time, by = interval)
  n_preds <- length(times)
  if (!station_id %in% stats$station_id) stop("That station does not exist.")

  station_vec <- rep(station_id, n_preds)
  time_vec <- Sys.time() + times

  dat <- matrix(data = c(station_vec, lubridate::hour(time_vec)),
                nrow = n_preds, ncol = 2)

  tibble::tibble(station_id = station_vec,
                 times = time_vec,
                 pred = predict(mod, newdata = dat) %>% round())
}
