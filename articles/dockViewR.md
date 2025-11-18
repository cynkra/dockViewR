# dockViewR

## Dynamically add panel

You can add **panels** to an existing **dock** with
[`add_panel()`](https://cynkra.github.io/dockViewR/reference/panel-operations.md)
which expects a
[`panel()`](https://cynkra.github.io/dockViewR/reference/panel.md)
object.

Toggle code

``` r
library(dockViewR)
library(shiny)
library(bslib)
library(visNetwork)

options("dockViewR.mode" = "dev")

nodes <- data.frame(id = 1:3)
edges <- data.frame(from = c(1, 2), to = c(1, 3))

ui <- page_fillable(
  actionButton("btn", "add Panel"),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  exportTestValues(
    panel_ids = get_panels_ids(dock_proxy),
    active_group = get_active_group(dock_proxy),
    grid = get_grid(dock_proxy)
  )

  output$dock <- renderDockView({
    dock_view(
      add_tab = new_add_tab_plugin(enable = TRUE),
      panels = list(
        panel(
          id = "1",
          title = "Panel 1",
          content = tagList(
            sliderInput(
              "obs",
              "Number of observations:",
              min = 0,
              max = 1000,
              value = 500
            ),
            plotOutput("distPlot")
          )
        ),
        panel(
          id = "2",
          title = "Panel 2",
          content = tagList(
            visNetworkOutput("network")
          ),
          position = list(
            referencePanel = "1",
            direction = "right"
          ),
          minimumWidth = 500
        ),
        panel(
          id = "3",
          title = "Panel 3",
          content = tagList(
            selectInput(
              "variable",
              "Variable:",
              c("Cylinders" = "cyl", "Transmission" = "am", "Gears" = "gear")
            ),
            tableOutput("data")
          ),
          position = list(
            referencePanel = "2",
            direction = "below"
          )
        )
      ),
      theme = "replit"
    )
  })

  output$distPlot <- renderPlot({
    req(input$obs)
    hist(rnorm(input$obs))
  })

  output$network <- renderVisNetwork({
    visNetwork(nodes, edges, width = "100%")
  })

  output$data <- renderTable(
    {
      mtcars[, c("mpg", input$variable), drop = FALSE]
    },
    rownames = TRUE
  )

  output$plot <- renderPlot({
    dist <- switch(
      input$dist,
      norm = rnorm,
      unif = runif,
      lnorm = rlnorm,
      exp = rexp,
      rnorm
    )

    hist(dist(500))
  })

  observeEvent(input$btn, {
    pnl <- panel(
      id = "new_1",
      title = "Dynamic panel",
      content = tagList(
        radioButtons(
          "dist",
          "Distribution type:",
          c(
            "Normal" = "norm",
            "Uniform" = "unif",
            "Log-normal" = "lnorm",
            "Exponential" = "exp"
          )
        ),
        plotOutput("plot")
      ),
      position = list(
        referencePanel = "1",
        direction = "within"
      ),
      remove = new_remove_tab_plugin(enable = TRUE, mode = "manual")
    )
    add_panel(
      dock_proxy,
      pnl
    )
  })

  observeEvent(input[["dock_added-panel"]], {
    showNotification(
      paste("Panel added:", input[["dock_added-panel"]]),
      type = "message"
    )
  })

  # Manually remove a panel after clicking on the button
  observeEvent(input[["dock_panel-to-remove"]], {
    showNotification(
      paste("Removing panel:", input[["dock_panel-to-remove"]]),
      type = "message"
    )
    remove_panel(
      dock_proxy,
      input[["dock_panel-to-remove"]]
    )
  })

  # Manually add a panel after clicking on the + button
  observeEvent(input[["dock_panel-to-add"]], {
    add_panel(
      dock_proxy,
      panel(
        id = as.character(as.numeric(tail(get_panels_ids(dock_proxy), 1)) + 1),
        title = paste(
          "Panel",
          as.character(as.numeric(tail(get_panels_ids(dock_proxy), 1)) + 1)
        ),
        content = paste(
          "This is panel",
          as.character(as.numeric(tail(get_panels_ids(dock_proxy), 1)) + 1)
        ),
        position = list(
          referenceGroup = input[["dock_panel-to-add"]],
          direction = "within"
        )
      )
    )
  })
}

shinyApp(ui, server)
```

  

An alternative way to add panels is to use the `+` icon next to the
panel tabs. For this, you make sure to initialize the dock with
`add_tab = list(enable = TRUE)`. By default, a callback function sets a
Shiny input value `input$<dock_id>_panel-to-add` to the id of group
where the panel should belong. You can listen to this input on the
server side to manually call
[`add_panel()`](https://cynkra.github.io/dockViewR/reference/panel-operations.md).
Make sure that the panel is passed like so:

``` r
add_panel(
  dock_id,
  panel = panel(
    id = "new_id", 
    position = list(
      referenceGroup = input[["<dock_id>_panel-to-add"]],
      direction = "right"
    )
  )
)
```

To add a floating panel, you can set `floating = TRUE` when calling
[`add_panel()`](https://cynkra.github.io/dockViewR/reference/panel-operations.md).

## Dynamically remove panels

You can remove **panels** from an existing **dock** with
[`remove_panel()`](https://cynkra.github.io/dockViewR/reference/panel-operations.md)
which expects the `id` of the panel to remove, in addition to the dock
`id`.

Toggle code

``` r
library(dockViewR)
library(shiny)
library(bslib)
library(visNetwork)

options("dockViewR.mode" = "dev")

nodes <- data.frame(id = 1:3)
edges <- data.frame(from = c(1, 2), to = c(1, 3))

ui <- page_fillable(
  selectInput("selinp", "Panel ids", choices = NULL),
  actionButton("btn", "remove Panel"),
  dockViewOutput("dock")
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  exportTestValues(
    panel_ids = get_panels_ids(dock_proxy),
    active_group = get_active_group(dock_proxy),
    grid = get_grid(dock_proxy)
  )
  observeEvent(get_panels_ids(dock_proxy), {
    updateSelectInput(
      session = session,
      inputId = "selinp",
      choices = get_panels_ids(dock_proxy)
    )
  })

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "1",
          title = "Panel 1",
          content = tagList(
            sliderInput(
              "obs",
              "Number of observations:",
              min = 0,
              max = 1000,
              value = 500
            ),
            plotOutput("distPlot")
          )
        ),
        panel(
          id = "2",
          title = "Panel 2",
          content = tagList(
            visNetworkOutput("network")
          ),
          position = list(
            referencePanel = "1",
            direction = "right"
          ),
          minimumWidth = 500
        ),
        panel(
          id = "3",
          title = "Panel 3",
          content = tagList(
            selectInput(
              "variable",
              "Variable:",
              c("Cylinders" = "cyl", "Transmission" = "am", "Gears" = "gear")
            ),
            tableOutput("data")
          ),
          position = list(
            referencePanel = "2",
            direction = "below"
          )
        )
      ),
      theme = "replit"
    )
  })

  output$distPlot <- renderPlot({
    req(input$obs)
    hist(rnorm(input$obs))
  })

  output$network <- renderVisNetwork({
    visNetwork(nodes, edges, width = "100%")
  })

  output$data <- renderTable(
    {
      mtcars[, c("mpg", input$variable), drop = FALSE]
    },
    rownames = TRUE
  )

  output$plot <- renderPlot({
    dist <- switch(
      input$dist,
      norm = rnorm,
      unif = runif,
      lnorm = rlnorm,
      exp = rexp,
      rnorm
    )

    hist(dist(500))
  })

  observeEvent(input$btn, {
    req(input$selinp)
    remove_panel(dock_proxy, input$selinp)
  })
}

shinyApp(ui, server)
```

  

## Dynamically move panel

You can **move** individual panels in the dock with
[`move_panel()`](https://cynkra.github.io/dockViewR/reference/panel-operations.md)
which expects:

- The dock id.
- The panel id: can be a string or numeric value.
- The position. If left NULL, the panel is moved to the latest index.
  Otherwise choose one of `"left", "right", "top", "bottom", "center"`.
- `group`: id of the panel that belongs to another group. The panel will
  be moved relative to the second group, depending on the position
  parameter. If left NULL, it is added on the right side.
- index: If panels belong to the same group, you can use index to move
  the target panel at the desired position. When group is left NULL,
  index must be passed and cannot exceed the total number of panels or
  be negative.

Toggle code

``` r
library(shiny)
library(bslib)
library(dockViewR)

options("dockViewR.mode" = "dev")

ui <- fluidPage(
  h1("Panels within the same group"),
  actionButton("move", "Move Panel 1"),
  dockViewOutput("dock"),
  h1("Panels with different groups"),
  actionButton("move2", "Move Panel 1"),
  dockViewOutput("dock2"),
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  exportTestValues(
    panel_ids = get_panels_ids(dock_proxy),
    active_group = get_active_group(dock_proxy),
    grid = get_grid(dock_proxy)
  )

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "1",
          title = "Panel 1",
          content = tagList(
            sliderInput(
              "obs",
              "Number of observations:",
              min = 0,
              max = 1000,
              value = 500
            ),
            plotOutput("distPlot")
          )
        ),
        panel(
          id = "2",
          title = "Panel 2",
          content = tagList(
            selectInput(
              "variable",
              "Variable:",
              c("Cylinders" = "cyl", "Transmission" = "am", "Gears" = "gear")
            ),
            tableOutput("data")
          ),
        ),
        panel(
          id = "3",
          title = "Panel 3",
          content = h1("Panel 3")
        )
      ),
      theme = "light-spaced"
    )
  })

  output$dock2 <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "1",
          title = "Panel 1",
          content = "Panel 1"
        ),
        panel(
          id = "2",
          title = "Panel 2",
          content = "Panel 2",
          position = list(
            referencePanel = "1",
            direction = "within"
          )
        ),
        panel(
          id = "3",
          title = "Panel 3",
          content = h1("Panel 3"),
          position = list(
            referencePanel = "1",
            direction = "right"
          )
        )
      ),
      theme = "light-spaced"
    )
  })

  output$distPlot <- renderPlot({
    req(input$obs)
    hist(rnorm(input$obs))
  })
  output$data <- renderTable(
    {
      mtcars[, c("mpg", input$variable), drop = FALSE]
    },
    rownames = TRUE
  )

  observeEvent(input$move, {
    move_panel(
      dock_proxy,
      id = 1,
      index = 3
    )
  })

  dock_proxy2 <- dock_view_proxy("dock2")

  observeEvent(input$move2, {
    move_panel(
      dock_proxy2,
      id = 1,
      group = 3,
      position = "bottom"
    )
  })
}

shinyApp(ui, server)
```

  

## Dynamically move groups

You can move **groups** of panels using 2 different APIs described
below.

### Group point of view

To move a **group** of panel(s),
[`move_group()`](https://cynkra.github.io/dockViewR/reference/panel-operations.md)
works by selecting the group **source** id, that is `from`, and the
group **target** id, `to`. Position is relative to the `to`.

Toggle code

``` r
library(shiny)
library(dockViewR)

options("dockViewR.mode" = "dev")

ui <- fluidPage(
  actionButton(
    "move",
    "Move Group with group-id 1 at the bottom of group with group-id 3"
  ),
  dockViewOutput("dock"),
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  exportTestValues(
    panel_ids = get_panels_ids(dock_proxy),
    active_group = get_active_group(dock_proxy),
    grid = get_grid(dock_proxy)
  )
  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "1",
          title = "Panel 1",
          content = "Panel 1"
        ),
        panel(
          id = "2",
          title = "Panel 2",
          content = "Panel 2",
          position = list(
            referencePanel = "1",
            direction = "within"
          )
        ),
        panel(
          id = "3",
          title = "Panel 3",
          content = h1("Panel 3"),
          position = list(
            referencePanel = "1",
            direction = "right"
          )
        ),
        panel(
          id = "4",
          title = "Panel 4",
          content = h1("Panel 4"),
          position = list(
            referencePanel = "3",
            direction = "within"
          )
        ),
        panel(
          id = "5",
          title = "Panel 5",
          content = h1("Panel 5"),
          position = list(
            referencePanel = "4",
            direction = "right"
          )
        ),
        panel(
          id = "6",
          title = "Panel 6",
          content = h1("Panel 6"),
          position = list(
            referencePanel = "5",
            direction = "within"
          )
        )
      ),
      theme = "light-spaced"
    )
  })

  observeEvent(input$move, {
    move_group(
      dock_proxy,
      from = 1,
      to = 3,
      position = "bottom"
    )
  })
}

shinyApp(ui, server)
```

  

### Panel point of view

Another approach is possible with `move_group2`, which works from the
point of view of a panel. This means given `from` which the panel id,
[dockViewR](https://github.com/cynkra/dockViewR) is able to find the
group where it belongs to. Same for the `to`. This way you don’t have to
worry about group ids, which are implicit.

Toggle code

``` r
library(shiny)
library(dockViewR)

options("dockViewR.mode" = "dev")

ui <- fluidPage(
  actionButton(
    "move",
    "Move Group that contains Panel 1 to the right of group 
    that contains Panel 3"
  ),
  dockViewOutput("dock"),
)

server <- function(input, output, session) {
  dock_proxy <- dock_view_proxy("dock")

  exportTestValues(
    panel_ids = get_panels_ids(dock_proxy),
    active_group = get_active_group(dock_proxy),
    grid = get_grid(dock_proxy)
  )
  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "1",
          title = "Panel 1",
          content = "Panel 1"
        ),
        panel(
          id = "2",
          title = "Panel 2",
          content = "Panel 2",
          position = list(
            referencePanel = "1",
            direction = "within"
          )
        ),
        panel(
          id = "3",
          title = "Panel 3",
          content = h1("Panel 3"),
          position = list(
            referencePanel = "1",
            direction = "right"
          )
        ),
        panel(
          id = "4",
          title = "Panel 4",
          content = h1("Panel 4"),
          position = list(
            referencePanel = "3",
            direction = "within"
          )
        ),
        panel(
          id = "5",
          title = "Panel 5",
          content = h1("Panel 5"),
          position = list(
            referencePanel = "4",
            direction = "right"
          )
        ),
        panel(
          id = "6",
          title = "Panel 6",
          content = h1("Panel 6"),
          position = list(
            referencePanel = "5",
            direction = "within"
          )
        )
      ),
      theme = "light-spaced"
    )
  })

  observeEvent(input$move, {
    move_group2(
      dock_proxy,
      from = 1,
      to = 3,
      position = "right"
    )
  })
}

shinyApp(ui, server)
```

  

## Get the state of the dock

You can access the **state** of the dock which can return something
like:

``` r
dockViewR:::test_dock
#> $grid
#> $grid$root
#> $grid$root$type
#> [1] "branch"
#> 
#> $grid$root$data
#> $grid$root$data[[1]]
#> $grid$root$data[[1]]$type
#> [1] "leaf"
#> 
#> $grid$root$data[[1]]$data
#> $grid$root$data[[1]]$data$views
#> $grid$root$data[[1]]$data$views[[1]]
#> [1] "test"
#> 
#> $grid$root$data[[1]]$data$views[[2]]
#> [1] "2"
#> 
#> 
#> $grid$root$data[[1]]$data$activeView
#> [1] "2"
#> 
#> $grid$root$data[[1]]$data$id
#> [1] "1"
#> 
#> 
#> $grid$root$data[[1]]$size
#> [1] 95
#> 
#> 
#> $grid$root$data[[2]]
#> $grid$root$data[[2]]$type
#> [1] "leaf"
#> 
#> $grid$root$data[[2]]$data
#> $grid$root$data[[2]]$data$views
#> $grid$root$data[[2]]$data$views[[1]]
#> [1] "3"
#> 
#> 
#> $grid$root$data[[2]]$data$activeView
#> [1] "3"
#> 
#> $grid$root$data[[2]]$data$id
#> [1] "2"
#> 
#> 
#> $grid$root$data[[2]]$size
#> [1] 95
#> 
#> 
#> 
#> $grid$root$size
#> [1] 0
#> 
#> 
#> $grid$width
#> [1] 0
#> 
#> $grid$height
#> [1] 0
#> 
#> $grid$orientation
#> [1] "HORIZONTAL"
#> 
#> 
#> $panels
#> $panels$`2`
#> $panels$`2`$id
#> [1] "2"
#> 
#> $panels$`2`$contentComponent
#> [1] "default"
#> 
#> $panels$`2`$params
#> $panels$`2`$params$content
#> $panels$`2`$params$content$head
#> [1] ""
#> 
#> $panels$`2`$params$content$singletons
#> list()
#> 
#> $panels$`2`$params$content$dependencies
#> list()
#> 
#> $panels$`2`$params$content$html
#> [1] "Panel 2"
#> 
#> 
#> $panels$`2`$params$id
#> [1] "2"
#> 
#> 
#> $panels$`2`$title
#> [1] "Panel 2"
#> 
#> 
#> $panels$`3`
#> $panels$`3`$id
#> [1] "3"
#> 
#> $panels$`3`$contentComponent
#> [1] "default"
#> 
#> $panels$`3`$params
#> $panels$`3`$params$content
#> $panels$`3`$params$content$head
#> [1] ""
#> 
#> $panels$`3`$params$content$singletons
#> list()
#> 
#> $panels$`3`$params$content$dependencies
#> list()
#> 
#> $panels$`3`$params$content$html
#> [1] "<h1>Panel 3</h1>"
#> 
#> 
#> $panels$`3`$params$id
#> [1] "3"
#> 
#> 
#> $panels$`3`$title
#> [1] "Panel 3"
#> 
#> 
#> $panels$test
#> $panels$test$id
#> [1] "test"
#> 
#> $panels$test$contentComponent
#> [1] "default"
#> 
#> $panels$test$params
#> $panels$test$params$content
#> $panels$test$params$content$head
#> [1] ""
#> 
#> $panels$test$params$content$singletons
#> list()
#> 
#> $panels$test$params$content$dependencies
#> list()
#> 
#> $panels$test$params$content$html
#> [1] "Panel 1"
#> 
#> 
#> $panels$test$params$id
#> [1] "test"
#> 
#> 
#> $panels$test$title
#> [1] "Panel 1"
#> 
#> 
#> 
#> $activeGroup
#> [1] "2"
```

The dock state is a deeply nested list:

``` r
str(dockViewR:::test_dock)
#> List of 3
#>  $ grid       :List of 4
#>   ..$ root       :List of 3
#>   .. ..$ type: chr "branch"
#>   .. ..$ data:List of 2
#>   .. .. ..$ :List of 3
#>   .. .. .. ..$ type: chr "leaf"
#>   .. .. .. ..$ data:List of 3
#>   .. .. .. .. ..$ views     :List of 2
#>   .. .. .. .. .. ..$ : chr "test"
#>   .. .. .. .. .. ..$ : chr "2"
#>   .. .. .. .. ..$ activeView: chr "2"
#>   .. .. .. .. ..$ id        : chr "1"
#>   .. .. .. ..$ size: int 95
#>   .. .. ..$ :List of 3
#>   .. .. .. ..$ type: chr "leaf"
#>   .. .. .. ..$ data:List of 3
#>   .. .. .. .. ..$ views     :List of 1
#>   .. .. .. .. .. ..$ : chr "3"
#>   .. .. .. .. ..$ activeView: chr "3"
#>   .. .. .. .. ..$ id        : chr "2"
#>   .. .. .. ..$ size: int 95
#>   .. ..$ size: int 0
#>   ..$ width      : int 0
#>   ..$ height     : int 0
#>   ..$ orientation: chr "HORIZONTAL"
#>  $ panels     :List of 3
#>   ..$ 2   :List of 4
#>   .. ..$ id              : chr "2"
#>   .. ..$ contentComponent: chr "default"
#>   .. ..$ params          :List of 2
#>   .. .. ..$ content:List of 4
#>   .. .. .. ..$ head        : chr ""
#>   .. .. .. ..$ singletons  : list()
#>   .. .. .. ..$ dependencies: list()
#>   .. .. .. ..$ html        : chr "Panel 2"
#>   .. .. ..$ id     : chr "2"
#>   .. ..$ title           : chr "Panel 2"
#>   ..$ 3   :List of 4
#>   .. ..$ id              : chr "3"
#>   .. ..$ contentComponent: chr "default"
#>   .. ..$ params          :List of 2
#>   .. .. ..$ content:List of 4
#>   .. .. .. ..$ head        : chr ""
#>   .. .. .. ..$ singletons  : list()
#>   .. .. .. ..$ dependencies: list()
#>   .. .. .. ..$ html        : chr "<h1>Panel 3</h1>"
#>   .. .. ..$ id     : chr "3"
#>   .. ..$ title           : chr "Panel 3"
#>   ..$ test:List of 4
#>   .. ..$ id              : chr "test"
#>   .. ..$ contentComponent: chr "default"
#>   .. ..$ params          :List of 2
#>   .. .. ..$ content:List of 4
#>   .. .. .. ..$ head        : chr ""
#>   .. .. .. ..$ singletons  : list()
#>   .. .. .. ..$ dependencies: list()
#>   .. .. .. ..$ html        : chr "Panel 1"
#>   .. .. ..$ id     : chr "test"
#>   .. ..$ title           : chr "Panel 1"
#>  $ activeGroup: chr "2"
```

On the top level it has 3 elements:

- **grid**: a list representing the dock layout.
- **panels**: a list having the same structure as
  [`panel()`](https://cynkra.github.io/dockViewR/reference/panel.md)
  composing the dock.
- **activeGroup**: the current active group (a string).

Within the Shiny server function, on can access the state of the dock
with
[`get_dock()`](https://cynkra.github.io/dockViewR/reference/dock-state.md),
passing the dock id (since the app may have multiple docks).

Each other function allows to deep dive into the returned value of
[`get_dock()`](https://cynkra.github.io/dockViewR/reference/dock-state.md):

- [`get_panels()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
  returns the **panels** element of
  [`get_dock()`](https://cynkra.github.io/dockViewR/reference/dock-state.md).
  - [`get_panels_ids()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
    returns a character vector containing all panel ids from
    [`get_panels()`](https://cynkra.github.io/dockViewR/reference/dock-state.md).
- [`get_active_group()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
  extracts the **activeGroup** component of
  [`get_dock()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
  as a string.
- [`get_grid()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
  returns the **grid** element of
  [`get_dock()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
  which is a list.
  -[`get_groups()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
  returns a list of panel groups from
  [`get_grid()`](https://cynkra.github.io/dockViewR/reference/dock-state.md).
  - [`get_groups_ids()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
    returns a character vector of groups ids from
    [`get_groups()`](https://cynkra.github.io/dockViewR/reference/dock-state.md).
  - [`get_groups_panels()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
    returns a list of character vector containing the ids of each panel
    within each group.

[`save_dock()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
and
[`restore_dock()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
are used for their side effect to allow to respectively **serialise**
and **restore** a dock object, as shown in the following demonstration
app.

Each time a panel moves, or a group is maximized, the dock state is
updated.

Toggle code

``` r
library(shiny)
library(bslib)
library(dockViewR)
library(listviewer)

ui <- fluidPage(
  h1("Serialise dock state"),
  div(
    class = "d-flex justify-content-center",
    actionButton("save", "Save layout"),
    actionButton("restore", "Restore saved layout"),
    selectInput("states", "Select a state", NULL)
  ),
  dockViewOutput("dock"),
  reactjsonOutput("dock_state"),
)

server <- function(input, output, session) {
  output$dock_state <- renderReactjson({
    reactjson(jsonlite::toJSON(input$dock_state))
  })

  dock_states <- reactiveVal(NULL)

  dock_proxy <- dock_view_proxy("dock")

  observeEvent(input$save, {
    save_dock(dock_proxy)
    states <- c(dock_states(), list(input$dock_state))
    dock_states(setNames(states, seq_along(states)))
  })

  exportTestValues(
    n_states = length(dock_states()),
    panel_ids = get_panels_ids(dock_proxy),
    group_ids = get_groups_ids(dock_proxy),
    active_group = get_active_group(dock_proxy),
    active_views = get_active_views(dock_proxy),
    active_panel = get_active_panel(dock_proxy),
    grid = get_grid(dock_proxy)
  )

  observeEvent(dock_states(), {
    updateSelectInput(session, "states", choices = names(dock_states()))
  })

  observeEvent(input$restore, {
    if (!length(dock_states())) {
      showNotification("No saved states", type = "error")
      return(NULL)
    }
    restore_dock(dock_proxy, dock_states()[[input$states]])
  })

  output$dock <- renderDockView({
    dock_view(
      panels = list(
        panel(
          id = "test",
          title = "Panel 1",
          content = tagList(
            sliderInput(
              "obs",
              "Number of observations:",
              min = 0,
              max = 1000,
              value = 500
            ),
            plotOutput("distPlot")
          )
        ),
        panel(
          id = 2,
          title = "Panel 2",
          content = "Panel 2",
          position = list(
            referencePanel = "test",
            direction = "within"
          )
        ),
        panel(
          id = 3,
          title = "Panel 3",
          content = h1("Panel 3"),
          position = list(
            referencePanel = "test",
            direction = "right"
          )
        )
      ),
      theme = "light-spaced"
    )
  })

  output$distPlot <- renderPlot({
    req(input$obs)
    hist(rnorm(input$obs))
  })
}

shinyApp(ui, server)
```

  
