# Validate dock view plugins

Internal validation functions for dock view plugins.

## Usage

``` r
validate_dock_view_plugin(plugin)

validate_common_plugin_fields(plugin)

# S3 method for class 'dock_view_plugin_add_tab'
validate_dock_view_plugin(plugin)

# S3 method for class 'dock_view_plugin_remove_tab'
validate_dock_view_plugin(plugin)
```

## Arguments

- plugin:

  A dock view plugin object.

## Value

The validated plugin object.
