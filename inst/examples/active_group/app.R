library(dockViewR)
library(shiny)
library(bslib)

ui <- page_fluid(
  dock_view_output("dock"),
  verbatimTextOutput("debug")
)

server <- function(input, output, session) {
  proxy <- dock_view_proxy("dock")

  exportTestValues(
    panel_ids = get_panels_ids(proxy),
    active_group = get_active_group(proxy),
    groups_panels = get_groups_panels(proxy)
  )

  output$dock <- render_dock_view({
    dock_view(
      panels = list(
        panel(
          id = 1,
          "Panel 1",
          tagList(
            "This is the content of Panel 1.",
            actionButton("add_panel", "Add panel")
          )
        ),
        panel(
          id = 2,
          "Panel 2",
          "This is the content of Panel 2.",
          position = list(referencePanel = 1, direction = "right")
        )
      )
    )
  })

  output$debug <- renderPrint({
    list(
      active_group = input[["dock_active-group"]]
    )
  })

  observe({
    active_group <- input[["dock_active-group"]]
    groups <- get_groups_ids(proxy)
    others <- setdiff(groups, active_group)
    target <- if (length(others) == 0) active_group else others[[length(others)]]
    next_id <- length(get_panels_ids(proxy)) + 1

    add_panel(
      proxy,
      panel(
        id = next_id,
        title = sprintf("Panel %s", next_id),
        "This is a newly added panel.",
        position = list(referenceGroup = target, direction = "within")
      )
    )
  }) |> bindEvent(input$add_panel)
}

shinyApp(ui, server)
