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
  dock_proxy <- dock_view_proxy("dock", session = session)

  expect_snapshot(error = TRUE, {
    # from and to are the same
    move_group(dock_proxy, 1, 1)
    move_group(dock_proxy, 1, 2, position = "plop")
  })

  move_group(dock_proxy, 1, 2, position = "right")
  expect_identical(session$lastCustomMessage$type, "dock_move-group")
  expect_type(session$lastCustomMessage$message, "list")
  expect_identical(session$lastCustomMessage$message$id, "1")
  expect_type(session$lastCustomMessage$message$options, "list")
  expect_identical(session$lastCustomMessage$message$options$to, "2")
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
