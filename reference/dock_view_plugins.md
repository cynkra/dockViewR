# Create dock view plugins

Create plugins to enable additional functionality in dock view
interfaces. Currently supports "add_tab" and "remove_tab" plugins.

## Usage

``` r
new_dock_view_plugin(type, ...)

# S3 method for class 'add_tab'
new_dock_view_plugin(type, enable = FALSE, callback = NULL, ...)

# S3 method for class 'remove_tab'
new_dock_view_plugin(type, enable = FALSE, callback = NULL, mode = "auto", ...)

new_add_tab_plugin(enable = FALSE, callback = NULL, ...)

new_remove_tab_plugin(enable = FALSE, callback = NULL, mode = "auto", ...)
```

## Arguments

- type:

  Character string specifying the plugin type.

- ...:

  Additional plugin configuration arguments.

- enable:

  Logical, whether the plugin functionality is enabled.

- callback:

  Optional JavaScript function. If `NULL` and `enable = TRUE`, a default
  callback is used.

- mode:

  For remove_tab plugins only. One of "auto" or "manual".

## Value

A dock view plugin object of class `add_tab` or `remove_tab`, depending
on the choosen \`type“.

## Examples

``` r
# Add tab plugin
new_dock_view_plugin("add_tab", enable = TRUE)
#> $enable
#> [1] TRUE
#> 
#> $callback
#> [1] "(config) => {\n      Shiny.setInputValue(`${config.dockId}_panel-to-add`, config.group.id, { priority: 'event' });\n    }"
#> attr(,"class")
#> [1] "JS_EVAL"
#> 
#> attr(,"class")
#> [1] "dock_view_plugin_add_tab" "dock_view_plugin"        
#> [3] "list"                    
new_add_tab_plugin(enable = TRUE)  # convenience function
#> $enable
#> [1] TRUE
#> 
#> $callback
#> [1] "(config) => {\n      Shiny.setInputValue(`${config.dockId}_panel-to-add`, config.group.id, { priority: 'event' });\n    }"
#> attr(,"class")
#> [1] "JS_EVAL"
#> 
#> attr(,"class")
#> [1] "dock_view_plugin_add_tab" "dock_view_plugin"        
#> [3] "list"                    

# Remove tab plugin
new_dock_view_plugin("remove_tab", enable = TRUE, mode = "auto")
#> $enable
#> [1] TRUE
#> 
#> $callback
#> [1] "(config) => {\n      Shiny.setInputValue(`${config.dockId}_panel-to-remove`, config.api.id, { priority: 'event' });\n    }\n    "
#> attr(,"class")
#> [1] "JS_EVAL"
#> 
#> $mode
#> [1] "auto"
#> 
#> attr(,"class")
#> [1] "dock_view_plugin_remove_tab" "dock_view_plugin"           
#> [3] "list"                       
new_remove_tab_plugin(enable = TRUE, mode = "manual")  # convenience function
#> $enable
#> [1] TRUE
#> 
#> $callback
#> [1] "(config) => {\n      Shiny.setInputValue(`${config.dockId}_panel-to-remove`, config.api.id, { priority: 'event' });\n    }\n    "
#> attr(,"class")
#> [1] "JS_EVAL"
#> 
#> $mode
#> [1] "manual"
#> 
#> attr(,"class")
#> [1] "dock_view_plugin_remove_tab" "dock_view_plugin"           
#> [3] "list"                       
```
