library(shiny)
library(bslib)

ui <- page_fillable(
  dock_viewOutput("dock")
)

server <- function(input, output, session) {
  output$dock <- renderDock_view({
    dock_view("plop")
  })
}

shinyApp(ui, server)
