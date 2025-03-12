# dockViewR


<!-- index.md is generated from index.Rmd. Please edit that file -->
<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/dockViewR.png)](https://CRAN.R-project.org/package=dockViewR)
[![R-CMD-check](https://github.com/cynkra/dockViewR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/cynkra/dockViewR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of dockViewR is to provide a layout manager for Shiny apps and
interactive R documents. It builds on top of
[dockview](https://dockview.dev/).

## Installation

You can install the development version of dockViewR like so:

``` r
pak::pak("cynkra/dockViewR")
```

## Example

To run the demo app:

``` r
library(dockViewR)
shinyAppDir(system.file("examples/demo", package = "dockViewR"))
```

<details>
<summary>
Toggle code
</summary>

``` r
library(shiny)
library(bslib)
library(visNetwork)

nodes <- data.frame(id = 1:3)
edges <- data.frame(from = c(1, 2), to = c(1, 3))

ui <- page_fillable(
  dock_viewOutput("dock")
)

server <- function(input, output, session) {
  output$dock <- renderDock_view({
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
}

shinyApp(ui, server)
```

</details>

<br/>

<iframe class="border border-5 rounded shadow-lg" src="https://shinylive.io/r/app/#h=0&amp;code=NobwRAdghgtgpmAXGKAHVA6ASmANGAYwHsIAXOMpMAdzgCMAnRRASwgGdSoAbbgCgA6YACZECAawBqLONSxDcAAgZxURdooC8ioQAtSpVO0QB6EwzbkGAMygE4GAOYtSugK50MLIuctwbdnAAtNRQ7DBBBAxQECZCAJQCENwsjFAMAJ58ohLSsliJHLpsGQCC6AAiLAx87BmccDAY1izccIJgcAAesKht7CbCjUQKiqh24lCOcFo6ImJSMnIJ8WAAvgC6QA" width="125%" height="900px"></iframe>

## Development

JS code is managed by `webpack`.

``` r
packer::bundle()
```
