#' Move Panel dynamically
#' @param dock Dock proxy object created with [dock_view_proxy()].
#' @param id Panel id.
#' @param position Panel position options: one of
#' \code{"left", "right", "top", "bottom", "center"}.
#' @param group ID of a panel that belongs to the target group. The moving panel
#' and this panel must belong to different groups.
#' @param index Panel index. If panels belong to the same group,
#' you can use index to move the target panel at the desired position.
#' When group is left NULL, index must be passed and cannot exceed the
#' total number of panels or be negative.
#' @param session shiny session object.
#' See \url{https://dockview.dev/docs/api/dockview/panelApi/}.
#' @export
#' @return The dock proxy object, invisibly.
move_panel <- function(
  dock,
  id,
  position = NULL,
  group = NULL,
  index = NULL,
  session = getDefaultReactiveDomain()
) {
  dock_proxy <- dock[["proxy"]]
  stopifnot(inherits(dock_proxy, "dock_view_proxy"))

  state <- dock_proxy[["data"]]
  dock_id <- dock_proxy[["id"]]

  # Convert to character for consistency
  panel_id <- as.character(id)

  # Validate panel exists
  validate_panel_exists(panel_id, state[["panels_ids"]])

  # Validate position if provided
  if (!is.null(position) && !(position %in% valid_positions)) {
    stop(sprintf(
      "<Panel (ID: %s)>: invalid value (%s) for `position`. `position` must be one of %s.",
      panel_id,
      position,
      paste(valid_positions, collapse = ", ")
    ))
  }

  # Handle group-based move
  if (!is.null(group)) {
    # Validate target panel exists
    validate_panel_exists(group, state[["panels_ids"]])

    # Find target group from target panel
    target_group <- find_panel_group(group, state[["panel_groups_map"]])
    if (is.null(target_group)) {
      stop(sprintf(
        "<Panel (ID: %s)>: target panel '%s' is not associated with any group.",
        panel_id,
        group
      ))
    }

    # Update dock state for group move
    update_dock_state_on_panel_move(dock, panel_id, target_group, position)

    options <- list(group = group, position = position)
  } else {
    # Handle index-based move
    validate_index_move(panel_id, index, state)

    # For index-based moves, validate panels are in the same group
    validate_index_move_same_group(panel_id, index, state)

    # For index moves, the panel stays in the same group, so update active group and active panel
    current_group <- find_panel_group(panel_id, state[["panel_groups_map"]])
    if (!is.null(current_group)) {
      dock[["proxy"]][["data"]][["active_group"]] <- current_group
      dock[["proxy"]][["data"]][["active_panel"]] <- panel_id
      dock[["proxy"]][["data"]][["active_views"]][[current_group]] <- panel_id
    }

    # JS starts from 0 ... and R from 1 ...
    options <- list(index = index - 1)
  }

  # Send move message to UI
  session$sendCustomMessage(
    sprintf("%s_move-panel", session$ns(dock_id)),
    list(
      id = panel_id,
      options = dropNulls(options)
    )
  )

  invisible(dock)
}

# Helper function to validate index-based move within same group
validate_index_move_same_group <- function(panel_id, index, state) {
  # Find current group of the panel
  current_group <- find_panel_group(panel_id, state[["panel_groups_map"]])

  if (is.null(current_group)) {
    stop(sprintf(
      "<Panel (ID: %s)>: panel is not associated with any group.",
      panel_id
    ))
  }

  # Get panels in the same group
  group_panels <- state[["panel_groups_map"]][[current_group]]
  group_size <- length(group_panels)

  if (index > group_size || index < 1) {
    stop(sprintf(
      "<Panel (ID: %s)>: invalid value (%s) for `index`. 
      `index` should belong to [1, %s] for group '%s'.",
      panel_id,
      index,
      group_size,
      current_group
    ))
  }
}

# Helper function to validate index-based move
validate_index_move <- function(panel_id, index, state) {
  if (is.null(index)) {
    stop(sprintf("<Panel (ID: %s)>: `index` cannot be NULL.", panel_id))
  }

  if (!is.numeric(index) || length(index) != 1) {
    stop(sprintf(
      "<Panel (ID: %s)>: `index` must be a single numeric value.",
      panel_id
    ))
  }
}

# Helper function to update dock state when moving panel to different group
update_dock_state_on_panel_move <- function(
  dock,
  panel_id,
  target_group,
  position
) {
  state <- dock[["proxy"]][["data"]]

  # Only update panel_groups_map if position is NULL
  # If position is not NULL, groups remain unchanged
  if (is.null(position)) {
    # Remove panel from current group
    current_group <- find_panel_group(panel_id, state[["panel_groups_map"]])
    if (!is.null(current_group)) {
      dock[["proxy"]][["data"]] <- remove_panel_from_group(
        dock[["proxy"]][["data"]],
        current_group,
        panel_id
      )
    }

    # Add panel to target group
    add_panel_to_group(
      dock,
      target_group,
      panel_id
    )

    # Update active panel for target group
    dock[["proxy"]][["data"]][["active_views"]][[target_group]] <- panel_id

    # Update active group to be the target group
    dock[["proxy"]][["data"]][["active_group"]] <- target_group

    # Update active panel (active view of the active group)
    dock[["proxy"]][["data"]][["active_panel"]] <- panel_id
  } else {
    # When position is not NULL, groups don't change but we still update active group and active panel
    # to the group containing the moved panel
    current_group <- find_panel_group(panel_id, state[["panel_groups_map"]])
    if (!is.null(current_group)) {
      dock[["proxy"]][["data"]][["active_group"]] <- current_group
      dock[["proxy"]][["data"]][["active_panel"]] <- panel_id
      dock[["proxy"]][["data"]][["active_views"]][[current_group]] <- panel_id
    }
  }
}
