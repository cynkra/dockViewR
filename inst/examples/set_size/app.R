library(shiny)
library(dockViewR)

options("dockViewR.mode" = "dev")

ui <- fluidPage(
  actionButton("skew", "Panel A to 50% (B and C share the rest, keeping their ratio)"),
  actionButton("resize", "Panel C to 60% (A and B share the rest, keeping their ratio)"),
  dockViewOutput("dock"),
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  exportTestValues(
    grid = get_grid(dock_proxy),
    state_source = session$input[["dock_state-source"]]
  )

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "A",
          title = "Panel A",
          content = "Panel A"
        ),
        panel(
          id = "B",
          title = "Panel B",
          content = "Panel B",
          position = list(
            referencePanel = "A",
            direction = "right"
          )
        ),
        panel(
          id = "C",
          title = "Panel C",
          content = "Panel C",
          position = list(
            referencePanel = "B",
            direction = "right"
          )
        )
      ),
      theme = "light-spaced"
    )
  })

  observeEvent(input$skew, {
    set_size(dock_proxy, id = "A", size = 0.5)
  })

  observeEvent(input$resize, {
    set_size(dock_proxy, id = "C", size = 0.6)
  })
}

shinyApp(ui, server)
