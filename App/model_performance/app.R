library(shiny)
library(tidyverse)

con <- DBI::dbConnect(odbc::odbc(), "Content DB")
pred_df <- tbl(con, "bike_pred_data")
err_dat <- pins::pin_get("alex.gold/bike_err", board = "rsconnect")
pins::board_register_rsconnect(server = "https://colorado.rstudio.com/rsc",
                               key = Sys.getenv("RSTUDIOCONNECT_API_KEY"))

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Model Performance Metrics"),

    # Sidebar with a slider input for number of bins
    sidebarLayout(
        sidebarPanel(
            selectInput("mod", "Which model?", choices = "")
        ),

        # Show a plot of the generated distribution
        mainPanel(
            plotOutput("quality_over_time"),
            HTML("Per Day Details"),
            selectInput("train_date", "Model Training Date", choices = ""),
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
                          selected = max(dates)
        )
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

    output$quality_over_time <- renderPlot({
        req(input$mod)

        plot_df <- err_dat %>%
            tidyr::gather(key = "measure", value = "value", -mod, -train_date) %>%
            dplyr::filter(mod == input$mod) %>%
            dplyr::mutate(measure = toupper(measure))
        last_point <- filter(plot_df, train_date == max(train_date))

        ggplot(mapping = aes(x = train_date, y = value, group = 1)) +
            geom_line(data = plot_df) +
            theme_bw() +
            xlab("Model Training Date") +
            ylab("Value") +
            ggtitle(glue::glue("Performance over time for {input$mod} model")) +
            ggrepel::geom_label_repel(aes(label = round(value, 3)), data = last_point) +
            geom_point(data = last_point, color = "red") +
            facet_wrap("measure", scales = "free_y")
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
            labs(color = "Series") +
            theme_bw()
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

