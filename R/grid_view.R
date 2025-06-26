#' Create a grid view widget
#'
#' Creates an interactive grid view widget that enables flexible
#' layout management with resizable panels.
#' This is a wrapper around the dockview.dev
#' JavaScript library, providing a powerful interface for
#' creating IDE-like layouts in Shiny applications or R Markdown documents.
#' grid view is a subset of dock view (with some feature removed like drag and drop).
#'
#' @param orientation Grid orientation. Either `horizontal` or `vertical`.
#' @param hide_borders Whether to hide panel borders. Default to FALSE.
#' @param proportional_layout TBD.
#'
#' @returns An HTML widget object.
#' @inheritParams dock_view
#'
#' @export
grid_view <- function(
  panels,
  ...,
  theme = c(
    "light-spaced",
    "light",
    "abyss",
    "abyss-spaced",
    "dark",
    "vs",
    "dracula",
    "replit"
  ),
  orientation = c("horizontal", "vertical"),
  hide_borders = FALSE,
  proportional_layout = FALSE,
  width = NULL,
  height = NULL,
  elementId = NULL
) {
  theme <- match.arg(theme)
  orientation <- match.arg(orientation)
  deps <- extract_panel_deps(panels)

  # check ids
  ids <- check_panel_ids(panels)
  # check reference panels ids
  check_panel_refs(panels, ids)

  # forward options using x
  x <- list(
    panels = panels,
    theme = theme,
    layout = list(
      width = if (!is.null(width)) validateCssUnit(width) else 800,
      height = if (!is.null(height)) validateCssUnit(height) else 800,
      orientation = orientation,
      proportionaLayout = proportional_layout
    ),
    hideBorders = hide_borders,
    ...
  )

  # create widget
  htmlwidgets::createWidget(
    name = "gridview",
    x,
    dependencies = c(
      unlist(deps, recursive = FALSE),
      # Add fontawesome (avoids to get dependency on {fontawesome})
      htmltools::findDependencies(icon("cogs"))
    ),
    width = width,
    height = height,
    package = "dockViewR",
    elementId = elementId
  )
}

#' Shiny bindings for grid_view
#'
#' Output and render functions for using grid_view within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a grid_view
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name grid_view-shiny
#'
#' @return \code{gridViewOutput} and grid_view_output`
#' return a Shiny output function that can be used in the UI definition.
#' \code{renderGridView} and `render_grid_view` return a
#' Shiny render function that can be used in the server definition to
#' render a `grid_view` element.
#'
#' @export
gridViewOutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(
    #nocov start
    outputId,
    "gridview",
    width,
    height,
    package = "dockViewR"
  )
} #nocov end

#' Alias to \link{gridViewOutput}
#' @export
#' @rdname grid_view-shiny
grid_view_output <- gridViewOutput

#' @rdname grid_view-shiny
#' @export
renderGridView <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    #nocov start
    expr <- substitute(expr)
  } # force quoted
  htmlwidgets::shinyRenderWidget(expr, gridViewOutput, env, quoted = TRUE)
} #nocov end

#' Alias to \link{renderGridView}
#' @export
#' @rdname grid_view-shiny
render_grid_view <- renderGridView
