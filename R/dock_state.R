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
#' [grid_shape()] returns [get_grid()] with each node's absolute pixel `size`
#' replaced by its sibling-relative fraction (rounded to 2 decimals) and the
#' absolute `width` / `height` dropped. The tree structure (nesting,
#' orientation, group ids, panel membership, order) is preserved, so it
#' captures real layout changes while staying stable against the render-stack
#' pixel noise that makes raw `get_grid()` snapshots flaky.
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

#' get dock grid shape
#' @rdname dock-state
#' @export
grid_shape <- function(dock) {
  grid <- get_grid(dock)
  list(
    orientation = grid[["orientation"]],
    root = shape_node(grid[["root"]], 1)
  )
}

#' @keywords internal
shape_node <- function(node, fraction) {
  if (node[["type"]] == "leaf") {
    list(
      type = "leaf",
      id = node[["data"]][["id"]],
      views = node[["data"]][["views"]],
      activeView = node[["data"]][["activeView"]],
      fraction = fraction
    )
  } else {
    list(
      type = "branch",
      fraction = fraction,
      data = shape_children(node[["data"]])
    )
  }
}

#' @keywords internal
shape_children <- function(children) {
  sizes <- vapply(children, `[[`, numeric(1), "size")
  total <- sum(sizes)
  fractions <- if (total == 0) rep(0, length(sizes)) else round(sizes / total, 2)
  mapply(shape_node, children, fractions, SIMPLIFY = FALSE, USE.NAMES = FALSE)
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
  setNames(
    lapply(get_groups(dock), function(group) {
      group[["data"]][["views"]]
    }),
    get_groups_ids(dock)
  )
}

#' @keywords internal
extract_active_view <- function(x) {
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
  result <- extract_active_view(root)
  if (length(result) == 0) NULL else result
}

#' get active panel
#' @rdname dock-state
#' @export
get_active_panel <- function(dock) {
  active_group <- get_active_group(dock)
  active_views <- get_active_views(dock)
  # We need no check since there is always an active group
  # and an active view.
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
