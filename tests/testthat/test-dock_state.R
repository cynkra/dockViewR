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

test_that("dock state", {
  session$input[["dock_state"]] <- test_dock
  dock_proxy <- dock_view_proxy("dock", session = session)

  dock <- get_dock(dock_proxy)
  expect_type(dock, "list")
  expect_named(dock, c("grid", "panels", "activeGroup"))

  panels <- get_panels(dock_proxy)
  expect_type(panels, "list")
  expect_length(panels, 3)

  panels_ids <- get_panels_ids(dock_proxy)
  expect_identical(names(panels), panels_ids)

  active_group <- get_active_group(dock_proxy)
  expect_identical(active_group, dock[["activeGroup"]])

  grid <- get_grid(dock_proxy)
  expect_type(grid, "list")
  expect_named(grid, c("root", "width", "height", "orientation"))

  groups <- get_groups(dock_proxy)
  expect_type(groups, "list")
  expect_length(groups, 2)

  groups_ids <- get_groups_ids(dock_proxy)
  expect_length(groups_ids, length(groups))

  groups_panels <- get_groups_panels(dock_proxy)
  expect_length(groups_panels, length(groups))
  expect_length(groups_panels[[1]], 2)
  expect_length(groups_panels[[2]], 1)
  expect_named(groups_panels, groups_ids)

  active_panel <- get_active_panel(dock_proxy)
  expect_identical(active_panel, "3")

  active_views <- get_active_views(dock_proxy)
  expect_length(active_views, length(groups))

  save_dock(dock_proxy)
  expect_identical(session$lastCustomMessage$type, "dock_save-state")

  expect_error(restore_dock(dock_proxy, c()))
  restore_dock(dock_proxy, test_dock)
  expect_identical(session$lastCustomMessage$type, "dock_restore-state")
})

test_that("dock state app works", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "serialise")

  app <- AppDriver$new(
    appdir,
    name = "dock_state",
    seed = 121,
    height = 752,
    width = 1211
  )

  Sys.sleep(2)
  app$expect_values(input = "obs", output = FALSE, export = TRUE)
  app$click("save")
  app$run_js(
    "HTMLWidgets.find('#dock').getWidget().component.api.getPanel('test').api.close()"
  )
  app$wait_for_idle()
  app$click("save")
  app$expect_values(input = "obs", output = FALSE, export = TRUE)
  app$click("restore")
  app$expect_values(input = "obs", output = FALSE, export = TRUE)
})
