#' Move Group dynamically
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param id Panel id.
#' @param position Panel position options: one of \code{"left", "right", "top", "bottom", "center"}.
#' @param group ID of the panel you want to move the target to. They must belong
#' to different groups.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#' @export
move_group <- function(
    proxy,
    id,
    group,
    position = NULL,
    session = shiny::getDefaultReactiveDomain()) {
  if (!(id %in% list_panels(proxy, session))) {
    stop("The panel ID cannot be found!")
  }
  if (!(group %in% list_panels(proxy, session))) {
    stop("group does not refer to an existing ID!")
  }
  options <- list(group = group, position = position)
  session$sendCustomMessage(
    sprintf("%s_move-group", proxy),
    list(
      id = id,
      options = dropNulls(options)
    )
  )
}
