library(shiny)
library(dockViewR)

ui <- fluidPage(
  actionButton("add", "Add panel"),
  actionButton("move", "Move panel"),
  actionButton("save", "Save layout"),
  actionButton("restore", "Restore layout"),
  verbatimTextOutput("source"),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")
  saved_layout <- reactiveVal(NULL)

  exportTestValues(
    panel_ids = get_panels_ids(dock_proxy)
  )

  output$source <- renderText({
    req(input[["dock_state-source"]])
    sprintf("last _state change: %s", input[["dock_state-source"]])
  })

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(id = "a", title = "A", content = "Panel A"),
        panel(
          id = "b",
          title = "B",
          content = "Panel B",
          position = list(referencePanel = "a", direction = "right")
        )
      )
    )
  })

  observeEvent(input$add, {
    add_panel(
      dock_proxy,
      panel(
        id = "c",
        title = "C",
        content = "Panel C",
        position = list(referencePanel = "a", direction = "within")
      )
    )
  })

  observeEvent(input$move, {
    move_panel(dock_proxy, id = "b", group = "a", position = "center")
  })

  observeEvent(input$save, {
    saved_layout(input[["dock_state"]])
  })

  observeEvent(input$restore, {
    req(saved_layout())
    restore_dock(dock_proxy, saved_layout())
  })
}

shinyApp(ui, server)
