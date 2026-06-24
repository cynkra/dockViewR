import { saveDock } from '../modules/proxy';

// Trailing-edge debounce: collapse a burst of calls into a single call that
// runs `wait` ms after the last one.
const debounce = (fn, wait) => {
  let timer = null;
  return function (...args) {
    if (timer) clearTimeout(timer);
    timer = setTimeout(() => {
      timer = null;
      fn.apply(this, args);
    }, wait);
  };
};

// `onDidLayoutChange` carries no cause: dockview (since the 4.10.0
// `renderer: 'always'` fix) re-fires it while a layout is still settling, and
// the global `resize` we dispatch to re-fit widgets nudges them by a fraction
// of a pixel, which re-fires it again -- a feedback loop that pegs the main
// thread on boards with many resize-sensitive widgets (e.g. ECharts). We break
// it by acting only on a real change: same structure with every panel size
// within RESIZE_EPS of the layout we last acted on is a no-op, so the sub-pixel
// echo terminates -- independent of client speed, unlike a fixed time window,
// and without dropping any genuine change (a real resize / add / remove moves
// sizes well beyond RESIZE_EPS and still passes).
const RESIZE_EPS = 2;       // px; below this a size delta is drift, not a change
const SIZE_KEYS = new Set(['width', 'height', 'size']);

// Deep-equal two `toJSON()` layouts, treating panel sizes as equal within `eps`
// px; structure (ids, grid, orientation, focus) must match exactly.
const sameLayout = (a, b, eps) => {
  if (typeof a !== typeof b) return false;
  if (a === null || b === null || typeof a !== 'object') return a === b;
  if (Array.isArray(a) !== Array.isArray(b)) return false;
  const keys = Object.keys(a);
  if (keys.length !== Object.keys(b).length) return false;
  for (const k of keys) {
    if (!(k in b)) return false;
    if (SIZE_KEYS.has(k) && typeof a[k] === 'number' && typeof b[k] === 'number') {
      if (Math.abs(a[k] - b[k]) > eps) return false;
    } else if (!sameLayout(a[k], b[k], eps)) {
      return false;
    }
  }
  return true;
};

const setDockViewCallbacks = (id, api) => {

  // Work around https://github.com/mathuo/dockview/issues/1031
  // resize the panel to its actual size :)
  api.onDidMovePanel((e) => {
    setTimeout(() => {
      e.panel.api.setSize(e.panel.api.height, e.panel.api.width)
    }, 1);
  })
  // Resize panel content on layout change (so plots / widgets re-fit) and sync
  // the dock state to Shiny. Debounced so a burst of intermediate frames while
  // the layout settles collapses to one run; `sameLayout` then breaks the
  // resize feedback loop by skipping when nothing changed beyond sub-pixel
  // drift (see the note on RESIZE_EPS above).
  let lastLayout = null;
  const onLayoutSettled = debounce(() => {
    let layout = null;
    try {
      layout = api.toJSON();
    } catch (e) {
      layout = null;                           // unreadable -- fall through and act
    }
    if (layout !== null && lastLayout !== null &&
        sameLayout(lastLayout, layout, RESIZE_EPS)) {
      return;                                  // only drift since we last acted
    }
    lastLayout = layout;
    window.dispatchEvent(new Event('resize'));
    if (HTMLWidgets.shinyMode) {
      saveDock(id, api)
      api.panels.map((panel) => {
        let pane = `#${id}-${panel.id}`;
        Shiny.initializeInputs($(pane));
        Shiny.bindAll($(pane));
      })
    }
  }, 250);
  api.onDidLayoutChange(onLayoutSettled)

  // When restored, we need to sync the new state for Shiny
  api.onDidLayoutFromJSON(() => {
    saveDock(id, api)
  })

  api.onDidMaximizedGroupChange((e) => {
    window.dispatchEvent(new Event('resize'));
  })

  api.onDidAddPanel((e) => {
    if (HTMLWidgets.shinyMode) {
      Shiny.setInputValue(id + '_added-panel', e.id);
      Shiny.setInputValue(id + '_n-panels', api.totalPanels);
    }
  })

  api.onDidRemovePanel((e) => {
    if (HTMLWidgets.shinyMode) {
      Shiny.setInputValue(id + '_removed-panel', e.id);
      Shiny.setInputValue(id + '_n-panels', api.totalPanels);
    }
  })

  api.onDidAddGroup((e) => {
    if (HTMLWidgets.shinyMode) {
      Shiny.setInputValue(id + '_n-groups', api.groups.length);
    }
  })

  api.onDidRemoveGroup((e) => {
    if (HTMLWidgets.shinyMode) {
      Shiny.setInputValue(id + '_n-groups', api.groups.length);
    }
  })

  api.onDidActivePanelChange((e) => {
    if (HTMLWidgets.shinyMode) {
      if (e === undefined) return null
      Shiny.setInputValue(id + '_active-panel', e.id);
    }
  })

  api.onDidActiveGroupChange((e) => {
    if (HTMLWidgets.shinyMode) {
      if (e === undefined) return null
      Shiny.setInputValue(id + '_active-group', e.id);
    }
  })
}

export { setDockViewCallbacks };