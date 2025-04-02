#' Add Panel dynamically
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param panel A panel object
#' @param ... Other options passed to the API.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#' @export
add_panel <- function(
  proxy,
  panel,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  if (panel$id %in% list_panels(proxy, session))
    stop("The panel ID you used is already in use!")
  session$sendCustomMessage(sprintf("%s_add-panel", proxy), panel)
}
