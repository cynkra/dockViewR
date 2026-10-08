# Default add tab callback

An example of a JavaScript function that can be used as a default when
adding a new tab/panel.

## Usage

``` r
default_add_tab_callback()
```

## Value

An object of class `JS_EVAL` representing the JavaScript callback.

## Details

An add tab callback runs when the "+" button in a group's header is
clicked, and is called with three arguments: the group's header config,
the click event and the button itself. The config carries the dock's id
in `config.dockId` and the group's in `config.group.id`. To place
something at the button, such as a menu, use the button's box,
`button.getBoundingClientRect()`. The button stays available to a
callback that defers its work, whereas the browser resets
`event.currentTarget` to `null` once the event has been handled, and the
click point, `event.clientX` and `event.clientY`, is 0, 0 when the click
does not come from a pointer, as for `element.click()` and some
assistive technology. The default callback uses neither and sets
`input[["<dock_ID>_panel-to-add"]]` to the group's id.

## Examples

``` r
new_add_tab_plugin(
  enable = TRUE,
  callback = htmlwidgets::JS(
    "(config, event, button) => {
      const box = button.getBoundingClientRect();
      Shiny.setInputValue(
        `${config.dockId}_add-tab`,
        { group: config.group.id, left: box.left, bottom: box.bottom },
        { priority: 'event' }
      );
    }"
  )
)
#> $enable
#> [1] TRUE
#> 
#> $callback
#> [1] "(config, event, button) => {\n      const box = button.getBoundingClientRect();\n      Shiny.setInputValue(\n        `${config.dockId}_add-tab`,\n        { group: config.group.id, left: box.left, bottom: box.bottom },\n        { priority: 'event' }\n      );\n    }"
#> attr(,"class")
#> [1] "JS_EVAL"
#> 
#> attr(,"class")
#> [1] "dock_view_plugin_add_tab" "dock_view_plugin"        
#> [3] "list"                    
```
