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
  if (!(position[["direction"]] %in% valid_directions)) {
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

#' @keywords internal
is_js <- function(x) {
  inherits(x, "JS_EVAL")
}
