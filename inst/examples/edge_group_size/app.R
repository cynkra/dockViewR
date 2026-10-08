library(shiny)
library(dockViewR)

options("dockViewR.mode" = "dev")

ui <- fluidPage(
  actionButton("left_wide", "Left rail to 40% of the dock's width"),
  actionButton("left_narrow", "Left rail to 20% of the dock's width"),
  actionButton("bottom_tall", "Bottom rail to 50% of the dock's height"),
  actionButton("bottom_short", "Bottom rail to 25% of the dock's height"),
  actionButton("collapse_left", "Collapse left rail"),
  actionButton("expand_left", "Expand left rail"),
  actionButton("collapse_bottom", "Collapse bottom rail"),
  actionButton("expand_bottom", "Expand bottom rail"),
  helpText(
    "A collapsed rail keeps its strip: resizing it sets the size it opens at",
    "when expanded, here or by clicking its tab."
  ),
  dockViewOutput("dock", height = "600px")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  exportTestValues(
    left_size = get_edge_groups(dock_proxy)[["left"]][["size"]],
    bottom_size = get_edge_groups(dock_proxy)[["bottom"]][["size"]],
    left_collapsed = is_edge_group_collapsed(dock_proxy, "left")
  )

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(id = "main", title = "Main", content = "Main panel"),
        panel(
          id = "other",
          title = "Other",
          content = "Takes what the rails give up",
          position = list(referencePanel = "main", direction = "right")
        ),
        panel(
          id = "tree",
          title = "Tree",
          content = "Left rail",
          position = list(referenceGroup = "left-edge")
        ),
        panel(
          id = "console",
          title = "Console",
          content = "Bottom rail",
          position = list(referenceGroup = "bottom-edge")
        )
      ),
      edge_groups = list(
        edge_group(id = "left-edge", position = "left", initial_size = 220),
        edge_group(id = "bottom-edge", position = "bottom", initial_size = 120)
      ),
      theme = "light-spaced"
    )
  })

  observeEvent(input$left_wide, {
    set_edge_group_size(dock_proxy, position = "left", size = 0.4)
  })

  observeEvent(input$left_narrow, {
    set_edge_group_size(dock_proxy, position = "left", size = 0.2)
  })

  observeEvent(input$bottom_tall, {
    set_edge_group_size(dock_proxy, position = "bottom", size = 0.5)
  })

  observeEvent(input$bottom_short, {
    set_edge_group_size(dock_proxy, position = "bottom", size = 0.25)
  })

  observeEvent(input$collapse_left, {
    set_edge_group_collapsed(dock_proxy, position = "left", collapsed = TRUE)
  })

  observeEvent(input$expand_left, {
    set_edge_group_collapsed(dock_proxy, position = "left", collapsed = FALSE)
  })

  observeEvent(input$collapse_bottom, {
    set_edge_group_collapsed(dock_proxy, position = "bottom", collapsed = TRUE)
  })

  observeEvent(input$expand_bottom, {
    set_edge_group_collapsed(dock_proxy, position = "bottom", collapsed = FALSE)
  })
}

shinyApp(ui, server)
