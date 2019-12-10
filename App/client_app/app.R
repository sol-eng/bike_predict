library(shiny)
library(shinydashboard)
library(httr)
library(ggplot2)
library(dplyr)
library(leaflet)

# Create dashboard page UI
ui <- dashboardPage(skin = "red",
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

server <- function(input, output, session) {
    # Get station pin
    pins::board_register_rsconnect(server = "https://colorado.rstudio.com/rsc",
                                   key = Sys.getenv("RSTUDIOCONNECT_API_KEY"))

    stats <- pins::pin_get("alex.gold/bike_station_info", board = "rsconnect")

    output$map <- renderLeaflet({
        stats %>%
            leaflet() %>%
            addProviderTiles(providers$CartoDB.Positron) %>%
            setView(lng = median(stats$lon), lat = median(stats$lat), zoom = 14) %>%
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


    # Use API to get predictions from model
    df <- reactive({
        req(input$map_marker_click)

        id <- stats %>%
            # Somtimes clicks and ids don't line up exactly, use min dist
            mutate(lat = lat - input$map_marker_click$lat,
                   lon = lon - input$map_marker_click$lng,
                   dist = lat^2 + lon^2) %>%
            filter(dist == min(dist)) %>%
            pull(station_id)
        print(glue::glue("Station id: {id}"))

            res <- httr::GET("https://colorado.rstudio.com/rsc/bike_predict_api/pred",
                      query = list(station_id = id)) %>%
                httr::content() %>%
                purrr::map_df(tibble::as_tibble)
    })

    # Create plot
    output$plot <- renderPlot({
        stat_name <- df() %>%
            inner_join(stats %>% select(name, station_id)) %>%
            pull(name) %>%
            unique()

        df() %>%
            mutate(times = as.POSIXct(times)) %>%

            ggplot(aes(x = times, y = pred, group = 1)) +
            ggtitle(glue::glue("Predicted Bikes Available at {stat_name}")) +
            ggthemes::theme_clean() +
            xlab("Time") +
            ylab("Predicted Number of Bikes") +
            scale_x_datetime(labels = function(x) format(x - 18000, "%H:%M")) +
            scale_y_continuous(labels = round) +
            geom_line()
    })

}

# Run the application
shinyApp(ui = ui, server = server)
