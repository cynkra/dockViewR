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

test_that("remove_panel works", {
  session$input[["dock_state"]] <- test_dock
  dock_proxy <- dock_view_proxy("dock", session = session)
  remove_panel(dock_proxy, id = "test")
  expect_identical(session$lastCustomMessage$type, "dock_rm-panel")
  expect_identical(session$lastCustomMessage$message, "test")
})

test_that("remove_panel app works", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "remove_panel")

  app <- AppDriver$new(
    appdir,
    name = "remove_panel",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$expect_values(
    input = c("obs", "variable", "selimp"),
    output = FALSE,
    export = TRUE
  )
  app$set_inputs(selinp = "2")
  app$click("btn")
  app$wait_for_idle()
  app$expect_values(
    input = c("obs", "variable", "selimp"),
    output = FALSE,
    export = TRUE
  )
  app$set_inputs(obs = 731)
  app$wait_for_idle()
  app$expect_values(
    input = c("obs", "variable", "selimp"),
    output = FALSE,
    export = TRUE
  )
  app$set_inputs(selinp = "3")
  app$click("btn")
  app$wait_for_idle()
  app$expect_values(
    input = c("obs", "selimp"),
    output = FALSE,
    export = TRUE
  )

  app$click("btn")
  app$click("btn")
  app$expect_values(
    input = c("obs", "selimp"),
    output = FALSE,
    export = TRUE
  )
})
