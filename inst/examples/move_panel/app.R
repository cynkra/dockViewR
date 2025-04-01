library(shiny)

ui <- fluidPage(
  actionButton("move", "Move Panel 1"),
  dock_viewOutput("dock")
)

server <- function(input, output, session) {
  output$dock <- renderDock_view({
    dock_view(
      panels = list(
        panel(
          id = "1",
          title = "Panel 1",
          group = 1,
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
          group = 1,
          title = "Panel 2",
          content = tagList(
            selectInput(
              "variable",
              "Variable:",
              c("Cylinders" = "cyl", "Transmission" = "am", "Gears" = "gear")
            ),
            tableOutput("data")
          ),
          position = list(
            referencePanel = "1",
            direction = "within"
          )
        ),
        panel(
          id = "3",
          group = 2,
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
      "dock",
      id = "1",
      group = 2,
      position = list(
       #referencePanel = "2",
       direction = "bottom"
      ),
      index = 2
    )
  })
}

shinyApp(ui, server)
