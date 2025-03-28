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

#' list all available panels
#' @param proxy Result of [dock_view()] or a character with the ID of the dockview.
#' @param session shiny session object.
#' @export
list_panels <- function(proxy, session = shiny::getDefaultReactiveDomain()) {
  ID <- session$ns(proxy) 
  session$input[[sprintf("%s_panel_ids", ID)]]
}