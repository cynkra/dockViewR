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
  expect_snapshot(
    error = TRUE,
    {
      # Wrong id
      move_panel("dock", 4, session = session)
      # Wrong position
      move_panel(
        "dock",
        id = "test",
        index = 3,
        position = "testposition",
        session = session
      )
      # Index error
      move_panel("dock", 3, session = session)
      move_panel("dock", 3, index = -2, session = session)
      move_panel("dock", 3, index = 20, session = session)
      # Group does not exist
      move_panel("dock", 3, group = 4, session = session)
    }
  )

  move_panel("dock", id = "test", index = 3, session = session)
  expect_identical(session$lastCustomMessage$type, "dock_move-panel")
  expect_type(session$lastCustomMessage$message, "list")
  expect_length(session$lastCustomMessage$message, 2)
  expect_identical(session$lastCustomMessage$message$id, "test")
  expect_identical(session$lastCustomMessage$message$options$index, 2)

  move_panel(
    "dock",
    id = "test",
    group = 3,
    position = "bottom",
    session = session
  )
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
