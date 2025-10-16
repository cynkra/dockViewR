# dock_view works

    Code
      dock_view(pnls)
    Condition
      Error in `check_panel_ids()`:
      ! <Panels>: duplicated ids found: id-1

---

    Code
      dock_view(pnls)
    Condition
      Error in `check_panel_ids()`:
      ! <Panels>: duplicated ids found: id-1, id-2

---

    Code
      dock_view(panels = list(panel(id = 4, "plop", "Panel 4", position = list(
        referencePanel = 10, direction = "above"))))
    Condition
      Error in `check_panel_refs()`:
      ! <Panel (ID: 4)>: invalid value (10) for `referencePanel`. Valid ids are: 4.
    Code
      dock_view(panels = list(), add_tab = list(enable = "plop"))
    Condition
      Error in `validate_add_tab()`:
      ! `add_tab$enable` must be a boolean.
    Code
      dock_view(panels = list(), add_tab = list(enable = TRUE, callback = "plop"))
    Condition
      Error in `validate_js_callback()`:
      ! `callback` must be a JavaScript function created with htmlwidgets::JS().

# validate js callback works

    Code
      validate_js_callback(1)
    Condition
      Error in `validate_js_callback()`:
      ! `callback` must be a JavaScript function created with htmlwidgets::JS().
    Code
      validate_js_callback("blabla")
    Condition
      Error in `validate_js_callback()`:
      ! `callback` must be a JavaScript function created with htmlwidgets::JS().

