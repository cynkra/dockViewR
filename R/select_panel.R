#' Select a panel dynamically
#' @param dock_id Dock unique id. When using modules the namespace
#' is automatically added.
#' @param id Panel id.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#' @export
#' @return This function is called for its side effect.
#' It sends a message to JavaScript through the current websocket connection,
#' leveraging the shiny session object.
select_panel <- function(dock_id, id, session = getDefaultReactiveDomain()) {
  id <- as.character(id)
  panel_ids <- get_panels_ids(dock_id, session)
  if (!(id %in% panel_ids))
    stop(sprintf(
      "<Panel (ID: %s)>: invalid value (%s) for `id`. Valid ids are: %s.",
      id,
      id,
      paste(panel_ids, collapse = ", ")
    ))

  session$sendCustomMessage(
    sprintf("%s_select-panel", session$ns(dock_id)),
    list(id = id)
  )
}
