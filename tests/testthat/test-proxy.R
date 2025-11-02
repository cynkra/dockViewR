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
  dock_proxy <- dock_view_proxy("dock", session = session)
  expect_snapshot(
    error = TRUE,
    {
      # No proxy
      add_panel("dock", panel(id = 4, "plop", "Panel 4"))

      # Wrong position names
      add_panel(
        dock_proxy,
        panel(
          id = 4,
          "plop",
          "Panel 4",
          position = list(pouet = 3, plop = "test")
        )
      )

      # Wrong direction value
      add_panel(
        dock_proxy,
        panel(
          id = 4,
          "plop",
          "Panel 4",
          position = list(referencePanel = 1, direction = "top")
        )
      )
    }
  )

  add_panel(
    dock_proxy,
    panel(
      id = 4,
      "plop",
      "Panel 4",
      position = list(referencePanel = "test", direction = "above")
    )
  )
  expect_identical(session$lastCustomMessage$type, "dock_add-panel")
  expect_type(session$lastCustomMessage$message, "list")
  expect_named(
    session$lastCustomMessage$message$panel,
    c("id", "title", "inactive", "remove", "content", "style", "position")
  )
  expect_identical(session$lastCustomMessage$message$panel$id, "4")
  expect_type(session$lastCustomMessage$message$panel$position, "list")
  expect_identical(
    session$lastCustomMessage$message$panel$position$referencePanel,
    "test"
  )
  expect_identical(
    session$lastCustomMessage$message$panel$position$direction,
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

  # Try add the same panel (will error)
  app$click("btn")
  app$wait_for_idle()
  app$expect_values(
    input = c("obs", "variable", "dist"),
    output = FALSE,
    export = TRUE
  )
})

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

test_that("move group 2 works", {
  session$input[["dock_state"]] <- test_dock
  dock_proxy <- dock_view_proxy("dock", session = session)

  expect_snapshot(error = TRUE, {
    move_group2(dock_proxy, "test", "test")
    move_group2(dock_proxy, "test", 2, position = "plop")
  })

  move_group2(dock_proxy, "test", 2, position = "right")
  expect_identical(session$lastCustomMessage$type, "dock_move-group2")
  expect_type(session$lastCustomMessage$message, "list")
  expect_identical(session$lastCustomMessage$message$id, "test")
  expect_type(session$lastCustomMessage$message$options, "list")
  expect_identical(session$lastCustomMessage$message$options$to, "2")
  expect_identical(session$lastCustomMessage$message$options$position, "right")
})

test_that("move_group2 app works", {
  appdir <- system.file(package = "dockViewR", "examples", "move_group2")

  app <- AppDriver$new(
    appdir,
    name = "move_group2",
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

test_that("select_panel works", {
  session$input[["dock_state"]] <- test_dock
  dock_proxy <- dock_view_proxy("dock", session = session)
  select_panel(dock_proxy, "2")
  expect_identical(session$lastCustomMessage$type, "dock_select-panel")
  expect_identical(session$lastCustomMessage$message, "2")
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

test_that("update_dock_view works", {
  dock_proxy <- dock_view_proxy("dock", session = session)
  update_dock_view(dock_proxy, list(theme = "dark"))
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

test_that("set_panel_title works", {
  session$input[["dock_state"]] <- test_dock
  dock_proxy <- dock_view_proxy("dock", session = session)
  set_panel_title(dock_proxy, id = "test", title = "New Title")
  expect_identical(session$lastCustomMessage$type, "dock_set-panel-title")
  expect_type(session$lastCustomMessage$message, "list")
  expect_identical(session$lastCustomMessage$message$id, "test")
  expect_identical(session$lastCustomMessage$message$title, "New Title")
})

test_that("set_panel_title app works", {
  skip_on_cran()
  appdir <- system.file(package = "dockViewR", "examples", "set_panel_title")
  app <- AppDriver$new(
    appdir,
    name = "set_panel_title",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$expect_values(input = FALSE, output = TRUE, export = TRUE)
  app$set_inputs(panel_title = "My new title")
  app$wait_for_idle()
  app$expect_values(input = "title", output = TRUE, export = TRUE)
})
