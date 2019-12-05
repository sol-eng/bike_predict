library(plumber)
library(pins)
library(tibble)
library(xgboost)

pins::board_register_rsconnect(server = "https://colorado.rstudio.com/rsc",
                               key = Sys.getenv("RSTUDIOCONNECT_API_KEY"))
pins::board_connect("rsconnect")
mod <- pin_get("alex.gold/bike_available_model", board = "rsconnect")
stats <- pin_get("alex.gold/bike_station_info", board = "rsconnect")


#* @apiTitle Bike Prediction API

#* Return the predicted number of bikes available at a station in 10 minutes
#* @param station_id the id number of (a) station(s) in the Capitol Bikeshare program
#* @param max_time time to stop predictions
#* @param interval prediction interval
#* @get /pred
a <- function(station_id, max_time = 86400, interval = 600) {
  # sanitize inputs
  station_id <- as.numeric(station_id)
  if (!all(station_id %in% stats$station_id)) stop("That station does not exist.")

  max_time <- as.numeric(max_time)
  interval <- as.numeric(interval)

  times <- Sys.time() + seq(0, max_time, by = interval)

  df <- tidyr::crossing(times, station_id)


  pred_df <- df %>%
    transmute(station = as.numeric(station_id), hour = lubridate::hour(times)) %>%
    as.matrix()

  df %>%
    mutate(pred = predict(mod, newdata = pred_df) %>% round())
}
