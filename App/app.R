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
                    dashboardBody(leafletOutput("map"),
                                  plotOutput("plot"))
)

server <- function(input, output, session) {
    # Get station pin
    pins::board_register_rsconnect(server = "https://colorado.rstudio.com/rsc",
                                   key = Sys.getenv("RSTUDIOCONNECT_API_KEY"))

    stats <- pins::pin_get("alex.gold/bike_station_info", board = "rsconnect")

    # Use API to get predictions from model
    df <- reactive({

        # Fake data for now
        # httr::GET("https://colorado.rstudio.com/rsc/bike_predict/pred",
        #           query = list(station_id = stats$station_id)

        times <- Sys.time() + seq(0, 3600, by = 600)
        tidyr::crossing(times, station_id = stats$station_id) %>%
            mutate(pred = sample(0:20, nrow(.), replace = TRUE)) %>%
            left_join(stats)

    })




    output$map <- renderLeaflet({
        df() %>%
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

    # Create plot
    output$plot <- renderPlot({
        req(input$map_marker_click)

        print(input$map_marker_click)
        df <- df() %>%
            filter(lat == input$map_marker_click$lat,
                   lon == input$map_marker_click$lng)

        stat_name <- unique(df$name)

        df %>%
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
