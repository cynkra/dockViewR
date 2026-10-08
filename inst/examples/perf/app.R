# dockViewR performance app: 100 panels (3 of them hosting a nested dock of 4
# panels), laid out over 24 groups in a deep split tree, with plots, tables and
# htmlwidgets. See report.md for the findings and bench.R to reproduce them.
#
# Knobs (environment variables, read at startup):
#   DOCKVIEWR_PERF_N         total panels, nested included (default 100)
#   DOCKVIEWR_PERF_CONTENT   "mixed" (default) or "static"
#   DOCKVIEWR_PERF_RENDERER  "onlyWhenVisible" (default) or "always"
#   DOCKVIEWR_PERF_NESTED    panels hosting a nested dock (default 3)

library(shiny)
library(bslib)
library(dockViewR)

source("helpers.R", local = TRUE)

cfg <- perf_config()
specs <- perf_specs(cfg)

ui <- page_fillable(
  padding = 0,
  gap = 0,
  tags$head(tags$script(src = "probe.js")),
  div(
    class = "d-flex align-items-center gap-2 px-2 py-1 border-bottom",
    style = "flex: 0 0 auto;",
    tags$strong("dockViewR perf"),
    textOutput("hud", inline = TRUE),
    div(
      class = "ms-auto d-flex gap-1",
      actionButton("add", "Add 10", class = "btn-sm"),
      actionButton("remove", "Remove 10", class = "btn-sm"),
      actionButton("save", "Save", class = "btn-sm"),
      actionButton("restore", "Restore", class = "btn-sm"),
      actionButton("rerender", "Re-render", class = "btn-sm")
    )
  ),
  dockViewOutput("dock", height = "100%")
)

server <- function(input, output, session) {
  proxy <- dock_view_proxy("dock")
  build <- reactiveValues(ms = NA, kb = NA)

  output$dock <- renderDockView({
    input$rerender
    t <- proc.time()[["elapsed"]]
    dock <- perf_dock(specs, cfg)
    build$ms <- round(1000 * (proc.time()[["elapsed"]] - t))
    # The serialiser htmlwidgets uses for the payload it sends.
    build$kb <- round(nchar(htmlwidgets:::toJSON(dock$x)) / 1024)
    dock
  })

  output$hud <- renderText({
    sprintf(
      "%d panels, content = %s, renderer = %s | dock_view() built in %s ms, x = %s KB",
      cfg$n,
      cfg$content,
      cfg$renderer,
      build$ms,
      build$kb
    )
  })

  register_outputs(specs, input, output, cfg)

  extra <- reactiveVal(character())

  observeEvent(input$add, {
    ids <- paste0("extra", length(extra()) + seq_len(10))
    for (id in ids) {
      add_panel(
        proxy,
        panel(
          id = id,
          title = id,
          content = static_content(id),
          style = panel_style,
          position = list(referencePanel = "p1", direction = "within")
        )
      )
    }
    extra(c(extra(), ids))
  })

  observeEvent(input$remove, {
    ids <- utils::tail(extra(), 10)
    req(length(ids))
    for (id in ids) {
      remove_panel(proxy, id)
    }
    extra(setdiff(extra(), ids))
  })

  saved <- reactiveVal()

  observeEvent(input$save, saved(input$dock_state))

  observeEvent(input$restore, {
    req(saved())
    restore_dock(proxy, saved())
  })
}

shinyApp(ui, server)
