# move_panel works

    Code
      move_panel("dock", 4, session = session)
    Condition
      Error in `move_panel()`:
      ! <Panel (ID: 4)>: invalid value (4) for `id`. Valid ids are: 2, 3, test.
    Code
      move_panel("dock", id = "test", index = 3, position = "testposition", session = session)
    Condition
      Error in `move_panel()`:
      ! <Panel (ID: test)>: invalid value (testposition) for `position`. `position` must be one of left, right, top, bottom, center.
    Code
      move_panel("dock", 3, session = session)
    Condition
      Error in `move_panel()`:
      ! <Panel (ID: 3)>: `index` cannot be NULL.
    Code
      move_panel("dock", 3, index = -2, session = session)
    Condition
      Error in `move_panel()`:
      ! <Panel (ID: 3)>: invalid value (-2) for `index`. `index` should belong to [1, 3].
    Code
      move_panel("dock", 3, index = 20, session = session)
    Condition
      Error in `move_panel()`:
      ! <Panel (ID: 3)>: invalid value (20) for `index`. `index` should belong to [1, 3].
    Code
      move_panel("dock", 3, group = 4, session = session)
    Condition
      Error in `move_panel()`:
      ! <PanelGroup (ID: 3)>: invalid value (3) for `id`. Valid ids are: 2, 3, test.

