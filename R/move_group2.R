#' Move a group dynamically
#' @param dock_id Dock unique id. When using modules the namespace is automatically
#' added.
#' @param from Panel-id of a panel within the group that should be moved.
#' @param position Group position options: one of \code{"left", "right", "top", "bottom", "center"}.
#' @param to Panel-id of a panel within the group you want as a to.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#'
#' @description
#' move_group2 moves a group to a different position from withing a shiny server function.
#' The parameter from refers to a panel-id of a panel within the group you want to move.
#' Likewise to refers to a panel-id of a panel within the group you want to
#' select as to.
#' The difference between move_group2 and move_group is that move_group2 selects both
#' from and to by panel-id, whereas move_group selects by group-id.
#' @export
move_group2 <- function(
  dock_id,
  from,
  to,
  position = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  if (!(from %in% list_panels(dock_id, session))) {
    stop("The 'from' panel-id cannot be found!")
  }
  if (!(to %in% list_panels(dock_id, session))) {
    stop("'to' does not refer to an existing panel-id!")
  }
  options <- list(to = to, position = position)
  session$sendCustomMessage(
    sprintf("%s_move-group2", session$ns(dock_id)),
    list(
      id = from,
      options = dropNulls(options)
    )
  )
}
