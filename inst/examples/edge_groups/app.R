library(shiny)
library(dockViewR)

options("dockViewR.mode" = "dev")

ui <- fluidPage(
  fluidRow(
    actionButton("add", "Add right edge group"),
    actionButton("rm", "Remove right edge group"),
    actionButton("hide_left", "Hide left edge group"),
    actionButton("show_left", "Show left edge group"),
    actionButton("save", "Save layout"),
    actionButton("restore", "Restore saved layout")
  ),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")
  saved <- reactiveVal(NULL)

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
          # No `direction`: naming a group is the whole instruction.
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

  observeEvent(input$save, {
    save_dock(dock_proxy)
    saved(input$dock_state)
  })

  observeEvent(input$restore, {
    req(saved())
    restore_dock(dock_proxy, saved())
  })

  exportTestValues(
    groups_ids = get_groups_ids(dock_proxy),
    groups_panels = get_groups_panels(dock_proxy),
    panels_ids = get_panels_ids(dock_proxy),
    active_group = get_active_group(dock_proxy),
    active_panel = get_active_panel(dock_proxy),
    active_views = get_active_views(dock_proxy),
    edge_positions = names(get_edge_groups(dock_proxy)),
    left_visible = is_edge_group_visible(dock_proxy, "left"),
    right_visible = is_edge_group_visible(dock_proxy, "right")
  )
}

shinyApp(ui, server)
