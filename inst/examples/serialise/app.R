library(shiny)
library(dockViewR)

ui <- fluidPage(
  h1("Serialise dock state"),
  div(
    class = "d-flex justify-content-center",
    actionButton("save", "Save layout"),
    actionButton("restore", "Restore saved layout"),
    selectInput("states", "Select a state", NULL)
  ),
  dock_viewOutput("dock")
)

server <- function(input, output, session) {
  dock_states <- reactiveVal(NULL)
  observeEvent(input$save, {
    save_dock("dock")
  })

  observeEvent(req(input$dock_state), {
    states <- c(dock_states(), list(input$dock_state))
    dock_states(setNames(states, seq_along(states)))
  })

  observeEvent(dock_states(), {
    updateSelectInput(session, "states", choices = names(dock_states()))
  })

  observeEvent(input$restore, {
    restore_dock("dock", dock_states()[[input$states]])
  })

  output$dock <- renderDock_view({
    dock_view(
      panels = list(
        panel(
          id = "test",
          title = "Panel 1",
          content = "Panel 1"
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
  output$data <- renderTable(
    {
      mtcars[, c("mpg", input$variable), drop = FALSE]
    },
    rownames = TRUE
  )
}

shinyApp(ui, server)
