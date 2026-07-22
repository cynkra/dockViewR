library(shiny)
library(dockViewR)

ui <- fluidPage(
  tags$head(
    tags$script(HTML(
      "document.addEventListener('dockview:active-panel', function(e) {
        Shiny.setInputValue('event_panel', e.detail.id, {priority: 'event'});
      });"
    ))
  ),
  actionButton("select_b", "Select B"),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(id = "a", title = "A", content = "Panel A"),
        panel(
          id = "b",
          title = "B",
          content = "Panel B",
          active = FALSE,
          position = list(referencePanel = "a", direction = "within")
        )
      )
    )
  })

  observeEvent(input$select_b, {
    select_panel(dock_proxy, "b")
  })
}

shinyApp(ui, server)
