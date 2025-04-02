library(shinytest2)

test_that("move_panel works", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "move_panel")

  app <- AppDriver$new(
    appdir,
    name = "move_panel",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$click("move")
  app$wait_for_idle()
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$click("move2")
  app$wait_for_idle()
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
})
