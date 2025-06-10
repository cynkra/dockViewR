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

test_that("select_panel works", {
  session$input[["dock_state"]] <- test_dock
  expect_snapshot(
    error = TRUE,
    {
      # Wrong id
      select_panel(
        "dock",
        "blabla",
        session = session
      )
    }
  )

  select_panel(
    "dock",
    "2",
    session = session
  )
  expect_identical(session$lastCustomMessage$type, "dock_select-panel")
  expect_type(session$lastCustomMessage$message, "list")
  expect_named(
    session$lastCustomMessage$message,
    c("id")
  )
  expect_identical(session$lastCustomMessage$message$id, "2")
})

test_that("select_panel app works", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "select_panel")

  app <- AppDriver$new(
    appdir,
    name = "select_panel",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
  app$set_inputs(selected = "3")
  app$wait_for_idle()
  app$expect_values(
    input = c("obs", "variable"),
    output = FALSE,
    export = TRUE
  )
})
