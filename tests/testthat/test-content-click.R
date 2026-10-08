library(shinytest2)

test_that("a press on panel content activates the panel once it ends", {
  # Synthetic pointer events move no focus, so they stand in for content that
  # cancels the press's default action (plotly's drag-zoom), which dockview's
  # focus-driven activation never sees.
  skip_on_cran()

  app <- AppDriver$new(
    shiny::shinyApp(
      shiny::fluidPage(dockViewOutput("dock")),
      function(input, output, session) {
        output$dock <- renderDockView(
          dock_view(
            panels = list(
              panel(id = "a", title = "A", content = "Panel A"),
              panel(
                id = "b",
                title = "B",
                content = "Panel B",
                position = list(referencePanel = "a", direction = "right")
              )
            )
          )
        )
      }
    ),
    name = "content_click",
    seed = 121,
    height = 752,
    width = 1211
  )
  on.exit(app$stop(), add = TRUE)
  app$wait_for_idle()

  active <- function() {
    app$get_js("HTMLWidgets.find('#dock').getWidget().activePanel.id")
  }

  expect_identical(active(), "b")

  app$run_js(
    "document.getElementById('dock-a').dispatchEvent(
      new PointerEvent('pointerdown', { bubbles: true, cancelable: true })
    );"
  )
  # Still pressed: activating now would land in the middle of the gesture.
  expect_identical(active(), "b")

  # Released elsewhere: the press still counts.
  app$run_js(
    "document.body.dispatchEvent(
      new PointerEvent('pointerup', { bubbles: true, cancelable: true })
    );"
  )
  app$wait_for_idle()
  expect_identical(active(), "a")
  expect_identical(app$get_value(input = "dock_active-panel"), "a")

  # A cancelled press activates nothing.
  app$run_js(
    "document.getElementById('dock-b').dispatchEvent(
      new PointerEvent('pointerdown', { bubbles: true, cancelable: true })
    );
    document.body.dispatchEvent(
      new PointerEvent('pointercancel', { bubbles: true })
    );
    document.body.dispatchEvent(
      new PointerEvent('pointerup', { bubbles: true })
    );"
  )
  app$wait_for_idle()
  expect_identical(active(), "a")
})
