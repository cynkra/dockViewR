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

test_that("add_panel works", {
  session$input[["dock_state"]] <- test_dock
  expect_snapshot(
    error = TRUE,
    {
      # Duplicated id
      add_panel(
        "dock",
        panel(id = "test", "plop", "Panel 1"),
        session = session
      )

      # Wrong position names
      add_panel(
        "dock",
        panel(
          id = 4,
          "plop",
          "Panel 4",
          position = list(pouet = 3, plop = "test")
        ),
        session = session
      )

      # Wrong direction value
      add_panel(
        "dock",
        panel(
          id = 4,
          "plop",
          "Panel 4",
          position = list(referencePanel = 1, direction = "top")
        ),
        session = session
      )

      # Wrong referencePanel
      add_panel(
        "dock",
        panel(
          id = 4,
          "plop",
          "Panel 4",
          position = list(referencePanel = 10, direction = "above")
        ),
        session = session
      )
    }
  )

  add_panel(
    "dock",
    panel(
      id = 4,
      "plop",
      "Panel 4",
      position = list(referencePanel = "test", direction = "above")
    ),
    session = session
  )
  expect_identical(session$lastCustomMessage$type, "dock_add-panel")
  expect_type(session$lastCustomMessage$message, "list")
  expect_named(
    session$lastCustomMessage$message,
    c("id", "title", "inactive", "remove", "content", "position")
  )
  expect_identical(session$lastCustomMessage$message$id, "4")
  expect_type(session$lastCustomMessage$message$position, "list")
  expect_identical(
    session$lastCustomMessage$message$position$referencePanel,
    "test"
  )
  expect_identical(
    session$lastCustomMessage$message$position$direction,
    "above"
  )
})

test_that("add_panel app works", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "add_panel")

  app <- AppDriver$new(
    appdir,
    name = "add_panel",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$expect_values(input = c("obs", "variable"), output = FALSE, export = TRUE)
  app$click("btn")
  app$set_inputs(dist = "norm")
  app$wait_for_idle()
  app$expect_values(
    input = c("obs", "variable", "dist"),
    output = FALSE,
    export = TRUE
  )
  app$set_inputs(dist = "unif")
  app$wait_for_idle()
  app$expect_values(
    input = c("obs", "variable", "dist"),
    output = FALSE,
    export = TRUE
  )
})

test_that("add_panel with + leftheader button works", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()

  appdir <- system.file(
    package = "dockViewR",
    "examples",
    "replace_panel_content"
  )

  app <- AppDriver$new(
    appdir,
    name = "replace_panel_content",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$expect_values(
    input = c("obs", "selimp"),
    output = FALSE,
    export = TRUE
  )
  app$click(selector = ".dv-left-actions-container .fas.fa-plus")
  app$set_inputs(
    selinp = app$get_js(
      "Object
        .getOwnPropertyNames(
          Shiny
            .shinyapp
            .$inputValues['dock_state']['panels']
        )
      "
    )[[
      2
    ]]
  )
  app$click("insert")
  Sys.sleep(2)
  app$expect_values(
    input = c("obs", "dist", "selimp"),
    output = FALSE,
    export = TRUE
  )
  app$set_inputs(dist = "unif")
  Sys.sleep(2)
  app$expect_values(
    input = c("obs", "dist", "selimp"),
    output = FALSE,
    export = TRUE
  )
})
