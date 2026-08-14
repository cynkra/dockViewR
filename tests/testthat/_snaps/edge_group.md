# edge_group input validation

    Code
      edge_group(id = "x", position = "diagonal")
    Condition
      Error in `match.arg()`:
      ! 'arg' should be one of "left", "right", "top", "bottom"
    Code
      edge_group(id = "", position = "left")
    Condition
      Error in `edge_group()`:
      ! <EdgeGroup>: `id` is required and must be a non-empty string.
    Code
      edge_group(id = "x", position = "left", collapsed = "no")
    Condition
      Error in `edge_group()`:
      ! <EdgeGroup (ID: x)>: `collapsed` must be a single boolean value.

# check_edge_groups validates list shape and uniqueness

    Code
      check_edge_groups("not a list")
    Condition
      Error in `check_edge_groups()`:
      ! `edge_groups` must be a list of `edge_group()` objects.
    Code
      check_edge_groups(list("not an edge group"))
    Condition
      Error in `check_edge_groups()`:
      ! <EdgeGroups>: every element of `edge_groups` must be created with `edge_group()`.
    Code
      check_edge_groups(list(edge_group(id = "a", position = "left"), edge_group(id = "a",
        position = "right")))
    Condition
      Error in `check_edge_groups()`:
      ! <EdgeGroups>: duplicated ids found: a
    Code
      check_edge_groups(list(edge_group(id = "a", position = "left"), edge_group(id = "b",
        position = "left")))
    Condition
      Error in `check_edge_groups()`:
      ! <EdgeGroups>: at most one edge group per position is allowed. Duplicated: left

# dock_view rejects malformed edge_groups

    Code
      dock_view(panels = list(panel(id = "1", title = "p", content = "x")),
      edge_groups = list("not an edge group"))
    Condition
      Error in `check_edge_groups()`:
      ! <EdgeGroups>: every element of `edge_groups` must be created with `edge_group()`.

# add_edge_group works

    Code
      add_edge_group("dock", edge_group(id = "x", position = "left"))
    Condition
      Error in `validate_dock_proxy()`:
      ! inherits(dock, "dock_view_proxy") is not TRUE
    Code
      add_edge_group(dock_proxy, edge_group = list(id = "x"))
    Condition
      Error in `add_edge_group()`:
      ! `edge_group` must be created with `edge_group()`.

# remove_edge_group works

    Code
      remove_edge_group(dock_proxy, position = "middle")
    Condition
      Error in `validate_edge_position()`:
      ! <EdgeGroup>: invalid value (middle) for `position`. `position` must be one of left, right, top, bottom.

# set_edge_group_visible works

    Code
      set_edge_group_visible(dock_proxy, position = "middle", visible = TRUE)
    Condition
      Error in `validate_edge_position()`:
      ! <EdgeGroup>: invalid value (middle) for `position`. `position` must be one of left, right, top, bottom.
    Code
      set_edge_group_visible(dock_proxy, position = "left", visible = "yes")
    Condition
      Error in `set_edge_group_visible()`:
      ! <EdgeGroup (position: left)>: `visible` must be a single boolean value.

