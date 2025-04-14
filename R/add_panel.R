#' Add Panel dynamically
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param panel A panel object. See \link{panel} for the different parameters.
#' @param ... Other options passed to the API. Not used yet.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#' @seealso [panel()]
#' @export
add_panel <- function(
  proxy,
  panel,
  ...,
  session = shiny::getDefaultReactiveDomain()
) {
  if (panel$id %in% list_panels(proxy, session))
    stop("The panel ID you used is already in use!")
  panel$id <- as.character(panel$id)
  if (!is.null(panel[["position"]]))
    panel[["position"]] <- process_panel_position(panel[["position"]])
  session$sendCustomMessage(sprintf("%s_add-panel", proxy), panel)
}
