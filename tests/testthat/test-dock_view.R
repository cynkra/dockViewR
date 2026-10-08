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

test_that("dock_view takes its close icon as HTML or a tag", {
  pnls <- list(panel(id = 1, title = "title", content = "content"))
  svg <- '<svg class="thin-x"></svg>'

  # Without one, the dock sends the same payload it always did.
  expect_false("closeIcon" %in% names(dock_view(pnls)$x))

  expect_identical(dock_view(pnls, close_icon = svg)$x$closeIcon, svg)
  expect_identical(
    dock_view(pnls, close_icon = shiny::icon("xmark"))$x$closeIcon,
    as.character(shiny::icon("xmark"))
  )

  expect_error(dock_view(pnls, close_icon = 1), "`close_icon`")
  expect_error(dock_view(pnls, close_icon = c(svg, svg)), "`close_icon`")
})

test_that("every manual tab draws the dock's close icon, restored ones included", {
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "close_icon")

  app <- shinytest2::AppDriver$new(
    appdir,
    name = "close_icon",
    seed = 121,
    height = 752,
    width = 1211
  )
  on.exit(app$stop(), add = TRUE)
  app$wait_for_idle()

  close_icons <- function() {
    unlist(app$get_js(
      "['dock-tab-own', 'plain-tab-default'].map(function (id) {
         var icon = document.querySelector('#' + id + ' .dv-default-tab-action > *');
         return icon && icon.getAttribute('class');
       })"
    ))
  }

  expect_identical(close_icons(), c("thin-x", "fas fa-xmark"))

  # The icon is the dock's, so the saved layout carries none, and a restore
  # builds the tab with the dock's icon again. Clearing the drawn icons first
  # means only a rebuilt tab passes.
  app$click("save")
  app$wait_for_idle()
  expect_false(grepl(
    "thin-x",
    app$get_js("JSON.stringify(Shiny.shinyapp.$inputValues['dock_state'])"),
    fixed = TRUE
  ))

  app$run_js(
    "document.querySelectorAll('#dock .dv-default-tab-action')
       .forEach(function (action) { action.innerHTML = ''; });"
  )
  app$click("restore")
  app$wait_for_idle()

  expect_identical(close_icons(), c("thin-x", "fas fa-xmark"))
})

test_that("get dock view mode", {
  expect_identical(get_dock_view_mode(), "prod")
  withr::local_options("dockViewR.mode" = "dev")
  expect_identical(get_dock_view_mode(), "dev")
  withr::local_options("dockViewR.mode" = "pouet")
  expect_snapshot(get_dock_view_mode(), error = TRUE)
})
