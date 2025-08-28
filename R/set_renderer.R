#' Select a panel renderer dynamically
#' @param dock_id Dock unique id. When using modules the namespace
#' is automatically added.
#' @param id Panel id.
#' @param renderer Renderer value. Either `"always"` or `"onlyWhenVisible"`.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#' @export
#' @return This function is called for its side effect.
#' It sends a message to JavaScript through the current websocket connection,
#' leveraging the shiny session object.
set_panel_renderer <- function(
  dock_id,
  id,
  renderer = c("always", "onlyWhenVisible"),
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

  renderer <- match.arg(renderer)

  session$sendCustomMessage(
    sprintf("%s_set-panel-renderer", session$ns(dock_id)),
    list(id = id, renderer = renderer)
  )
}
