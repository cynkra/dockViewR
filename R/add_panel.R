#' Add Panel dynamically
#' @param dock_id Dock unique id. When using modules the namespace is
#' automatically added.
#' @param panel A panel object. See \link{panel} for the different parameters.
#' @param ... Other options passed to the API. Not used yet.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#' @seealso [panel()]
#' @export
#' @return This function is called for its side effect.
#' It sends a message to JavaScript through the current websocket connection,
#' leveraging the shiny session object.
add_panel <- function(
  dock_id,
  panel,
  ...,
  session = getDefaultReactiveDomain()
) {
  panel$id <- as.character(panel$id)
  if (
    length(get_panels_ids(dock_id, session)) &&
      panel$id %in% get_panels_ids(dock_id, session)
  )
    stop(sprintf(
      "<Panel (ID: %s)>: invalid value (%s) for `id`: already in use.",
      panel$id,
      panel$id
    ))

  # Make sure position is a valid list with right properties
  if (!is.null(panel[["position"]]))
    panel[["position"]] <- process_panel_position(
      panel$id,
      panel[["position"]],
      dock_id,
      session
    )

  session$sendCustomMessage(sprintf("%s_add-panel", session$ns(dock_id)), panel)
}
