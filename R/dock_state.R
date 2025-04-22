#' get dock
#' @param dock_id Dock unique id. When using modules the namespace is automatically
#' added.
#' @param session shiny session object.
#' @export
#' @note Only works with server side functions like \link{add_panel}. Don't call it
#' from the UI.
#' @rdname dock-state
get_dock <- function(dock_id, session = getDefaultReactiveDomain()) {
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
    lapply(get_groups(dock_id, session), \(group) {
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
    lapply(get_groups(dock_id, session), \(group) {
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
