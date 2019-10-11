library(shiny)
library(shinydashboard)
library(httr)
library(ggplot2)
library(dplyr)

# Create dashboard page UI
ui <- dashboardPage(
    dashboardHeader(title = "Capitol Bikeshare Availability"),
    dashboardSidebar(selectInput("station", label = "Which Station",
                                 choices = ""),
                     sliderInput("times", "Start and End Time",
                                 min = 0, max = 36000, c(600, 600),
                                 step = 600),
                     numericInput("interval", "Time Interval", 600),
                     actionButton("get_preds", "Get Predictions")),
    dashboardBody(plotOutput("plot"))
)

server <- function(input, output, session) {
    # Get station pin
    pins::board_register_rsconnect(server = "https://colorado.rstudio.com/rsc",
                                   key = Sys.getenv("RSTUDIOCONNECT_API_KEY"))

    stats <- pins::pin_get("alex.gold/bike_rental_stations", board = "rsconnect")

    # Update station names and get id
    observe({
        updateSelectInput(session, "station", choices = stats$name)
    })
    station_id <- reactive({
        stats %>%
            dplyr::filter(name == input$station) %>%
            dplyr::pull(station_id)
    })

    # Use API to get predictions from model
    df <- eventReactive(input$get_preds,
                        {
                            httr::GET("https://colorado.rstudio.com/rsc/bike_predict/pred",
                                      query = list(station_id = station_id(),
                                                   min_time = input$times[1],
                                                   max_time = input$times[2],
                                                   interval = input$interval)) %>%
                                httr::content() %>%
                                dplyr::bind_rows() %>%
                                mutate(times = as.POSIXct(times))
                        })

    # Create plot
    output$plot <- renderPlot({
        plot <- df() %>%
            ggplot(aes(x = times, y = pred, group = 1)) +
            ggtitle(glue::glue("Predicted Bikes Available at {input$station}")) +
            ggthemes::theme_clean() +
            xlab("Time") +
            ylab("Predicted Number of Bikes") +
            scale_x_datetime(labels = function(x) format(x, "%H:%M")) +
            scale_y_continuous(labels = round)

        if (nrow(df()) == 1) {
            plot <- plot + geom_point()
        } else {
            plot <- plot + geom_line()
        }
        plot
    })
}

# Run the application
shinyApp(ui = ui, server = server)
