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
#' An edge group's size, visibility, collapsed state and panel contents are part
#' of the serialised layout, so [save_dock()] and [restore_dock()] round-trip a
#' rail along with the rest of the dock.
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
#'   Two of those options need a dockview module that this package does not
#'   bundle, and have no effect here: `autoHide`, the pinnable tool-window
#'   behaviour, and `dockToEdgeGroups`, which reveals an edge by dragging onto
#'   it. Both ship in the commercially licensed `dockview-enterprise`. Setting
#'   either logs an error in the browser console naming the missing module.
#'
#'   Everything else about an edge group is core, including collapsing. Clicking
#'   the active tab of a rail collapses it to `collapsed_size` and clicking again
#'   expands it, and it can be resized with the sash. Note that collapsing and
#'   [set_edge_group_visible()] are different: a collapsed rail leaves its header
#'   strip standing, while an invisible one renders at zero and leaves the
#'   collapsed state untouched.
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

  if (
    missing(id) ||
      is.null(id) ||
      length(id) != 1L ||
      is.na(id) ||
      !nzchar(as.character(id))
  ) {
    stop("<EdgeGroup>: `id` is required and must be a single non-empty string.")
  }

  id <- as.character(id)

  if (!is.logical(collapsed) || length(collapsed) != 1 || is.na(collapsed)) {
    stop(sprintf(
      "<EdgeGroup (ID: %s)>: `collapsed` must be a single boolean value.",
      id
    ))
  }

  # The values themselves cannot be checked here: `initialSize` is a request
  # against a splitview whose available space dockview resolves at layout, as are
  # the min and max. Type and domain can be.
  validate_edge_size(initial_size, "initial_size", id)
  validate_edge_size(minimum_size, "minimum_size", id)
  validate_edge_size(maximum_size, "maximum_size", id)
  validate_edge_size(collapsed_size, "collapsed_size", id)

  if (
    !is.null(minimum_size) &&
      !is.null(maximum_size) &&
      minimum_size > maximum_size
  ) {
    stop(sprintf(
      "<EdgeGroup (ID: %s)>: `minimum_size` must not exceed `maximum_size`.",
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
# A pixel dimension forwarded to dockview: optional, and when given a single
# finite non-negative number. Whether it can be satisfied is dockview's business,
# not ours.
validate_edge_size <- function(value, arg, id) {
  if (is.null(value)) {
    return(invisible(NULL))
  }

  ok <- is.numeric(value) &&
    length(value) == 1L &&
    !is.na(value) &&
    is.finite(value) &&
    value >= 0

  if (!ok) {
    stop(sprintf(
      "<EdgeGroup (ID: %s)>: `%s` must be a single non-negative number.",
      id,
      arg
    ))
  }

  invisible(NULL)
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
