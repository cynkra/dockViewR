# Dockview edge group operations

Manipulate edge groups, that is groups pinned to one of the four edges
of a dock, from the server. See
<https://dockview.dev/docs/core/groups/edgeGroups>.

## Usage

``` r
add_edge_group(dock, edge_group)

remove_edge_group(dock, position)

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
  `position` without removing it. Hiding is not the same as collapsing:
  an invisible rail renders at zero and keeps whatever collapsed state
  it had, while a collapsed one leaves its header strip standing.
  Collapsing is a user gesture, a click on the rail's active tab.

Read the current visibility back with
[`is_edge_group_visible()`](https://cynkra.github.io/dockViewR/reference/dock-state.md).

## See also

[`edge_group()`](https://cynkra.github.io/dockViewR/reference/edge_group.md),
[`is_edge_group_visible()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
