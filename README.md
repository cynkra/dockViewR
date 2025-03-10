
<!-- README.md is generated from README.Rmd. Please edit that file -->

# dockViewR

<!-- badges: start -->

[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![CRAN
status](https://www.r-pkg.org/badges/version/dockViewR)](https://CRAN.R-project.org/package=dockViewR)
[![R-CMD-check](https://github.com/cynkra/dockViewR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/cynkra/dockViewR/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of dockViewR is to …

## Installation

You can install the development version of dockViewR like so:

``` r
# FILL THIS IN! HOW CAN PEOPLE INSTALL YOUR DEV PACKAGE?
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(shiny)
library(bslib)
library(dockViewR)

ui <- page_fillable(
  dock_viewOutput("dock")
)

server <- function(input, output, session) {
  output$dock <- renderDock_view({
    dock_view("plop")
  })
}

shinyApp(ui, server)
```
