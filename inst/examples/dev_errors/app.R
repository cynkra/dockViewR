library(shiny)
library(dockViewR)

# In dev mode a failed proxy call is reported through a Shiny notification
# instead of escaping to the browser console, which is the surface this example
# exists to exercise.
options("dockViewR.mode" = "dev")

ui <- fluidPage(
  fluidRow(
    actionButton("bad_select", "Select a panel that does not exist"),
    actionButton("bad_remove", "Remove a panel that does not exist"),
    actionButton("good_select", "Select a panel that does exist")
  ),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(id = "one", title = "One", content = "Panel one"),
        panel(
          id = "two",
          title = "Two",
          content = "Panel two",
          position = list(referencePanel = "one", direction = "right")
        )
      )
    )
  })

  observeEvent(input$bad_select, {
    select_panel(dock_proxy, "does-not-exist")
  })

  observeEvent(input$bad_remove, {
    remove_panel(dock_proxy, "does-not-exist")
  })

  observeEvent(input$good_select, {
    select_panel(dock_proxy, "two")
  })

  exportTestValues(
    panel_ids = get_panels_ids(dock_proxy),
    active_panel = get_active_panel(dock_proxy)
  )
}

shinyApp(ui, server)
