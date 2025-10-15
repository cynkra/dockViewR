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

