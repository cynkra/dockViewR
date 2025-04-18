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
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
  app$set_inputs(obs = 781)
  app$wait_for_idle()
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
  app$set_inputs(variable = "am")
  app$wait_for_idle()
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
})
