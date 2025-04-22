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

test_that("move group works", {
  session$input[["dock_state"]] <- test_dock

  expect_snapshot(error = TRUE, {
    move_group("dock", "test", 2, session = session)
    move_group("dock", 1, "test", session = session)
    move_group("dock", 1, 1, session = session)
    move_group("dock", 1, 2, position = "plop", session = session)
  })

  move_group("dock", 1, 2, position = "right", session = session)
  expect_identical(session$lastCustomMessage$type, "dock_move-group")
  expect_type(session$lastCustomMessage$message, "list")
  expect_identical(session$lastCustomMessage$message$id, 1)
  expect_type(session$lastCustomMessage$message$options, "list")
  expect_identical(session$lastCustomMessage$message$options$to, 2)
  expect_identical(session$lastCustomMessage$message$options$position, "right")
})

test_that("move_group app works", {
  appdir <- system.file(package = "dockViewR", "examples", "move_group")

  app <- AppDriver$new(
    appdir,
    name = "move_group",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)
  app$click("move")
  app$wait_for_idle()
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)
})
