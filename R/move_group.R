#' Move a group dynamically
#' @param dock_id Dock unique id. When using modules the namespace is automatically
#' added.
#' @param from Group-id of a panel within the group that should be moved.
#' @param position Group position options: one of \code{"left", "right", "top", "bottom", "center"}.
#' @param to Group-id of a panel within the group you want as a destination.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#'
#' @description
#' move_group moves a group to a different position from withing a shiny server function.
#' The parameter from refers to the group-id you want to be moved.
#' Likewise to refers to the group-id of a group you want to
#' select as destination.
#' The difference between move_group2 and move_group is that move_group2 selects both
#' from and to by panel-id, whereas move_group selects by group-id.
#' @export
move_group <- function(
  dock_id,
  from,
  to,
  position = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  if (!(from %in% list_panels(dock_id, session))) {
    stop("The 'from' group-id cannot be found!")
  }
  if (!(to %in% list_panels(dock_id, session))) {
    stop("'to' does not refer to an existing group-id!")
  }
  options <- list(to = to, position = position)
  session$sendCustomMessage(
    sprintf("%s_move-group", session$ns(dock_id)),
    list(
      id = from,
      options = dropNulls(options)
    )
  )
}
