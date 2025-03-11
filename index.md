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

<iframe class="border border-5 rounded shadow-lg" src="https://shinylive.io/r/app/#h=0&amp;code=NobwRAdghgtgpmAXGKAHVA6ASmANGAYwHsIAXOMpMAdzgCMAnRRASwgGdSoAbbgCgA6YACZECAawBqLONSxDcAAgZxURdooC8ioQAtSpVO0QB6EwzbkGAMygE4GAOYtSugK50MLIuctwbdnAAtNRQ7DBBBAxQECZCAJQCENwsjFAMAJ58ohLSsliJHLpsGQCC6AAiLAx87BmccDAY1izccIJgcAAesKht7CbCjUQKiqh24lCOcFo6ImJSMnIJ8WAAvgC6QA" width="125%" height="900px"></iframe>

## Development

JS code is managed by `webpack`.

``` r
packer::bundle()
```
