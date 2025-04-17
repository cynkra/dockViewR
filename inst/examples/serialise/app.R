library(shiny)
library(dockViewR)

ui <- fluidPage(
  h1("Serialise dock state"),
  dock_viewOutput("dock")
)

server <- function(input, output, session) {
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

  observeEvent(req(get_dock("dock")), {
    test_dock <- get_dock("dock")
    usethis::use_data(test_dock, internal = TRUE, overwrite = TRUE)
  })
  #observe(print(get_panels("dock")))
  #observe(print(get_panels_ids("dock")))
  #observe(print(get_active_group("dock")))
  #observe(print(get_groups("dock")))
  #observe(print(get_groups_ids("dock")))
  #observe(print(get_groups_panels("dock")))

  #observeEvent(input$dock_state, {
  #  print(input$dock_state)
  #})
}

shinyApp(ui, server)
