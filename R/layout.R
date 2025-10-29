#' @keywords internal
make_grid <- function(root_data = list()) {
  if (length(root_data) > 1) {
    root <- list(
      type = "branch",
      data = root_data,
      size = 0L
    )
  } else if (length(root_data) == 1) {
    root <- root_data[[1]]
  } else {
    root <- list(type = "branch", data = list(), size = 0L)
  }
  list(
    root = root,
    width = 0L,
    height = 0L,
    orientation = "HORIZONTAL"
  )
}

#' Dockview Layout Constructor
#'
#' Create a new `dock_layout` object that holds
#' a compatible layout for dockview.
#'
#' @param grid,panels,active_group Layout components
#' @rdname layout
#' @export
new_dock_layout <- function(
  grid = NULL,
  panels = NULL,
  active_group = NULL
) {
  if (is.null(grid)) {
    grid <- make_grid()
  }

  if (is.null(panels)) {
    panels <- stats::setNames(list(), character(0L))
  }

  content <- list(grid = grid, panels = panels)

  if (!is.null(active_group)) {
    content <- c(content, list(activeGroup = active_group))
  }

  validate_dock_layout(
    structure(content, class = "dock_layout")
  )
}

#' @rdname layout
#' @export
is_dock_layout <- function(x) {
  inherits(x, "dock_layout")
}

is_empty_layout <- function(x) length(x[["panels"]]) == 0L

#' @rdname layout
#' @export
validate_dock_layout <- function(x, ...) {
  UseMethod("validate_dock_layout")
}

#' @export
validate_dock_layout.dock_layout <- function(
  x,
  ...
) {
  if (is.null(x)) {
    return(x)
  }

  if (!is.list(x) || !is_dock_layout(x)) {
    abort(
      "Expecting the `layout` component of a `dock_board` to be a list ",
      "inheriting from `dock_layout`.",
      class = "dock_layout_invalid"
    )
  }

  required <- c("grid", "panels")

  if (!all(required %in% names(x))) {
    abort(
      "Expecting a `layout` to contain component{?s} {required}.",
      class = "dock_layout_invalid"
    )
  }

  unexpected <- setdiff(names(x), c(required, "activeGroup"))

  if (length(unexpected)) {
    abort(
      "Not expecting `layout` component{?s} {unexpected}.",
      class = "dock_layout_invalid"
    )
  }

  x
}

#' @rdname layout
#' @export
as_dock_layout <- function(x, ...) {
  UseMethod("as_dock_layout")
}

#' @export
as_dock_layout.dock_layout <- function(x, ...) x

#' @export
as_dock_layout.list <- function(x, ...) {
  if ("activeGroup" %in% names(x)) {
    names(x)[names(x) == "activeGroup"] <- "active_group"
  }

  do.call(new_dock_layout, x)
}

#' @rdname layout
#' @export
layout_panel_ids <- function(x) {
  x <- as_dock_layout(x)
  chr_xtr(x[["panels"]], "id")
}

#' @rdname layout
#' @export
empty_dock_layout <- function() {
  new_dock_layout()
}

#' @keywords internal
make_group_id <- function(i) paste0("group_", i)

#' @keywords internal
make_panel <- function(id, remove = FALSE) {
  tab_component <- if (remove) "manual" else "custom"

  list(
    id = id,
    contentComponent = "default",
    tabComponent = tab_component,
    params = list(
      content = list(html = paste("Panel", id)),
      style = "padding:10px;overflow:auto;height:100%;margin:10px;"
    ),
    title = id
  )
}

#' @keywords internal
make_group_leaf <- function(tab_ids, group_id) {
  list(
    type = "leaf",
    data = list(
      views = as.list(tab_ids),
      activeView = tab_ids[[1]],
      id = group_id
    )
  )
}

#' @keywords internal
make_branch <- function(groups) {
  list(
    type = "branch",
    data = groups,
    size = 0L
  )
}

#' @keywords internal
process_column <- function(col_groups, group_idx, panels, group_ids, remove) {
  if (!is.list(col_groups)) {
    col_groups <- list(col_groups)
  }
  col_data <- list()
  for (row in seq_along(col_groups)) {
    tab_ids <- col_groups[[row]]
    group_id <- make_group_id(group_idx)
    group_ids <- c(group_ids, group_id)
    for (tab_id in tab_ids) {
      tmp_remove <- length(remove) > 0 && tab_id %in% remove
      panels[[tab_id]] <- make_panel(tab_id, tmp_remove)
    }
    col_data[[row]] <- make_group_leaf(tab_ids, group_id)
    group_idx <- group_idx + 1
  }
  list(
    col_data = col_data,
    group_idx = group_idx,
    panels = panels,
    group_ids = group_ids
  )
}

#' Convert a tree structure to a dock_layout
#'
#' @param tree nested List representing the layout tree.
#' @param remove Character vector of panel IDs to mark as to be closable.
#' @param activeGroup Optional active group ID.
#'
#' @rdname layout
#'
#' @export
tree_to_dock_layout <- function(tree, remove, active_group = NULL) {
  panels <- list()
  group_idx <- 1
  root_data <- list()
  group_ids <- c()
  for (col in seq_along(tree)) {
    res <- process_column(tree[[col]], group_idx, panels, group_ids, remove)
    col_data <- res$col_data
    group_idx <- res$group_idx
    panels <- res$panels
    group_ids <- res$group_ids
    if (length(col_data) > 1) {
      root_data[[col]] <- make_branch(col_data)
    } else {
      root_data[[col]] <- col_data[[1]]
    }
  }
  grid <- make_grid(root_data)
  if (is.null(active_group)) {
    active_group <- group_ids[[1]]
  }
  new_dock_layout(
    grid = grid,
    panels = structure(unname(panels), names = names(panels)),
    active_group = active_group
  )
}
