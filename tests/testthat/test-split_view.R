test_that("split_view works", {
  pnls <- lapply(
    paste0("id-", c(1, 2, 1)),
    \(x) panel(id = x, title = "title", content = shiny::h1("content"))
  )

  expect_snapshot(error = TRUE, split_view(pnls))

  pnls <- lapply(
    paste0("id-", c(1, 2, 1, 2)),
    \(x) panel(id = x, title = "title", content = shiny::h1("content"))
  )
  expect_snapshot(error = TRUE, split_view(pnls))

  expect_s3_class(
    split_view(
      panels = list(
        panel(
          id = 1,
          title = "title",
          content = shiny::h1("content")
        )
      )
    ),
    "splitview"
  )
})

library(shinytest2)

test_that("split_view demo works", {
  # Don't run these tests on the CRAN build servers
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "split_view")
  app <- AppDriver$new(
    appdir,
    name = "split_view",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$expect_values()
  app$set_inputs(obs = 678)
  app$expect_values(
    output = FALSE,
    export = TRUE
  )
  app$set_inputs(nodeSelectnetwork = character(0))
  app$set_inputs(selectedBynetwork = character(0))
  app$expect_values(
    output = FALSE,
    export = TRUE
  )
  app$expect_values(
    output = FALSE,
    export = TRUE
  )
  app$set_inputs(variable = "am")
  app$expect_values(
    output = FALSE,
    export = TRUE
  )
})
