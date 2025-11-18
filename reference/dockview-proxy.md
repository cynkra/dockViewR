# Create a proxy object to modify an existing dockview instance

This function creates a proxy object that can be used to update an
existing dockview instance after it has been rendered in the UI. The
proxy allows for server-side modifications of the graph without
completely re-rendering it.

## Usage

``` r
dock_view_proxy(id, data = NULL, session = getDefaultReactiveDomain())
```

## Arguments

- id:

  Character string matching the ID of the dockview instance to be
  modified.

- data:

  Unused parameter (for future compatibility).

- session:

  The Shiny session object within which the graph exists. By default,
  this uses the current reactive domain.

## Value

A proxy object of class "dock_view_proxy" that can be used with dockview
proxy methods such as
[`add_panel()`](https://cynkra.github.io/dockViewR/reference/panel-operations.md),
[`remove_panel()`](https://cynkra.github.io/dockViewR/reference/panel-operations.md),
etc. It contains:

- `id`: The ID of the dockview instance.

- `session`: The Shiny session object.
