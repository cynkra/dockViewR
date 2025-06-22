test_that("dock_view works", {
  pnls <- lapply(
    paste0("id-", c(1, 2, 1)),
    function(x) panel(id = x, title = "title", content = shiny::h1("content"))
  )

  expect_snapshot(error = TRUE, dock_view(pnls))

  pnls <- lapply(
    paste0("id-", c(1, 2, 1, 2)),
    function(x) panel(id = x, title = "title", content = shiny::h1("content"))
  )
  expect_snapshot(error = TRUE, dock_view(pnls))

  expect_snapshot(
    error = TRUE,
    {
      dock_view(
        panels = list(
          panel(
            id = 4,
            "plop",
            "Panel 4",
            position = list(referencePanel = 10, direction = "above")
          )
        )
      )
    }
  )

  expect_s3_class(
    dock_view(
      panels = list(
        panel(
          id = 1,
          title = "title",
          content = shiny::h1("content")
        )
      )
    ),
    "dockview"
  )
})
