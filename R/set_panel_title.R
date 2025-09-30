#' Set a panel title dynamically
#' @param dock_id Dock unique id. When using modules the namespace
#' is automatically added.
#' @param id Panel id.
#' @param title New panel title.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#' @export
#' @return This function is called for its side effect.
#' It sends a message to JavaScript through the current websocket connection,
#' leveraging the shiny session object.
set_panel_title <- function(dock_id, id, title, session = getDefaultReactiveDomain()) {
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
    sprintf("%s_set-panel-title", session$ns(dock_id)),
    list(id = id, title = title)
  )
}
