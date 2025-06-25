library(shiny)
library(bslib)
library(visNetwork)
library(dockViewR)
library(thematic)

thematic_shiny()

nodes <- data.frame(id = 1:3)
edges <- data.frame(from = c(1, 2), to = c(1, 3))

ui <- page_fillable(
  input_dark_mode(id = "app_theme"),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  exportTestValues(
    panel_ids = get_panels_ids("dock"),
    active_group = get_active_group("dock"),
    grid = get_grid("dock")
  )

  output$dock <- renderDockView({
    dock_view(
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
          position = list(
            referencePanel = "1",
            direction = "right"
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
          position = list(
            referencePanel = "2",
            direction = "below"
          )
        )
      ),
      theme = "dark"
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

  observeEvent(input$app_theme, {
    # Update the dock theme
    update_dock_view("dock", list(theme = input$app_theme))
  })
}

shinyApp(ui, server)
