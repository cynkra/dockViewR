#' Dock view widget
#'
#' Create a dock view widget
#'
#' @import htmlwidgets
#' @param panels Widget configuration. Slot for \link{panel}.
#' @param ... Other options. See \url{https://dockview.dev/docs/api/dockview/options}.
#' @param theme Theme. One of
#' \code{c("abyss", "dark", "light", "vs", "dracula", "replit")}.
#' @param width Widget width.
#' @param height Widget height.
#' @param elementId When used outside Shiny.
#'
#' @export
#' @examplesShinylive
#' webr::install("dockViewR", repos = "https://rinterface.github.io/rinterface-wasm-cran/")
#' library(shiny)
#' library(bslib)
#' library(dockViewR)
#'
#' ui <- page_fillable(
#'   dock_viewOutput("dock")
#' )
#'
#'server <- function(input, output, session) {
#'  output$dock <- renderDock_view({
#'    dock_view(
#'      panels = list(
#'        panel(
#'          id = "1",
#'          title = "Panel 1",
#'          content = tagList(
#'            sliderInput(
#'              "obs",
#'              "Number of observations:",
#'              min = 0,
#'              max = 1000,
#'              value = 500
#'            ),
#'            plotOutput("distPlot")
#'          )
#'        ),
#'        panel(
#'          id = "2",
#'          title = "Panel 2",
#'          content = tagList(
#'            selectInput(
#'              "variable",
#'              "Variable:",
#'              c("Cylinders" = "cyl", "Transmission" = "am", "Gears" = "gear")
#'            ),
#'            tableOutput("data")
#'          ),
#'          position = list(
#'            referencePanel = "1",
#'            direction = "right"
#'          )
#'        )
#'      ),
#'      theme = "replit"
#'    )
#'  })
#'
#'  output$distPlot <- renderPlot({
#'    req(input$obs)
#'    hist(rnorm(input$obs))
#'  })
#'  output$data <- renderTable(
#'    {
#'      mtcars[, c("mpg", input$variable), drop = FALSE]
#'    },
#'    rownames = TRUE
#'  )
#'}

#' shinyApp(ui, server)
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

#' Dock panel
#'
#' Create a dock panel
#'
#' @import htmlwidgets
#' @param id Panel unique id.
#' @param title Panel title.
#' @param content Panel content. Can be a list of Shiny tags.
#' @param active Is active?
#' @param ... Other options passed to the API.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#'
#' @export
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
