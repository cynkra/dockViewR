# Edge group

Create an edge group, that is a
[group](https://dockview.dev/docs/core/groups/edgeGroups) pinned to one
of the four edges (left, right, top, bottom) of a
[`dock_view()`](https://cynkra.github.io/dockViewR/reference/dock_view.md).
Edge groups support tabs, drag-and-drop, overflow and the full group
panel API. They cannot be maximised, floated or popped out.

## Usage

``` r
edge_group(
  id,
  position = c("left", "right", "top", "bottom"),
  initial_size = NULL,
  minimum_size = NULL,
  maximum_size = NULL,
  collapsed = FALSE,
  collapsed_size = NULL,
  ...
)
```

## Arguments

- id:

  Edge group unique id. Used to reference the group from a
  [`panel()`](https://cynkra.github.io/dockViewR/reference/panel.md)'s
  `position = list(referenceGroup = ...)`.

- position:

  Edge on which to pin the group. One of `"left"`, `"right"`, `"top"`,
  `"bottom"`.

- initial_size:

  Initial size of the edge group, in pixels.

- minimum_size:

  Minimum size of the edge group, in pixels.

- maximum_size:

  Maximum size of the edge group, in pixels.

- collapsed:

  Whether the edge group is initially collapsed.

- collapsed_size:

  Size of the edge group when collapsed, in pixels. Defaults to `35` on
  the dockview side.

- ...:

  Other options forwarded to `api.addEdgeGroup()`. See
  <https://dockview.dev/docs/core/groups/edgeGroups>. Use the JavaScript
  option names (camelCase) for these extras.

  Two of those options need a dockview module that this package does not
  bundle, and have no effect here: `autoHide`, the pinnable tool-window
  behaviour, and `dockToEdgeGroups`, which reveals an edge by dragging
  onto it. Both ship in the commercially licensed `dockview-enterprise`.
  Setting either logs an error in the browser console naming the missing
  module.

  Everything else about an edge group is core, including collapsing.
  Clicking the active tab of a rail collapses it to `collapsed_size` and
  clicking again expands it, and it can be resized with the sash. Note
  that collapsing and
  [`set_edge_group_visible()`](https://cynkra.github.io/dockViewR/reference/edge-group-proxy.md)
  are different: a collapsed rail leaves its header strip standing,
  while an invisible one renders at zero and leaves the collapsed state
  untouched.

## Value

A list of class `dock_edge_group` with the camelCased options ready to
be sent to the dockview JavaScript API. Contains at least:

- `id`: the edge group id (string).

- `position`: one of `"left"`, `"right"`, `"top"`, `"bottom"`.

- `options`: a list of options forwarded to `api.addEdgeGroup()`.

## Details

Pass edge groups to
[`dock_view()`](https://cynkra.github.io/dockViewR/reference/dock_view.md)
through `edge_groups`, or add them on the fly from the server with
[`add_edge_group()`](https://cynkra.github.io/dockViewR/reference/edge-group-proxy.md).

An edge group's size, visibility, collapsed state and panel contents are
part of the serialised layout, so
[`save_dock()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
and
[`restore_dock()`](https://cynkra.github.io/dockViewR/reference/dock-state.md)
round-trip a rail along with the rest of the dock.

## See also

[`add_edge_group()`](https://cynkra.github.io/dockViewR/reference/edge-group-proxy.md),
[`remove_edge_group()`](https://cynkra.github.io/dockViewR/reference/edge-group-proxy.md),
[`set_edge_group_visible()`](https://cynkra.github.io/dockViewR/reference/edge-group-proxy.md).
