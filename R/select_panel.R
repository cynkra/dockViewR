#' Select a panel dynamically
#' @param dock Dock proxy object created with [dock_view_proxy()].
#' @param id Panel id.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#' @export
#' @return The dock proxy object, invisibly.
select_panel <- function(dock, id, session = getDefaultReactiveDomain()) {
  dock_proxy <- dock[["proxy"]]
  stopifnot(inherits(dock_proxy, "dock_view_proxy"))

  state <- dock_proxy[["data"]]
  dock_id <- dock_proxy[["id"]]

  # Convert to character for consistency
  panel_id <- as.character(id)

  # Validate panel exists
  validate_panel_exists(panel_id, state[["panels_ids"]])

  # Validate panel is not already the active view of the active group
  validate_panel_not_selected(panel_id, state)

  # Find which group contains this panel (reusing the logic from remove_panel)
  panel_group_id <- find_panel_group(panel_id, state[["panel_groups_map"]])

  # Update dock state
  update_dock_state_on_panel_selected(dock, panel_id, panel_group_id, state)

  # Send selection message to UI
  session$sendCustomMessage(
    sprintf("%s_select-panel", session$ns(dock_id)),
    list(id = panel_id)
  )

  invisible(dock)
}

update_dock_state_on_panel_selected <- function(
  dock,
  panel_id,
  panel_group_id,
  state
) {
  # Update active panel for this group
  dock[["proxy"]][["data"]][["active_views"]][[panel_group_id]] <- panel_id

  # Update active group if it's different from current
  # For instance, if panels are in tabs, there is no need
  # to change the active group.
  current_active_group <- state[["active_group"]]
  if (current_active_group != panel_group_id) {
    dock[["proxy"]][["data"]][["active_group"]] <- panel_group_id
  }

  # Update active panel (active view of the active group)
  # This should always be updated since we're selecting a new panel
  dock[["proxy"]][["data"]][["active_panel"]] <- panel_id
}

validate_panel_not_selected <- function(panel_id, state) {
  current_active_panel <- get_active_panel(state)

  if (!is.null(current_active_panel) && current_active_panel == panel_id) {
    stop(
      sprintf(
        "Panel ID '%s' is already selected.",
        panel_id
      ),
      call. = FALSE
    )
  }
}
