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

test_that("edge_group constructor works", {
  eg <- edge_group(
    id = "left-edge",
    position = "left",
    initial_size = 220,
    minimum_size = 150,
    collapsed = FALSE
  )
  expect_s3_class(eg, "dock_edge_group")
  expect_true(is_edge_group(eg))
  expect_identical(eg$id, "left-edge")
  expect_identical(eg$position, "left")
  expect_identical(eg$options$initialSize, 220)
  expect_identical(eg$options$minimumSize, 150)
  expect_identical(eg$options$id, "left-edge")
  # collapsedSize is NULL and must be dropped
  expect_null(eg$options$collapsedSize)
  expect_named(
    eg$options,
    c("id", "initialSize", "minimumSize", "collapsed")
  )
})

test_that("edge_group input validation", {
  expect_snapshot(
    error = TRUE,
    {
      edge_group(id = "x", position = "diagonal")
      edge_group(id = "", position = "left")
      edge_group(id = "x", position = "left", collapsed = "no")
    }
  )
})

test_that("check_edge_groups validates list shape and uniqueness", {
  expect_snapshot(
    error = TRUE,
    {
      check_edge_groups("not a list")
      check_edge_groups(list("not an edge group"))
      check_edge_groups(list(
        edge_group(id = "a", position = "left"),
        edge_group(id = "a", position = "right")
      ))
      check_edge_groups(list(
        edge_group(id = "a", position = "left"),
        edge_group(id = "b", position = "left")
      ))
    }
  )
  expect_invisible(check_edge_groups(list()))
})

test_that("dock_view accepts edge_groups and forwards them", {
  w <- dock_view(
    panels = list(panel(id = "1", title = "p", content = "x")),
    edge_groups = list(
      edge_group(id = "left-edge", position = "left", initial_size = 200)
    )
  )
  expect_s3_class(w, "dockview")
  expect_length(w$x$edgeGroups, 1)
  expect_identical(w$x$edgeGroups[[1]]$position, "left")
  expect_identical(w$x$edgeGroups[[1]]$options$id, "left-edge")
})

test_that("dock_view rejects malformed edge_groups", {
  expect_snapshot(
    error = TRUE,
    dock_view(
      panels = list(panel(id = "1", title = "p", content = "x")),
      edge_groups = list("not an edge group")
    )
  )
})

test_that("add_edge_group works", {
  dock_proxy <- dock_view_proxy("dock", session = session)
  expect_snapshot(
    error = TRUE,
    {
      add_edge_group("dock", edge_group(id = "x", position = "left"))
      add_edge_group(dock_proxy, edge_group = list(id = "x"))
    }
  )

  add_edge_group(
    dock_proxy,
    edge_group(id = "left-edge", position = "left", initial_size = 220)
  )
  expect_identical(session$lastCustomMessage$type, "dock_add-edge-group")
  expect_type(session$lastCustomMessage$message, "list")
  expect_identical(session$lastCustomMessage$message$position, "left")
  expect_identical(
    session$lastCustomMessage$message$options$id,
    "left-edge"
  )
  expect_identical(
    session$lastCustomMessage$message$options$initialSize,
    220
  )
})

test_that("remove_edge_group works", {
  dock_proxy <- dock_view_proxy("dock", session = session)
  expect_snapshot(
    error = TRUE,
    remove_edge_group(dock_proxy, position = "middle")
  )
  remove_edge_group(dock_proxy, position = "right")
  expect_identical(session$lastCustomMessage$type, "dock_rm-edge-group")
  expect_identical(session$lastCustomMessage$message$position, "right")
})

test_that("set_edge_group_visible works", {
  dock_proxy <- dock_view_proxy("dock", session = session)
  expect_snapshot(
    error = TRUE,
    {
      set_edge_group_visible(dock_proxy, position = "middle", visible = TRUE)
      set_edge_group_visible(dock_proxy, position = "left", visible = "yes")
    }
  )
  set_edge_group_visible(dock_proxy, position = "top", visible = FALSE)
  expect_identical(
    session$lastCustomMessage$type,
    "dock_set-edge-group-visible"
  )
  expect_identical(session$lastCustomMessage$message$position, "top")
  expect_false(session$lastCustomMessage$message$visible)
})

test_that("edge_groups app works", {
  skip_on_cran()
  appdir <- system.file(package = "dockViewR", "examples", "edge_groups")
  skip_if(!nzchar(appdir))

  app <- AppDriver$new(
    appdir,
    name = "edge_groups",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)

  app$click("add")
  app$wait_for_idle()
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)

  app$click("hide_left")
  app$wait_for_idle()
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)

  app$click("show_left")
  app$wait_for_idle()
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)

  app$click("rm")
  app$wait_for_idle()
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)
})
