#' Edge group
#'
#' Create an edge group, that is a [group](https://dockview.dev/docs/core/groups/edgeGroups)
#' pinned to one of the four edges (left, right, top, bottom) of a
#' [dock_view()]. Edge groups support tabs, drag-and-drop, overflow and the
#' full group panel API. They cannot be maximised, floated or popped out.
#'
#' Pass edge groups to [dock_view()] through `edge_groups`, or add them on
#' the fly from the server with [add_edge_group()].
#'
#' @param id Edge group unique id. Used to reference the group from a
#'   [panel()]'s `position = list(referenceGroup = ...)`.
#' @param position Edge on which to pin the group. One of `"left"`,
#'   `"right"`, `"top"`, `"bottom"`.
#' @param initial_size Initial size of the edge group, in pixels.
#' @param minimum_size Minimum size of the edge group, in pixels.
#' @param maximum_size Maximum size of the edge group, in pixels.
#' @param collapsed Whether the edge group is initially collapsed.
#' @param collapsed_size Size of the edge group when collapsed, in pixels.
#'   Defaults to `35` on the dockview side.
#' @param ... Other options forwarded to `api.addEdgeGroup()`. See
#'   \url{https://dockview.dev/docs/core/groups/edgeGroups}. Use the
#'   JavaScript option names (camelCase) for these extras.
#'
#' @return A list of class `dock_edge_group` with the camelCased options
#'   ready to be sent to the dockview JavaScript API. Contains at least:
#'   - `id`: the edge group id (string).
#'   - `position`: one of `"left"`, `"right"`, `"top"`, `"bottom"`.
#'   - `options`: a list of options forwarded to `api.addEdgeGroup()`.
#'
#' @seealso [add_edge_group()], [remove_edge_group()],
#'   [set_edge_group_visible()].
#'
#' @export
edge_group <- function(
  id,
  position = c("left", "right", "top", "bottom"),
  initial_size = NULL,
  minimum_size = NULL,
  maximum_size = NULL,
  collapsed = FALSE,
  collapsed_size = NULL,
  ...
) {
  position <- match.arg(position)

  if (missing(id) || is.null(id) || !nzchar(as.character(id))) {
    stop("<EdgeGroup>: `id` is required and must be a non-empty string.")
  }

  id <- as.character(id)

  if (!is.logical(collapsed) || length(collapsed) != 1) {
    stop(sprintf(
      "<EdgeGroup (ID: %s)>: `collapsed` must be a single boolean value.",
      id
    ))
  }

  options <- dropNulls(list(
    id = id,
    initialSize = initial_size,
    minimumSize = minimum_size,
    maximumSize = maximum_size,
    collapsed = collapsed,
    collapsedSize = collapsed_size,
    ...
  ))

  structure(
    list(
      id = id,
      position = position,
      options = options
    ),
    class = c("dock_edge_group", "list")
  )
}

#' Check whether an object is an edge group
#'
#' @param x An object to test.
#' @return Logical value indicating whether `x` was created with [edge_group()].
#' @export
is_edge_group <- function(x) {
  inherits(x, "dock_edge_group")
}

#' @keywords internal
check_edge_groups <- function(edge_groups) {
  if (length(edge_groups) == 0) {
    return(invisible(edge_groups))
  }

  if (!is.list(edge_groups)) {
    stop("`edge_groups` must be a list of `edge_group()` objects.")
  }

  ok <- vapply(edge_groups, is_edge_group, logical(1))
  if (!all(ok)) {
    stop(
      "<EdgeGroups>: every element of `edge_groups` must be created with `edge_group()`."
    )
  }

  ids <- vapply(edge_groups, function(eg) eg[["id"]], character(1))
  dupes <- unique(ids[duplicated(ids)])
  if (length(dupes)) {
    stop(sprintf(
      "<EdgeGroups>: duplicated ids found: %s",
      paste(dupes, collapse = ", ")
    ))
  }

  positions <- vapply(edge_groups, function(eg) eg[["position"]], character(1))
  dup_pos <- unique(positions[duplicated(positions)])
  if (length(dup_pos)) {
    stop(sprintf(
      "<EdgeGroups>: at most one edge group per position is allowed. Duplicated: %s",
      paste(dup_pos, collapse = ", ")
    ))
  }

  invisible(edge_groups)
}

#' @keywords internal
valid_edge_positions <- c("left", "right", "top", "bottom")

#' @keywords internal
validate_edge_position <- function(position, context_id = NULL) {
  if (length(position) != 1 || !(position %in% valid_edge_positions)) {
    context <- if (!is.null(context_id)) {
      sprintf(" (ID: %s)", context_id)
    } else {
      ""
    }
    stop(sprintf(
      "<EdgeGroup%s>: invalid value (%s) for `position`. `position` must be one of %s.",
      context,
      paste(position, collapse = ", "),
      paste(valid_edge_positions, collapse = ", ")
    ))
  }
  invisible(position)
}
