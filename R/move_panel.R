#' Move Panel dynamically
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param id Panel id.
#' @param position Panel position options. A list with `referencePanel` and `direction`.
#' @param group Panel group.
#' @param index Panel index.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#' @export
move_panel <- function(proxy, id, position, group = NULL, index = NULL, session = shiny::getDefaultReactiveDomain()) {
  if (!(id %in% list_panels(proxy, session))) stop("The panel ID cannot be found!")
  session$sendCustomMessage(
    "move-panel",
    list(id = id, moveTo = list(group = group, position = position, index = index))
  )
}