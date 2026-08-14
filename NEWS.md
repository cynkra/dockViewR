# dockViewR (development version)

## Breaking changes

- `move_panel()` now places the moved panel with the same `position` vocabulary as `add_panel()` and `panel()` — a list carrying a `referencePanel` or `referenceGroup` plus a `direction` (one of "above", "below", "left", "right", "within") and an optional `index` — replacing the previous scalar `position` / `group` / `index` arguments. Server-side callers can now express "move panel X next to panel Y" with the same placement grammar they use to add panels.

- Removed `input[["<dock_ID>_state-source"]]` (added in 0.3.0) and the provenance machinery behind it. It tagged each `_state` update `"server"` or `"client"` so a consumer could ignore an echo of a layout it had just pushed. No consumer relies on it any more, and a future `dockview-core` will report the same programmatic-vs-user origin natively through its layout-mutation transaction events, so the hand-rolled tag is not worth carrying until then. Note that the bundled 4.13.1 carries no such native signal: an app that still needs to tell its own echo from a user gesture has to track the layouts it pushes itself, since the settled-`_state` gating above removes transients, not provenance.

## New features

- Added `set_size()` to resize the group a panel belongs to from the server. The caller gives a single target fraction of the group's splitview along its axis; the other groups in that split keep their relative sizes and share the remaining space.

- The widget now dispatches a `dockview:active-panel` DOM event on the dock container each time a panel becomes active, carrying the newly active panel's id in `event.detail.id` and the dock's own id in `event.detail.dock`. It is the client-side counterpart of `input[["<dock_ID>_active-panel"]]`: because the widget's dockview `api` is closure-private, this event is the only handle a consumer's own JavaScript has onto activation. A consumer can listen for it to run DOM work on the tick a panel activates — for example to move deferred content into a panel whose element dockview mounts lazily on first activation, before paint and without a server round-trip. The event bubbles, so a listener can bind to a single dock container or to `document`; panel ids are unique only within a dock, so a listener bound above one dock needs `event.detail.dock` to tell which fired.

  The event reports transitions only, and a dock's first activation fires while the widget renders — so bind before that. A `document`-level listener registered at page load sees every dock, including ones inserted later by `renderUI()` / `insertUI()`. A listener bound after a dock has rendered — for instance from `input[["<dock_ID>_initialized"]]` — misses that dock's initial activation, and there is no way to query the current one after the fact.

## Bug fixes

- A layout gesture no longer rebinds every panel in the dock. Each `Shiny.bindAll()` ends by scheduling a walk over every bound output on the page — re-sending each one's hidden state and, where it reports one, its size — and schedules it whether or not the scope it was handed holds anything unbound. Binding all panels on every sync therefore charged that walk to gestures that change no panel body at all: a sash drag, a maximize, a window or container resize. Panel bodies are now bound once, on the first sync that finds one in the document — when a panel is added, when a background tab is brought to the front for the first time, and when a restore rebuilds the bodies. Measured on a nine-panel dock holding 46 bound outputs, a window resize went from nine `bindAll()` and nine `initializeInputs()` calls to none, and from 76–101 client-data input writes to 10–35, the remainder being the per-output size reports for the outputs that genuinely changed size.

- `input$<dock_id>_state` now only ever surfaces a settled layout. A restore (`restore_dock()` → `fromJSON`) and a widget re-render each tear the layout down and rebuild it; the empty grid and the zero-sized intermediate structure produced along the way used to reach the input, so a consumer mirroring `_state` into storage could commit an empty or partial layout. Emission is now gated across both windows — a restore emits its single settled layout at `onDidLayoutFromJSON`, and the initial render holds until the ResizeObserver reports real geometry — so every `_state` a consumer receives is a valid, settled layout that needs no per-frame guard.

  A dock that has not been shown yet therefore has no state to report: it never measured, so there is no geometry to publish. Until it is first displayed `save_dock()` publishes nothing and the readers derived from `_state` (`get_grid()`, `grid_shape()`, `get_panels_ids()`, `get_active_views()`, `get_active_panel()`, …) return `NULL`, where a dock in a not-yet-opened tab previously reported a zero-sized layout. Everything converges as soon as the dock becomes visible; code that reads these on a possibly-hidden dock should treat `NULL` as "not laid out yet" rather than as an error.

- `input$<dock_id>_restored` now fires after the restored layout has been published to `input$<dock_id>_state` and the restored panels have been rebound, rather than as soon as `fromJSON()` returned. An `observeEvent()` on it can therefore read the restored layout directly instead of racing the state update.

- `input$<dock_id>_state` is now emitted once per layout gesture rather than on every `onDidLayoutChange` frame. The per-frame stream was the source of the `onDidLayoutChange → resize → onDidLayoutChange` feedback loop that pegged the main thread on boards with many resize-sensitive widgets (e.g. ECharts); the layout-tolerance heuristic that previously absorbed its sub-pixel echo is gone. Each discrete gesture (panel add / remove / move, group add / remove, active panel / group change, maximize, restore, and the pointer-up that ends a sash drag) coalesces into a single update, so a compound gesture that fires several dockview events still emits one settled `_state` carrying the final layout — consumers no longer need to debounce the burst themselves. Widget re-fit is likewise driven off the gestures, not the layout stream. The initial layout is captured once; a container / window resize has no gesture boundary, so it is debounced and persisted once it settles, so `_state` always reflects the live dock.

- Upgrade the bundled `dockview-core` to 4.13.1, which carries the upstream fix for panel content not rendering when a panel is dragged to an extreme drop target: <https://github.com/mathuo/dockview/issues/1031>.

# dockViewR 0.3.0

## Breaking changes

In the previous API, we relied on `input$<dock_id>_state` to perform checks on panel ids but this was no reliable. For instance, calling `add_panel()` in an `observeEvent()`, the state was not up to date as you had to wait for the next reactive flush to get an update of the input. This lead to unconvenient workarounds when manipulating the dock from the server. Now, checks are performed UI side an raise JS warnings in the console and optionally Shiny notification when `options(dockViewR.mode = "dev")`.

- Added `dock_view_proxy()` to create a reactive proxy to a dock instance.
- `add_panel()` `dock_id` parameter is changed to `dock`. It now expects a dock proxy created with `dock_view_proxy()`. This is to be more consistent with other htmlwidgets. Same applies for `remove_panel()`, `select_panel()` and `move_panel()`.
- `dock_state()` and all related functions also expect a dock proxy created with `dock_view_proxy()`.
- `update_dock_view()` also relies on `dock_view_proxy()`.
- All proxy method return the dock invisibly so you can chain calls.

We reworked the infrastructure around adding and removing tabs using `new_add_tab_plugin()` and `new_remove_tab_plugin()`. See the updated documentation for more details. This also impacts the way `add_tab` and `remove` parameters are used in `dock_view()` and `panel()` respectively, which weren't very safe in the previous API.

## New features

- Add `set_panel_title()` to change the title of a panel from the server of a Shiny app.
- Add new `input[["<dock_ID>_n-panels"]]`, `input[["<dock_ID>_n-groups"]]`,`input[["<dock_ID>_active-panel"]]`, `input[["<dock_ID>_active-group"]]` as subset of `input[["<dock_ID>_state"]]`. Priority is normal so any observer listening to those input won't trigger when there is no change in the layout.
- Add new `input[["<dock_ID>_restored"]]` as a callback when the dock get restored after calling `restore_dock()`.
- Add new `input[["<dock_ID>_state-source"]]`, emitted alongside every `input[["<dock_ID>_state"]]` update to report **what produced the change**: `"server"` when R drove the dock — the initial render, or a proxy call (`restore_dock()`, `add_panel()`, `remove_panel()`, `move_panel()`, `move_group()`, `move_group2()`, `select_panel()`, `set_panel_title()`), including the proxy call your server makes in response to the built-in add (`+`) and close (`x`) tab buttons, which round-trip through Shiny — and `"client"` when the widget changed its own layout directly, such as a user drag, sash resize, or tab activation. An app that mirrors `_state` back into server-side layout state can use this to ignore its own echoes instead of feeding a restore/reconcile loop ([#70](https://github.com/cynkra/dockViewR/issues/70)). Attribution is causal (a flag carried across dockview's microtask-batched `onDidLayoutChange`), not time-based.
- Fix [#53](https://github.com/cynkra/dockViewR/issues/53): Added `get_active_views()]`, a convenience function that returns the active view in each group and `get_active_panel()]`, another convenience function that returns the active panel in the active group.
- Allow initialising a dock with no panels (default to `list()`).
- Added `input[["<dock_ID>_initialized"]]` within an `onRender` callback. Allows to track when the dock is ready
to perform actions server side.
- In `add_panel()`: if no `referencePanel` or `referenceGroup` is provided, the panel is added relative to the [container](https://dockview.dev/docs/core/panels/add/#relative-to-the-container).
- Fix: `get_groups_ids()` now correctly returns all group ids (nested groups were not returned).
- Fix [#52](https://github.com/cynkra/dockViewR/issues/52): Reworked `add_tab` parameter in `dock_view()`. By default, there is a `default_add_tab_callback()` that sets `input[["<dock_ID>_panel-to-add"]]`, so you can create observers with custom logic, including removing the panel with `add_panel()`. An example of usage is available at <https://github.com/cynkra/dockViewR/blob/main/inst/examples/add_panel/app.R>.
- Fix: typo in `abyss-spaced` theme caused the theme not to be applied.
- Fix: options in `...` were not passed to the dockview JS constructor. (:clown:)
- Fix [#48](https://github.com/cynkra/dockViewR/issues/48): dock state is saved before panels are added.
- Remove unecessary content in saved JSON state (dependencies, head, singletons). They should
already be present in the app when initialising the graph.
- Fix: update input layout state when layout is restored.
- Added `style` parameter to `panel()`. This allows to customize the style of the panel container. It expects a named list with CSS properties and values. We kept old default values for backward compatibility, but you can now overwrite them.
- Upgrade dockview JS to 4.10.0. Fix Windows shaking issue: <https://github.com/mathuo/dockview/issues/988>.

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
