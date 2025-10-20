test_that("plugin type checking works", {
  add_plugin <- new_add_tab_plugin()
  remove_plugin <- new_remove_tab_plugin()

  # Specific type checks
  expect_true(is_dock_view_plugin(add_plugin, "add_tab"))
  expect_false(is_dock_view_plugin(add_plugin, "remove_tab"))
  expect_false(is_dock_view_plugin("string", "add_tab"))

  # Convenience functions
  expect_true(is_add_tab_plugin(add_plugin))
  expect_false(is_add_tab_plugin(remove_plugin))

  expect_true(is_remove_tab_plugin(remove_plugin))
  expect_false(is_remove_tab_plugin(add_plugin))
})

test_that("new_add_tab_plugin works", {
  # Basic creation
  plugin <- new_add_tab_plugin()
  expect_s3_class(plugin, "dock_view_plugin_add_tab")
  expect_equal(plugin$enable, FALSE)
  expect_null(plugin$callback)

  # With parameters
  plugin <- new_add_tab_plugin(enable = TRUE)
  expect_equal(plugin$enable, TRUE)
})

test_that("new_remove_tab_plugin works", {
  # Basic creation
  plugin <- new_remove_tab_plugin()
  expect_s3_class(plugin, "dock_view_plugin_remove_tab")
  expect_equal(plugin$enable, FALSE)
  expect_equal(plugin$mode, "auto")
  expect_null(plugin$callback)

  # With parameters
  plugin <- new_remove_tab_plugin(enable = TRUE, mode = "manual")
  expect_equal(plugin$enable, TRUE)
  expect_equal(plugin$mode, "manual")
})

test_that("validation catches errors", {
  expect_error(new_add_tab_plugin(enable = "true"))
  expect_error(new_remove_tab_plugin(enable = c(TRUE, FALSE)))
  expect_error(new_remove_tab_plugin(mode = "invalid"))
})

test_that("generic function works", {
  add_plugin <- new_dock_view_plugin("add_tab")
  expect_s3_class(add_plugin, "dock_view_plugin_add_tab")

  remove_plugin <- new_dock_view_plugin("remove_tab")
  expect_s3_class(remove_plugin, "dock_view_plugin_remove_tab")

  expect_error(new_dock_view_plugin("invalid"))
})

test_that("default callbacks are set when enabled", {
  plugin <- new_add_tab_plugin(enable = TRUE)
  expect_s3_class(plugin$callback, "JS_EVAL")

  plugin <- new_remove_tab_plugin(enable = TRUE)
  expect_s3_class(plugin$callback, "JS_EVAL")
})

test_that("validate_js_callback works", {
  # Valid JS callback
  js_callback <- htmlwidgets::JS("function() {}")
  expect_silent(validate_js_callback(js_callback))

  # Invalid callbacks
  expect_error(validate_js_callback("string"))
  expect_error(validate_js_callback(function() {}))
  expect_error(validate_js_callback(123))
})

test_that("plugins validate callbacks when enabled", {
  expect_error(new_add_tab_plugin(enable = TRUE, callback = "invalid"))
  expect_silent(new_add_tab_plugin(enable = FALSE, callback = "invalid"))
})
