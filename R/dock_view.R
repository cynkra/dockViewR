#' Dock view widget
#'
#' Create a dock view widget
#'
#' @import htmlwidgets
#' @param panels Widget configuration.
#' @param ... Other options.
#' @param theme Theme. One of
#' \code{c("abyss", "dark", "light", "vs", "dracula", "replit")}.
#' @param width Widget width.
#' @param height Widget height.
#' @param elementId When used outside Shiny.
#'
#' @export
dock_view <- function(
  panels,
  ...,
  theme = c(
    "light",
    "abyss",
    "dark",
    "vs",
    "dracula",
    "replit"
  ),
  width = NULL,
  height = NULL,
  elementId = NULL
) {
  theme <- match.arg(theme)

  deps <- dropNulls(lapply(panels, \(panel) {
    if (length(panel$content$dependencies)) {
      panel$content$dependencies
    } else {
      NULL
    }
  }))

  # forward options using x
  x <- list(
    theme = sprintf("dockview-theme-%s", theme),
    panels = panels,
    ...
  )

  # create widget
  htmlwidgets::createWidget(
    name = 'dock_view',
    x,
    dependencies = unlist(deps, recursive = FALSE),
    width = width,
    height = height,
    package = 'dockViewR',
    elementId = elementId
  )
}

panel <- function(id, title, content, active = TRUE, ...) {
  list(
    id = id,
    title = title,
    inactive = !active,
    content = htmltools::renderTags(content),
    ...
  )
}

#' Shiny bindings for dock_view
#'
#' Output and render functions for using dock_view within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a dock_view
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name dock_view-shiny
#'
#' @export
dock_viewOutput <- function(outputId, width = '100%', height = '400px') {
  htmlwidgets::shinyWidgetOutput(
    outputId,
    'dock_view',
    width,
    height,
    package = 'dockViewR'
  )
}

#' @rdname dock_view-shiny
#' @export
renderDock_view <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  } # force quoted
  htmlwidgets::shinyRenderWidget(expr, dock_viewOutput, env, quoted = TRUE)
}
