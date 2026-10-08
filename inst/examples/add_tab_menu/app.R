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
          "(config, event, button) => {
            Shiny.setInputValue(
              `${config.dockId}_add-tab`,
              {
                group: config.group.id,
                box: button.getBoundingClientRect().toJSON(),
                window: { width: innerWidth, height: innerHeight }
              },
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

    # The menu hangs below the button from its left edge, and flips above it or
    # onto its right edge in the lower or right half of the window, so that it
    # stays inside the window.
    flip_x <- at$box$left > at$window$width / 2
    flip_y <- at$box$top > at$window$height / 2

    removeUI("#add-tab-menu")
    insertUI(
      "body",
      ui = div(
        id = "add-tab-menu",
        class = "card p-2 shadow",
        style = css(
          position = "fixed",
          z_index = 1000,
          left = validateCssUnit(if (flip_x) at$box$right else at$box$left),
          top = validateCssUnit(if (flip_y) at$box$top else at$box$bottom),
          transform = sprintf(
            "translate(%s, %s)",
            if (flip_x) "-100%" else "0",
            if (flip_y) "-100%" else "0"
          )
        ),
        actionLink("add", "Add a panel"),
        actionLink("cancel", "Cancel")
      )
    )
  })

  observe({
    req(target())
    if (!target() %in% get_groups_ids(dock_proxy)) {
      removeUI("#add-tab-menu")
    }
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
