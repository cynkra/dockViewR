# move_panel works

    Code
      move_panel("dock", 4, session = session)
    Condition
      Error in `move_panel()`:
      ! <Panel (ID: 4)>: `id` cannot be found.
    Code
      move_panel("dock", id = "test", index = 3, position = "testposition", session = session)
    Condition
      Error in `move_panel()`:
      ! <Panel (ID: test)>: invalid position parameter. `position` must be one of left, right, top, bottom, center.
    Code
      move_panel("dock", 3, session = session)
    Condition
      Error in `move_panel()`:
      ! <Panel (ID: 3)>: `index` cannot be NULL.
    Code
      move_panel("dock", 3, index = -2, session = session)
    Condition
      Error in `move_panel()`:
      ! <Panel (ID: 3)>: `index` (value: -2) should belong to [1, 3].
    Code
      move_panel("dock", 3, index = 20, session = session)
    Condition
      Error in `move_panel()`:
      ! <Panel (ID: 3)>: `index` (value: 20) should belong to [1, 3].
    Code
      move_panel("dock", 3, group = 4, session = session)
    Condition
      Error in `move_panel()`:
      ! <PanelGroup (ID: 3)>: `id` cannot be found.

