#' Remove Panel dynamically
#' @param dock_id Dock unique id. When using modules the namespace is
#' automatically added.
#' @param id Id of the panel that ought to be removed.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#' @export
#' @return This function is called for its side effect.
#' It sends a message to JavaScript through the current websocket connection,
#' leveraging the shiny session object.
remove_panel <- function(
  dock_id,
  id,
  session = getDefaultReactiveDomain()
) {
  panel_ids <- get_panels_ids(dock_id, session)
  if (!(id %in% panel_ids))
    stop(sprintf(
      "<Panel (ID: %s)>: invalid value (%s) for `id`. Valid ids are: %s.",
      id,
      id,
      paste(panel_ids, collapse = ", ")
    ))
  session$sendCustomMessage(sprintf("%s_rm-panel", session$ns(dock_id)), id)
}
