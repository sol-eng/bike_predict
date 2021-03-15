library(targets)
options(tidyverse.quiet = TRUE)
tar_option_set(packages = c("magrittr", "bikeHelpR", "dbplyr", "dplyr",
                            "xgboost", "yardstick", "tidymodels", "RPostgreSQL",
                            "tarchetypes"))

list(
  tar_target(
    database_connection,
    DBI::dbConnect(odbc::odbc(), "Content DB")
  ),
  tar_target(
    register_pins_board,
    pins::board_register_rsconnect(server = "https://colorado.rstudio.com/rsc",
                                   key = Sys.getenv("RSTUDIOCONNECT_API_KEY"))
  ),
  tar_target(
    model_details,
    pins::pin_get("bike_model_rxgb", board = "rsconnect")
  ),
  tar_target(
    model,
    model_details$model
  ),
  tar_target(
    recipe,
    model_details$recipe
  ),
  tar_target(
    train_date,
    model_details$train_date
  ),
  tar_target(
    split_date,
    model_details$split_date
  ),
  tar_target(
    all_days,
    tbl(database_connection, "bike_model_data") %>% collect()
  ),
  tar_target(
    predictions,
    all_days %>%
      bake(recipe, .) %>%
      select(-id, -date, -n_bikes) %>%
      as.matrix() %>%
      predict(model, .)
  ),
  tar_target(
    results,
    all_days %>%
      transmute(
        id = id,
        hour = hour,
        date = date,
        preds = predictions,
        residuals = n_bikes - preds,
        actual = n_bikes,
        upload_time = Sys.time(),
        train_date = train_date,
        model = "rxgb"
      )
  ),
  tar_target(
    drop_pgsql_table,
    db_drop_table(database_connection, "bike_pred_data", force = TRUE)
  ),
  tar_target(
    setup_pgsql_driver,
    dbDriver("PostgreSQL")
  ),
  tar_target(
    setup_pgsql_connection,
    RPostgreSQL::dbConnect(setup_pgsql_driver,
                                   host = Sys.getenv("CONTENT_DB_URL"),
                                   dbname = "rds",
                                   user = Sys.getenv("CONTENT_DB_USER"),
                                   password = Sys.getenv("CONTENT_DB_PWD")
    )
  ),
  tar_target(
    write_pgsql_table,
    RPostgreSQL::dbWriteTable(setup_pgsql_connection, "bike_pred_data", results)
  ),
  tar_target(
    train_res,
    results %>%
      filter(date < split_date)
  ),
  tar_target(
    test_res,
    results %>%
      filter(date >= split_date)
  ),
  tar_target(
    latest_res,
    results %>%
      filter(date == { results %>%
                       slice_max(order_by = date, n=1, with_ties = FALSE) %>%
                       pull(date)
                      }
             )
  ),
  #tar_target(
  #  disconnect_db,
  #  DBI::dbDisconnect(database_connection)
  #),
  tar_target(
    pgsql_disconnection,
    RPostgreSQL::dbDisconnect(setup_pgsql_connection)
  )
)
