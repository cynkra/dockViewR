#' Add Panel dynamically
#' @param dock Dock proxy object created with [dock_view_proxy()].
#' @param panel A panel object. See \link{panel} for the different parameters.
#' @param ... Other options passed to the API. Not used yet.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#' @seealso [panel()]
#' @export
#' @return The dock proxy object, invisibly.
add_panel <- function(dock, panel, ..., session = getDefaultReactiveDomain()) {
  # Extract and validate proxy
  dock_proxy <- dock[["proxy"]]
  stopifnot(inherits(dock_proxy, "dock_view_proxy"))

  # Extract common variables once
  dock_id <- dock_proxy[["id"]]
  session <- dock_proxy[["session"]]
  state <- dock_proxy[["data"]]

  panel_id <- as.character(panel[["id"]])
  panel[["id"]] <- panel_id

  # Validate panel ID uniqueness
  if (panel_id %in% state[["panels_ids"]]) {
    stop(sprintf("Panel ID '%s' is already in use.", panel_id), call. = FALSE)
  }

  # Process position if provided
  position <- panel[["position"]]
  if (!is.null(position)) {
    panel[["position"]] <- process_panel_position(panel_id, position, state)
  }

  # Update dock state directly
  update_dock_state_on_panel_addition(dock, panel)

  # Send message to UI
  session$sendCustomMessage(sprintf("%s_add-panel", session$ns(dock_id)), panel)

  invisible(dock)
}

# Helper function to update dock state when adding a panel
update_dock_state_on_panel_addition <- function(dock, panel) {
  state <- dock[["proxy"]][["data"]]
  panel_id <- panel[["id"]]
  position <- panel[["position"]]

  # Add panel to panels list
  dock[["proxy"]][["data"]][["panels_ids"]] <- c(
    state[["panels_ids"]],
    panel_id
  )

  # Update groups based on position
  if (is.null(position)) {
    # Add to active group
    target_group <- state[["active_group"]]
    add_panel_to_group(dock, target_group, panel_id)

    # Update active view for the target group and active panel
    update_active_panel_state(dock, panel_id, target_group)
  } else {
    # Get reference info
    ref_info <- get_reference_info(position)

    if (position[["direction"]] == "within") {
      # Add to existing group
      group_id <- find_panel_group(
        ref_info[["panel"]],
        state[["panel_groups_map"]]
      )
      add_panel_to_group(dock, group_id, panel_id)

      # Update active view for this group and active panel
      update_active_panel_state(dock, panel_id, group_id)
    } else {
      # Create new group
      new_group_id <- create_new_group(dock, panel_id)

      # Update active view for new group and active panel
      update_active_panel_state(dock, panel_id, new_group_id)
    }
  }
}

# Helper to add panel to existing group
add_panel_to_group <- function(dock, group_id, panel_id) {
  if (is.null(group_id)) {
    return()
  }

  current_panels <- dock[["proxy"]][["data"]][["panel_groups_map"]][[group_id]]
  dock[["proxy"]][["data"]][["panel_groups_map"]][[group_id]] <- c(
    current_panels,
    panel_id
  )
}

# Helper to create new group
create_new_group <- function(dock, panel_id) {
  # Add new group ID
  current_group_ids <- dock[["proxy"]][["data"]][["group_ids"]]
  new_group_id <- as.character(length(current_group_ids) + 1)
  dock[["proxy"]][["data"]][["group_ids"]] <- c(current_group_ids, new_group_id)

  # Add panel to new group
  panel_groups_map <- dock[["proxy"]][["data"]][["panel_groups_map"]]
  next_map_id <- as.character(length(panel_groups_map) + 1)
  dock[["proxy"]][["data"]][["panel_groups_map"]][[next_map_id]] <- panel_id

  # Return the new group ID
  return(new_group_id)
}

# Helper to update active panel state
update_active_panel_state <- function(dock, panel_id, group_id) {
  if (is.null(group_id)) {
    return()
  }

  # Update active view for this group
  dock[["proxy"]][["data"]][["active_views"]][[group_id]] <- panel_id

  # Update active group to the group containing the new panel
  dock[["proxy"]][["data"]][["active_group"]] <- group_id

  # Update active panel (active view of the active group)
  dock[["proxy"]][["data"]][["active_panel"]] <- panel_id
}

# Helper to get reference information
get_reference_info <- function(position) {
  if ("referencePanel" %in% names(position)) {
    list(type = "panel", panel = position[["referencePanel"]])
  } else if ("referenceGroup" %in% names(position)) {
    list(type = "group", panel = position[["referenceGroup"]])
  }
}
