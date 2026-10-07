library(shiny)
library(bslib)
library(dockViewR)

ui <- page_fillable(
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")
  target <- reactiveVal()

  exportTestValues(groups_panels = get_groups_panels(dock_proxy))

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(id = "1", title = "Panel 1", content = "Panel 1"),
        panel(
          id = "2",
          title = "Panel 2",
          content = "Panel 2",
          position = list(referencePanel = "1", direction = "right")
        )
      ),
      add_tab = new_add_tab_plugin(
        enable = TRUE,
        callback = htmlwidgets::JS(
          "(config, event) => {
            const box = event.currentTarget.getBoundingClientRect();
            Shiny.setInputValue(
              `${config.dockId}_add-tab`,
              { group: config.group.id, left: box.left, bottom: box.bottom },
              { priority: 'event' }
            );
          }"
        )
      )
    )
  })

  observeEvent(input[["dock_add-tab"]], {
    at <- input[["dock_add-tab"]]
    target(at$group)

    removeUI("#add-tab-menu")
    insertUI(
      "body",
      ui = div(
        id = "add-tab-menu",
        class = "card p-2 shadow",
        style = sprintf(
          "position: fixed; left: %spx; top: %spx; z-index: 1000;",
          at$left,
          at$bottom
        ),
        actionLink("add", "Add a panel"),
        actionLink("cancel", "Cancel")
      )
    )
  })

  observeEvent(input$add, {
    id <- as.character(length(get_panels_ids(dock_proxy)) + 1L)
    add_panel(
      dock_proxy,
      panel(
        id = id,
        title = paste("Panel", id),
        content = paste("Panel", id),
        position = list(referenceGroup = target(), direction = "within")
      )
    )
    removeUI("#add-tab-menu")
  })

  observeEvent(input$cancel, removeUI("#add-tab-menu"))
}

shinyApp(ui, server)
