# Dock panel

Create a panel for use within a
[`dock_view()`](https://cynkra.github.io/dockViewR/reference/dock_view.md)
widget. Panels are the main container components that can be docked,
dragged, resized, and arranged within the dockview interface.

## Usage

``` r
panel(
  id,
  title,
  content,
  active = TRUE,
  remove = new_remove_tab_plugin(),
  style = list(padding = "10px", overflow = "auto", height = "100%", margin = "10px"),
  ...
)
```

## Arguments

- id:

  Panel unique id.

- title:

  Panel title.

- content:

  Panel content. Can be a list of Shiny tags.

- active:

  Is active?

- remove:

  List with two fields: enable and mode. Enable is a boolean and mode is
  one of `manual`, `auto` (default to auto). In auto mode, dockview JS
  removes the panel when it is closed and all its content. If you need
  more control over the panel removal, set it to manual so you can
  explicitly call
  [`remove_panel()`](https://cynkra.github.io/dockViewR/reference/panel-operations.md)
  and perform other tasks. On the server side, a shiny input is
  available `input[["<dock_ID>_panel-to-remove"]]` so you can create
  observers with custom logic.

- style:

  List of CSS style attributes to apply to the panel content. See
  defaults

- ...:

  Other options passed to the API. See
  <https://dockview.dev/docs/api/dockview/panelApi/>. If you pass
  position, it must be a list with 2 fields:

  - referencePanel: reference panel id.

  - direction: one of `above`, `below`, `left`, `right` or `within`
    (`above`, `below`, `left`, `right` put the panel in a new group,
    while `within` puts the panel after its reference panel in the same
    group). Position is relative to the reference panel target.

## Value

A list representing a panel object to be consumed by
[dock_view](https://cynkra.github.io/dockViewR/reference/dock_view.md):

- id: unique panel id (string).

- title: panel title (string).

- content: panel content (`shiny.tag.list` or single `shiny.tag`).

- active: whether the panel is active or not (boolean).

- ...: extra parameters to pass to the API.
