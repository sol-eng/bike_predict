print("Loading libraries")
library(shiny)
library(shinydashboard)
library(httr)
library(ggplot2)
library(dplyr)
library(vetiver)
library(glue)
library(leaflet)
library(lubridate)
print("---- Loading libraries complete")
# ////////////////////////////////////////////////////////////////////////////
# Setup
# ////////////////////////////////////////////////////////////////////////////
con <- odbc::dbConnect(odbc::odbc(), "Content DB", timeout = 10)
bike_station_info <- collect(tbl(con, "bike_station_info"))
print("---- bike station info start")
print(bike_station_info)
print("---- bike station info end")


# ////////////////////////////////////////////////////////////////////////////
# UI
# ////////////////////////////////////////////////////////////////////////////
ui <- dashboardPage(
  skin = "red",
  dashboardHeader(title = "Capitol Bikeshare Availability"),
  dashboardSidebar(disable = TRUE),
  dashboardBody(
    box(title = "Station Map",
        leafletOutput("map"),
        width = 12
    ),
    box("Click a station to populate",
        width = 12,
        plotOutput("plot")
    )
  )
)

# ////////////////////////////////////////////////////////////////////////////
# Server
# ////////////////////////////////////////////////////////////////////////////
server <- function(input, output, session) {

  # Draw station map ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  output$map <- renderLeaflet({
    bike_station_info %>%
      leaflet() %>%
      addProviderTiles(providers$CartoDB.Positron) %>%
      setView(lng = median(bike_station_info$lon), lat = median(bike_station_info$lat), zoom = 14) %>%
      addAwesomeMarkers(
        lng = ~lon,
        lat = ~lat,
        icon = awesomeIcons(
          "bicycle",
          library = "fa",
          iconColor = "white",
          markerColor = "red"
        ),
        label = ~paste0(name)
      )
  })


  # Make predictions ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  predictions_df <- reactive({

    # Get the station clicked. Somtimes clicks and ids don't line up exactly, use min dist
    req(input$map_marker_click)

    selected_bike_station_info <-
      bike_station_info %>%
      mutate(
        lat = lat - input$map_marker_click$lat,
        lon = lon - input$map_marker_click$lng,
        dist = lat^2 + lon^2
      ) %>%
      filter(dist == min(dist)) %>%
      head(1)

    # Create a tibble that has one row for each hour in the day.
    selected_station_hourly <-
      tibble(hour = c(0: 23)) %>%
      mutate(
        station_name = selected_bike_station_info$name,
        id = selected_bike_station_info$station_id,
        date = today(),
        month = month(today()),
        dow = wday(today(), label = TRUE, abbr = FALSE),
        lat = selected_bike_station_info$lat,
        lon = selected_bike_station_info$lon
      )

    url <- "https://colorado.rstudio.com/rsc/bike-predict-r-api/predict"
    endpoint <- vetiver_endpoint(url)

    predictions <-
      predict(
        endpoint,
        select(
          selected_station_hourly,
          id, hour, date, month, dow, lat, lon
        )
      ) %>%
      bind_cols(selected_station_hourly) %>%
      mutate(
        time = lubridate::make_datetime(
          year = year(today()),
          month = month(today()),
          day = day(today()),
          hour = hour
        )
      )

  })

  # Create plot of predictions~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  output$plot <- renderPlot({

    station_name <- predictions_df() %>%
      distinct(station_name) %>%
      pull()

    predictions_df() %>%
      ggplot(aes(x = time, y = .pred)) +
      ggtitle(glue::glue("Predicted Bikes Available at {station_name}")) +
      xlab("Time") +
      ylab("Predicted Number of Bikes") +
      scale_x_datetime(labels = function(x) format(x - 18000, "%H:%M")) +
      scale_y_continuous(labels = round) +
      geom_line()
  })

}

# ////////////////////////////////////////////////////////////////////////////
# Run the app
# ////////////////////////////////////////////////////////////////////////////
shinyApp(ui = ui, server = server)
