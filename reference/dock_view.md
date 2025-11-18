# Create a dock view widget

Creates an interactive dock view widget that enables flexible layout
management with draggable, resizable, and dockable panels. This is a
wrapper around the dockview.dev JavaScript library, providing a powerful
interface for creating IDE-like layouts in Shiny applications or R
Markdown documents.

## Usage

``` r
dock_view(
  panels = list(),
  ...,
  theme = c("light-spaced", "light", "abyss", "abyss-spaced", "dark", "vs", "dracula",
    "replit"),
  add_tab = new_add_tab_plugin(),
  width = NULL,
  height = NULL,
  elementId = NULL
)
```

## Arguments

- panels:

  An unnamed list of
  [`panel()`](https://cynkra.github.io/dockViewR/reference/panel.md).

- ...:

  Other options. See <https://dockview.dev/docs/api/dockview/options/>.

- theme:

  Theme. One of
  `c("abyss", "dark", "light", "vs", "dracula", "replit")`.

- add_tab:

  Globally controls the add tab behavior. List with enable and callback.
  Enable is a boolean, default to FALSE and callback is a JavaScript
  function passed with
  [JS](https://rdrr.io/pkg/htmlwidgets/man/JS.html). See
  [`default_add_tab_callback()`](https://cynkra.github.io/dockViewR/reference/default_add_tab_callback.md).
  By default, the callback sets a Shiny input
  `input[["<dock_ID>_panel-to-add"]]` so you can create observers with
  custom logic.

- width:

  Widget width.

- height:

  Widget height.

- elementId:

  When used outside Shiny.

## Value

An HTML widget object.

## Examples in Shinylive

- example-1:

  [Open in
  Shinylive](https://shinylive.io/r/app/#code=NobwRAdghgtgpmAXGKAHVA6ASmANGAYwHsIAXOMpMAdzgCMAnRRASwgGdSoAbbgCgA6EAAQCwAEyIEA1gDUWcaljG4hwhnFRF2wgLyiwAC1KlU7RAHoLDNuQYAzKATgYA5i1KGArnQwsi1rZwDk5wALTUUOwwYQQMUBAWYkIAlELcLIxQDACefOyGbDlpEBlZuXx07GUlZfEVkjLyilglQl4swgA8YcKoUK5wAPr2LLxQdNxwgiLCjXIK1ADyXqarghJS0mIlbRzBAG7B3b32XhAEpP4QfGyoq7jCRKv3pI-scOzs1ynCIGrPNakAAk8xO6go4mCABEts1qHx-rM5lshgdFjNhFisf0IHBuDp9BlOJjsdjcfjSWTsSxxHoDABGFRqanYq6kKb0sQABQS+OETLwLNZwmIZAopHpXFcABkWCThSLhNVacEAJIQV5UpVYsREKrM5E6gwAOS8MDoxyI9ieVUOUCuJHMhuN2JgbHpAAZVEadTAoAAPekMz2hn2urEHHheOD0gCsocVIpS4eNqG4RFIKyBG3E8tI3IzpB2SbJJWTqepFP4pZpdP0YgATC6lezOQ2wLy8dxhM2hb6yWLyGQpQM5QqB9SPlNLhqtbXWWIozYJlMW66xLJsixV3BEOvjQQNgBhHIZCBQhjsMRcwhnlQGAAq8Q47q+1xvHdgD7EAHE4Nk15gLegzZCWk5lpWra7tm84SA6UDgTqKYLn02geNc9LEqQ2oiho9jBBQzhdvyHaClBIp5holyYR2NiuMYyQQcI5asqx2Iob6nhwPAt4aOmHhMRxagAL57E8LyrKC+aFpm4IaBewSyThSLYhoACOtyalJ+rsOxhQkgwEBEAwMBaa8wK6Sk5ZiQCkkguICHyZCwSPruVKqWSMCkAQgHAI8R5iDAqCuA+dxScuO6THAKZzAwRCoPSABiACCMoAMoAKIALrCiJlbxdQ0DwISwiPlgACqmVqCUIlCAURQpegfAdO8hzBCkYAidlQA)
