#' Change panel size dynamically
#' @param dock_id Dock unique id. When using modules the namespace
#' is automatically added.
#' @param id Panel id.
#' @param height New height of the panel.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/core/panels/resizing}.
#' @export
#' @return This function is called for its side effect.
#' It sends a message to JavaScript through the current websocket connection,
#' leveraging the shiny session object.
set_panel_size <- function(
  dock_id,
  id,
  height,
  session = getDefaultReactiveDomain()
) {
  id <- as.character(id)
  panel_ids <- get_panels_ids(dock_id, session)
  if (!(id %in% panel_ids)) {
    stop(sprintf(
      "<Panel (ID: %s)>: invalid value (%s) for `id`. Valid ids are: %s.",
      id,
      id,
      paste(panel_ids, collapse = ", ")
    ))
  }
  session$sendCustomMessage(
    sprintf("%s_resize-panel", session$ns(dock_id)),
    list(
      id = id,
      options = list(height = height)
    )
  )
}
