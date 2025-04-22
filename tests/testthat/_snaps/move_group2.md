# move group works

    Code
      move_group2("dock", "test", 2, session = session)
      move_group2("dock", 1, "test", session = session)
    Condition
      Error in `move_group2()`:
      ! <Panel (ID: 1)>: invalid value (1) for `from`. Valid panel ids are: 2, 3, test.
    Code
      move_group2("dock", "test", "test", session = session)
    Condition
      Error in `move_group2()`:
      ! <Panel (ID: test)>: `from` and `to` must be different panel ids.
    Code
      move_group2("dock", "test", 2, position = "plop", session = session)
    Condition
      Error in `move_group2()`:
      ! <Panel (ID: test)>: invalid value for `position`. `position` must be one of left, right, top, bottom, center.

