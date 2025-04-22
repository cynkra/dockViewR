library(shinytest2)

test_that("move_group2 app works", {

  appdir <- system.file(package = "dockViewR", "examples", "move_group2")

  app <- AppDriver$new(appdir, name = "move_group2", seed = 121, height = 752, width = 1211)
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$click("move2")
  app$wait_for_idle()
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$wait_for_idle()
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$click("move2")
  app$wait_for_idle()
})
