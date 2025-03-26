# File: tests/testthat/test-inst-apps.R
library(shinytest2)

test_that("sample_app works", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "demo")

  app <- AppDriver$new(appdir, name = "sample_app", seed = 121, height = 863, width = 2259)

  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$set_window_size(width = 2259, height = 863)
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$set_window_size(width = 2259, height = 863)
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$set_inputs(obs = 781)
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$set_window_size(width = 2259, height = 863)
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$set_window_size(width = 2259, height = 863)
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$set_window_size(width = 2259, height = 863)
  app$set_inputs(variable = "am")

})