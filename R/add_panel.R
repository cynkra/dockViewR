#' Add Panel dynamically
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param panel A panel object
#' @param ... Other options passed to the API.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#' @export
add_panel <- function(proxy, panel, ..., session = shiny::getDefaultReactiveDomain()) {
  ID <- session$ns(proxy)
  if (panel$id %in% session$input[[sprintf("%s_panel_ids", ID)]]) stop("The panel ID you used is already in use!")
  session$sendCustomMessage("add-panel", panel)
}

