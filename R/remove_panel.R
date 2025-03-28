#' Remove Panel dynamically
#' @param id Id of the panel that ought to be removed.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#' @export
remove_panel <- function(id, session = shiny::getDefaultReactiveDomain()) {
  session$sendCustomMessage("rm-panel", id)
}

