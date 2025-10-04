#' Remove Panel dynamically
#' @param dock Dock proxy object created with [dock_view_proxy()].
#' @param id Id of the panel that ought to be removed.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#' @export
#' @return The dock proxy object, invisibly.
remove_panel <- function(dock, id, session = getDefaultReactiveDomain()) {
  dock_proxy <- dock[["proxy"]]
  stopifnot(inherits(dock_proxy, "dock_view_proxy"))

  state <- dock_proxy[["data"]]
  dock_id <- dock_proxy[["id"]]

  # Validate panel exists
  validate_panel_exists(id, state[["panels_ids"]])

  # Update dock state
  update_dock_state_on_panel_removal(dock, id)

  # Send removal message to UI
  session$sendCustomMessage(
    sprintf("%s_rm-panel", session$ns(dock_id)),
    id
  )

  invisible(dock)
}

# Helper function to update dock state when removing a panel
update_dock_state_on_panel_removal <- function(dock, panel_id) {
  state <- dock[["proxy"]][["data"]]

  # Remove panel from panels list
  dock[["proxy"]][["data"]][["panels_ids"]] <- setdiff(
    state[["panels_ids"]],
    panel_id
  )

  # Find and remove from group
  group_id <- find_panel_group(panel_id, state[["panel_groups_map"]])
  if (!is.null(group_id)) {
    dock[["proxy"]][["data"]] <- remove_panel_from_group(
      dock[["proxy"]][["data"]],
      group_id,
      panel_id
    )
  }
}

# Keep the existing helper functions
remove_panel_from_group <- function(state, group_id, panel_id) {
  current_panels <- state[["panel_groups_map"]][[group_id]]
  remaining_panels <- setdiff(current_panels, panel_id)

  if (length(remaining_panels) == 0) {
    # Remove empty group completely
    state[["panel_groups_map"]][[group_id]] <- NULL

    # Remove from group_ids
    if (!is.null(state[["group_ids"]])) {
      state[["group_ids"]] <- setdiff(state[["group_ids"]], group_id)
    }

    # Update active group if needed
    if (
      !is.null(state[["active_group"]]) && state[["active_group"]] == group_id
    ) {
      remaining_groups <- names(state[["panel_groups_map"]])
      state[["active_group"]] <- if (length(remaining_groups) > 0) {
        remaining_groups[1]
      } else {
        NULL
      }
    }
  } else {
    # Update group with remaining panels
    state[["panel_groups_map"]][[group_id]] <- remaining_panels
  }

  state
}
