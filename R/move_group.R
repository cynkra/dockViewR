#' Move a group dynamically
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param source Group-id of a panel within the group that should be moved.
#' @param position Group position options: one of \code{"left", "right", "top", "bottom", "center"}.
#' @param destination Group-id of a panel within the group you want as a destination.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#' 
#' @description
#' move_group moves a group to a different position from withing a shiny server function. 
#' The parameter source refers to the group-id you want to be moved. 
#' Likewise destination refers to the group-id of a group you want to 
#' select as destination.
#' The difference between move_group2 and move_group is that move_group2 selects both 
#' source and destination by panel-id, whereas move_group selects by group-id.
#' @export
move_group <- function(
    proxy,
    source,
    destination,
    position = NULL,
    session = shiny::getDefaultReactiveDomain()) {
  if (!(source %in% list_panels(proxy, session))) {
    stop("The source group-id cannot be found!")
  }
  if (!(destination %in% list_panels(proxy, session))) {
    stop("destination does not refer to an existing group-id!")
  }
  options <- list(destination = destination, position = position)
  session$sendCustomMessage(
    sprintf("%s_move-group", proxy),
    list(
      id = source,
      options = dropNulls(options)
    )
  )
}
