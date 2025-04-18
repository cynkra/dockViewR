#' get dock
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param session shiny session object.
#' @export
#' @note Only works with server side functions like \link{add_panel}. Don't call it
#' from the UI.
#' @rdname dock-state
get_dock <- function(proxy, session = getDefaultReactiveDomain()) {
  ID <- session$ns(proxy)
  session$input[[sprintf("%s_state", ID)]]
}

#' get dock panels
#' @rdname dock-state
#' @export
get_panels <- function(proxy, session = getDefaultReactiveDomain()) {
  get_dock(proxy, session)[["panels"]]
}

#' get dock panels ids
#' @rdname dock-state
#' @export
get_panels_ids <- function(proxy, session = getDefaultReactiveDomain()) {
  names(get_panels(proxy, session))
}

#' get dock active group
#' @rdname dock-state
#' @export
get_active_group <- function(proxy, session = getDefaultReactiveDomain()) {
  get_dock(proxy, session)[["activeGroup"]]
}

#' get dock grid
#' @rdname dock-state
#' @export
get_grid <- function(proxy, session = getDefaultReactiveDomain()) {
  get_dock(proxy, session)[["grid"]]
}

#' get dock groups
#' @rdname dock-state
#' @export
get_groups <- function(proxy, session = getDefaultReactiveDomain()) {
  get_grid(proxy, session)[["root"]][["data"]]
}

#' get dock groups ids
#' @rdname dock-state
#' @export
get_groups_ids <- function(proxy, session = getDefaultReactiveDomain()) {
  unlist(
    lapply(get_groups(proxy, session), \(group) {
      group[["data"]][["id"]]
    }),
    use.names = FALSE
  )
}

#' get dock groups panels
#' @rdname dock-state
#' @export
get_groups_panels <- function(proxy, session = getDefaultReactiveDomain()) {
  setNames(
    lapply(get_groups(proxy, session), \(group) {
      group[["data"]][["views"]]
    }),
    get_groups_ids(proxy, session)
  )
}

#' save a dock
#' @rdname dock-state
#' @export
save_dock <- function(proxy, session = getDefaultReactiveDomain()) {
  session$sendCustomMessage(sprintf("%s_save-state", proxy), list())
}

#' restore a dock
#' @rdname dock-state
#' @param data Data representing a serialised dock object.
#' @export
restore_dock <- function(proxy, data, session = getDefaultReactiveDomain()) {
  stopifnot(is.list(data))
  session$sendCustomMessage(sprintf("%s_restore-state", proxy), data)
}
