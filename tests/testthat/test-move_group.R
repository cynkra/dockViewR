library(shinytest2)

test_that("move_group app works", {
  appdir <- system.file(package = "dockViewR", "examples", "move_group")

  app <- AppDriver$new(appdir, name = "move_group", seed = 121, height = 752, width = 1211)
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$click("move2")
})
