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
  # `_state` is held until the ResizeObserver reports real geometry, and every
  # exported value below derives from it.
  app$wait_for_value(input = "dock_state")

  # A panel naming an edge group in `referenceGroup` lands in the rail, and the
  # rail is reported like any other group even though it is serialised beside
  # the grid rather than inside it.
  expect_setequal(app$get_value(export = "groups_ids"), c("1", "left-edge"))
  expect_setequal(app$get_value(export = "panels_ids"), c("main", "tree"))
  expect_identical(
    app$get_value(export = "groups_panels")[["left-edge"]],
    list("tree")
  )
  expect_identical(app$get_value(export = "edge_positions"), "left")
  expect_true(app$get_value(export = "left_visible"))
  # No right-hand rail yet, so visibility is unknown rather than FALSE.
  expect_null(app$get_value(export = "right_visible"))

  # Asserted directly rather than left to the snapshot below: a rail holding
  # focus used to make this NULL, which is the headline of the change, and a
  # snapshot carries it inside a blob that snapshot_accept() can rewrite.
  expect_identical(app$get_value(export = "active_group"), "left-edge")
  expect_identical(app$get_value(export = "active_panel"), "tree")
  expect_identical(
    app$get_value(export = "active_views")[["left-edge"]],
    "tree"
  )
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)

  # Adding a rail from the server surfaces in `_state` without an explicit
  # save: addEdgeGroup adds a dockview group, so the gesture flush carries it.
  app$click("add")
  app$wait_for_idle()
  expect_setequal(
    app$get_value(export = "edge_positions"),
    c("left", "right")
  )
  # The new rail is empty, so it serialises a group node with no `activeView`.
  # That is the NA_character_ branch of get_active_views(): the rail must be
  # absent from the result rather than present as NA.
  views <- app$get_value(export = "active_views")
  expect_false("right-edge" %in% names(views))
  expect_identical(views[["left-edge"]], "tree")
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)

  # Toggling visibility fires no dockview event, so the handler persists
  # explicitly; without that `is_edge_group_visible()` would go stale.
  app$click("hide_left")
  app$wait_for_idle()
  expect_false(app$get_value(export = "left_visible"))

  app$click("show_left")
  app$wait_for_idle()
  expect_true(app$get_value(export = "left_visible"))

  app$click("rm")
  app$wait_for_idle()
  expect_identical(app$get_value(export = "edge_positions"), "left")
  app$expect_values(input = FALSE, output = FALSE, export = TRUE)

  app$stop()
})

test_that("a rail survives a save and restore round-trip", {
  skip_on_cran()
  appdir <- system.file(package = "dockViewR", "examples", "edge_groups")
  skip_if(!nzchar(appdir))

  app <- AppDriver$new(
    appdir,
    name = "edge_groups_roundtrip",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$wait_for_value(input = "dock_state")

  # Save the {left rail} layout, then diverge from it by adding a right rail.
  app$click("save")
  app$wait_for_idle()
  app$click("add")
  app$wait_for_idle()
  expect_setequal(
    app$get_value(export = "edge_positions"),
    c("left", "right")
  )

  # dockview 8 carries edge group size, visibility and panel contents through
  # toJSON / fromJSON, so the restore has to put the dock back to one rail
  # holding its panel -- no dockViewR-side bookkeeping involved.
  app$click("restore")
  app$wait_for_idle()

  expect_identical(app$get_value(export = "edge_positions"), "left")
  expect_identical(
    app$get_value(export = "groups_panels")[["left-edge"]],
    list("tree")
  )
  expect_true(app$get_value(export = "left_visible"))

  app$stop()
})

test_that("collapsing a rail reaches `_state`", {
  skip_on_cran()
  appdir <- system.file(package = "dockViewR", "examples", "edge_groups")
  skip_if(!nzchar(appdir))

  app <- AppDriver$new(
    appdir,
    name = "edge_group_collapse",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$wait_for_value(input = "dock_state")

  # Clicking the active tab of a rail toggles its collapsed state and changes
  # nothing else -- no move, no add, no activation change -- so `_state` keeps
  # up only if the collapse is subscribed in its own right. A click that lands
  # on some other tab does change the active panel, and would flush for that
  # reason whether or not the collapse is watched.
  toggle_rail <- function() {
    app$run_js(
      "HTMLWidgets.find('#dock').getWidget().groups
         .find((g) => g.api.location.type === 'edge')
         .element.querySelector('.dv-tab').click();"
    )
    app$wait_for_idle()
  }

  rail_collapsed <- function() {
    isTRUE(unlist(app$get_js(
      "HTMLWidgets.find('#dock').getWidget().getEdgeGroup('left').isCollapsed()"
    )))
  }

  state_collapsed <- function() {
    isTRUE(app$get_value(input = "dock_state")$edgeGroups$left$collapsed)
  }

  expect_false(rail_collapsed())
  expect_false(state_collapsed())

  toggle_rail()
  expect_true(rail_collapsed())
  expect_true(state_collapsed())

  toggle_rail()
  expect_false(rail_collapsed())
  expect_false(state_collapsed())

  # A restore empties a standing rail rather than rebuilding it, so the rail
  # that comes back is the one already subscribed. Were it rebuilt instead, the
  # collapse would go unwatched again from here on.
  app$click("save")
  app$wait_for_idle()
  app$click("restore")
  app$wait_for_idle()

  toggle_rail()
  expect_true(rail_collapsed())
  expect_true(state_collapsed())

  app$stop()
})

test_that("set_edge_group_collapsed drives a rail from the server", {
  skip_on_cran()
  appdir <- system.file(package = "dockViewR", "examples", "edge_groups")
  skip_if(!nzchar(appdir))

  app <- AppDriver$new(
    appdir,
    name = "edge_group_collapsed_setter",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()
  app$wait_for_value(input = "dock_state")

  # The sibling test above covers the user gesture and the `_state` flush behind
  # it. This one covers the server-side pair: the proxy call reaching
  # collapse() / expand(), and is_edge_group_collapsed() reading it back.
  rail_collapsed <- function() {
    isTRUE(unlist(app$get_js(
      "HTMLWidgets.find('#dock').getWidget().getEdgeGroup('left').isCollapsed()"
    )))
  }

  expect_false(rail_collapsed())
  expect_false(app$get_value(export = "left_collapsed"))

  app$click("collapse_left")
  app$wait_for_idle()
  expect_true(rail_collapsed())
  expect_true(app$get_value(export = "left_collapsed"))

  app$click("expand_left")
  app$wait_for_idle()
  expect_false(rail_collapsed())
  expect_false(app$get_value(export = "left_collapsed"))

  # Collapsed and invisible are independent states, which is the whole reason
  # both setters exist: hiding a collapsed rail leaves it collapsed.
  app$click("collapse_left")
  app$wait_for_idle()
  app$click("hide_left")
  app$wait_for_idle()
  expect_false(app$get_value(export = "left_visible"))
  expect_true(app$get_value(export = "left_collapsed"))

  app$stop()
})

test_that("set_edge_group_collapsed works", {
  dock_proxy <- dock_view_proxy("dock", session = session)
  expect_snapshot(error = TRUE, {
    set_edge_group_collapsed(dock_proxy, position = "middle", collapsed = TRUE)
    set_edge_group_collapsed(dock_proxy, position = "left", collapsed = "yes")
    set_edge_group_collapsed(dock_proxy, position = "left", collapsed = NA)
  })

  set_edge_group_collapsed(dock_proxy, position = "top", collapsed = TRUE)
  expect_identical(
    session$lastCustomMessage$type,
    "dock_set-edge-group-collapsed"
  )
  expect_identical(session$lastCustomMessage$message$position, "top")
  expect_true(session$lastCustomMessage$message$collapsed)
})
