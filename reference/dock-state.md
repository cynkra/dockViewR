# get dock

get dock

get dock panels

get dock panels ids

get dock active group

get dock grid

get dock groups

get dock groups ids

get dock groups panels

get active views

get active panel

save a dock

restore a dock

## Usage

``` r
get_dock(dock)

get_panels(dock)

get_panels_ids(dock)

get_active_group(dock)

get_grid(dock)

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
`grid` element of `get_dock()` which is a list. `get_groups()` returns a
list of panel groups from `get_grid()`. `get_groups_ids()` returns a
character vector of groups ids from `get_groups()`.
`get_groups_panels()` returns a list of character vector containing the
ids of each panel within each group. `save_dock()` and `restore_dock()`
are used for their side effect to allow to respectively serialise and
restore a dock object.

## Note

Only works with server side functions like
[add_panel](https://cynkra.github.io/dockViewR/reference/panel-operations.md).
Don't call it from the UI.
