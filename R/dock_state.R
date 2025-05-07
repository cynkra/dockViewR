#' get dock
#' @param dock_id Dock unique id. When using modules the namespace is
#' automatically added.
#' @param session shiny session object.
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
get_dock <- function(dock_id, session = getDefaultReactiveDomain()) {
  if (is.null(session))
    stop(sprintf(
      "%s must be called from the server of a Shiny app",
      deparse(sys.call())
    ))
  session$input[[sprintf("%s_state", dock_id)]]
}

#' get dock panels
#' @rdname dock-state
#' @export
get_panels <- function(dock_id, session = getDefaultReactiveDomain()) {
  get_dock(dock_id, session)[["panels"]]
}

#' get dock panels ids
#' @rdname dock-state
#' @export
get_panels_ids <- function(dock_id, session = getDefaultReactiveDomain()) {
  names(get_panels(dock_id, session))
}

#' get dock active group
#' @rdname dock-state
#' @export
get_active_group <- function(dock_id, session = getDefaultReactiveDomain()) {
  get_dock(dock_id, session)[["activeGroup"]]
}

#' get dock grid
#' @rdname dock-state
#' @export
get_grid <- function(dock_id, session = getDefaultReactiveDomain()) {
  get_dock(dock_id, session)[["grid"]]
}

#' get dock groups
#' @rdname dock-state
#' @export
get_groups <- function(dock_id, session = getDefaultReactiveDomain()) {
  get_grid(dock_id, session)[["root"]][["data"]]
}

#' get dock groups ids
#' @rdname dock-state
#' @export
get_groups_ids <- function(dock_id, session = getDefaultReactiveDomain()) {
  unlist(
    lapply(get_groups(dock_id, session), function(group) {
      group[["data"]][["id"]]
    }),
    use.names = FALSE
  )
}

#' get dock groups panels
#' @rdname dock-state
#' @export
get_groups_panels <- function(dock_id, session = getDefaultReactiveDomain()) {
  setNames(
    lapply(get_groups(dock_id, session), function(group) {
      group[["data"]][["views"]]
    }),
    get_groups_ids(dock_id, session)
  )
}

#' save a dock
#' @rdname dock-state
#' @export
save_dock <- function(dock_id, session = getDefaultReactiveDomain()) {
  session$sendCustomMessage(
    sprintf("%s_save-state", session$ns(dock_id)),
    list()
  )
}

#' restore a dock
#' @rdname dock-state
#' @param data Data representing a serialised dock object.
#' @export
restore_dock <- function(dock_id, data, session = getDefaultReactiveDomain()) {
  stopifnot(is.list(data))
  session$sendCustomMessage(
    sprintf("%s_restore-state", session$ns(dock_id)),
    data
  )
}
