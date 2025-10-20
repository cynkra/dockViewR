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

# move group works

    Code
      move_group(dock_proxy, 1, 1)
    Condition
      Error in `validate_move_targets()`:
      ! <PanelGroup (ID: 1)>: `from` and `to` must be different group ids.
    Code
      move_group(dock_proxy, 1, 2, position = "plop")
    Condition
      Error in `validate_position()`:
      ! <Panel (ID: 1)>: invalid value (plop) for `position`. `position` must be one of left, right, top, bottom, center.

# move group 2 works

    Code
      move_group2(dock_proxy, "test", "test")
    Condition
      Error in `validate_move_targets()`:
      ! <Panel (ID: test)>: `from` and `to` must be different group ids.
    Code
      move_group2(dock_proxy, "test", 2, position = "plop")
    Condition
      Error in `validate_position()`:
      ! <Panel (ID: test)>: invalid value (plop) for `position`. `position` must be one of left, right, top, bottom, center.

# move_panel works

    Code
      move_panel(dock_proxy, id = "test", index = 3, position = "testposition")
    Condition
      Error in `validate_position()`:
      ! <Panel (ID: test)>: invalid value (testposition) for `position`. `position` must be one of left, right, top, bottom, center.

