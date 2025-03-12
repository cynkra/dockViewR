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
