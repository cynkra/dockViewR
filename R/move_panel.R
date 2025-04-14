#' Move Panel dynamically
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param id Panel id.
#' @param position Panel position options: one of \code{"left", "right", "top", "bottom", "center"}.
#' @param group ID of the panel you want to move the target to. They must belong
#' to different groups.
#' @param index Panel index. If panels belong to the same group, you can use index to move the target
#' panel at the desired position.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi}.
#' @export
move_panel <- function(
  proxy,
  id,
  position = NULL,
  group = NULL,
  index = NULL,
  session = shiny::getDefaultReactiveDomain()
) {
  id <- as.character(id)
  if (!(id %in% list_panels(proxy, session)))
    stop(sprintf("<Panel (ID: %s)>: `id` cannot be found.", id))

  if (!is.null(group)) {
    if (!(group %in% list_panels(proxy, session)))
      stop(sprintf("<PanelGroup (ID: %s)>: `id` cannot be found.", id))
    options <- list(group = group, position = position)
  } else {
    if (is.null(index)) index <- 1
    # JS starts from 0 ... and R from 1 ...
    options <- list(index = index - 1)
  }

  session$sendCustomMessage(
    sprintf("%s_move-panel", proxy),
    list(
      id = id,
      options = dropNulls(options)
    )
  )
}
