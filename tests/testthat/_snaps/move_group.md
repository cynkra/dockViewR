# move group works

    Code
      move_group("dock", "test", 2, session = session)
    Condition
      Error in `move_group()`:
      ! <PanelGroup (ID: test)>: invalid value (test) for `from`. Valid group ids are: 1, 2.
    Code
      move_group("dock", 1, "test", session = session)
    Condition
      Error in `move_group()`:
      ! <PanelGroup (ID: 1)>: invalid value (test) for `to`. Valid group ids are: 1, 2.
    Code
      move_group("dock", 1, 1, session = session)
    Condition
      Error in `move_group()`:
      ! <PanelGroup (ID: 1)>: `from` and `to` must be different group ids.
    Code
      move_group("dock", 1, 2, position = "plop", session = session)
    Condition
      Error in `move_group()`:
      ! <PanelGroup (ID: 1)>: invalid value for `position`. `position` must be one of left, right, top, bottom, center.

