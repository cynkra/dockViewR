library(shinytest2)

session <- as.environment(
  list(
    ns = identity,
    input = list(),
    sendCustomMessage = function(type, message) {
      session$lastCustomMessage <- list(
        type = type,
        message = message
      )
    }
  )
)

test_that("update_dock_view works", {
  # Invalid shiny session
  expect_snapshot(error = TRUE, {
    update_dock_view("dock", "test")
  })

  update_dock_view("dock", list(theme = "dark"), session = session)
  expect_identical(session$lastCustomMessage$type, "dock_update-options")
  expect_identical(session$lastCustomMessage$message, list(theme = "dark"))
})

test_that("update theme app works", {
  appdir <- system.file(package = "dockViewR", "examples", "update_theme")

  app <- AppDriver$new(
    appdir,
    name = "update-theme",
    seed = 121,
    height = 752,
    width = 1211
  )
  Sys.sleep(2)
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)
  # Classic set_inputs or click fails ...
  app$run_js("$('#app_theme').attr('mode', 'light')")
  Sys.sleep(2)
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)
})
