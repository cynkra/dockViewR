test_that("dock_view works", {
  pnls <- lapply(
    paste0("id-", c(1, 2, 1)),
    \(x) panel(id = x, title = "title", content = shiny::h1("content"))
  )
  expect_error(
    dock_view(pnls),
    regexp = "you have duplicated ids: id-1$"
  )

  pnls <- lapply(
    paste0("id-", c(1, 2, 1, 2)),
    \(x) panel(id = x, title = "title", content = shiny::h1("content"))
  )
  expect_error(
    dock_view(pnls),
    regexp = "you have duplicated ids: id-1, id-2$"
  )
})
