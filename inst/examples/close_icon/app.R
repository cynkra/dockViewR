library(shiny)
library(bslib)
library(dockViewR)

thin_x <- HTML(
  '<svg class="thin-x" viewBox="0 0 10 10" width="10" height="10" fill="none"
    stroke="currentColor" stroke-linecap="round" aria-hidden="true">
    <path d="M2.5 2.5l5 5M7.5 2.5l-5 5"/>
  </svg>'
)

ui <- page_fillable(
  div(
    class = "d-flex gap-2",
    actionButton("save", "Save layout"),
    actionButton("restore", "Restore saved layout")
  ),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")
  saved <- reactiveVal()

  observeEvent(input$save, {
    saved(get_dock(dock_proxy))
  })

  observeEvent(input$restore, {
    req(saved())
    restore_dock(dock_proxy, saved())
  })

  observeEvent(input[["dock_panel-to-remove"]], {
    remove_panel(dock_proxy, input[["dock_panel-to-remove"]])
  })

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "own",
          title = "Own icon",
          content = "This tab's close button draws the icon its plugin names.",
          remove = new_remove_tab_plugin(
            enable = TRUE,
            mode = "manual",
            icon = thin_x
          )
        ),
        panel(
          id = "default",
          title = "Default icon",
          content = "This tab's plugin names no icon, so it keeps the xmark.",
          remove = new_remove_tab_plugin(enable = TRUE, mode = "manual"),
          position = list(
            referencePanel = "own",
            direction = "right"
          )
        )
      ),
      theme = "light-spaced"
    )
  })
}

shinyApp(ui, server)
