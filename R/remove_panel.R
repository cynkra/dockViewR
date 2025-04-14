#' Remove Panel dynamically
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param id Id of the panel that ought to be removed.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#' @export
remove_panel <- function(
  proxy,
  id,
  session = shiny::getDefaultReactiveDomain()
) {
  if (!(id %in% list_panels(proxy, session)))
    stop(sprintf("<Panel (ID: %s)>: `id` cannot be found.", id))
  session$sendCustomMessage(sprintf("%s_rm-panel", proxy), id)
}
