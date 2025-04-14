# move_panel works

    Code
      move_panel("dock", 4, session = session)
    Condition
      Error in `move_panel()`:
      ! <Panel (ID: 4)>: `id` cannot be found.
    Code
      move_panel("dock", 3, group = 4, session = session)
    Condition
      Error in `move_panel()`:
      ! <PanelGroup (ID: 3)>: `id` cannot be found.

