# dockViewR performance audit

dockViewR 0.4.0 (dockview 8.0.0), shiny 1.14.0, htmlwidgets 1.6.4, R 4.6.1.
Headless Chrome on Apple Silicon, 1600x1000 viewport, app on localhost. There
is no network latency in these numbers, so anything that scales with bytes on
the wire is understated compared to a deployed app.

## Summary

dockview itself is not the problem. Laying out 100 panels takes about 64 ms,
tab switches cause no long tasks, and `api.toJSON()` costs 0.1 ms. The cost
sits in what dockViewR ships around it:

1. **`_state` carries every panel's HTML and style, and is re-sent whole on
   every gesture.** At 100 panels that is 40 KB per tab click or sash drag, 3
   to 13 times the traffic of the gesture's own output update.
2. **Persists are not coalesced across tasks.** A tab click in another group
   sends two full snapshots. Ten `add_panel()` calls send ten (423 KB).
3. **The widget payload is 63% dead weight.** Every panel embeds its own
   htmlDependency JSON, which the JS never reads.

It also turned up two correctness bugs:

4. `add_panel()` never loads the dependencies of the panel it adds, so a
   widget type that isn't already on the page stays blank.
5. A sash drag that hits a group's minimum size never reaches `_state`, so the
   server keeps a stale layout.

## The app

`app.R` builds 100 panels: 88 top-level panels over 24 groups in a split tree
several levels deep, 3 of which host a nested `dock_view()` of 4 panels. The
content cycles through base plots, ggplot2, plotly, DT, reactable, leaflet,
echarts4r, visNetwork, dygraphs, `renderTable()`, inputs with `renderUI()`, and
static HTML. Environment variables switch the panel count, the content (`mixed`
or `static`), dockview's `defaultRenderer` and the number of nested docks (see
the header of `app.R`).

`www/probe.js` wraps the WebSocket before Shiny connects and records every
frame, every `setInputValue()` call (sent or deduplicated), output renders,
long tasks and heap. `bench.R` starts the app against the source package,
drives it with real CDP mouse events, and writes the counters to JSON:

```sh
Rscript inst/examples/perf/bench.R results.json
```

## Measurements

### Load

| | mixed, 100 | mixed, 100, `always` | static, 25 | static, 100 | static, 200 |
|---|---:|---:|---:|---:|---:|
| `dock_view()` build (R) | 69 ms | 69 ms | 12 ms | 70 ms | 152 ms |
| Widget payload `x` | 123 KB | 123 KB | 9 KB | 53 KB | 113 KB |
| Dock value to rendered (JS) | 280 ms | 185 ms | 39 ms | 64 ms | 97 ms |
| First `_state` | 1.33 s | 1.07 s | 0.42 s | 0.53 s | 0.73 s |
| Last visible output rendered | 2.87 s | 4.29 s | n/a | n/a | n/a |
| Outputs rendered | 27 | 98 | 0 | 0 | 0 |
| Bytes in | 243 KB | 710 KB | 16 KB | 60 KB | 120 KB |
| Longest task / blocking time | 393 / 592 ms | 557 / 682 ms | 0 / 0 | 70 / 20 ms | 106 / 56 ms |
| DOM nodes | 2,770 | 7,582 | 886 | 1,256 | 1,656 |
| JS heap | 36 MB | 62 MB | 9 MB | 10 MB | 16 MB |

Times are from navigation start. The static rows isolate dockview: render time
grows by about 0.3 ms per panel, so the layout engine scales fine. In the mixed
case, the 280 ms between the dock value and its render is mostly the async load
of 33 widget dependencies, and the long tasks are the widgets initialising.

Server side, a full `renderDockView()` of the mixed dock takes 220 ms in steady
state. Per-panel `htmltools::renderTags()` takes 17% of that,
`resolveDependencies()` over 335 dependency entries (33 unique) another 17%,
and JSON serialisation 21%.

### Gestures (mixed, 100 panels, default renderer)

| Gesture | `dock_state` sent | Bytes out | Bytes in | Renders | Settled after |
|---|---:|---:|---:|---:|---:|
| Tab click, same group | 1 | 41 KB | 4 to 13 KB | 1 | 32 to 92 ms |
| Tab click, other group | 2 | 80 KB | 4 to 13 KB | 1 | 39 to 140 ms |
| Sash drag | 1 | 40 KB | 36 KB | 4 | 605 ms |
| Maximize / restore group | 1 / 1 | 41 / 40 KB | 17 / 9 KB | 2 / 2 | 211 / 151 ms |
| Window resize | 1 | 44 KB | 33 KB | 5 | 249 ms |
| `add_panel()` x 10 | 10 | 429 KB | 26 KB | 4 | 167 ms |
| `remove_panel()` x 10 | 10 | 420 KB | 0.4 KB | 0 | n/a |
| `restore_dock()` | 1 | 58 KB | 40 KB | 0 | 279 ms long task |
| Re-render whole dock | 1 | 58 KB | 133 KB | 3 | 854 ms |

No gesture other than restore and re-render produced a long task.

## Findings

### 1. `_state` ships all panel content on every gesture (high)

`clean_dock_state()` in `srcjs/modules/proxy.js` trims each panel's
`params.content` down to `html` but keeps it, along with `params.style`. At 100
panels, the 40.6 KB state breaks down as:

| Part | Size |
|---|---:|
| Panel HTML | 20.0 KB |
| Panel style (one identical string, repeated 88 times) | 5.5 KB |
| Grid | 3.2 KB |
| Other per-panel fields | 11.9 KB |

`saveDock()` sends the whole thing on every tab click, sash release, maximize,
add, remove and container resize. It grows linearly: 15 KB at 25 static
panels, 51 KB at 100, 101 KB at 200. HTML-heavy panels (long static text,
inline SVG) make it bigger.

CPU is not the issue. `api.toJSON()` takes 0.1 ms at 100 panels and 0.2 ms at
200, and parsing the JSON in R takes 0.5 ms per 100 panels. The cost is
bandwidth and downstream reactivity: every observer on `input$dock_state` (or
on `get_panels_ids()`, `get_active_group()`, and so on) reruns. On a 1 Mbit/s
uplink, 40 KB is about 0.3 s per gesture, before any reactivity.

**Fix:** keep content out of `_state`. The JS side can hold panel content in a
map keyed by panel id. `restore_dock()` then rehydrates from that map, or from
R for a state saved in another session. This changes what `get_dock()` /
`save_dock()` return, so check downstream users (blockr.dock serialises
`_state`) before changing it. Dropping just `style`, or sending it once per
dock, is a non-breaking first step worth 14%.

### 2. Persists are coalesced per microtask, not per gesture (high)

`requestSync()` coalesces onto a microtask, which only merges events fired in
the same task. Two common cases fall outside that:

- **Tab click in another group:** `active-group`, `active-panel` and
  `dock_state` fire at t, then `active-panel` and `dock_state` again 17 ms
  later in a separate task. That is two full snapshots, both sent because
  they differ.
- **Server-side batches:** each `add_panel()` / `remove_panel()` is its own
  custom message, handled in its own task. Ten adds give ten full snapshots,
  423 KB for 10 static panels. The cost is quadratic in the batch size,
  because each snapshot also includes the panels already added.

**Fix:** a trailing debounce (one animation frame, or about 50 ms) instead of
the microtask, keeping the `persisting` guard. Batch variants of `add_panel()`
/ `remove_panel()` that take a list would also help, since they need one
message and one layout pass.

### 3. Per-panel dependencies bloat the widget payload (medium)

`panel()` stores the full `htmltools::renderTags(content)` result: `head`,
`singletons`, `dependencies` and `html`. `dock_view()` then also passes every
panel's dependencies to `createWidget()`. So each dependency travels twice,
once as a widget dependency and once as JSON inside `x$panels[[i]]$content`,
where the JS never reads it (`Panel.init()` only uses `content.html`).

| Panels (mixed) | `x` | Panel HTML | Panel dependency JSON | Widget deps (unique) |
|---:|---:|---:|---:|---:|
| 25 | 15 KB | 2.7 KB | 8.5 KB | 38 (20) |
| 100 | 123 KB | 18 KB | 77.5 KB | 335 (33) |
| 200 | 272 KB | 42 KB | 172 KB | 740 (33) |

**Fix:** `panel()` keeps `html` (plus `head` if non-empty) for the initial
render. `dock_view()` collects the dependencies once with
`htmltools::resolveDependencies()`. That removes about 60% of the payload and
most of the 17% of server render time spent resolving duplicates. Keep the
dependencies on the `add_panel()` path, which needs them (finding 4).

### 4. `add_panel()` drops the new panel's dependencies (correctness)

The `_add-panel` handler calls `addPanel()` directly; nothing calls
`Shiny.renderDependenciesAsync()`. The initial render works because
`dock_view()` lifts the dependencies to the widget. A panel added later whose
widget type isn't already on the page renders nothing. Verified with a dock
holding a single text panel, then `add_panel()` with a `leafletOutput()`:
`window.L` stays undefined, and the output is never bound and never rendered.

**Fix:** in the `_add-panel` handler, `await
Shiny.renderDependenciesAsync(m.panel.content.dependencies)` before
`addPanel()`.

### 5. A clamped sash drag never reaches `_state` (correctness)

Resize persistence hangs off a delegated `pointerup` whose target must be
inside `.dv-sash`. When the drag hits a group's minimum size, the sash stops
and the pointer is released over panel content, so the check fails. Verified:
an outer sash dragged 1500 px left emits no `dock_state`, and the server's
grid no longer matches `api.toJSON().grid`. The layout only catches up on the
next unrelated gesture. Small groups (nested docks, dense grids) hit this
constantly.

**Fix:** arm a one-shot `pointerup` on `document` from a `pointerdown` on a
sash, or persist from a debounced `onDidLayoutChange`.

### 6. Nested docks wake the outer dock's resize sync (low)

The outer container's `pointerup` listener also catches sashes of nested
docks, since `closest('.dv-sash')` matches them. A nested sash release makes
the outer dock recompute its full state. Shiny drops it as unchanged, so the
cost is small (about 0.1 ms), but the check should be scoped to the
container's own sashes. Clicking into a nested dock also moves the outer
active group through the panel's `pointerdown` capture handler, which does
send a full outer `dock_state` (40 KB). That one is legitimate.

### 7. Re-render and restore retain widget memory (medium, mostly upstream)

After forced GC, with mixed content, the JS heap grows by 4.3 MB per full
re-render (31.6 to 74.3 MB over 10) and 2.2 MB per `restore_dock()` (to
96.6 MB over 10). With static content, the growth is 0.2 and 0.1 MB. The Shiny
binding count stays at 26 throughout, so the retained memory is widget
internals (plotly, leaflet, visNetwork, ...). htmlwidgets has no teardown hook,
so those instances outlive their discarded DOM.

dockViewR can't fully fix this. It can make re-render consistent with restore
by calling `Shiny.unbindAll()` on the old panels before `api.dispose()` in
`renderValue()`. The app-level advice is to mutate through the proxy instead of
re-rendering, and to keep restore for occasional use.

### 8. Keep `defaultRenderer = "onlyWhenVisible"` (informational)

dockview detaches background tab bodies, and Shiny 1.14 binds only attached
outputs. With the default renderer, only 26 of 93 outputs are bound on load.
Setting `always` keeps every body in the DOM:

| | `onlyWhenVisible` | `always` |
|---|---:|---:|
| Outputs rendered on load | 27 | 98 |
| Bytes in on load | 243 KB | 710 KB |
| Last output rendered | 2.87 s | 4.29 s |
| DOM nodes | 2,770 | 7,582 |
| Restore blocking time | 229 ms | 628 ms |

`always` makes the first visit to a widget tab free (no server round trip),
but plot tabs re-render on show either way, and every other cost goes up. The
default is right; document the trade-off in `dock_view()`'s docs.

### 9. Plot outputs re-render on every revisit (informational, app side)

A detached `plotOutput()` reports a zero size. Coming back to its tab
invalidates it and reruns the R plotting code (each revisit cost 41 to 140 ms
here). htmlwidget outputs keep their DOM and don't round-trip. For expensive
plots, `bindCache()` keyed on the plot's input data, or `renderCachedPlot()`,
avoids the rerun. Worth a line in the docs.

## Things that are fine

- **Layout engine:** dockview's own render scales about linearly at 0.3 ms
  per panel (39 ms at 25 panels, 97 ms at 200). Tab switches, maximize and
  sash drags cause no long tasks.
- **`bindPanels()`:** skipping panes that stay attached keeps it cheap.
  Switching between 16 tabs produced no long tasks, and binding counts stayed
  stable.
- **`refitWidgets()`:** the synthetic `window` resize after each gesture
  triggered no extra output renders. Shiny 1.14 already gives each output its
  own ResizeObserver, so on Shiny 1.14 this mostly serves static widgets.
- **`_state` gating:** the seeding and restoring gates hold. The first
  `_state` arrives once, after the layout settles.
- **Heap during tab switches:** 24 switches after the restore loop moved the
  heap by 2 MB.

## Suggested order

| # | Change | Effort | Gain |
|---|---|---|---|
| 4 | Render dependencies in the `_add-panel` handler | Small | Fixes blank widgets |
| 5 | Persist sash drags regardless of release target | Small | Fixes stale layout |
| 2 | Debounce `requestSync()` across tasks | Small | Halves cross-group tab clicks; batched adds go from N to 1 snapshot |
| 3 | Drop per-panel dependency JSON from `x`, resolve once | Small | About 60% smaller payload, faster server render |
| 6 | Scope the sash listener to the dock's own sashes | Trivial | Hygiene |
| 1 | Keep content out of `_state` | Medium, API-visible | 40 KB down to a few KB per gesture at 100 panels |
| 7 | Unbind panels before `dispose()` on re-render | Trivial | Consistency; doesn't fix the widget leak |
