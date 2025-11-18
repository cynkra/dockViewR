# Update options for dockview instance

This does not rerender the widget, just update options like global
theme.

## Usage

``` r
update_dock_view(dock, options)
```

## Arguments

- dock:

  Dock proxy created with
  [`dock_view_proxy()`](https://cynkra.github.io/dockViewR/reference/dockview-proxy.md).

- options:

  List of options for the
  [dock_view](https://cynkra.github.io/dockViewR/reference/dock_view.md)
  instance.

## Value

This function is called for its side effect. It sends a message to
JavaScript through the current websocket connection, leveraging the
shiny session object.
