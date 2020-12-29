library(shiny)
library(tidyverse)
library(pool)
library(bikeHelpR)

con <- dbPool(odbc::odbc(), dsn = "Content DB")
pins::board_register_rsconnect(server = "https://colorado.rstudio.com/rsc",
                               key = Sys.getenv("RSTUDIOCONNECT_API_KEY"))

model_details <- pins::pin_get("bike_model_rxgb", board = "rsconnect")

all_days <- tbl(con, "bike_pred_data") %>%
    collect()

print("data loaded")
print(nrow(all_days))

onStop(function() {
    poolClose(con)
})


ui <- fluidPage(

    # Application title
    titlePanel("Model Performance Metrics"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            selectInput("data","Train or Test Results?", choices = c("Train", "Test"))
        ),
        mainPanel(
            p("Model Details:"),
            textOutput("dets"),
            tableOutput("summary"),
            tableOutput("metrics"),
            plotOutput("distrib"),
            plotOutput("resids"),
            plotOutput("qq")
        )
    )
)


server <- function(input, output, session) {
    results <- reactive({
        if (input$data == "Test") {
            all_days %>%
                filter(date >= model_details$split_date)
        } else {
            all_days %>%
                filter(date < model_details$split_date)
        }
    })

    output$dets <- renderText({
        capture.output(model_details$model)
    })

    output$summary <- renderTable({
        tibble(
            train_date = model_details$train_date,
            train_window_start = model_details$train_window_start,
            split_date = model_details$split_date
        )
    })

    output$metrics <- renderTable({
            oos_metrics(results()$actual, results()$preds)
    })

    output$qq <- renderPlot(
        results() %>%
            select(actual, preds) %>%
            gather(key = "which", value = "value", actual, preds) %>%
            mutate(which = ifelse(which == "actual", "Actual", "Prediction")) %>%

            ggplot(aes(sample = value, color = which)) +
            geom_qq() +
            ggtitle("QQ-Norm Plot (Overlap means model congruent with actual)") +
            theme_bw() +
            labs(color = "Series")
    )

    output$distrib <- renderPlot(
        results() %>%
            select(actual, preds) %>%
            tidyr::gather("var", "val", actual, preds) %>%

            mutate(var = ifelse(var == "actual", "Actual", "Prediction")) %>%
            ggplot(aes(x = val, color = var)) +
            geom_density() +
            ggtitle("Distributions of Number of Bikes") +
            labs(color = "Series") +
            theme_bw()
    )

    output$resids <- renderPlot(
        results() %>%
            ggplot(aes(x = resid)) +
            geom_density() +
            ggtitle("Residual Density Plot") +
            theme_bw() +
            geom_vline(xintercept = 0)
    )
}

# Run the application
shinyApp(ui = ui, server = server)

