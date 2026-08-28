#' get dock
#' @param dock Dock proxy created with [dock_view_proxy()].
#' @export
#' @note Only works with server side functions like \link{add_panel}.
#' Don't call it from the UI.
#' @rdname dock-state
#' @return `get_dock` returns a list of 3 elements:
#' - grid: a list representing the dock layout.
#' - panels: a list having the same structure as [panel()] composing the dock.
#' - activeGroup: the current active group (a string).
#'
#' Each other function allows to deep dive into the returned
#' value of [get_dock()].
#' [get_panels()] returns the `panels` element of [get_dock()].
#' [get_panels_ids()] returns a character vector containing all panel ids
#' from [get_panels()].
#' [get_active_group()] extracts the `activeGroup` component of
#' [get_dock()] as a string.
#' [get_active_views()] is a convenience function that returns the active view
#' in each group.
#' [get_active_panel()] is a convenience function that returns the active panel
#' in the active group.
#' [get_grid()] returns the `grid` element of [get_dock()] which is a list.
#' [grid_shape()] returns the structural shape of [get_grid()]: the
#' branch / leaf nesting, orientation, group ids, panel membership and order,
#' with all absolute geometry (`size`, `width`, `height`) dropped. Pixel
#' geometry is volatile -- and in a headless render not even a valid partition --
#' so snapshotting structure alone keeps the layout coverage that matters
#' without the flake.
#' [get_groups()] returns a list of panel groups from [get_grid()].
#' [get_groups_ids()] returns a character vector of groups ids
#' from [get_groups()].
#' [get_groups_panels()] returns a list of character vector containing
#' the ids of each panel within each group.
#' [save_dock()] and [restore_dock()] are used for their side effect to
#' allow to respectively serialise and restore a dock object.
get_dock <- function(dock) {
  stopifnot(inherits(dock, "dock_view_proxy"))
  session <- dock[["session"]]
  dock_id <- dock[["id"]]
  session$input[[sprintf("%s_state", dock_id)]]
}

#' get dock panels
#' @rdname dock-state
#' @export
get_panels <- function(dock) {
  get_dock(dock)[["panels"]]
}

#' get dock panels ids
#' @rdname dock-state
#' @export
get_panels_ids <- function(dock) {
  names(get_panels(dock))
}

#' get dock active group
#' @rdname dock-state
#' @export
get_active_group <- function(dock) {
  get_dock(dock)[["activeGroup"]]
}

#' get dock grid
#' @rdname dock-state
#' @export
get_grid <- function(dock) {
  get_dock(dock)[["grid"]]
}

#' get dock edge groups
#'
#' Edge groups are serialised beside the grid rather than inside it, keyed by
#' edge rather than by group id. `get_edge_groups()` returns that raw record;
#' the group-level helpers ([get_groups_ids()], [get_groups_panels()],
#' [get_active_views()]) fold edge groups in so a rail's panels are reported
#' like any other group's.
#'
#' @rdname dock-state
#' @export
get_edge_groups <- function(dock) {
  get_dock(dock)[["edgeGroups"]]
}

#' Whether the edge group at `position` is currently visible
#'
#' @param position Edge position. One of `"left"`, `"right"`, `"top"`,
#'   `"bottom"`.
#' @return `TRUE` or `FALSE`, or `NULL` when no edge group is pinned to
#'   `position` (or the dock has not yet published a state).
#' @rdname dock-state
#' @export
is_edge_group_visible <- function(dock, position) {
  validate_edge_position(position)
  edge <- get_edge_groups(dock)[[position]]
  if (is.null(edge)) {
    return(NULL)
  }
  isTRUE(edge[["visible"]])
}

#' Whether the edge group at `position` is currently collapsed
#'
#' Collapsed and invisible are different states: a collapsed rail keeps its
#' header strip standing, while an invisible one renders at zero and keeps
#' whatever collapsed state it had. Set it with [set_edge_group_collapsed()].
#'
#' @return `TRUE` or `FALSE`, or `NULL` when no edge group is pinned to
#'   `position` (or the dock has not yet published a state).
#' @rdname dock-state
#' @export
is_edge_group_collapsed <- function(dock, position) {
  validate_edge_position(position)
  edge <- get_edge_groups(dock)[[position]]
  if (is.null(edge)) {
    return(NULL)
  }
  # `collapsed` is optional on the serialised edge: absent means expanded.
  isTRUE(edge[["collapsed"]])
}

#' @keywords internal
# The group node of each edge group, named by group id. Every serialised edge
# carries one, including an empty rail, so there is nothing to filter out: the
# only entry dockview writes without a group is deleted whole, and that path
# needs the enterprise drag-reveal to reach. The length guard has to stay, since
# `setNames(list(), character(0))` carries a names attribute and would turn
# `get_groups_ids()` from NULL into character(0) on an empty dock.
edge_group_nodes <- function(dock) {
  groups <- lapply(get_edge_groups(dock), `[[`, "group")
  if (length(groups) == 0) {
    return(list())
  }

  setNames(groups, vapply(groups, `[[`, character(1), "id"))
}

#' get dock grid shape
#' @rdname dock-state
#' @export
grid_shape <- function(dock) {
  grid <- get_grid(dock)

  if (is.null(grid)) {
    return(NULL)
  }

  list(
    orientation = grid[["orientation"]],
    root = shape_node(grid[["root"]])
  )
}

#' @keywords internal
shape_node <- function(node) {
  if (is.null(node)) {
    return(NULL)
  }

  if (node[["type"]] == "leaf") {
    list(
      type = "leaf",
      id = node[["data"]][["id"]],
      views = node[["data"]][["views"]],
      activeView = node[["data"]][["activeView"]]
    )
  } else {
    list(
      type = "branch",
      data = lapply(node[["data"]], shape_node)
    )
  }
}

#' get dock groups
#' @rdname dock-state
#' @export
get_groups <- function(dock) {
  get_grid(dock)[["root"]][["data"]]
}

#' get dock groups ids
#' @rdname dock-state
#' @export
get_groups_ids <- function(dock) {
  c(grid_group_ids(dock), names(edge_group_nodes(dock)))
}

#' @keywords internal
grid_group_ids <- function(dock) {
  unlist(
    lapply(get_groups(dock), function(group) {
      find_group_id(group)
    })
  )
}

#' @keywords internal
find_group_id <- function(x) {
  if (x[["type"]] == "leaf") {
    return(x[["data"]][["id"]])
  } else {
    unlist(lapply(x[["data"]], find_group_id))
  }
}

#' get dock groups panels
#' @rdname dock-state
#' @export
get_groups_panels <- function(dock) {
  grid_groups <- get_groups(dock)
  edge_groups <- edge_group_nodes(dock)

  grid_views <- lapply(grid_groups, function(group) {
    group[["data"]][["views"]]
  })
  edge_views <- lapply(edge_groups, function(group) {
    group[["views"]]
  })

  # Named off the grid ids alone, as before edge groups existed; the edge
  # entries are already named by their own group id.
  c(setNames(grid_views, grid_group_ids(dock)), edge_views)
}

#' @keywords internal
extract_active_view <- function(x) {
  if (is.null(x)) {
    return(NULL)
  }

  if (x[["type"]] == "leaf") {
    active_view <- x[["data"]][["activeView"]]
    group_id <- x[["data"]][["id"]]
    if (is.null(active_view) || is.null(group_id)) {
      return(NULL)
    }
    setNames(active_view, group_id)
  } else if (x[["type"]] == "branch") {
    unlist(lapply(x[["data"]], extract_active_view))
  } else {
    NULL
  }
}

#' get active views
#' @rdname dock-state
#' @export
get_active_views <- function(dock) {
  root <- get_grid(dock)[["root"]]
  result <- c(
    extract_active_view(root),
    vapply(
      edge_group_nodes(dock),
      function(group) {
        active_view <- group[["activeView"]]
        if (is.null(active_view)) NA_character_ else as.character(active_view)
      },
      character(1)
    )
  )
  result <- result[!is.na(result)]
  if (length(result) == 0) NULL else result
}

#' get active panel
#' @rdname dock-state
#' @export
get_active_panel <- function(dock) {
  active_group <- get_active_group(dock)
  active_views <- get_active_views(dock)

  if (!isTRUE(active_group %in% names(active_views))) {
    return(NULL)
  }

  active_views[[active_group]]
}

#' save a dock
#' @rdname dock-state
#' @export
save_dock <- function(dock) {
  session <- dock[["session"]]
  dock_id <- dock[["id"]]
  session$sendCustomMessage(
    sprintf("%s_save-state", session$ns(dock_id)),
    list()
  )

  invisible(dock)
}

#' restore a dock
#' @rdname dock-state
#' @param data Data representing a serialised dock object.
#' @export
restore_dock <- function(dock, data) {
  session <- dock[["session"]]
  dock_id <- dock[["id"]]
  stopifnot(is.list(data))
  session$sendCustomMessage(
    sprintf("%s_restore-state", session$ns(dock_id)),
    data
  )

  invisible(dock)
}
