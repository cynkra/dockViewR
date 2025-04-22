library(shiny)
library(dockViewR)

ui <- fluidPage(
  actionButton(
    "move",
    "Move Group with group-id 1 to the righ of group with group-id 2"
  ),
  dockViewOutput("dock"),
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
        ),
        panel(
          id = "5",
          title = "Panel 5",
          content = h1("Panel 5"),
          position = list(
            referencePanel = "4",
            direction = "right"
          )
        ),
        panel(
          id = "6",
          title = "Panel 6",
          content = h1("Panel 6"),
          position = list(
            referencePanel = "5",
            direction = "within"
          )
        )
      ),
      theme = "light-spaced"
    )
  })

  observeEvent(input$move, {
    move_group(
      "dock",
      from = "1",
      to = "2",
      position = "right"
    )
  })
}

shinyApp(ui, server)
