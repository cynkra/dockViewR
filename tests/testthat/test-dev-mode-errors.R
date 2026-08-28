library(shinytest2)

test_that("a failed proxy call names the operation in dev mode", {
  skip_on_cran()

  # In dev mode `evalDockView()` catches a failed proxy call and reports it
  # through a Shiny notification; in prod it lets the exception escape to the
  # console. So this notification is the only feedback an app author gets for a
  # proxy call that fails, and nothing asserted anything about it before.
  appdir <- system.file(package = "dockViewR", "examples", "dev_errors")
  skip_if(!nzchar(appdir))

  app <- AppDriver$new(
    appdir,
    name = "dev_errors",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  app$run_js(
    "window.__notes = [];
     var show = Shiny.notifications.show;
     Shiny.notifications.show = function (opts) {
       window.__notes.push(opts.html);
       return show.apply(this, arguments);
     };"
  )

  app$click("bad_select")
  app$wait_for_idle()
  notes <- unlist(app$get_js("window.__notes"))

  # The operation is named after the R function the caller used, because the
  # name is passed in. Deriving it from a stack trace reported the bundle's URL
  # instead, so the message used to read `Error in http: ...`.
  expect_length(notes, 1L)
  expect_match(notes[[1]], "select_panel\\(\\)")
  expect_match(notes[[1]], "does-not-exist")
  expect_false(grepl("Error in http", notes[[1]], fixed = TRUE))
  expect_false(grepl("Error in unknown", notes[[1]], fixed = TRUE))

  # A different operation reports its own name, rather than whatever the stack
  # happened to hold.
  app$click("bad_remove")
  app$wait_for_idle()
  notes <- unlist(app$get_js("window.__notes"))
  expect_length(notes, 2L)
  expect_match(notes[[2]], "remove_panel\\(\\)")

  # A call that succeeds reports nothing, so the notification tracks failures
  # rather than proxy traffic.
  app$click("good_select")
  app$wait_for_idle()
  expect_length(unlist(app$get_js("window.__notes")), 2L)
  expect_identical(app$get_value(export = "active_panel"), "two")

  app$stop()
})
