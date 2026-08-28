# get dock

Edge groups are serialised beside the grid rather than inside it, keyed
by edge rather than by group id. `get_edge_groups()` returns that raw
record; the group-level helpers (`get_groups_ids()`,
`get_groups_panels()`, `get_active_views()`) fold edge groups in so a
rail's panels are reported like any other group's.

Collapsed and invisible are different states: a collapsed rail keeps its
header strip standing, while an invisible one renders at zero and keeps
whatever collapsed state it had. Set it with
[`set_edge_group_collapsed()`](https://cynkra.github.io/dockViewR/reference/edge-group-proxy.md).

## Usage

``` r
get_dock(dock)

get_panels(dock)

get_panels_ids(dock)

get_active_group(dock)

get_grid(dock)

get_edge_groups(dock)

is_edge_group_visible(dock, position)

is_edge_group_collapsed(dock, position)

grid_shape(dock)

get_groups(dock)

get_groups_ids(dock)

get_groups_panels(dock)

get_active_views(dock)

get_active_panel(dock)

save_dock(dock)

restore_dock(dock, data)
```

## Arguments

- dock:

  Dock proxy created with
  [`dock_view_proxy()`](https://cynkra.github.io/dockViewR/reference/dockview-proxy.md).

- position:

  Edge position. One of `"left"`, `"right"`, `"top"`, `"bottom"`.

- data:

  Data representing a serialised dock object.

## Value

`get_dock` returns a list of 3 elements:

- grid: a list representing the dock layout.

- panels: a list having the same structure as
  [`panel()`](https://cynkra.github.io/dockViewR/reference/panel.md)
  composing the dock.

- activeGroup: the current active group (a string).

Each other function allows to deep dive into the returned value of
`get_dock()`. `get_panels()` returns the `panels` element of
`get_dock()`. `get_panels_ids()` returns a character vector containing
all panel ids from `get_panels()`. `get_active_group()` extracts the
`activeGroup` component of `get_dock()` as a string.
`get_active_views()` is a convenience function that returns the active
view in each group. `get_active_panel()` is a convenience function that
returns the active panel in the active group. `get_grid()` returns the
`grid` element of `get_dock()` which is a list. `grid_shape()` returns
the structural shape of `get_grid()`: the branch / leaf nesting,
orientation, group ids, panel membership and order, with all absolute
geometry (`size`, `width`, `height`) dropped. Pixel geometry is volatile
– and in a headless render not even a valid partition – so snapshotting
structure alone keeps the layout coverage that matters without the
flake. `get_groups()` returns a list of panel groups from `get_grid()`.
`get_groups_ids()` returns a character vector of groups ids from
`get_groups()`. `get_groups_panels()` returns a list of character vector
containing the ids of each panel within each group. `save_dock()` and
`restore_dock()` are used for their side effect to allow to respectively
serialise and restore a dock object.

`TRUE` or `FALSE`, or `NULL` when no edge group is pinned to `position`
(or the dock has not yet published a state).

`TRUE` or `FALSE`, or `NULL` when no edge group is pinned to `position`
(or the dock has not yet published a state).

## Note

Only works with server side functions like
[add_panel](https://cynkra.github.io/dockViewR/reference/panel-operations.md).
Don't call it from the UI.
