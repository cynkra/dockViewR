# add_panel works

    Code
      add_panel("dock", panel(id = "test", "plop", "Panel 1"), session = session)
    Condition
      Error in `add_panel()`:
      ! <Panel (ID: test)>: invalid value (test) for `id`: already in use.
    Code
      add_panel("dock", panel(id = 4, "plop", "Panel 4", position = list(pouet = 3,
        plop = "test")), session = session)
    Condition
      Error in `validate_position_names()`:
      ! <Panel (ID: 4)>: `position` must be a list with a subset of names: referencePanel, direction, referenceGroup, index.
              Found wrong values: pouet, plop.
    Code
      add_panel("dock", panel(id = 4, "plop", "Panel 4", position = list(
        referencePanel = 1, direction = "top")), session = session)
    Condition
      Error in `validate_position_direction()`:
      ! <Panel (ID: 4)>: `direction` must be one of above, below, left, right, within.
    Code
      add_panel("dock", panel(id = 4, "plop", "Panel 4", position = list(
        referencePanel = 10, direction = "above")), session = session)
    Condition
      Error in `validate_position_ref()`:
      ! <Panel (ID: 4)>: invalid value (10) for `referencePanel`. Valid ids are: 2, 3, test.

