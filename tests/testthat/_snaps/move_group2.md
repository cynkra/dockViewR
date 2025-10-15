# move group works

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

