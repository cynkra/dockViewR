library(shinytest2)

test_that("active-panel DOM event re-broadcasts on activation", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "active_panel")

  app <- AppDriver$new(
    appdir,
    name = "active_panel",
    seed = 121,
    height = 752,
    width = 1211
  )
  on.exit(app$stop(), add = TRUE)
  app$wait_for_idle()

  # dockview activates the front panel on render, so the re-broadcast fires for
  # it -- the listener in the example records the id through `event_panel`.
  expect_identical(app$get_value(input = "event_panel"), "a")

  # A background tab's content mounts lazily on first activation; the
  # re-broadcast fires on that tick, carrying its id.
  app$click("select_b")
  app$wait_for_idle()
  expect_identical(app$get_value(input = "event_panel"), "b")
})
