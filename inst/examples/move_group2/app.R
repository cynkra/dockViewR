library(shiny)
library(dockViewR)

ui <- fluidPage(
  actionButton("move2", "Move Group that contains Panel 1"),
  dock_viewOutput("dock2"),
)

server <- function(input, output, session) {
  output$dock2 <- renderDock_view({
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
        ),
        panel(
          id = "4",
          title = "Panel 4",
          content = h1("Panel 4"),
          position = list(
            referencePanel = "3",
            direction = "within"
          )
        )
      ),
      theme = "light-spaced"
    )
  })

  observeEvent(input$move2, {
    move_group2(
      "dock2",
      source = "1",
      destination = "3",
      position = "right"
    )
  })
}

shinyApp(ui, server)
