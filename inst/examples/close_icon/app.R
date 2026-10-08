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
  layout_columns(
    dockViewOutput("dock"),
    dockViewOutput("plain")
  )
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")
  plain_proxy <- dock_view_proxy("plain")
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

  observeEvent(input[["plain_panel-to-remove"]], {
    remove_panel(plain_proxy, input[["plain_panel-to-remove"]])
  })

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "own",
          title = "Own icon",
          content = "This dock names a close icon, so its tabs draw it.",
          remove = new_remove_tab_plugin(enable = TRUE, mode = "manual")
        )
      ),
      close_icon = thin_x,
      theme = "light-spaced"
    )
  })

  output$plain <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "default",
          title = "Default icon",
          content = "This dock names no close icon, so its tabs keep the xmark.",
          remove = new_remove_tab_plugin(enable = TRUE, mode = "manual")
        )
      ),
      theme = "light-spaced"
    )
  })
}

shinyApp(ui, server)
