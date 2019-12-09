library(shiny)
library(tidyverse)

con <- DBI::dbConnect(odbc::odbc(), "Content DB")
pred_df <- tbl(con, "bike_pred_data")
pins::board_register_rsconnect(server = "https://colorado.rstudio.com/rsc",
                               key = Sys.getenv("RSTUDIOCONNECT_API_KEY"))

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Model Performance Metrics"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            selectInput("mod", "Which model?", choices = ""),
            selectInput("train_date", "Model Training Date", choices = "")
        ),

        # Show a plot of the generated distribution
        mainPanel(
            verbatimTextOutput("mod_summ"),
            plotOutput("distrib"),
            plotOutput("resids"),
            plotOutput("qq")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {

    observe({
        mods <- pred_df %>% count(model) %>% pull(model)
        updateSelectInput(
            session, "mod",
            choices = mods,
            selected = mods[1]
        )

        dates <- pred_df %>% count(train_date) %>% pull(train_date)
        updateSelectInput(session,
                        "train_date",
                        choices = dates,
                        selected = max(dates))
    })

    preds_selected <- reactive({
        req(input$mod)
        req(input$train_date)
        showNotification(glue::glue("Collecting data for {input$mod} on {input$train_date}."))
        dat <- pred_df %>%
            dplyr::filter(model == !!input$mod, train_date == !!input$train_date) %>%
            collect()

        if (nrow(dat) == 0) {
            showNotification("No results on that day.")
        }
        dat
    })

    output$mod_summ <- renderText({
        req(preds_selected())

        dat <- pins::pin_get("alex.gold/bike_err", board = "rsconnect") %>%
            filter(mod == input$mod, train_date == input$train_date) %>%
            select(-train_date, -mod)


        stats <- glue::glue("{names(dat)}: \n\t {dat}") %>%
                paste(collapse = "\n\t")

        glue::glue(
            "Performance Metrics for {input$mod}: {stats}")
    })

    output$qq <- renderPlot(
        preds_selected() %>%
            select(n_bikes, preds) %>%
            gather(key = "which", value = "value", n_bikes, preds) %>%
            mutate(which = ifelse(which == "n_bikes", "Actual", "Prediction")) %>%

            ggplot(aes(sample = value, color = which)) +
            geom_qq() +
            ggtitle("QQ-Norm Plot (Overlap means model congruent with actual)") +
            theme_bw() +
            labs(color = "Series")
    )

    output$distrib <- renderPlot(
        preds_selected() %>%
            select(n_bikes, preds) %>%
            tidyr::gather("var", "val", n_bikes, preds) %>%

            mutate(var = ifelse(var == "n_bikes", "Actual", "Prediction")) %>%
            ggplot(aes(x = val, color = var)) +
            geom_density() +
            ggtitle("Distributions of Number of Bikes") +
            labs(color = "Series")
    )

    output$resids <- renderPlot(
        preds_selected() %>%
            ggplot(aes(x = resid)) +
            geom_density() +
            ggtitle("Residual Density Plot") +
            theme_bw() +
            geom_vline(xintercept = 0)
    )
}

# Run the application
shinyApp(ui = ui, server = server)

