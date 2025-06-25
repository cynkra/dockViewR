#' Create a dock view widget
#'
#' Creates an interactive dock view widget that enables flexible
#' layout management with draggable, resizable, and dockable panels.
#' This is a wrapper around the dockview.dev
#' JavaScript library, providing a powerful interface for
#' creating IDE-like layouts in Shiny applications or R Markdown documents.
#'
#' @param panels Widget configuration. Slot for \link{panel}.
#' @param ... Other options. See
#' \url{https://dockview.dev/docs/api/dockview/options/}.
#' @param theme Theme. One of
#' \code{c("abyss", "dark", "light", "vs", "dracula", "replit")}.
#' @param add_tab Globally controls the add tab behavior. List with enable and callback.
#' Enable is a boolean, default to FALSE and callback is a
#' JavaScript function passed with \link[htmlwidgets]{JS}.
#' @param width Widget width.
#' @param height Widget height.
#' @param elementId When used outside Shiny.
#'
#' @returns An HTML widget object.
#'
#' @export
#' @examplesShinylive
#' webr::install(
#'  "dockViewR",
#'  repos = "https://rinterface.github.io/rinterface-wasm-cran/"
#' )
#' library(shiny)
#' library(bslib)
#' library(dockViewR)
#'
#' ui <- page_fillable(
#'   dockViewOutput("dock")
#' )
#'
#'server <- function(input, output, session) {
#'  output$dock <- renderDockView({
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
    "light-spaced",
    "light",
    "abyss",
    "abyss-spaced",
    "dark",
    "vs",
    "dracula",
    "replit"
  ),
  add_tab = list(enable = FALSE, callback = NULL),
  width = NULL,
  height = NULL,
  elementId = NULL
) {
  theme <- match.arg(theme)

  deps <- extract_panel_deps(panels)

  # check ids
  ids <- check_panel_ids(panels)
  # check reference panels ids
  check_panel_refs(panels, ids)

  if (add_tab$enable) {
    if (is.null(add_tab$callback)) {
      add_tab$callback <- JS(
        "(config) => {
          const addPanel = (panel, api) => {
            let internals = {
              component: 'default',
              params: {
                content: panel.content,
                addTab: panel.addTab
              }
            }

            // Disable tab removal.
            //internals.tabComponent = 'custom';
            // You can use manual removal.
            //internals.tabComponent = 'manual';
            let props = { ...panel, ...internals }
            return (api.addPanel(props))
          }
          const defaultPanel = (pnId) => {
            return (`
              <p>Exchange me by running:</p>
              <p>removeUI(<br>
                &nbsp;&nbsp;selector = \"#${pnId} > *\",<br>
                &nbsp;&nbsp;multiple = TRUE<br>
              )</p>
              <p>shiny::insertUI(<br>
                    &nbsp;&nbsp;selector = \"#${pnId}\",<br>
                    &nbsp;&nbsp;where = \"beforeEnd\",<br>
                    &nbsp;&nbsp;ui = \"your ui code here\"<br>
              )</p>
            `)
          }
          const dockId = config.containerApi.component
            .gridview.element.closest('.dockview')
            .attributes.id.textContent;
          const pnId = `panel-${Date.now()}`
          addPanel({
            id: pnId,
            title: 'Panel new',
            inactive: false,
            content: {
              head: '',
              singletons: [],
              dependencies: [],
              html: defaultPanel(dockId + '-' + pnId)
            },
            position: { referenceGroup: config.group.id, direction: 'within' }
          }, config.containerApi);
        }"
      )
    } else {
      if (!is_js(add_tab$callback)) {
        stop("`callback` must be a JavaScript function.")
      }
    }
  }

  # forward options using x
  x <- list(
    theme = theme,
    panels = panels,
    # camelCase for JS ...
    addTab = add_tab,
    ...
  )

  # create widget
  htmlwidgets::createWidget(
    name = "dockview",
    x,
    dependencies = c(
      unlist(deps, recursive = FALSE),
      # Add fontawesome (avoids to get dependency on {fontawesome})
      htmltools::findDependencies(icon("cogs"))
    ),
    width = width,
    height = height,
    package = "dockViewR",
    elementId = elementId,
    sizingPolicy = htmlwidgets::sizingPolicy(
      defaultWidth = "100%",
      viewer.defaultHeight = "100%",
      viewer.defaultWidth = "100%",
      viewer.fill = FALSE,
      knitr.figure = FALSE,
      viewer.suppress = FALSE,
      browser.external = TRUE,
      browser.fill = FALSE,
      padding = 5
    )
  )
}

#' Dock panel
#'
#' Create a panel for use within a [dock_view()] widget.
#' Panels are the main container components that can be docked, dragged,
#' resized, and arranged within the dockview interface.
#'
#' @param id Panel unique id.
#' @param title Panel title.
#' @param content Panel content. Can be a list of Shiny tags.
#' @param active Is active?
#' @param remove List with two fields: enable and mode. Enable is a boolean
#' and mode is one of `manual`, `auto` (default to auto). In auto mode,
#' dockview JS removes the panel when it is closed and all its content. If you
#' need more control over the panel removal, set it to manual so you can explicitly
#' call `remove_panel()` and perform other tasks. On the server side, a shiny input is available
#' `input[["<dock_ID>_panel-to-remove"]]` so you can create observers with custom logic.
#' @param ... Other options passed to the API.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#' If you pass position, it must be a list with 2 fields:
#' - referencePanel: reference panel id.
#' - direction: one of `above`, `below`, `left`, `right` or `within`
#' (`above`, `below`, `left`, `right` put the panel in a new group,
#' while `within` puts the panel after its reference panel in the same group).
#' Position is relative to the reference panel target.
#'
#' @return A list representing a panel object to be consumed by
#' \link{dock_view}:
#' - id: unique panel id (string).
#' - title: panel title (string).
#' - content: panel content (`shiny.tag.list` or single `shiny.tag`).
#' - active: whether the panel is active or not (boolean).
#' - ...: extra parameters to pass to the API.
#'
#' @export
panel <- function(
  id,
  title,
  content,
  active = TRUE,
  remove = list(enable = FALSE, mode = "auto"),
  ...
) {
  # We can't check id uniqueness here because panel has no
  # idea of other existing panel ids at that point.
  id <- as.character(id)

  panel_opts <- list(
    id = id,
    title = title,
    inactive = !active,
    remove = remove,
    content = htmltools::renderTags(content)
  )

  # Extract extra parameters and process
  pars <- list(...)
  if (length(pars)) {
    if (!is.null(pars[["position"]])) {
      pars[["position"]] <- process_panel_position(id, pars[["position"]])
    }
    panel_opts <- c(panel_opts, pars)
  }
  panel_opts
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
#' is useful if you want to save an expression in a variable.
#'
#' @rdname dock_view-shiny
#'
#' @return \code{dockViewOutput} and `dock_view_output`
#' return a Shiny output function that can be used in the UI definition.
#' \code{renderDockView} and `render_dock_view` return a
#' Shiny render function that can be used in the server definition to
#' render a `dock_view` element.
#'
#' @export
dockViewOutput <- function(outputId, width = "100%", height = "400px") {
  #nocov start
  htmlwidgets::shinyWidgetOutput(
    outputId,
    "dockview",
    width,
    height,
    package = "dockViewR"
  )
} #nocov end

#' Alias to \link{dockViewOutput}
#' @export
#' @rdname dock_view-shiny
dock_view_output <- dockViewOutput

#' @rdname dock_view-shiny
#' @export
renderDockView <- function(expr, env = parent.frame(), quoted = FALSE) {
  #nocov start
  if (!quoted) {
    expr <- substitute(expr)
  } # force quoted
  htmlwidgets::shinyRenderWidget(
    expr,
    dockViewOutput,
    env,
    quoted = TRUE
  )
} #nocov end

#' Alias to \link{renderDockView}
#' @export
#' @rdname dock_view-shiny
render_dock_view <- renderDockView

#' Update options for dockview instance
#'
#' This does not rerender the widget, just update options like global theme.
#'
#' @param dock_id The id of the dock view widget to update.
#' @param options List of options for the \link{dock_view} instance.
#' @param session Shiny session object.
#' @return This function is called for its side effect.
#' It sends a message to JavaScript through the current websocket connection,
#' leveraging the shiny session object.
#' @export
update_dock_view <- function(
  dock_id,
  options,
  session = getDefaultReactiveDomain()
) {
  if (is.null(session)) {
    stop("`session` must be a valid Shiny session object.")
  }
  session$sendCustomMessage(
    type = sprintf("%s_update-options", session$ns(dock_id)),
    message = options
  )
}
