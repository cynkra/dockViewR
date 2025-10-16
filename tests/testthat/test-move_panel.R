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

test_that("move_panel works", {
  session$input[["dock_state"]] <- test_dock
  dock_proxy <- dock_view_proxy("dock", session = session)
  expect_snapshot(
    error = TRUE,
    {
      # Wrong position
      move_panel(
        dock_proxy,
        id = "test",
        index = 3,
        position = "testposition"
      )
    }
  )

  move_panel(dock_proxy, id = "test", index = 3)
  expect_identical(session$lastCustomMessage$type, "dock_move-panel")
  expect_type(session$lastCustomMessage$message, "list")
  expect_length(session$lastCustomMessage$message, 2)
  expect_identical(session$lastCustomMessage$message$id, "test")
  expect_identical(session$lastCustomMessage$message$options$index, 3)

  move_panel(
    dock_proxy,
    id = "test",
    group = 3,
    position = "bottom"
  )

  expect_identical(session$lastCustomMessage$type, "dock_move-panel")
  expect_type(session$lastCustomMessage$message, "list")
  expect_length(session$lastCustomMessage$message, 2)
  expect_identical(session$lastCustomMessage$message$id, "test")
  expect_identical(session$lastCustomMessage$message$options$group, "3")
  expect_identical(session$lastCustomMessage$message$options$position, "bottom")
})

test_that("move_panel app works", {
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
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
  app$click("move")
  app$wait_for_idle()
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
  app$click("move2")
  app$wait_for_idle()
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
})
