#' get dock
#' @param dock Dock unique id. When using modules the namespace is
#' automatically added.
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
#' [get_grid()] returns the `grid` element of [get_dock()] which is a list.
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

#' get dock groups
#' @rdname dock-state
#' @export
get_groups <- function(dock_id) {
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
