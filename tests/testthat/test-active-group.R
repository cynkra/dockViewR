library(shinytest2)

test_that("active_group app works", {
  # Regression test for the race condition where `input[["<dock>_active-group"]]`
  # was updated by dockview AFTER the Shiny observer fired, causing repeated
  # button clicks inside a panel to add panels to the wrong group.
  # Guards the capture-phase pointerdown handler in `srcjs/modules/components.js`.
  # Verified by A/B on dockview 8: without it panel 3 lands in group 1 instead of
  # group 2. Distinct from mathuo/dockview#1032 (which upstream fixed): that was
  # about tab clicks after addPanel/removePanel, whereas dockview by design does
  # not change the active group on a click inside a panel's content.
  skip_on_cran()

  appdir <- system.file(package = "dockViewR", "examples", "active_group")
  app <- AppDriver$new(
    appdir,
    name = "active_group",
    seed = 121,
    height = 752,
    width = 1211
  )
  app$wait_for_idle()

  # `app$click("add_panel")` would set the actionButton input directly via
  # websocket, bypassing DOM events — that would not exercise the pointerdown
  # handler we are testing. Dispatch a real DOM click sequence instead so the
  # capture-phase pointerdown on the panel container fires first.
  click_button <- function() {
    app$run_js(
      "(function() {
        var btn = document.getElementById('add_panel');
        var opts = { bubbles: true, cancelable: true };
        btn.dispatchEvent(new PointerEvent('pointerdown', opts));
        btn.dispatchEvent(new MouseEvent('mousedown', opts));
        btn.dispatchEvent(new MouseEvent('mouseup', opts));
        btn.dispatchEvent(new PointerEvent('pointerup', opts));
        btn.dispatchEvent(new MouseEvent('click', opts));
      })()"
    )
    app$wait_for_idle()
  }

  app$expect_values(input = FALSE, output = TRUE, export = TRUE)
  click_button()
  app$expect_values(input = FALSE, output = TRUE, export = TRUE)
  click_button()
  app$expect_values(input = FALSE, output = TRUE, export = TRUE)
  click_button()
  app$expect_values(input = FALSE, output = TRUE, export = TRUE)

  # Every added panel must land in group 2 (the "other" group from the panel
  # hosting the button). With a stale active-group, panels would alternate
  # between groups; with the fix, group 2 collects panels 2..5.
  groups_panels <- app$get_value(export = "groups_panels")
  expect_setequal(groups_panels[["1"]], "1")
  expect_setequal(groups_panels[["2"]], c("2", "3", "4", "5"))
})
