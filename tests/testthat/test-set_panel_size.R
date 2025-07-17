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

test_that("set_panel_size works", {
  session$input[["dock_state"]] <- test_dock
  expect_snapshot(
    error = TRUE,
    {
      # Wrong id
      set_panel_size(
        "dock",
        "blabla",
        height = 400,
        session = session
      )
    }
  )

  set_panel_size(
    "dock",
    "3",
    height = 400,
    session = session
  )
  expect_identical(session$lastCustomMessage$type, "dock_resize-panel")
  expect_type(session$lastCustomMessage$message, "list")
  expect_named(
    session$lastCustomMessage$message,
    c("id", "options")
  )
  expect_identical(session$lastCustomMessage$message$id, "3")
  expect_identical(session$lastCustomMessage$message$options$height, 400)
})

test_that("set_panel_size app works", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "resize_panel")

  app <- AppDriver$new(
    appdir,
    name = "set_panel_size",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
  app$set_inputs(panel_height = 100)
  app$wait_for_idle()
  app$expect_values(
    input = c("obs", "variable"),
    output = FALSE,
    export = TRUE
  )
})
