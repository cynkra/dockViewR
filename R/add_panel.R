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
  session = getDefaultReactiveDomain()
) {
  panel$id <- as.character(panel$id)
  if (
    length(get_panels_ids(proxy, session)) &&
      panel$id %in% get_panels_ids(proxy, session)
  )
    stop(sprintf(
      "<Panel (ID: %s)>: `id` %s already in use.",
      panel$id,
      panel$id
    ))

  # Make sure position is a valid list with right properties
  if (!is.null(panel[["position"]]))
    panel[["position"]] <- process_panel_position(
      panel$id,
      panel[["position"]],
      proxy,
      session
    )

  session$sendCustomMessage(sprintf("%s_add-panel", proxy), panel)
}
