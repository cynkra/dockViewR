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

  # Check if removing the active panel
  is_removing_active_panel <- is_panel_active(id, state)

  # Update dock state
  update_dock_state_on_panel_removal(dock, id, is_removing_active_panel)

  # Send removal message to UI
  session$sendCustomMessage(
    sprintf("%s_rm-panel", session$ns(dock_id)),
    id
  )

  invisible(dock)
}

# Helper function to check if a panel is the currently active panel
is_panel_active <- function(panel_id, state) {
  current_active_panel <- get_active_panel(state)
  return(!is.null(current_active_panel) && current_active_panel == panel_id)
}

# Helper function to reset active panel to the first available panel
reset_active_panel_to_first <- function(dock) {
  state <- dock[["proxy"]][["data"]]
  remaining_panels <- state[["panels_ids"]]

  if (length(remaining_panels) > 0) {
    # Get the first panel
    first_panel <- remaining_panels[1]

    # Find which group contains the first panel
    first_panel_group <- find_panel_group(
      first_panel,
      state[["panel_groups_map"]]
    )

    if (!is.null(first_panel_group)) {
      # Update active group
      dock[["proxy"]][["data"]][["active_group"]] <- first_panel_group

      # Initialize active_views if it doesn't exist
      if (is.null(dock[["proxy"]][["data"]][["active_views"]])) {
        dock[["proxy"]][["data"]][["active_views"]] <- list()
      }

      # Update active view for that group
      dock[["proxy"]][["data"]][["active_views"]][[
        first_panel_group
      ]] <- first_panel

      # Update active panel
      dock[["proxy"]][["data"]][["active_panel"]] <- first_panel
    }
  }
}

# Helper function to clear all active state
clear_all_active_state <- function(dock) {
  dock[["proxy"]][["data"]][["active_group"]] <- NULL
  dock[["proxy"]][["data"]][["active_panel"]] <- NULL
  # Keep active_views as an empty list rather than NULL
  dock[["proxy"]][["data"]][["active_views"]] <- list()
}

# Updated remove_panel_from_group function with comprehensive empty vector protection
remove_panel_from_group <- function(state, group_id, panel_id) {
  # Early return if basic structures don't exist
  if (is.null(state) || is.null(group_id) || is.null(panel_id)) {
    return(state)
  }

  if (
    is.null(state[["panel_groups_map"]]) ||
      is.null(state[["panel_groups_map"]][[group_id]])
  ) {
    return(state)
  }

  current_panels <- state[["panel_groups_map"]][[group_id]]
  if (is.null(current_panels) || length(current_panels) == 0) {
    return(state)
  }

  remaining_panels <- setdiff(current_panels, panel_id)

  if (length(remaining_panels) == 0) {
    # Remove empty group completely
    state[["panel_groups_map"]][[group_id]] <- NULL

    # Handle group_ids - protect against empty vector assignment
    if (!is.null(state[["group_ids"]]) && length(state[["group_ids"]]) > 0) {
      new_group_ids <- setdiff(state[["group_ids"]], group_id)
      # Only assign if not empty, otherwise set to NULL
      state[["group_ids"]] <- if (length(new_group_ids) > 0) {
        new_group_ids
      } else {
        NULL
      }
    }

    # Remove from active_views if it exists
    if (
      !is.null(state[["active_views"]]) &&
        is.list(state[["active_views"]]) &&
        group_id %in% names(state[["active_views"]])
    ) {
      state[["active_views"]][[group_id]] <- NULL
    }

    # Update active group if this was the active group
    if (
      !is.null(state[["active_group"]]) &&
        length(state[["active_group"]]) > 0 &&
        state[["active_group"]] == group_id
    ) {
      # Get remaining groups safely
      remaining_groups <- if (!is.null(state[["panel_groups_map"]])) {
        names(state[["panel_groups_map"]])
      } else {
        character(0)
      }

      # Only assign if not empty, otherwise set to NULL
      state[["active_group"]] <- if (length(remaining_groups) > 0) {
        remaining_groups[1]
      } else {
        NULL
      }
    }
  } else {
    # Update group with remaining panels (this should be safe as remaining_panels has length > 0)
    state[["panel_groups_map"]][[group_id]] <- remaining_panels

    # Handle active_views update
    if (
      !is.null(state[["active_views"]]) &&
        is.list(state[["active_views"]]) &&
        group_id %in% names(state[["active_views"]]) &&
        !is.null(state[["active_views"]][[group_id]]) &&
        state[["active_views"]][[group_id]] == panel_id
    ) {
      # Only update if we have remaining panels (which we do in this branch)
      state[["active_views"]][[group_id]] <- remaining_panels[1]
    }
  }

  state
}

# Also update the main removal function to be more defensive
update_dock_state_on_panel_removal <- function(
  dock,
  panel_id,
  is_removing_active_panel
) {
  if (
    is.null(dock) ||
      is.null(dock[["proxy"]]) ||
      is.null(dock[["proxy"]][["data"]])
  ) {
    return()
  }

  state <- dock[["proxy"]][["data"]]

  # Remove panel from panels list - protect against empty vector
  if (!is.null(state[["panels_ids"]]) && length(state[["panels_ids"]]) > 0) {
    remaining_panels <- setdiff(state[["panels_ids"]], panel_id)
    dock[["proxy"]][["data"]][["panels_ids"]] <- if (
      length(remaining_panels) > 0
    ) {
      remaining_panels
    } else {
      NULL # Set to NULL instead of empty vector
    }
  }

  # Find and remove from group
  group_id <- find_panel_group(panel_id, state[["panel_groups_map"]])
  if (!is.null(group_id)) {
    dock[["proxy"]][["data"]] <- remove_panel_from_group(
      dock[["proxy"]][["data"]],
      group_id,
      panel_id
    )
  }

  # Handle active panel reset only if we removed the active panel
  if (is_removing_active_panel) {
    # Get current remaining panels after removal
    current_remaining <- dock[["proxy"]][["data"]][["panels_ids"]]

    if (!is.null(current_remaining) && length(current_remaining) > 0) {
      reset_active_panel_to_first(dock)
    } else {
      # No panels left, clear all active state completely
      clear_all_active_state(dock)
    }
  }
}
