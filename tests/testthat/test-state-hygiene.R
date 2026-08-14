library(shinytest2)

test_that("_state tracks a settled container resize", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state")

  app <- AppDriver$new(
    appdir,
    name = "state_resize",
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
  # The poll below exits on a width that differs from this baseline, so the seed
  # has to have landed first: starting from an unseeded 0 the very first read
  # would satisfy it and the resize would never be exercised.
  before <- grid_width()
  expect_gt(before, 0)

  # A container / window resize changes the layout but has no gesture and no
  # event-driven end, so it is debounced and persisted once it settles. `_state`
  # must reflect it -- consumers read the input directly. The debounced emit
  # produces no Shiny activity until it fires, so poll for the settled width
  # rather than wait_for_idle.
  app$set_window_size(width = 820, height = 700)
  for (i in 1:30) {
    Sys.sleep(0.1)
    if (!identical(grid_width(), before)) break
  }

  after <- grid_width()
  expect_gt(after, 0)
  expect_false(identical(after, before))
})

test_that("maximizing a group emits a bounded number of `_state` updates", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state")

  app <- AppDriver$new(
    appdir,
    name = "state_maximize",
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

test_that("set_panel_title persists the new title", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state")

  app <- AppDriver$new(
    appdir,
    name = "state_settitle",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  # setTitle fires no allowlisted gesture, so without an explicit persist the new
  # title never reaches `_state`. Count the `_state` emits: exactly the one
  # explicit persist, no stray extra from a lingering initial one-shot.
  app$run_js(
    "window.__c = 0;
     var o = Shiny.setInputValue;
     Shiny.setInputValue = function (n, v, p) {
       if (typeof n === 'string' && /_state$/.test(n)) window.__c++;
       return o.apply(this, arguments);
     };"
  )
  app$click("settitle")
  app$wait_for_idle()

  expect_equal(unlist(app$get_js("window.__c")), 1)
  expect_true(unlist(app$get_js(
    "(JSON.stringify(Shiny.shinyapp.$inputValues['dock_state'] || {})).indexOf('Renamed') >= 0"
  )))
})

test_that("initial layout is captured with real pixels", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state")

  app <- AppDriver$new(
    appdir,
    name = "state_initial",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  # The synchronous render captures a zero-sized grid; the ResizeObserver's first
  # real-size observation completes it. Without that, `_state` would carry a zero
  # grid until the first gesture.
  expect_gt(
    unlist(app$get_js("Shiny.shinyapp.$inputValues['dock_state'].grid.width")),
    0
  )
})

test_that("a container-only resize re-fits widgets without looping", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state")

  app <- AppDriver$new(
    appdir,
    name = "state_container_resize",
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

test_that("a gesture that changes no panel body books no rebind", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state")

  app <- AppDriver$new(
    appdir,
    name = "state_rebind_scope",
    seed = 121,
    height = 752,
    width = 1211
  )
  on.exit(app$stop(), add = TRUE)
  app$wait_for_idle()

  # Each `Shiny.bindAll` books a walk over every bound output on the page,
  # whether or not the scope it was handed holds anything unbound -- so a sync
  # that binds nothing still costs one. Count the calls across gestures that
  # change no panel body; they have to book none. Adding a panel brings in a body
  # that does need binding, and is the control that keeps the assertions above it
  # from passing vacuously.
  app$run_js(
    "window.__b = 0;
     var ob = Shiny.bindAll;
     Shiny.bindAll = function () {
       window.__b++;
       return ob.apply(this, arguments);
     };
     var oi = Shiny.initializeInputs;
     Shiny.initializeInputs = function () {
       window.__b++;
       return oi.apply(this, arguments);
     };"
  )

  app$run_js(
    "window.__b = 0;
     document
       .querySelector('.dv-sash')
       .dispatchEvent(new PointerEvent('pointerup', { bubbles: true }));"
  )
  Sys.sleep(0.2)
  app$wait_for_idle()
  expect_equal(unlist(app$get_js("window.__b")), 0)

  app$run_js(
    "window.__b = 0;
     document.getElementById('dock').style.width = '620px';"
  )
  Sys.sleep(0.5)
  app$wait_for_idle()
  expect_equal(unlist(app$get_js("window.__b")), 0)

  app$run_js("window.__b = 0;")
  app$click("add")
  app$wait_for_idle()
  expect_gt(unlist(app$get_js("window.__b")), 0)
})

test_that("container listeners are torn down on re-render", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state")

  app <- AppDriver$new(
    appdir,
    name = "state_teardown",
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

  appdir <- system.file(package = "dockViewR", "examples", "state")

  app <- AppDriver$new(
    appdir,
    name = "state_hygiene",
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

  app$stop()
})

test_that("a panel revealed for the first time gets its inputs bound", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "serialise")

  app <- AppDriver$new(
    appdir,
    name = "serialise_reveal_bind",
    seed = 121,
    height = 752,
    width = 1211
  )
  on.exit(app$stop(), add = TRUE)
  app$wait_for_idle()

  # The slider's panel starts behind panel 2, so dockview keeps its body out of
  # the document and there is nothing to bind while the dock renders. Bringing it
  # to the front attaches that body, and the sync that follows has to bind it --
  # otherwise the slider is dead DOM: it renders, but its value never reaches the
  # server.
  app$run_js(
    "HTMLWidgets.find('#dock').getWidget().component.api.getPanel('test').api.setActive()"
  )
  app$wait_for_idle()

  app$set_inputs(obs = 781)
  app$wait_for_idle()
  expect_equal(app$get_value(input = "obs"), 781)
})

test_that("a restore rebinds the panels' inputs and outputs", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "serialise")

  app <- AppDriver$new(
    appdir,
    name = "serialise_rebind",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  # The slider shares a group with panel 2 and starts behind it, so bring it to
  # the front -- an inactive tab renders no content to bind.
  app$run_js(
    "HTMLWidgets.find('#dock').getWidget().component.api.getPanel('test').api.setActive()"
  )
  app$wait_for_idle()

  # A restore unbinds every panel and fromJSON re-creates their bodies, so the
  # settled persist has to rebind them. Without that the slider is dead DOM: it
  # still renders, but reports nothing back, so the server keeps the stale value.
  app$click("save")
  app$wait_for_idle()
  app$set_inputs(states = "1", wait_ = FALSE)
  app$click("restore")
  app$wait_for_idle()

  app$set_inputs(obs = 781)
  app$wait_for_idle()
  expect_equal(app$get_value(input = "obs"), 781)

  app$stop()
})

test_that("a failed restore does not wedge `_state`", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "state")

  app <- AppDriver$new(
    appdir,
    name = "state_failed_restore",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  # A corrupt layout makes fromJSON revert and rethrow *before* it fires
  # onDidLayoutFromJSON, so the restore never reaches its settle boundary. The
  # gate must still be lowered, or `_state` would stay shut for the rest of the
  # session and no later change would ever reach the consumer.
  app$click("restorebad")
  app$wait_for_idle()

  app$click("addfresh")
  app$wait_for_idle()
  expect_true("z" %in% app$get_value(export = "panel_ids"))

  app$stop()
})
