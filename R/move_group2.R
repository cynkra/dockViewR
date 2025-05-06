#' Move a group dynamically
#' @param dock_id Dock unique id. When using modules the namespace is
#' automatically added.
#' @param from Panel-id of a panel within the group that should be moved.
#' @param position Group position options: one of
#' \code{"left", "right", "top", "bottom", "center"}.
#' @param to Panel-id of a panel within the group you want as a to.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#'
#' @description
#' move_group2 moves a group to a different position from within
#' a shiny server function.
#' The parameter from refers to a panel-id of a panel within the group you
#' want to move.
#' Likewise to refers to a panel-id of a panel within the group you want to
#' select as to.
#' The difference between [move_group2()] and [move_group()]
#' is that [move_group2()] selects both
#' from and to by panel-id, whereas [move_group()] selects by group-id.
#' @export
#' @return This function is called for its side effect.
#' It sends a message to JavaScript through the current websocket connection,
#' leveraging the shiny session object.
move_group2 <- function(
  dock_id,
  from,
  to,
  position = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  panel_ids <- get_panels_ids(dock_id, session)
  if (!(from %in% panel_ids)) {
    stop(sprintf(
      "<Panel (ID: %s)>: invalid value (%s) for `from`. Valid panel ids are: %s.",
      from,
      from,
      paste(panel_ids, collapse = ", ")
    ))
  }
  if (!(to %in% panel_ids)) {
    stop(sprintf(
      "<Panel (ID: %s)>: invalid value (%s) for `to`. Valid panel ids are: %s.",
      from,
      to,
      paste(panel_ids, collapse = ", ")
    ))
  }
  if (from == to) {
    stop(sprintf(
      "<Panel (ID: %s)>: `from` and `to` must be different panel ids.",
      from
    ))
  }
  if (!is.null(position) && !(position %in% valid_positions)) {
    stop(sprintf(
      "<Panel (ID: %s)>: invalid value for `position`. `position` must be one of %s.",
      from,
      paste(valid_positions, collapse = ", ")
    ))
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
