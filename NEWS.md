# dockViewR 0.3.0

## Breaking changes

In the previous API, we relied on `input$<dock_id>_state` to perform checks on panel ids but this was no reliable. For instance, calling `add_panel()` in an `observeEvent()`, the state was not up to date as you had to wait for the next reactive flush to get an update of the input. This lead to unconvenient workarounds when manipulating the dock from the server. Now, checks are performed UI side an raise JS warnings in the console and optionally Shiny notification when `options(dockViewR.mode = "dev")`.

- Added `dock_view_proxy()` to create a reactive proxy to a dock instance.
- `add_panel()` `dock_id` parameter is changed to `dock`. It now expects a dock proxy created with `dock_view_proxy()`. This is to be more consistent with other htmlwidgets. Same applies for `remove_panel()`, `select_panel()` and `move_panel()`.
- `dock_state()` and all related functions also expect a dock proxy created with `dock_view_proxy()`.


## New features

- Fix [#53](https://github.com/cynkra/dockViewR/issues/53): Added `get_active_views()]`, a convenience function that returns the active view in each group and `get_active_panel()]`, another convenience function that returns the active panel in the active group.
- Allow initialising a dock with no panels (default to `list()`).
- Added `input[["<dock_ID>_initialized"]]` within an `onRender` callback. Allows to track when the dock is ready
to perform actions server side.
- In `add_panel()`: if no `referencePanel` or `referenceGroup` is provided, the panel is added relative to the [container](https://dockview.dev/docs/core/panels/add#relative-to-the-container).
- Fix: `get_groups_ids()` now correctly returns all group ids (nested groups were not returned).
- Fix [#52](https://github.com/cynkra/dockViewR/issues/52): Reworked `add_tab` parameter in `dock_view()`. By default, there is a `default_add_tab_callback()` that sets `input[["<dock_ID>_panel-to-add"]]`, so you can create observers with custom logic, including removing the panel with `add_panel()`. An example of usage is available at <https://github.com/cynkra/dockViewR/blob/main/inst/examples/add_panel/app.R>.
- Fix: options in `...` were not passed to the dockview JS constructor. (:clown:)
- Fix [#48](https://github.com/cynkra/dockViewR/issues/48): dock state is saved before panels are added.
- Remove unecessary content in saved JSON state (dependencies, head, singletons). They should
already be present in the app when initialising the graph.
- Fix: update input layout state when layout is restored.
- Added `style` parameter to `panel()`. This allows to customized the style of
the panel container. It expects a named list with CSS properties and values. We kept
old default values for backward compatibility, but you can now overwrite them.
- Upgrade dockview JS to 4.9.0. Fix Windows shaking issue: <https://github.com/mathuo/dockview/issues/988>.

# dockViewR 0.2.0

- Bump [dockview](https://github.com/mathuo/dockview/releases/tag/v4.4.0) JS to 4.4.0.
- Add `update_dock_view()` to update a dock instance from the server of a Shiny app.
- Add `input[["<dock_ID>_added-panel"]]` to track which panel has been added. This can be useful in a shiny app context.
- Add `input[["<dock_ID>_removed-panel"]]` to track which panel has been removed. This can be useful in a shiny app context.
- Add `select_panel()` function to select a specific panel by id from the server.
- Add `remove` parameter to `add_panel()` to allow panels to be removable or not. It expects a list with two fields: enable and mode. Enable is a boolean (default to FALSE) and mode is one of `manual`, `auto` (default to auto). In auto mode, dockview JS removes the panel when it is closed and all its content. If you need more control over the panel removal, set it to manual. Doing so, clicking on remove triggers a custom input on the server side, `input[["<dock_ID>_panel-to-remove"]]`, so you can create observers with custom logic, including removing the panel with `remove_panel()`. An example of usage is available at <https://github.com/cynkra/dockViewR/blob/main/inst/examples/add_panel/app.R>.
- Add `add_tab` parameter to `dock_view()` to allow controlling the add tab behavior. By default, it is disabled. You can activate it by passing `list(enable = TRUE)`. By default, a JS callback inserts a panel into the dock with instructions on how to overwrite it by content created from the server of a Shiny app. This control is global, that is, you can't have panel for which add_tab is enabled and another for which it is disabled due to constraints imposed by the JS api.

# dockViewR 0.1.0

- Initial release
