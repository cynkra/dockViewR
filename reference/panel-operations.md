# Dockview Panel Operations

Functions to dynamically manipulate panels in a dockview instance.

## Usage

``` r
add_panel(dock, panel, ...)

remove_panel(dock, id)

set_panel_title(dock, id, title)

select_panel(dock, id)

move_panel(dock, id, position)

move_group(dock, from, to, position = NULL)

move_group2(dock, from, to, position = NULL)

set_size(dock, id, size)
```

## Arguments

- dock:

  Dock proxy object created with
  [`dock_view_proxy()`](https://cynkra.github.io/dockViewR/reference/dockview-proxy.md).

- panel:

  A panel object (for `add_panel`). See
  [panel](https://cynkra.github.io/dockViewR/reference/panel.md) for
  parameters.

- ...:

  Additional options (currently unused).

- id:

  Panel ID (character string).

- title:

  New panel title.

- position:

  For `move_group()` and `move_group2()`, placement relative to the
  destination group: one of "left", "right", "top", "bottom", "center".
  For `move_panel()`, a placement list sharing the vocabulary of
  [`panel()`](https://cynkra.github.io/dockViewR/reference/panel.md)'s
  `position`: a `referencePanel` *or* `referenceGroup` (not both) to
  move next to, a `direction` (one of "above", "below", "left", "right",
  "within"), and an `index` used only with `direction = "within"` to set
  the tab position in the target group. "above" / "below" / "left" /
  "right" put the panel in a new group on that side of the reference;
  "within" drops it into the reference's group. With no reference, the
  panel moves to a new group at the dock edge in `direction`.

- from:

  Source group/panel ID (for move operations).

- to:

  Destination group/panel ID (for move operations).

- size:

  Target size for a group along its splitview axis, as a fraction
  between 0 and 1 of that splitview (for `set_size`). The other groups
  in the split keep their relative sizes and share the remaining space.
  Sizing is best-effort: dockview's minimum group size can clamp a
  group, in which case the requested fraction is approximate.

## Value

All functions return the dock proxy object invisibly, allowing for
method chaining.

## Details

- `set_panel_title()`: Sets the title of a panel dynamically.

- `add_panel()`: Adds a new panel to the dockview

- `remove_panel()`: Removes an existing panel

- `select_panel()`: Selects/focuses a specific panel

- `move_panel()`: Moves an existing panel next to a reference panel or
  group, using the same `position` vocabulary as
  [`panel()`](https://cynkra.github.io/dockViewR/reference/panel.md)

- `move_group()`: Moves a group using group IDs

- `move_group2()`: Moves a group using panel IDs

- `set_size()`: Resizes the group a panel belongs to, as a fraction of
  its splitview; the other groups in the split keep their relative sizes

## See also

[`panel()`](https://cynkra.github.io/dockViewR/reference/panel.md)
