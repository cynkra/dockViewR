# Benchmark driver for the dockViewR performance app. Starts app.R in a
# background R process against the source package, drives it from headless
# Chrome with real mouse events, and reads the counters probe.js collects.
#
#   Rscript inst/examples/perf/bench.R [out.json]
#
# Needs callr, chromote, pkgload, jsonlite and the packages app.R uses.

args <- commandArgs(trailingOnly = TRUE)
out_file <- if (length(args)) args[[1]] else tempfile(fileext = ".json")

pkg_dir <- normalizePath(".")
app_dir <- file.path(pkg_dir, "inst", "examples", "perf")
stopifnot(file.exists(file.path(app_dir, "app.R")))

port <- 8765L
viewport <- c(width = 1600L, height = 1000L)

# R side ----------------------------------------------------------------------

pkgload::load_all(pkg_dir, quiet = TRUE)
library(shiny)
source(file.path(app_dir, "helpers.R"))

r_side <- function(n, content = "mixed") {
  cfg <- list(n = n, content = content, renderer = "onlyWhenVisible", nested = 3L)
  specs <- perf_specs(cfg)

  t <- system.time(for (i in 1:5) dock <- perf_dock(specs, cfg))[["elapsed"]]
  panels <- dock$x$panels
  json_len <- function(x) nchar(htmlwidgets:::toJSON(x))

  dep_names <- unlist(lapply(dock$dependencies, `[[`, "name"))

  list(
    n = n,
    content = content,
    build_ms = 1000 * t / 5,
    x_kb = json_len(dock$x) / 1024,
    html_kb = sum(vapply(panels, function(p) nchar(p$content$html), 1)) / 1024,
    panel_deps_kb = sum(
      vapply(panels, function(p) json_len(p$content$dependencies), 1)
    ) / 1024,
    widget_deps = length(dep_names),
    widget_deps_unique = length(unique(dep_names))
  )
}

message("R side ...")
r_results <- c(
  lapply(c(25L, 50L, 100L, 200L), r_side, content = "mixed"),
  lapply(c(25L, 50L, 100L, 200L), r_side, content = "static")
)

# Browser side ----------------------------------------------------------------

start_app <- function(env) {
  callr::r_bg(
    function(pkg_dir, app_dir, port) {
      pkgload::load_all(pkg_dir, quiet = TRUE)
      shiny::runApp(app_dir, port = port, launch.browser = FALSE)
    },
    args = list(pkg_dir, app_dir, port),
    env = c(callr::rcmd_safe_env(), env),
    stdout = "|",
    stderr = "2>&1"
  )
}

wait_port <- function(timeout = 30) {
  end <- Sys.time() + timeout
  while (Sys.time() < end) {
    ok <- tryCatch(
      {
        con <- url(sprintf("http://127.0.0.1:%d", port))
        on.exit(close(con))
        suppressWarnings(readLines(con, n = 1, warn = FALSE))
        TRUE
      },
      error = function(e) FALSE
    )
    if (ok) {
      return(invisible(TRUE))
    }
    Sys.sleep(0.25)
  }
  stop("App did not start.")
}

js <- function(b, expr) {
  b$Runtime$evaluate(expr, returnByValue = TRUE, awaitPromise = TRUE)$result$value
}

# Settled = no websocket frame and no output render for `quiet` ms, and Shiny
# not busy.
wait_settled <- function(b, quiet = 1000, timeout = 60) {
  end <- Sys.time() + timeout
  repeat {
    done <- js(
      b,
      sprintf(
        "dvPerf.quietFor() > %d &&
         !document.documentElement.classList.contains('shiny-busy')",
        quiet
      )
    )
    if (isTRUE(done) || Sys.time() > end) {
      return(invisible(done))
    }
    Sys.sleep(0.1)
  }
}

summary_js <- function(b) {
  jsonlite::fromJSON(js(b, "JSON.stringify(dvPerf.summary())"))
}

mouse <- function(b, type, x, y) {
  x <- as.numeric(x)
  y <- as.numeric(y)
  b$Input$dispatchMouseEvent(
    type = type,
    x = x,
    y = y,
    button = "left",
    buttons = if (type == "mouseReleased") 0L else 1L,
    clickCount = 1L
  )
}

click_at <- function(b, xy) {
  xy <- unlist(xy)
  mouse(b, "mouseMoved", xy[1], xy[2])
  mouse(b, "mousePressed", xy[1], xy[2])
  mouse(b, "mouseReleased", xy[1], xy[2])
}

drag <- function(b, xy, dx, dy, steps = 10, pause = 0.03) {
  xy <- unlist(xy)
  mouse(b, "mouseMoved", xy[1], xy[2])
  mouse(b, "mousePressed", xy[1], xy[2])
  for (i in seq_len(steps)) {
    mouse(b, "mouseMoved", xy[1] + dx * i / steps, xy[2] + dy * i / steps)
    Sys.sleep(pause)
  }
  mouse(b, "mouseReleased", xy[1] + dx, xy[2] + dy)
}

# Owning dock of an element: the closest widget container. Nested docks are
# widgets too, so this tells outer from nested chrome.
owner_js <- "(el) => el.closest('.html-widget-output').id"

# Centres of clickable inactive tabs of the outer dock (not hidden by tab
# overflow), skipping tabs whose panel hosts a nested dock.
inactive_tabs <- function(b, dock = "outer") {
  pred <- if (dock == "outer") "id === 'dock'" else "id !== 'dock'"
  js(
    b,
    sprintf(
      "(() => {
        const owner = %s;
        return JSON.stringify([...document.querySelectorAll('.dv-tab.dv-inactive-tab')]
          .filter((t) => { const id = owner(t); return %s; })
          .filter((t) => !/nested/.test(t.textContent))
          .map((t) => { const r = t.getBoundingClientRect();
            return { x: r.x + r.width / 2, y: r.y + r.height / 2, t };
          })
          .filter((p) => p.t.contains(document.elementFromPoint(p.x, p.y)))
          .map((p) => ({ x: p.x, y: p.y, title: p.t.textContent })));
      })()",
      owner_js,
      pred
    )
  ) |>
    jsonlite::fromJSON()
}

# A vertical sash (dragged sideways) belonging to the outer or a nested dock.
find_sash <- function(b, dock = "outer") {
  pred <- if (dock == "outer") "id === 'dock'" else "id !== 'dock'"
  js(
    b,
    sprintf(
      "(() => {
        const owner = %s;
        const s = [...document.querySelectorAll('.dv-sash')]
          .filter((el) => { const id = owner(el); return %s; })
          .map((el) => ({ el, r: el.getBoundingClientRect() }))
          .filter((x) => x.r.height > 80 && x.r.width > 0 && x.r.width < 10)
          .find((x) => x.el.contains(document.elementFromPoint(
            x.r.x + x.r.width / 2, x.r.y + x.r.height / 2)));
        return s ? [s.r.x + s.r.width / 2, s.r.y + s.r.height / 2] : null;
      })()",
      owner_js,
      pred
    )
  )
}

element_centre <- function(b, selector) {
  js(
    b,
    sprintf(
      "(() => {
        const el = document.querySelector(%s);
        if (!el) return null;
        const r = el.getBoundingClientRect();
        return [r.x + r.width / 2, r.y + r.height / 2];
      })()",
      jsonlite::toJSON(selector, auto_unbox = TRUE)
    )
  )
}

scenario <- function(b, action, quiet = 1000) {
  js(b, "dvPerf.reset()")
  action()
  wait_settled(b, quiet = quiet)
  summary_js(b)
}

run_variant <- function(label, env, full = TRUE) {
  message("Variant ", label, " ...")
  proc <- start_app(env)
  on.exit(proc$kill(), add = TRUE)
  wait_port()

  b <- chromote::ChromoteSession$new(
    width = viewport[["width"]],
    height = viewport[["height"]]
  )
  on.exit(b$close(), add = TRUE)

  res <- list(label = label)

  b$Page$navigate(sprintf("http://127.0.0.1:%d", port), wait_ = TRUE)
  wait_settled(b, quiet = 2000)
  res$load <- summary_js(b)

  # Tab switches: each one shows a panel that has never been on screen.
  tabs <- utils::head(inactive_tabs(b), 8)
  res$tab_first <- lapply(seq_len(NROW(tabs)), function(i) {
    s <- scenario(b, function() click_at(b, c(tabs$x[i], tabs$y[i])))
    s$title <- tabs$title[i]
    s
  })

  res$sash <- scenario(b, function() {
    xy <- find_sash(b, "outer")
    if (!is.null(xy)) drag(b, xy, dx = -60, dy = 0)
  })

  if (!full) {
    return(res)
  }

  # Switch back to tabs already rendered once.
  back <- utils::head(inactive_tabs(b), 8)
  res$tab_back <- lapply(seq_len(NROW(back)), function(i) {
    s <- scenario(b, function() click_at(b, c(back$x[i], back$y[i])))
    s$title <- back$title[i]
    s
  })

  res$nested_sash <- scenario(b, function() {
    xy <- find_sash(b, "nested")
    if (!is.null(xy)) drag(b, xy, dx = -30, dy = 0)
  })

  nested_tabs <- inactive_tabs(b, "nested")
  res$nested_tab <- scenario(b, function() {
    if (NROW(nested_tabs)) click_at(b, c(nested_tabs$x[1], nested_tabs$y[1]))
  })

  res$maximize <- scenario(b, function() {
    click_at(b, element_centre(b, "#dock .dv-groupview .fa-expand"))
  })
  res$unmaximize <- scenario(b, function() {
    click_at(b, element_centre(b, "#dock .fa-compress"))
  })

  res$window_resize <- scenario(
    b,
    function() {
      b$Emulation$setDeviceMetricsOverride(
        width = 1200L,
        height = 800L,
        deviceScaleFactor = 1,
        mobile = FALSE
      )
    },
    quiet = 1500
  )
  b$Emulation$clearDeviceMetricsOverride()
  wait_settled(b, quiet = 1500)

  button <- function(id) {
    function() click_at(b, element_centre(b, paste0("#", id)))
  }

  res$add_10 <- scenario(b, button("add"))
  res$remove_10 <- scenario(b, button("remove"))
  res$save <- scenario(b, button("save"))
  res$restore <- scenario(b, button("restore"), quiet = 1500)
  res$rerender <- scenario(b, button("rerender"), quiet = 2000)

  res
}

variants <- list(
  list(label = "mixed-100", env = c(DOCKVIEWR_PERF_N = "100"), full = TRUE),
  list(
    label = "mixed-100-always",
    env = c(DOCKVIEWR_PERF_N = "100", DOCKVIEWR_PERF_RENDERER = "always"),
    full = TRUE
  ),
  list(
    label = "static-25",
    env = c(
      DOCKVIEWR_PERF_N = "25",
      DOCKVIEWR_PERF_CONTENT = "static",
      DOCKVIEWR_PERF_NESTED = "0"
    ),
    full = FALSE
  ),
  list(
    label = "static-50",
    env = c(
      DOCKVIEWR_PERF_N = "50",
      DOCKVIEWR_PERF_CONTENT = "static",
      DOCKVIEWR_PERF_NESTED = "0"
    ),
    full = FALSE
  ),
  list(
    label = "static-100",
    env = c(
      DOCKVIEWR_PERF_N = "100",
      DOCKVIEWR_PERF_CONTENT = "static",
      DOCKVIEWR_PERF_NESTED = "0"
    ),
    full = FALSE
  ),
  list(
    label = "static-200",
    env = c(
      DOCKVIEWR_PERF_N = "200",
      DOCKVIEWR_PERF_CONTENT = "static",
      DOCKVIEWR_PERF_NESTED = "0"
    ),
    full = FALSE
  )
)

browser_results <- lapply(variants, function(v) {
  tryCatch(
    run_variant(v$label, v$env, v$full),
    error = function(e) list(label = v$label, error = conditionMessage(e))
  )
})

results <- list(
  meta = list(
    date = format(Sys.time()),
    r = R.version.string,
    shiny = as.character(packageVersion("shiny")),
    htmlwidgets = as.character(packageVersion("htmlwidgets")),
    dockViewR = as.character(packageVersion("dockViewR")),
    platform = R.version$platform,
    viewport = viewport
  ),
  r_side = r_results,
  browser = browser_results
)

jsonlite::write_json(results, out_file, auto_unbox = TRUE, digits = 4, pretty = TRUE)
message("Results written to ", out_file)
