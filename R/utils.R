dropNulls <- function(x) {
  x[!vapply(x, is.null, FUN.VALUE = logical(1))]
}

code_chunk <- function(output, language = "r") {
  cat(paste0("```", language, "\n"))
  cat(output)
  cat("\n```\n")
}

print_r_code <- function(path) {
  path <- system.file(
    path,
    package = utils::packageName()
  )
  lines <- readLines(path)
  code_chunk(cat(paste(lines, collapse = "\n")))
}

#' @keywords internal
extract_panel_deps <- function(panels) {
  dropNulls(
    lapply(panels, function(panel) {
      if (length(panel$content$dependencies)) {
        panel$content$dependencies
      } else {
        NULL
      }
    })
  )
}

#' @keywords internal
check_panel_ids <- function(panels) {
  ids <- unlist(lapply(panels, function(x) x$id))
  dupes <- unique(ids[duplicated(ids)])
  if (length(dupes)) {
    stop(sprintf(
      "<Panels>: duplicated ids found: %s",
      paste(dupes, collapse = ", ")
    ))
  }
  invisible(ids)
}

#' @keywords internal
check_panel_refs <- function(panels, ids) {
  refs <- unlist(lapply(
    panels,
    function(x) {
      res <- c(x[["position"]][["referencePanel"]])
      if (!is.null(res)) {
        names(res) <- x[["id"]]
      }
      res
    }
  ))
  if (is.null(refs)) {
    return(NULL)
  }
  if (any(!(refs %in% ids))) {
    wrong_id <- which(!(refs %in% ids))
    stop(
      sprintf(
        "<Panel (ID: %s)>: invalid value (%s) for `referencePanel`. Valid ids are: %s.",
        names(refs)[wrong_id],
        refs[wrong_id],
        paste(ids, collapse = ", ")
      )
    )
  }
  invisible(refs)
}

#' @keywords internal
valid_directions <- c("above", "below", "left", "right", "within")

#' @keywords internal
valid_positions <- c("left", "right", "top", "bottom", "center")

#' @keywords internal
valid_position_names <- c(
  "referencePanel",
  "direction",
  "referenceGroup",
  "index"
)

#' @keywords internal
process_panel_position <- function(
  id,
  position
) {
  # Check names
  validate_position_names(id, position)
  if (!is.null(position[["referencePanel"]])) {
    position[["referencePanel"]] <- as.character(position[["referencePanel"]])
  }
  if (!is.null(position[["referenceGroup"]])) {
    position[["referenceGroup"]] <- as.character(position[["referenceGroup"]])
  }
  # Check position
  validate_position_direction(id, position)
  invisible(position)
}

#' @keywords internal
validate_position_names <- function(id, position) {
  if (length(position) == 0) {
    stop(sprintf(
      "<Panel (ID: %s)>: `position` must be a non-empty list.",
      id
    ))
  }
  if (any(!(names(position) %in% valid_position_names))) {
    invalid_names <- which(!(names(position) %in% valid_position_names))
    stop(
      sprintf(
        "<Panel (ID: %s)>: `position` must be a list with a subset of names: %s.
        Found wrong values: %s.",
        id,
        paste(valid_position_names, collapse = ", "),
        paste(names(position)[invalid_names], collapse = ", ")
      )
    )
  }
}

#' @keywords internal
validate_position_direction <- function(id, position) {
  direction <- position[["direction"]]
  # `direction` is optional when targeting a `referenceGroup` (e.g. an edge
  # group): the panel is added inside that group with no further placement.
  if (is.null(direction)) {
    return(invisible(NULL))
  }
  if (!(direction %in% valid_directions)) {
    stop(sprintf(
      "<Panel (ID: %s)>: `direction` must be one of %s.",
      id,
      paste(valid_directions, collapse = ", ")
    ))
  }
}

`%OR%` <- function(x, y) {
  if (is.null(x)) y else x
}

#' Normalise pixel dimensions in a grid list
#'
#' Replaces absolute pixel sizes in a grid returned by [get_grid()] by the
#' share each child takes of its parent branch, rounded to `digits` decimals.
#' The top-level `width` and `height` (viewport-dependent) are dropped.
#'
#' Useful when comparing dock state in a `{shinytest2}` snapshot: absolute
#' pixel sizes drift by a few units across Chromium and OS versions (causing
#' fragile CI failures), while the *relative* layout (the actual invariant
#' dockview preserves) stays stable and still catches real regressions
#' (e.g. a panel collapsing to a sliver when it should be half the dock).
#'
#' @param x A list, typically the result of [get_grid()].
#' @param digits Number of decimals to round shares to. Default `2`.
#' @return The same list with each branch's child `size` replaced by its
#'   share of the branch total, the branch's own `size` removed, and the
#'   grid-level `width` / `height` removed.
#' @export
normalize_dock_dims <- function(x, digits = 2L) {
  if (!is.list(x)) return(x)

  # Top-level grid: drop viewport-dependent width / height, recurse into root.
  if (!is.null(x[["root"]])) {
    x[["width"]] <- NULL
    x[["height"]] <- NULL
    x[["root"]] <- normalize_dock_dims(x[["root"]], digits = digits)
    return(x)
  }

  # Branch: replace each child's `size` by its share of the branch total,
  # then drop the branch's own (redundant) `size`.
  if (identical(x[["type"]], "branch") && is.list(x[["data"]])) {
    children <- x[["data"]]
    sizes <- vapply(children, function(child) {
      s <- child[["size"]]
      if (is.null(s)) NA_real_ else as.numeric(s)
    }, numeric(1))
    total <- sum(sizes[!is.na(sizes)])
    for (i in seq_along(children)) {
      if (!is.na(sizes[i]) && total > 0) {
        children[[i]][["size"]] <- round(sizes[i] / total, digits)
      }
      children[[i]] <- normalize_dock_dims(children[[i]], digits = digits)
    }
    x[["data"]] <- children
    x[["size"]] <- NULL
    return(x)
  }

  # Leaf or other list: recurse to handle any nested branches.
  lapply(x, normalize_dock_dims, digits = digits)
}

#' @keywords internal
is_js <- function(x) {
  inherits(x, "JS_EVAL")
}
