library(shiny)
library(bslib)

ui <- page_fillable(
  dock_viewOutput("dock")
)

server <- function(input, output, session) {
  output$dock <- renderDock_view({
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
          content = tagList(div("hello world")),
          position = list(
            referencePanel = "1",
            direction = "right"
          )
        )
      ),
      theme = "replit"
    )
  })

  output$distPlot <- renderPlot({
    req(input$obs)
    hist(rnorm(input$obs))
  })
}

shinyApp(ui, server)
