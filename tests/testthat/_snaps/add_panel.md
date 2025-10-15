# add_panel works

    Code
      add_panel("dock", panel(id = 4, "plop", "Panel 4"))
    Condition
      Error in `validate_dock_proxy()`:
      ! inherits(dock, "dock_view_proxy") is not TRUE
    Code
      add_panel(dock_proxy, panel(id = 4, "plop", "Panel 4", position = list(pouet = 3,
        plop = "test")))
    Condition
      Error in `validate_position_names()`:
      ! <Panel (ID: 4)>: `position` must be a list with a subset of names: referencePanel, direction, referenceGroup, index.
              Found wrong values: pouet, plop.
    Code
      add_panel(dock_proxy, panel(id = 4, "plop", "Panel 4", position = list(
        referencePanel = 1, direction = "top")))
    Condition
      Error in `validate_position_direction()`:
      ! <Panel (ID: 4)>: `direction` must be one of above, below, left, right, within.

