#' Move Panel dynamically
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param id Panel id.
#' @param position Panel position options: one of \code{"left", "right", "top", "bottom", "center"}.
#' @param group ID of the panel you want to move the target to. They must belong
#' to different groups.
#' @param index Panel index. If panels belong to the same group, you can use index to move the target
#' panel at the desired position. When group is left NULL, index must be passed and cannot exceed the
#' total number of panels or be negative.
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
  panel_ids <- get_panels_ids(proxy, session)
  if (!(id %in% panel_ids))
    stop(sprintf("<Panel (ID: %s)>: `id` cannot be found.", id))

  if (!is.null(group)) {
    if (!(group %in% panel_ids))
      stop(sprintf("<PanelGroup (ID: %s)>: `id` cannot be found.", id))
    options <- list(group = group, position = position)
  } else {
    if (is.null(index))
      stop(sprintf("<Panel (ID: %s)>: `index` cannot be NULL.", id))
    if (index > length(panel_ids) || index < 1)
      stop(sprintf(
        "<Panel (ID: %s)>: `index` (value: %s) should belong to [%s].",
        id,
        index,
        paste(c(1, length(panel_ids)), collapse = ", ")
      ))
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
