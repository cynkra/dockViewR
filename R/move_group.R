#' Move a group dynamically
#' @param dock_id Dock unique id. When using modules the namespace is
#' automatically added.
#' @param from Group-id of a panel within the group that should be moved.
#' @param position Group position options: one of
#' \code{"left", "right", "top", "bottom", "center"}.
#' @param to Group-id of a panel within the group you want as a destination.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#'
#' @description
#' move_group moves a group to a different position from
#' within a shiny server function.
#' The parameter from refers to the group-id you want to be moved.
#' Likewise to refers to the group-id of a group you want to
#' select as destination.
#' The difference between [move_group2()] and [move_group()] is that
#' [move_group2()] selects both
#' from and to by panel-id, whereas [move_group()] selects by group-id.
#' @export
#' @return This function is called for its side effect.
#' It sends a message to JavaScript through the current websocket connection,
#' leveraging the shiny session object.
move_group <- function(
  dock_id,
  from,
  to,
  position = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  group_ids <- get_groups_ids(dock_id, session)
  if (!(from %in% group_ids)) {
    stop(sprintf(
      "<PanelGroup (ID: %s)>: invalid value (%s) for `from`. Valid group ids are: %s.",
      from,
      from,
      paste(group_ids, collapse = ", ")
    ))
  }
  if (!(to %in% group_ids)) {
    stop(sprintf(
      "<PanelGroup (ID: %s)>: invalid value (%s) for `to`. Valid group ids are: %s.",
      from,
      to,
      paste(group_ids, collapse = ", ")
    ))
  }
  if (from == to) {
    stop(sprintf(
      "<PanelGroup (ID: %s)>: `from` and `to` must be different group ids.",
      from
    ))
  }
  if (!is.null(position) && !(position %in% valid_positions)) {
    stop(sprintf(
      "<PanelGroup (ID: %s)>: invalid value for `position`. `position` must be one of %s.",
      from,
      paste(valid_positions, collapse = ", ")
    ))
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
