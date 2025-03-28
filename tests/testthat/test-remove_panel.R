library(shinytest2)

test_that("remove_panel works", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "remove_panel")
  
  app <- AppDriver$new(appdir, name = "remove_panel", seed = 121, height = 752, width = 1211)
  app$wait_for_idle()
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$set_inputs(selinp = "2")
  app$click("btn")
  app$set_window_size(width = 1211, height = 752)
  app$wait_for_idle()
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$set_window_size(width = 1211, height = 752)
  app$set_inputs(obs = 731)
  app$wait_for_idle()
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$set_inputs(selinp = "3")
  app$click("btn")
  app$set_window_size(width = 1211, height = 752)
  app$wait_for_idle()
  app$expect_values(input = TRUE, output = FALSE, export = TRUE)
  app$set_inputs(obs = 389)
})
