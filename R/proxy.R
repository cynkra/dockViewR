# Helper function to validate dock proxy and extract session info
validate_dock_proxy <- function(dock) {
  stopifnot(inherits(dock, "dock_view_proxy"))
  list(
    session = dock[["session"]],
    dock_id = dock[["id"]]
  )
}

# Helper function to send custom message
send_dock_message <- function(dock, action, data = NULL) {
  dock_info <- validate_dock_proxy(dock)
  message_type <- sprintf(
    "%s_%s",
    dock_info$session$ns(dock_info$dock_id),
    action
  )
  dock_info$session$sendCustomMessage(message_type, data)
  invisible(dock)
}

# Helper function to validate position
validate_position <- function(position, context_id = NULL) {
  if (!is.null(position) && !(position %in% valid_positions)) {
    context <- if (!is.null(context_id)) {
      sprintf(" (ID: %s)", context_id)
    } else {
      ""
    }
    stop(sprintf(
      "<%s%s>: invalid value (%s) for `position`. `position` must be one of %s.",
      "Panel",
      context,
      position,
      paste(valid_positions, collapse = ", ")
    ))
  }
}

#' Create a proxy object to modify an existing dockview instance
#'
#' This function creates a proxy object that can be used to update an existing dockview
#' instance after it has been rendered in the UI. The proxy allows for server-side
#' modifications of the graph without completely re-rendering it.
#'
#' @param id Character string matching the ID of the dockview instance to be modified.
#' @param data Unused parameter (for future compatibility).
#' @param session The Shiny session object within which the graph exists.
#'   By default, this uses the current reactive domain.
#'
#' @return A proxy object of class "dock_view_proxy" that can be used with dockview proxy methods
#'   such as `add_panel()`, `remove_panel()`, etc. It contains:
#' - `id`: The ID of the dockview instance.
#' - `session`: The Shiny session object.
#' @export
#' @rdname dockview-proxy
dock_view_proxy <- function(
  id,
  data = NULL,
  session = getDefaultReactiveDomain()
) {
  if (is.null(session)) {
    stop(
      "dock_view_proxy must be called from the server function of a Shiny app."
    )
  }

  structure(
    list(
      id = id,
      session = session
    ),
    class = "dock_view_proxy"
  )
}

#' Dockview Panel Operations
#'
#' Functions to dynamically manipulate panels in a dockview instance.
#'
#' @param dock Dock proxy object created with [dock_view_proxy()].
#' @param panel A panel object (for `add_panel`). See \link{panel} for parameters.
#' @param id Panel ID (character string).
#' @param position Panel/group position: one of "left", "right", "top", "bottom", "center".
#' @param group ID of a panel that belongs to the target group (for `move_panel`).
#' @param index Panel index within a group (for `move_panel`).
#' @param from Source group/panel ID (for move operations).
#' @param to Destination group/panel ID (for move operations).
#' @param ... Additional options (currently unused).
#'
#' @return All functions return the dock proxy object invisibly, allowing for method chaining.
#'
#' @details
#' - `add_panel()`: Adds a new panel to the dockview
#' - `remove_panel()`: Removes an existing panel
#' - `select_panel()`: Selects/focuses a specific panel
#' - `move_panel()`: Moves a panel to a new position
#' - `move_group()`: Moves a group using group IDs
#' - `move_group2()`: Moves a group using panel IDs
#'
#' @seealso [panel()]
#' @export
#' @rdname panel-operations
add_panel <- function(dock, panel, ...) {
  panel_id <- as.character(panel[["id"]])
  panel[["id"]] <- panel_id

  # Process position if provided
  position <- panel[["position"]]
  if (!is.null(position)) {
    panel[["position"]] <- process_panel_position(panel_id, position)
  }

  send_dock_message(dock, "add-panel", panel)
}

#' @export
#' @rdname panel-operations
remove_panel <- function(dock, id) {
  panel_id <- as.character(id)
  send_dock_message(dock, "rm-panel", panel_id)
}

#' @export
#' @rdname panel-operations
select_panel <- function(dock, id) {
  panel_id <- as.character(id)
  send_dock_message(dock, "select-panel", panel_id)
}

#' @export
#' @rdname panel-operations
move_panel <- function(
  dock,
  id,
  position = NULL,
  group = NULL,
  index = NULL
) {
  panel_id <- as.character(id)
  validate_position(position, panel_id)

  options <- list(
    position = position,
    group = group,
    index = index
  )

  send_dock_message(
    dock,
    "move-panel",
    list(
      id = panel_id,
      options = dropNulls(options)
    )
  )
}

#' @export
#' @rdname panel-operations
move_group <- function(
  dock,
  from,
  to,
  position = NULL
) {
  validate_move_targets(from, to, "PanelGroup")
  validate_position(position, from)

  options <- list(to = to, position = position)
  send_dock_message(
    dock,
    "move-group",
    list(
      id = from,
      options = dropNulls(options)
    )
  )
}

#' @export
#' @rdname panel-operations
move_group2 <- function(
  dock,
  from,
  to,
  position = NULL
) {
  validate_move_targets(from, to, "Panel")
  validate_position(position, from)

  options <- list(to = to, position = position)
  send_dock_message(
    dock,
    "move-group2",
    list(
      id = from,
      options = dropNulls(options)
    )
  )
}

validate_move_targets <- function(from, to, context) {
  if (from == to) {
    stop(sprintf(
      "<%s (ID: %s)>: `from` and `to` must be different group ids.",
      context,
      from
    ))
  }
}
