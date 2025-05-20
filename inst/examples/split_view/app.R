library(shiny)
library(bslib)
library(visNetwork)
library(dockViewR)

nodes <- data.frame(id = 1:3)
edges <- data.frame(from = c(1, 2), to = c(1, 3))

ui <- page_fillable(
  splitViewOutput("split")
)

server <- function(input, output, session) {
  exportTestValues(
    panel_ids = get_panels_ids("split"),
    active_group = get_active_group("split"),
    grid = get_grid("split")
  )
  output$split <- renderSplitView({
    split_view(
      panels = list(
        panel(
          id = "1",
          title = "Panel 1",
          content = tagList(
            sliderInput(
              "obs",
              "Number of observations:",
              min = 0,
              max = 1000,
              value = 500
            ),
            plotOutput("distPlot")
          )
        ),
        panel(
          id = "2",
          title = "Panel 2",
          content = tagList(
            visNetworkOutput("network")
          ),
          minimumWidth = 500
        ),
        panel(
          id = "3",
          title = "Panel 3",
          content = tagList(
            selectInput(
              "variable",
              "Variable:",
              c("Cylinders" = "cyl", "Transmission" = "am", "Gears" = "gear")
            ),
            tableOutput("data")
          ),
          minimumHeight = 400
        )
      ),
      theme = "light",
      orientation = "vertical"
    )
  })

  output$distPlot <- renderPlot({
    req(input$obs)
    hist(rnorm(input$obs))
  })

  output$network <- renderVisNetwork({
    visNetwork(nodes, edges, width = "100%")
  })

  output$data <- renderTable(
    {
      mtcars[, c("mpg", input$variable), drop = FALSE]
    },
    rownames = TRUE
  )
}

shinyApp(ui, server)
