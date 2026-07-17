library(shinytest2)

test_that("_state-source tags programmatic vs user layout changes", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state_source")

  app <- AppDriver$new(
    appdir,
    name = "state_source",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  # The initial layout is produced by the server (the panels passed to
  # dock_view()), not a user gesture.
  expect_identical(app$get_value(input = "dock_state-source"), "server")

  # Stash the {a, b} layout to restore later.
  app$click("save")

  # A programmatic apply (add_panel -> _add-panel handler) is tagged server.
  app$click("add")
  app$wait_for_idle()
  expect_identical(app$get_value(input = "dock_state-source"), "server")
  expect_true("c" %in% app$get_value(export = "panel_ids"))

  # A programmatic move stays server through its async resize tail (the
  # onDidMovePanel setTimeout that fires a trailing onDidLayoutChange).
  app$click("move")
  app$wait_for_idle()
  expect_identical(app$get_value(input = "dock_state-source"), "server")

  # A restore (fromJSON -- the issue's headline case) is tagged server across
  # its whole teardown/rebuild cascade, not just the first frame.
  app$click("restore")
  app$wait_for_idle()
  expect_identical(app$get_value(input = "dock_state-source"), "server")
  expect_false("c" %in% app$get_value(export = "panel_ids"))

  # A genuine user gesture (closing a panel, as a tab-X click would) is tagged
  # client -- the next layout change after a server apply is not mis-attributed.
  app$run_js(
    "HTMLWidgets.find('#dock').getWidget().component.api.getPanel('a').api.close()"
  )
  app$wait_for_idle()
  expect_identical(app$get_value(input = "dock_state-source"), "client")
})
