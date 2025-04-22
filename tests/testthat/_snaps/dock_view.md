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

