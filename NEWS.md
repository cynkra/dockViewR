# dockViewR 0.2.0

- Add `select_panel()` function to select a specific panel by id from the server.
- Add `removable` parameter to `add_panel()` to allow panels to be removable or not. Default is FALSE so you don't accidentally corrupt the layout of your app.
- Add `addTab` parameter to `dock_view()` to allow controlling the add tab behavior. By default, it is disabled. You can activate it by passing `list(enable = TRUE)`. By default, a JS callback inserts a panel into the dock with instructions on how to overwrite it by content created from the server of a Shiny app. This control is global, that is, you can't have panel for which addTab is enabled and another for which it is disabled due to constraints imposed by the JS api.

# dockViewR 0.1.0

- Initial release
