# Builders for the dockViewR performance app. Kept apart from app.R so bench.R
# can build the exact same dock offline to measure the R side.

perf_config <- function() {
  list(
    # Total number of panels, nested ones included.
    n = as.integer(Sys.getenv("DOCKVIEWR_PERF_N", "100")),
    # "mixed": plots, tables and htmlwidgets. "static": plain HTML only, to
    # isolate the cost of dockview itself.
    content = Sys.getenv("DOCKVIEWR_PERF_CONTENT", "mixed"),
    # dockview's `defaultRenderer`: "onlyWhenVisible" (dockview default) or
    # "always".
    renderer = Sys.getenv("DOCKVIEWR_PERF_RENDERER", "onlyWhenVisible"),
    # Number of panels hosting a nested dock_view() of 4 panels each.
    nested = as.integer(Sys.getenv("DOCKVIEWR_PERF_NESTED", "3"))
  )
}

panel_kinds <- c(
  "plot",
  "ggplot",
  "plotly",
  "dt",
  "reactable",
  "leaflet",
  "echarts",
  "visnetwork",
  "dygraph",
  "table",
  "inputs",
  "static"
)

# Group placement: group k is created relative to the anchor panel of group
# `ref`. Mixing directions against earlier groups yields a split tree several
# levels deep rather than a flat row/column grid.
group_specs <- list(
  NULL,
  list(ref = 1, direction = "right"),
  list(ref = 2, direction = "right"),
  list(ref = 3, direction = "right"),
  list(ref = 1, direction = "below"),
  list(ref = 2, direction = "below"),
  list(ref = 3, direction = "below"),
  list(ref = 4, direction = "below"),
  list(ref = 5, direction = "right"),
  list(ref = 6, direction = "below"),
  list(ref = 7, direction = "right"),
  list(ref = 8, direction = "below"),
  list(ref = 9, direction = "below"),
  list(ref = 10, direction = "right"),
  list(ref = 11, direction = "below"),
  list(ref = 12, direction = "left"),
  list(ref = 13, direction = "right"),
  list(ref = 14, direction = "below"),
  list(ref = 15, direction = "right"),
  list(ref = 16, direction = "below"),
  list(ref = 17, direction = "below"),
  list(ref = 18, direction = "right"),
  list(ref = 19, direction = "below"),
  list(ref = 20, direction = "right")
)

static_content <- function(id) {
  tagList(
    tags$h5(sprintf("Static panel %s", id)),
    tags$p(
      "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do",
      "eiusmod tempor incididunt ut labore et dolore magna aliqua."
    ),
    tags$ul(lapply(1:5, function(i) tags$li(sprintf("Item %s.%s", id, i))))
  )
}

# One spec per panel: list(id, kind, ui, server, children). `server` is a
# function(output, input) registering the panel's outputs, `children` holds the
# specs of a nested dock.
panel_spec <- function(id, kind) {
  out <- paste0("out_", id)
  fill <- "100%"

  switch(
    kind,
    plot = list(
      ui = plotOutput(out, height = fill),
      server = function(input, output) {
        output[[out]] <- renderPlot({
          par(mar = c(2, 2, 0.5, 0.5))
          hist(rnorm(500), main = NULL)
        })
      }
    ),
    ggplot = list(
      ui = plotOutput(out, height = fill),
      server = function(input, output) {
        output[[out]] <- renderPlot(
          ggplot2::ggplot(
            mtcars,
            ggplot2::aes(wt, mpg, colour = factor(cyl))
          ) +
            ggplot2::geom_point()
        )
      }
    ),
    plotly = list(
      ui = plotly::plotlyOutput(out, height = fill),
      server = function(input, output) {
        output[[out]] <- plotly::renderPlotly(
          plotly::plot_ly(
            data.frame(x = 1:200, y = cumsum(rnorm(200))),
            x = ~x,
            y = ~y,
            type = "scatter",
            mode = "lines"
          )
        )
      }
    ),
    dt = list(
      ui = DT::DTOutput(out),
      server = function(input, output) {
        output[[out]] <- DT::renderDT(
          DT::datatable(iris, options = list(pageLength = 5, dom = "tp"))
        )
      }
    ),
    reactable = list(
      ui = reactable::reactableOutput(out),
      server = function(input, output) {
        output[[out]] <- reactable::renderReactable(
          reactable::reactable(mtcars, defaultPageSize = 5, compact = TRUE)
        )
      }
    ),
    leaflet = list(
      ui = leaflet::leafletOutput(out, height = fill),
      server = function(input, output) {
        # No tile layer: keeps the bench off the network.
        output[[out]] <- leaflet::renderLeaflet(
          leaflet::addCircleMarkers(
            leaflet::leaflet(),
            lng = runif(50, -10, 10),
            lat = runif(50, 40, 50),
            radius = 4
          )
        )
      }
    ),
    echarts = list(
      ui = echarts4r::echarts4rOutput(out, height = fill),
      server = function(input, output) {
        output[[out]] <- echarts4r::renderEcharts4r(
          echarts4r::e_bar(
            echarts4r::e_charts(
              data.frame(x = LETTERS[1:10], y = runif(10)),
              x
            ),
            y
          )
        )
      }
    ),
    visnetwork = list(
      ui = visNetwork::visNetworkOutput(out, height = fill),
      server = function(input, output) {
        output[[out]] <- visNetwork::renderVisNetwork(
          visNetwork::visNetwork(
            data.frame(id = 1:20),
            data.frame(from = sample(1:20, 30, TRUE), to = sample(1:20, 30, TRUE))
          )
        )
      }
    ),
    dygraph = list(
      ui = dygraphs::dygraphOutput(out, height = fill),
      server = function(input, output) {
        output[[out]] <- dygraphs::renderDygraph(
          dygraphs::dygraph(ts(cumsum(rnorm(200))))
        )
      }
    ),
    table = list(
      ui = tableOutput(out),
      server = function(input, output) {
        output[[out]] <- renderTable(head(mtcars, 8), rownames = TRUE)
      }
    ),
    inputs = list(
      ui = tagList(
        sliderInput(paste0(out, "_n"), "n", 1, 100, 50),
        selectInput(paste0(out, "_var"), "Variable", names(mtcars)),
        uiOutput(out)
      ),
      server = function(input, output) {
        output[[out]] <- renderUI(
          tags$code(
            sprintf(
              "n = %s, var = %s",
              input[[paste0(out, "_n")]],
              input[[paste0(out, "_var")]]
            )
          )
        )
      }
    ),
    static = list(
      ui = static_content(id),
      server = NULL
    ),
    nested = list(
      ui = dockViewOutput(out, height = fill),
      server = NULL
    )
  )
}

# Specs for the whole dock. Panel ids are "p<k>" at the top level and
# "p<k>_<j>" inside the nested dock hosted by panel "p<k>".
perf_specs <- function(cfg = perf_config()) {
  n_top <- cfg$n - 4L * cfg$nested
  stopifnot(n_top >= cfg$nested, n_top >= 1L)

  nested_at <- if (cfg$nested > 0) {
    round(seq(5, n_top - 5, length.out = cfg$nested))
  } else {
    integer()
  }

  kind_of <- function(i) {
    if (identical(cfg$content, "static")) {
      return("static")
    }
    panel_kinds[(i - 1L) %% length(panel_kinds) + 1L]
  }

  lapply(seq_len(n_top), function(i) {
    id <- paste0("p", i)
    if (i %in% nested_at) {
      spec <- c(list(id = id, kind = "nested"), panel_spec(id, "nested"))
      spec$children <- lapply(1:4, function(j) {
        cid <- paste0(id, "_", j)
        kind <- kind_of(i + j)
        c(list(id = cid, kind = kind), panel_spec(cid, kind))
      })
      spec
    } else {
      kind <- kind_of(i)
      c(list(id = id, kind = kind), panel_spec(id, kind))
    }
  })
}

panel_style <- list(
  padding = "4px",
  overflow = "auto",
  height = "100%",
  `box-sizing` = "border-box"
)

# Lay `specs` out across up to 24 groups: the first panel of each group splits
# off an earlier group, the rest are added as tabs.
perf_panels <- function(specs) {
  n_groups <- min(length(group_specs), length(specs))
  anchors <- vapply(specs[seq_len(n_groups)], `[[`, character(1), "id")

  lapply(seq_along(specs), function(i) {
    spec <- specs[[i]]
    g <- (i - 1L) %% n_groups + 1L

    position <- if (i == 1L) {
      NULL
    } else if (i <= n_groups) {
      list(
        referencePanel = anchors[[group_specs[[g]]$ref]],
        direction = group_specs[[g]]$direction
      )
    } else {
      list(referencePanel = anchors[[g]], direction = "within")
    }

    args <- list(
      id = spec$id,
      title = sprintf("%s (%s)", spec$id, spec$kind),
      content = spec$ui,
      style = panel_style,
      # Last tab of each group stays active.
      active = i > length(specs) - n_groups
    )
    if (!is.null(position)) {
      args$position <- position
    }
    do.call(panel, args)
  })
}

# A nested dock: 4 panels, two side by side and two tabbed below.
nested_panels <- function(children) {
  ids <- vapply(children, `[[`, character(1), "id")
  positions <- list(
    NULL,
    list(referencePanel = ids[1], direction = "right"),
    list(referencePanel = ids[1], direction = "below"),
    list(referencePanel = ids[3], direction = "within")
  )
  Map(
    function(spec, position) {
      args <- list(
        id = spec$id,
        title = sprintf("%s (%s)", spec$id, spec$kind),
        content = spec$ui,
        style = panel_style
      )
      if (!is.null(position)) {
        args$position <- position
      }
      do.call(panel, args)
    },
    children,
    positions
  )
}

perf_dock <- function(specs, cfg = perf_config()) {
  dock_view(
    panels = perf_panels(specs),
    theme = "light-spaced",
    defaultRenderer = cfg$renderer
  )
}

# Register every output, nested docks included.
register_outputs <- function(specs, input, output, cfg = perf_config()) {
  for (spec in specs) {
    if (identical(spec$kind, "nested")) {
      local({
        children <- spec$children
        output[[paste0("out_", spec$id)]] <- renderDockView(
          dock_view(
            panels = nested_panels(children),
            theme = "light-spaced",
            defaultRenderer = cfg$renderer
          )
        )
      })
      register_outputs(spec$children, input, output, cfg)
    } else if (!is.null(spec$server)) {
      spec$server(input, output)
    }
  }
}
