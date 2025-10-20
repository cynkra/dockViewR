library(shiny)
library(bslib)
library(dockViewR)
library(listviewer)

ui <- fluidPage(
  h1("Serialise dock state"),
  div(
    class = "d-flex justify-content-center",
    actionButton("save", "Save layout"),
    actionButton("restore", "Restore saved layout"),
    selectInput("states", "Select a state", NULL)
  ),
  dockViewOutput("dock"),
  reactjsonOutput("dock_state"),
)

server <- function(input, output, session) {
  output$dock_state <- renderReactjson({
    reactjson(jsonlite::toJSON(input$dock_state))
  })

  dock_states <- reactiveVal(NULL)

  dock_proxy <- dock_view_proxy("dock")

  observeEvent(input$save, {
    save_dock(dock_proxy)
    states <- c(dock_states(), list(input$dock_state))
    dock_states(setNames(states, seq_along(states)))
  })

  exportTestValues(
    n_states = length(dock_states()),
    panel_ids = get_panels_ids(dock_proxy),
    group_ids = get_groups_ids(dock_proxy),
    active_group = get_active_group(dock_proxy),
    active_views = get_active_views(dock_proxy),
    active_panel = get_active_panel(dock_proxy),
    grid = get_grid(dock_proxy)
  )

  observeEvent(dock_states(), {
    updateSelectInput(session, "states", choices = names(dock_states()))
  })

  observeEvent(input$restore, {
    if (!length(dock_states())) {
      showNotification("No saved states", type = "error")
      return(NULL)
    }
    restore_dock(dock_proxy, dock_states()[[input$states]])
  })

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "test",
          title = "Panel 1",
          content = tagList(
            sliderInput(
              "obs",
              "Number of observations:",
              min = 0,
              max = 1000,
              value = 500
            ),
            plotOutput("distPlot")
          )
        ),
        panel(
          id = 2,
          title = "Panel 2",
          content = "Panel 2",
          position = list(
            referencePanel = "test",
            direction = "within"
          )
        ),
        panel(
          id = 3,
          title = "Panel 3",
          content = h1("Panel 3"),
          position = list(
            referencePanel = "test",
            direction = "right"
          )
        )
      ),
      theme = "light-spaced"
    )
  })

  output$distPlot <- renderPlot({
    req(input$obs)
    hist(rnorm(input$obs))
  })
}

shinyApp(ui, server)
