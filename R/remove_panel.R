#' Remove Panel dynamically
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param panel A panel object
#' @param ... Other options passed to the API.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#' @export
remove_panel <- function(id, session = shiny::getDefaultReactiveDomain()) {
  session$sendCustomMessage("rm-panel", id)
}

