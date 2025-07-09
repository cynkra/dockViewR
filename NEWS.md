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
