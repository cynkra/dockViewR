# Dockview edge group operations

Manipulate edge groups, that is groups pinned to one of the four edges
of a dock, from the server. See
<https://dockview.dev/docs/core/groups/edgeGroups>.

## Usage

``` r
add_edge_group(dock, edge_group)

remove_edge_group(dock, position)

set_edge_group_collapsed(dock, position, collapsed)

set_edge_group_visible(dock, position, visible)
```

## Arguments

- dock:

  Dock proxy object created with
  [`dock_view_proxy()`](https://cynkra.github.io/dockViewR/reference/dockview-proxy.md).

- edge_group:

  An edge group object created with
  [`edge_group()`](https://cynkra.github.io/dockViewR/reference/edge_group.md).

- position:

  Edge position. One of `"left"`, `"right"`, `"top"`, `"bottom"`.

- collapsed:

  Whether the edge group should be collapsed.

- visible:

  Whether the edge group should be visible.

## Value

All functions return the dock proxy object invisibly, so they can be
chained.

## Details

- `add_edge_group()`: pins a new edge group to the requested edge.

- `remove_edge_group()`: removes the edge group pinned to `position`,
  disposing of the panels it holds.

- `set_edge_group_visible()`: shows or hides the edge group at
  `position` without removing it. An invisible rail renders at zero and
  keeps whatever collapsed state it had.

- `set_edge_group_collapsed()`: collapses the edge group at `position`
  to its `collapsed_size`, or expands it again. A collapsed rail keeps
  its header strip standing, which is what distinguishes it from an
  invisible one. This is the server-side equivalent of the user gesture,
  a click on the rail's active tab.

  It is the only route to the collapsed state of a dock that is already
  running. The state can also be *declared* two other ways, neither of
  which needs this: `edge_group(collapsed = TRUE)` at construction, and
  the `edgeGroups` entry of a payload handed to
  [`restore_dock()`](https://cynkra.github.io/dockViewR/reference/dock-state.md),
  which carries `collapsed` beside `size` and `visible` and is honoured
  on restore.

Read either state back with
[`is_edge_group_visible()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
and
[`is_edge_group_collapsed()`](https://cynkra.github.io/dockViewR/reference/dock-state.md).

## See also

[`edge_group()`](https://cynkra.github.io/dockViewR/reference/edge_group.md),
[`is_edge_group_visible()`](https://cynkra.github.io/dockViewR/reference/dock-state.md),
[`is_edge_group_collapsed()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
