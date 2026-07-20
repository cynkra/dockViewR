library(shinytest2)

test_that("_state-source tags programmatic vs user layout changes", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state_source")

  app <- AppDriver$new(
    appdir,
    name = "state_source",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  # The initial layout is produced by the server (the panels passed to
  # dock_view()), not a user gesture.
  expect_identical(app$get_value(input = "dock_state-source"), "server")

  # Stash the {a, b} layout to restore later.
  app$click("save")

  # A programmatic apply (add_panel -> _add-panel handler) is tagged server.
  app$click("add")
  app$wait_for_idle()
  expect_identical(app$get_value(input = "dock_state-source"), "server")
  expect_true("c" %in% app$get_value(export = "panel_ids"))

  # A programmatic move stays server -- its dockview events coalesce into one
  # flush that runs inside the op's provenance window.
  app$click("move")
  app$wait_for_idle()
  expect_identical(app$get_value(input = "dock_state-source"), "server")

  # A restore (fromJSON -- the issue's headline case) is tagged server across
  # its whole teardown/rebuild cascade, not just the first frame.
  app$click("restore")
  app$wait_for_idle()
  expect_identical(app$get_value(input = "dock_state-source"), "server")
  expect_false("c" %in% app$get_value(export = "panel_ids"))

  # A genuine user gesture (closing a panel, as a tab-X click would) is tagged
  # client -- the next layout change after a server apply is not mis-attributed.
  app$run_js(
    "HTMLWidgets.find('#dock').getWidget().component.api.getPanel('a').api.close()"
  )
  app$wait_for_idle()
  expect_identical(app$get_value(input = "dock_state-source"), "client")
})

test_that("_state tracks a settled container resize, tagged client", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state_source")

  app <- AppDriver$new(
    appdir,
    name = "state_source_resize",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  grid_width <- function() {
    unlist(app$get_js(
      "(function(){var s=Shiny.shinyapp.$inputValues['dock_state'];return s && s.grid ? s.grid.width : 0;})()"
    ))
  }
  before <- grid_width()

  # A container / window resize changes the layout but has no gesture and no
  # event-driven end, so it is debounced and persisted once it settles. `_state`
  # must reflect it -- consumers read the input directly -- and it is tagged
  # client: environmental, not server-initiated. The debounced emit produces no
  # Shiny activity until it fires, so poll for it rather than wait_for_idle.
  app$set_window_size(width = 820, height = 700)
  for (i in 1:30) {
    Sys.sleep(0.1)
    if (identical(app$get_value(input = "dock_state-source"), "client")) break
  }

  expect_identical(app$get_value(input = "dock_state-source"), "client")
  expect_gt(grid_width(), 0)
  expect_false(identical(grid_width(), before))
})

test_that("maximizing a group emits a bounded number of `_state` updates", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state_source")

  app <- AppDriver$new(
    appdir,
    name = "state_source_maximize",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  # While a group is maximized, `api.toJSON()` (read by saveDock on each flush)
  # re-fires onDidMaximizedGroupChange. Without the re-entrancy guard the persist
  # feeds itself thousands of times; count the emits and assert it stays a handful.
  app$run_js(
    "var o = Shiny.setInputValue;
     Shiny.setInputValue = function (n, v, p) {
       if (typeof n === 'string' && /_state$/.test(n)) window.__c = (window.__c || 0) + 1;
       return o.apply(this, arguments);
     };
     window.__c = 0;
     HTMLWidgets.find('#dock').getWidget().component.api.groups[0].api.maximize();"
  )
  app$wait_for_idle()

  expect_lt(unlist(app$get_js("window.__c")), 10)
})

test_that("set_panel_title persists the new title, tagged server", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state_source")

  app <- AppDriver$new(
    appdir,
    name = "state_source_settitle",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  # setTitle fires no allowlisted gesture, so without an explicit persist the new
  # title never reaches `_state` with server provenance. Capture the source tags:
  # the server-driven title save must be among them.
  app$run_js(
    "window.__src = [];
     var o = Shiny.setInputValue;
     Shiny.setInputValue = function (n, v, p) {
       if (typeof n === 'string' && /_state-source$/.test(n)) window.__src.push(v);
       return o.apply(this, arguments);
     };"
  )
  app$click("settitle")
  app$wait_for_idle()

  # exactly one emit, tagged server -- the explicit persist. No stray client from
  # a lingering initial one-shot (which this PR replaced with the seeding branch).
  expect_equal(unlist(app$get_js("window.__src.length")), 1)
  expect_identical(unlist(app$get_js("window.__src[0]")), "server")
  expect_true(unlist(app$get_js(
    "(JSON.stringify(Shiny.shinyapp.$inputValues['dock_state'] || {})).indexOf('Renamed') >= 0"
  )))
})

test_that("initial layout is captured with real pixels, tagged server", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state_source")

  app <- AppDriver$new(
    appdir,
    name = "state_source_initial",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  # The synchronous render captures a zero-sized grid; the ResizeObserver's first
  # real-size observation completes it, server-tagged. Without that, `_state`
  # carries a zero grid until the first gesture (which then mis-tags it client).
  expect_identical(app$get_value(input = "dock_state-source"), "server")
  expect_gt(
    unlist(app$get_js("Shiny.shinyapp.$inputValues['dock_state'].grid.width")),
    0
  )
})

test_that("a container-only resize re-fits widgets without looping", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state_source")

  app <- AppDriver$new(
    appdir,
    name = "state_source_container_resize",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  app$run_js(
    "window.__rd = 0;
     var od = window.dispatchEvent.bind(window);
     window.dispatchEvent = function (e) {
       if (e && e.type === 'resize') window.__rd++;
       return od(e);
     };
     var o = Shiny.setInputValue;
     Shiny.setInputValue = function (n, v, p) {
       if (typeof n === 'string' && /_state$/.test(n)) window.__c = (window.__c || 0) + 1;
       return o.apply(this, arguments);
     };"
  )

  # A container-only resize (no window resize) must still re-fit embedded
  # widgets -- they get no native resize event otherwise -- and must not reform
  # the onDidLayoutChange -> resize -> onDidLayoutChange loop.
  app$run_js(
    "window.__rd = 0; window.__c = 0;
     document.getElementById('dock').style.width = '620px';"
  )
  Sys.sleep(0.5)
  app$wait_for_idle()

  expect_gte(unlist(app$get_js("window.__rd")), 1)
  expect_lt(unlist(app$get_js("window.__c")), 3)
})

test_that("container listeners are torn down on re-render", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state_source")

  app <- AppDriver$new(
    appdir,
    name = "state_source_teardown",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  app$run_js(
    "var o = Shiny.setInputValue;
     Shiny.setInputValue = function (n, v, p) {
       if (typeof n === 'string' && /_state$/.test(n)) window.__c = (window.__c || 0) + 1;
       return o.apply(this, arguments);
     };"
  )

  # A reactive re-render adds a fresh sash-pointerup listener each time. Without
  # teardown they accumulate, so one sash release fans out to one emit per render;
  # with teardown exactly one listener is live.
  for (i in 1:3) {
    app$click("rerender")
    app$wait_for_idle()
  }
  app$run_js(
    "window.__c = 0;
     var s = document.querySelector('.dv-sash');
     if (s) s.dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));"
  )
  Sys.sleep(0.2)
  app$wait_for_idle()

  expect_equal(unlist(app$get_js("window.__c")), 1)
})

test_that("re-init and restore surface only a settled `_state`, never a transient", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state_source")

  app <- AppDriver$new(
    appdir,
    name = "state_source_hygiene",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  # Capture the shape of every `_state` emission: panel count, grid width, root
  # child count. A settled frame has panels and real geometry; an empty grid or a
  # zero-sized mid-build structure -- the transients this gates out -- does not.
  app$run_js(
    "window.__seq = [];
     var o = Shiny.setInputValue;
     Shiny.setInputValue = function (n, v, p) {
       if (typeof n === 'string' && /dock_state$/.test(n)) {
         window.__seq.push({
           np: (v && v.panels) ? Object.keys(v.panels).length : 0,
           gw: (v && v.grid) ? v.grid.width : 0,
           rc: (v && v.grid && v.grid.root && v.grid.root.data) ? v.grid.root.data.length : 0
         });
       }
       return o.apply(this, arguments);
     };"
  )

  count_js <- "window.__seq.length"
  transient_js <- "window.__seq.some(function (f) { return !f.np || !f.gw || !f.rc; })"

  # A re-render tears the widget down and rebuilds it -- the path that used to
  # leak an empty grid, then a zero-sized structure, before the settled layout.
  app$run_js("window.__seq = [];")
  app$click("rerender")
  app$wait_for_idle()
  expect_gt(unlist(app$get_js(count_js)), 0)
  expect_false(unlist(app$get_js(transient_js)))

  # A restore (fromJSON) tears down and rebuilds again. Only the settled restored
  # layout surfaces -- no empty or intermediate frame from the cascade escapes,
  # and the restore is not swallowed either.
  app$click("save")
  app$click("add")
  app$wait_for_idle()
  app$run_js("window.__seq = [];")
  app$click("restore")
  app$wait_for_idle()
  expect_gt(unlist(app$get_js(count_js)), 0)
  expect_false(unlist(app$get_js(transient_js)))

  # The restored layout is exactly the saved {a, b}.
  expect_setequal(app$get_value(export = "panel_ids"), c("a", "b"))
})
