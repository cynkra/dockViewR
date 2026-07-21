library(shiny)
library(dockViewR)

ui <- fluidPage(
  actionButton("add", "Add panel"),
  actionButton("move", "Move panel"),
  actionButton("save", "Save layout"),
  actionButton("restore", "Restore layout"),
  actionButton("restorebad", "Restore corrupt layout"),
  actionButton("addfresh", "Add unplaced panel"),
  actionButton("settitle", "Set title"),
  actionButton("rerender", "Re-render"),
  verbatimTextOutput("state"),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")
  saved_layout <- reactiveVal(NULL)
  rerender_count <- reactiveVal(0)

  exportTestValues(
    panel_ids = get_panels_ids(dock_proxy)
  )

  output$state <- renderText({
    state <- req(input[["dock_state"]])
    sprintf(
      "panels: %s | grid width: %s",
      paste(names(state$panels), collapse = ", "),
      state$grid$width
    )
  })

  output$dock <- renderDockView({
    rerender_count()
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
    move_panel(
      dock_proxy,
      id = "b",
      position = list(referencePanel = "a", direction = "within")
    )
  })

  observeEvent(input$save, {
    saved_layout(input[["dock_state"]])
  })

  observeEvent(input$restore, {
    req(saved_layout())
    restore_dock(dock_proxy, saved_layout())
  })

  observeEvent(input$restorebad, {
    restore_dock(dock_proxy, list())
  })

  observeEvent(input$addfresh, {
    add_panel(dock_proxy, panel(id = "z", title = "Z", content = "Panel Z"))
  })

  observeEvent(input$settitle, {
    set_panel_title(dock_proxy, id = "a", title = "Renamed")
  })

  observeEvent(input$rerender, {
    rerender_count(rerender_count() + 1)
  })
}

shinyApp(ui, server)
