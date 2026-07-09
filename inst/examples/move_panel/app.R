library(shiny)
library(bslib)
library(dockViewR)

options("dockViewR.mode" = "dev")

ui <- fluidPage(
  h1("Reorder a panel within its group"),
  actionButton("move", "Move Panel 1"),
  dockViewOutput("dock"),
  h1("Move a panel next to another group"),
  actionButton("move2", "Move Panel 1"),
  dockViewOutput("dock2"),
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  exportTestValues(
    panel_ids = get_panels_ids(dock_proxy),
    active_group = get_active_group(dock_proxy),
    grid = grid_shape(dock_proxy)
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
            selectInput(
              "variable",
              "Variable:",
              c("Cylinders" = "cyl", "Transmission" = "am", "Gears" = "gear")
            ),
            tableOutput("data")
          ),
        ),
        panel(
          id = "3",
          title = "Panel 3",
          content = h1("Panel 3")
        )
      ),
      theme = "light-spaced"
    )
  })

  output$dock2 <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "1",
          title = "Panel 1",
          content = "Panel 1"
        ),
        panel(
          id = "2",
          title = "Panel 2",
          content = "Panel 2",
          position = list(
            referencePanel = "1",
            direction = "within"
          )
        ),
        panel(
          id = "3",
          title = "Panel 3",
          content = h1("Panel 3"),
          position = list(
            referencePanel = "1",
            direction = "right"
          )
        )
      ),
      theme = "light-spaced"
    )
  })

  output$distPlot <- renderPlot({
    req(input$obs)
    hist(rnorm(input$obs))
  })
  output$data <- renderTable(
    {
      mtcars[, c("mpg", input$variable), drop = FALSE]
    },
    rownames = TRUE
  )

  observeEvent(input$move, {
    move_panel(
      dock_proxy,
      id = "1",
      position = list(referencePanel = "2", direction = "within", index = 2)
    )
  })

  dock_proxy2 <- dock_view_proxy("dock2")

  observeEvent(input$move2, {
    move_panel(
      dock_proxy2,
      id = "1",
      position = list(referencePanel = "3", direction = "below")
    )
  })
}

shinyApp(ui, server)
