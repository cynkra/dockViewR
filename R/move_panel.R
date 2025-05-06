#' Move Panel dynamically
#' @param dock_id Dock unique id. When using modules the namespace
#' is automatically added.
#' @param id Panel id.
#' @param position Panel position options: one of
#' \code{"left", "right", "top", "bottom", "center"}.
#' @param group ID of the panel you want to move the target to. They must belong
#' to different groups.
#' @param index Panel index. If panels belong to the same group,
#' you can use index to move the target panel at the desired position.
#' When group is left NULL, index must be passed and cannot exceed the
#' total number of panels or be negative.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#' @export
#' @return This function is called for its side effect.
#' It sends a message to JavaScript through the current websocket connection,
#' leveraging the shiny session object.
move_panel <- function(
  dock_id,
  id,
  position = NULL,
  group = NULL,
  index = NULL,
  session = getDefaultReactiveDomain()
) {
  id <- as.character(id)
  panel_ids <- get_panels_ids(dock_id, session)
  if (!(id %in% panel_ids))
    stop(sprintf(
      "<Panel (ID: %s)>: invalid value (%s) for `id`. Valid ids are: %s.",
      id,
      id,
      paste(panel_ids, collapse = ", ")
    ))

  if (!is.null(position) && !(position %in% valid_positions)) {
    stop(sprintf(
      "<Panel (ID: %s)>: invalid value (%s) for `position`. `position` must be one of %s.",
      id,
      position,
      paste(valid_positions, collapse = ", ")
    ))
  }

  if (!is.null(group)) {
    if (!(group %in% panel_ids))
      stop(sprintf(
        "<PanelGroup (ID: %s)>: invalid value (%s) for `id`. Valid ids are: %s.",
        id,
        id,
        paste(panel_ids, collapse = ", ")
      ))
    options <- list(group = group, position = position)
  } else {
    if (is.null(index))
      stop(sprintf("<Panel (ID: %s)>: `index` cannot be NULL.", id))
    if (index > length(panel_ids) || index < 1)
      stop(sprintf(
        "<Panel (ID: %s)>: invalid value (%s) for `index`. `index` should belong to [%s].",
        id,
        index,
        paste(c(1, length(panel_ids)), collapse = ", ")
      ))
    # JS starts from 0 ... and R from 1 ...
    options <- list(index = index - 1)
  }

  session$sendCustomMessage(
    sprintf("%s_move-panel", session$ns(dock_id)),
    list(
      id = id,
      options = dropNulls(options)
    )
  )
}
