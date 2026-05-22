library(shiny)
library(dockViewR)

options("dockViewR.mode" = "dev")

ui <- fluidPage(
  fluidRow(
    actionButton("add", "Add right edge group"),
    actionButton("rm", "Remove right edge group"),
    actionButton("hide_left", "Hide left edge group"),
    actionButton("show_left", "Show left edge group")
  ),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "main",
          title = "Main",
          content = "Main panel"
        ),
        panel(
          id = "tree",
          title = "Tree",
          content = "Lives inside the left edge group",
          position = list(referenceGroup = "left-edge")
        )
      ),
      edge_groups = list(
        edge_group(
          id = "left-edge",
          position = "left",
          initial_size = 220,
          minimum_size = 150
        )
      ),
      theme = "light-spaced"
    )
  })

  observeEvent(input$add, {
    add_edge_group(
      dock_proxy,
      edge_group(
        id = "right-edge",
        position = "right",
        initial_size = 220
      )
    )
  })

  observeEvent(input$rm, {
    remove_edge_group(dock_proxy, position = "right")
  })

  observeEvent(input$hide_left, {
    set_edge_group_visible(dock_proxy, position = "left", visible = FALSE)
  })

  observeEvent(input$show_left, {
    set_edge_group_visible(dock_proxy, position = "left", visible = TRUE)
  })
}

shinyApp(ui, server)
