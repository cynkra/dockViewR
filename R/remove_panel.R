#' Remove Panel dynamically
#' @param dock_id Dock unique id. When using modules the namespace is automatically
#' added.
#' @param id Id of the panel that ought to be removed.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#' @export
remove_panel <- function(
  dock_id,
  id,
  session = getDefaultReactiveDomain()
) {
  if (!(id %in% get_panels_ids(dock_id, session)))
    stop(sprintf("<Panel (ID: %s)>: `id` cannot be found.", id))
  session$sendCustomMessage(sprintf("%s_rm-panel", session$ns(dock_id)), id)
}
