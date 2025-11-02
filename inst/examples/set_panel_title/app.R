library(dockViewR)
library(shiny)
library(bslib)

ui <- page_fillable(
  textInput("panel_title", "Panel title"),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  exportTestValues(
    panel_ids = get_panels_ids(dock_proxy),
    active_group = get_active_group(dock_proxy),
    grid = get_grid(dock_proxy)
  )

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = 1,
          title = "Panel 1",
          content = "Panel 1",
          remove = new_remove_tab_plugin(TRUE)
        ),
        panel(
          id = 2,
          title = "Panel 2",
          content = "Panel 2",
          position = list(
            referencePanel = "1",
            direction = "right"
          ),
          minimumWidth = 500
        ),
        panel(
          id = 3,
          title = "Panel 3",
          content = "Panel 3",
          position = list(
            referencePanel = "2",
            direction = "below"
          )
        )
      ),
      theme = "replit"
    )
  })

  observeEvent(
    input$panel_title,
    {
      set_panel_title(dock_proxy, 1, input$panel_title)
      set_panel_title(dock_proxy, 2, input$panel_title)
    },
    ignoreInit = TRUE
  )
}

shinyApp(ui, server)
