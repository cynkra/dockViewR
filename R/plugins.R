#' Create dock view plugins
#'
#' Create plugins to enable additional functionality in dock view interfaces.
#' Currently supports "add_tab" and "remove_tab" plugins.
#'
#' @param type Character string specifying the plugin type.
#' @param enable Logical, whether the plugin functionality is enabled.
#' @param callback Optional JavaScript function. If `NULL` and `enable = TRUE`,
#'   a default callback is used.
#' @param mode For remove_tab plugins only. One of "auto" or "manual".
#' @param ... Additional plugin configuration arguments.
#'
#' @return A dock view plugin object.
#'
#' @examples
#' # Add tab plugin
#' new_dock_view_plugin("add_tab", enable = TRUE)
#' new_add_tab_plugin(enable = TRUE)  # convenience function
#'
#' # Remove tab plugin
#' new_dock_view_plugin("remove_tab", enable = TRUE, mode = "auto")
#' new_remove_tab_plugin(enable = TRUE, mode = "manual")  # convenience function
#'
#' @name dock_view_plugins
NULL

valid_plugins <- c("add_tab", "remove_tab")

#' @keywords internal
validate_plugin_name <- function(type) {
  if (!(type %in% valid_plugins)) {
    stop(
      "Unknow plugin type. `type` must be one of: ",
      paste(valid_plugins, collapse = ", "),
      call. = FALSE
    )
  }
  structure(type, class = type)
}

#' @rdname dock_view_plugins
#' @export
new_dock_view_plugin <- function(type, ...) {
  # Create a temporary object with the type as class for method dispatch
  type_obj <- validate_plugin_name(type)
  UseMethod("new_dock_view_plugin", type_obj)
}

#' @rdname dock_view_plugins
#' @export
new_dock_view_plugin.add_tab <- function(
  type,
  enable = FALSE,
  callback = NULL,
  ...
) {
  plugin <- list(
    enable = enable,
    callback = callback,
    ...
  )

  class(plugin) <- c("dock_view_plugin_add_tab", "dock_view_plugin", "list")
  validate_dock_view_plugin(plugin)
}

#' @rdname dock_view_plugins
#' @export
new_dock_view_plugin.remove_tab <- function(
  type,
  enable = FALSE,
  callback = NULL,
  mode = "auto",
  ...
) {
  plugin <- list(
    enable = enable,
    callback = callback,
    mode = mode,
    ...
  )

  class(plugin) <- c("dock_view_plugin_remove_tab", "dock_view_plugin", "list")
  validate_dock_view_plugin(plugin)
}

#' @rdname dock_view_plugins
#' @export
new_add_tab_plugin <- function(enable = FALSE, callback = NULL, ...) {
  new_dock_view_plugin("add_tab", enable = enable, callback = callback, ...)
}

#' @rdname dock_view_plugins
#' @export
new_remove_tab_plugin <- function(
  enable = FALSE,
  callback = NULL,
  mode = "auto",
  ...
) {
  new_dock_view_plugin(
    "remove_tab",
    enable = enable,
    callback = callback,
    mode = mode,
    ...
  )
}

#' Validate dock view plugins
#'
#' Internal validation functions for dock view plugins.
#'
#' @param plugin A dock view plugin object.
#' @return The validated plugin object.
#' @keywords internal
#' @name validate_plugins
NULL

#' @rdname validate_plugins
validate_dock_view_plugin <- function(plugin) {
  UseMethod("validate_dock_view_plugin", plugin)
}

#' @rdname validate_plugins
validate_common_plugin_fields <- function(plugin) {
  if (!is.logical(plugin$enable) || length(plugin$enable) != 1) {
    stop("`enable` must be a single boolean value.", call. = FALSE)
  }

  if (plugin$enable && !is.null(plugin$callback)) {
    validate_js_callback(plugin$callback)
  }

  plugin
}

#' @rdname validate_plugins
validate_dock_view_plugin.dock_view_plugin_add_tab <- function(plugin) {
  plugin <- validate_common_plugin_fields(plugin)

  if (plugin$enable && is.null(plugin$callback)) {
    plugin$callback <- default_add_tab_callback()
  }

  plugin
}

#' @rdname validate_plugins
validate_dock_view_plugin.dock_view_plugin_remove_tab <- function(plugin) {
  plugin <- validate_common_plugin_fields(plugin)

  valid_modes <- c("auto", "manual")
  if (!plugin$mode %in% valid_modes) {
    stop(
      "`mode` must be one of: ",
      paste(valid_modes, collapse = ", "),
      call. = FALSE
    )
  }

  if (plugin$enable && is.null(plugin$callback)) {
    plugin$callback <- default_remove_tab_callback()
  }

  plugin
}

#' @keywords internal
validate_js_callback <- function(callback) {
  if (!inherits(callback, "JS_EVAL")) {
    stop(
      "`callback` must be a JavaScript function created with htmlwidgets::JS()."
    )
  }
}

#' Default add tab callback
#'
#' An example of a JavaScript function that can be used as a default
#' when adding a new tab/panel.
#'
#' @export
default_add_tab_callback <- function() {
  htmlwidgets::JS(
    "(config) => {
      Shiny.setInputValue(`${config.dockId}_panel-to-add`, config.group.id, { priority: 'event' });
    }"
  )
}

#' Default remove tab callback
#'
#' An example of a JavaScript function that can be used as a default
#' when removing a tab/panel.
#'
#' @export
default_remove_tab_callback <- function() {
  htmlwidgets::JS(
    "(config) => {
      Shiny.setInputValue(`${config.dockId}_panel-to-remove`, config.api.id, { priority: 'event' });
    }
    "
  )
}

#' Check if object is a dock view plugin of specific type
#'
#' @param x An object to test.
#' @param type Character string specifying plugin type ("add_tab" or "remove_tab").
#' @return Logical value indicating whether the object is the specified plugin type.
#' @export
is_dock_view_plugin <- function(x, type) {
  if (!inherits(x, "dock_view_plugin")) {
    return(FALSE)
  }

  inherits(x, paste0("dock_view_plugin_", type))
}

#' Check if object is an add tab plugin
#' @param x An object to test.
#' @return Logical value.
#' @export
is_add_tab_plugin <- function(x) {
  is_dock_view_plugin(x, "add_tab")
}

#' Check if object is a remove tab plugin
#' @param x An object to test.
#' @return Logical value.
#' @export
is_remove_tab_plugin <- function(x) {
  is_dock_view_plugin(x, "remove_tab")
}
