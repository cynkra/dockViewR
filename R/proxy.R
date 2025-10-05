#' Create a proxy object to modify an existing dockview instance
#'
#' This function creates a proxy object that can be used to update an existing dockview
#' instance after it has been rendered in the UI. The proxy allows for server-side
#' modifications of the graph without completely re-rendering it.
#'
#' @param id Character string matching the ID of the dockview instance to be modified.
#' @param data Optional initial data to set the state of the dockview.
#' Use in conjunction with [dock_view_reactive_proxy()].
#' @param session The Shiny session object within which the graph exists.
#'   By default, this uses the current reactive domain.
#'
#' @return A proxy object of class "dock_view_proxy" that can be used with g6 proxy methods
#'   such as `add_panel()`, `remove_panel()`, etc. It contains:
#' - `id`: The ID of the dockview instance.
#' - `session`: The Shiny session object.
#' - `data`: A list containing the current state of the dock, including:
#'  - `panels_ids`: Character vector of panel IDs.
#'  - `group_ids`: Character vector of group IDs.
#'  - `panel_groups_map`: Named list mapping group IDs to their panel IDs.
#'  - `active_views`: Named character vector mapping group IDs to their active panel IDs.
#'  - `active_group`: The ID of the currently active group.
#'  - `active_panel`: The ID of the currently active panel within the active group.
#'  - `timestamp`: The time when the proxy was created or last updated.
#'
#'
#' @export
#' @rdname dockview-proxy
dock_view_proxy <- function(
  id,
  data = NULL,
  session = getDefaultReactiveDomain()
) {
  if (is.null(session)) {
    stop(
      "dock_view_proxy must be called from the server function of a Shiny app."
    )
  }

  # TBD: validate data structure if provided
  panels_ids <- character(0)
  groups_ids <- character(0)
  panel_groups_map <- list()
  active_views <- character(0)
  active_group <- character(0)
  active_panel <- character(0)

  # process data if provided
  if (!is.null(data)) {
    # extract panel ids
    panels_ids <- get_panel_ids(data)
    # extract group ids
    group_ids <- get_group_ids(data)
    # map panel ids to group ids
    panel_groups_map <- get_panel_group(data)
    # get active panel per group
    active_views <- get_active_panel_group(data)
    # get active group id
    active_group <- get_active_group(data)
    # get active panel id
    active_panel <- get_active_panel(
      list(
        active_group = active_group,
        active_views = active_views
      )
    )
  }

  structure(
    list(
      id = id,
      session = session,
      data = list(
        panels_ids = panels_ids, # Store panel information
        group_ids = group_ids, # Store group information
        panel_groups_map = panel_groups_map, # Map panel IDs to group IDs
        active_views = active_views, # Active panel per group
        active_group = active_group, # Currently active group ID
        active_panel = active_panel,
        timestamp = Sys.time() # Maybe we need that one day ...
      )
    ),
    class = "dock_view_proxy"
  )
}

#' A reactive version of the dock_view_proxy
#'
#' Proxy that is updated each time the dock state changes.
#'
#' @return A reactive values containing a
#' `dock_view_proxy` object initialized with
#' the initial state of the dock. This value is updated
#' each time the dock state changes (caused by a user action)
#' or from the server side using the proxy methods like
#' [add_panel()], [remove_panel()], etc.
#'
#' @export
#' @rdname dockview-proxy
dock_view_reactive_proxy <- function(
  id,
  session = getDefaultReactiveDomain()
) {
  input <- session$input
  state_id <- sprintf("%s_state", id)

  vals <- reactiveValues(proxy = NULL)
  # Check for initialization and listen to state changes
  observeEvent(
    {
      req(input[[sprintf("%s_initialized", id)]])
      input[[state_id]]
    },
    {
      vals$proxy <- dock_view_proxy(
        id,
        data = input[[state_id]],
        session
      )
    }
  )
  vals
}

#' Extract Panel IDs from Dock Layout
#'
#' Retrieves all panel identifiers from a dock layout structure.
#'
#' @param layout A dock layout list containing grid and panels structures.
#' @return A character vector of panel IDs, or
#' NULL if no panels exist.
#' @export
#' @rdname dockview-proxy-utils
get_panel_ids <- function(layout) {
  panels <- layout[["panels"]]
  if (is.null(panels) || length(panels) == 0) {
    return(NULL)
  }
  names(panels)
}

#' Extract Group IDs from Dock Layout
#'
#' Recursively traverses the dock grid structure to extract all group identifiers.
#'
#' @return A character vector of group IDs in
#' traversal order, or NULL if no groups exist.
#' @export
#' @rdname dockview-proxy-utils
get_group_ids <- function(layout) {
  extract_group_ids <- function(node) {
    if (node[["type"]] == "leaf") {
      return(node[["data"]][["id"]])
    } else if (node[["type"]] == "branch") {
      return(unlist(lapply(node[["data"]], extract_group_ids)))
    }
    NULL
  }

  root <- layout[["grid"]][["root"]]
  if (is.null(root)) {
    return(NULL)
  }

  result <- extract_group_ids(root)
  if (length(result) == 0) NULL else result
}

#' Map Groups to Their Panels
#'
#' Creates a mapping between group IDs and the panel IDs they contain.
#'
#' @return A named list where names are group IDs
#' and values are character vectors of panel IDs,
#' or NULL if no groups exist.
#' @export
#' @rdname dockview-proxy-utils
get_panel_group <- function(layout) {
  root <- layout[["grid"]][["root"]]
  if (is.null(root)) {
    return(NULL)
  }

  map_panels <- function(node) {
    if (is.null(node)) {
      return(list())
    }

    if (node[["type"]] == "leaf") {
      views <- node[["data"]][["views"]]
      group_id <- node[["data"]][["id"]]

      if (is.null(views) || length(views) == 0) {
        return(list())
      }

      # Create a list with group_id as name and panels as value
      result <- list()
      result[[group_id]] <- unlist(views)
      return(result)
    } else if (node[["type"]] == "branch") {
      # Use do.call and c to combine all child results
      child_results <- lapply(node[["data"]], map_panels)
      do.call(c, child_results)
    } else {
      list()
    }
  }

  result <- map_panels(root)
  if (length(result) == 0) {
    return(NULL)
  }
  result
}

#' Find a panel in a group mapping
#'
#' Given a panel ID and a mapping of groups to panels,
#' returns the group ID that contains the specified panel.
#'
#' @param id Panel ID to search for.
#' @param panel_groups_map Returned by [get_panel_group()].
#' @return A character string representing the group ID
#' containing the panel, or NULL if not found.
#' @export
find_panel_group <- function(id, panel_groups_map) {
  names(panel_groups_map)[sapply(panel_groups_map, function(x) id %in% x)]
}

#' Get Active Group ID
#'
#' Retrieves the currently active group identifier from the dock layout.
#'
#' @return A character string representing the active
#' group ID, or NULL if none set.
#' @export
#' @rdname dockview-proxy-utils
get_active_group <- function(layout) {
  layout[["activeGroup"]]
}

#' Get Active Panel for Each Group
#'
#' Creates a mapping between group IDs and their currently active panel IDs.
#'
#' @return A named character vector where names are
#' group IDs and values are active panel IDs, or
#' NULL if no groups exist.
#' @export
#' @rdname dockview-proxy-utils
get_active_panel_group <- function(layout) {
  root <- layout[["grid"]][["root"]]
  if (is.null(root)) {
    return(NULL)
  }

  extract_active <- function(node) {
    if (node[["type"]] == "leaf") {
      active_view <- node[["data"]][["activeView"]]
      group_id <- node[["data"]][["id"]]
      if (is.null(active_view) || is.null(group_id)) {
        return(NULL)
      }
      setNames(active_view, group_id)
    } else if (node[["type"]] == "branch") {
      unlist(lapply(node[["data"]], extract_active))
    } else {
      NULL
    }
  }

  result <- extract_active(root)
  if (length(result) == 0) NULL else result
}

#' Get Active Panel
#'
#' Retrieves the active panel ID for the currently active group in a dock.
#'
#' @param state A list containing the dock state data after
#' calling [dock_view_reactive_proxy()], typically accessed via
#'   `dock[["proxy"]][["data"]]`. Must contain:
#'   - `active_group`: The ID of the currently active group
#'   - `active_views`: A named list mapping group IDs to their active panel IDs
#'
#' @return A character string representing the active panel ID.
#'
#' @details
#' This function is used internally to determine which panel is currently
#' active within the active group of a dockview. In dockview terminology,
#' each group can contain multiple panels (e.g., in tabs), but only one
#' panel per group can be active at a time.
#'
#' @seealso
#' \code{\link{select_panel}} for selecting a different panel,
#' \code{\link{dock_view_proxy}} for creating the dock proxy object
#' @export
get_active_panel <- function(state) {
  active_group <- state[["active_group"]]
  active_views <- state[["active_views"]]

  # We need no check since there is always an active group
  # and an active view.

  active_views[[active_group]]
}
