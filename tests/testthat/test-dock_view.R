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

  # Named panels raised a warning as names
  # are ignored.
  expect_warning(
    dock_view(
      panels = list(
        a = panel(
          id = 1,
          title = "title",
          content = shiny::h1("content")
        )
      )
    )
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

test_that("get dock view mode", {
  expect_identical(get_dock_view_mode(), "prod")
  withr::local_options("dockViewR.mode" = "dev")
  expect_identical(get_dock_view_mode(), "dev")
  withr::local_options("dockViewR.mode" = "pouet")
  expect_snapshot(get_dock_view_mode(), error = TRUE)
})
