# File: tests/testthat/test-inst-apps.R
library(shinytest2)

test_that("sample_app works", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "demo")

  app <- AppDriver$new(
    appdir,
    name = "sample_app",
    seed = 121,
    height = 863,
    width = 2259
  )

  app$wait_for_idle()
  # `_state` is emitted once the ResizeObserver reports real geometry, not on the
  # initial zero-sized render, and the exported grid derives from it. This app
  # drives no output off `_state`, so wait_for_idle cannot observe that settle --
  # wait for the input itself before snapshotting the grid.
  app$wait_for_value(input = "dock_state")
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
  app$set_inputs(obs = 781)
  app$wait_for_idle()
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
  app$set_inputs(variable = "am")
  app$wait_for_idle()
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
})
