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
  expect_identical(app$get_value(input = "event_dock"), "dock")

  # A background tab's content mounts lazily on first activation; the
  # re-broadcast fires on that tick, carrying its id.
  app$click("select_b")
  app$wait_for_idle()
  expect_identical(app$get_value(input = "event_panel"), "b")
})

test_that("a re-entrant listener leaves the active-panel input current", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "active_panel")

  app <- AppDriver$new(
    appdir,
    name = "active_panel_reentrant",
    seed = 121,
    height = 752,
    width = 1211
  )
  on.exit(app$stop(), add = TRUE)
  app$wait_for_idle()

  # Activating a panel from the listener re-enters the handler synchronously, so
  # the nested activation must be the one `_active-panel` ends up reporting. A
  # tab activates on pointerdown, which is a consumer's client-side route to it.
  app$run_js(
    "document.addEventListener('dockview:active-panel', function(e) {
      if (e.detail.id !== 'b') return;
      document
        .getElementById(e.detail.dock + '-tab-c')
        .dispatchEvent(new PointerEvent('pointerdown', {bubbles: true}));
    });"
  )

  app$click("select_b")
  app$wait_for_idle()

  expect_identical(app$get_value(input = "event_panel"), "c")
  expect_identical(app$get_value(input = "dock_active-panel"), "c")
})
