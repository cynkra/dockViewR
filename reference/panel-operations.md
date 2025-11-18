# Dockview Panel Operations

Functions to dynamically manipulate panels in a dockview instance.

## Usage

``` r
add_panel(dock, panel, ...)

remove_panel(dock, id)

set_panel_title(dock, id, title)

select_panel(dock, id)

move_panel(dock, id, position = NULL, group = NULL, index = NULL)

move_group(dock, from, to, position = NULL)

move_group2(dock, from, to, position = NULL)
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

  Panel/group position: one of "left", "right", "top", "bottom",
  "center".

- group:

  ID of a panel that belongs to the target group (for `move_panel`).

- index:

  Panel index within a group (for `move_panel`).

- from:

  Source group/panel ID (for move operations).

- to:

  Destination group/panel ID (for move operations).

## Value

All functions return the dock proxy object invisibly, allowing for
method chaining.

## Details

- `set_panel_title()`: Sets the title of a panel dynamically.

- `add_panel()`: Adds a new panel to the dockview

- `remove_panel()`: Removes an existing panel

- `select_panel()`: Selects/focuses a specific panel

- `move_panel()`: Moves a panel to a new position

- `move_group()`: Moves a group using group IDs

- `move_group2()`: Moves a group using panel IDs

## See also

[`panel()`](https://cynkra.github.io/dockViewR/reference/panel.md)
