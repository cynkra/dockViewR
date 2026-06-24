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

const setDockViewCallbacks = (id, api) => {

  // Work around https://github.com/mathuo/dockview/issues/1031
  // resize the panel to its actual size :)
  api.onDidMovePanel((e) => {
    setTimeout(() => {
      e.panel.api.setSize(e.panel.api.height, e.panel.api.width)
    }, 1);
  })
  // Resize panel content on layout change
  // (useful so that plots or widgets resize correctly)
  // Also update the dock state.
  //
  // This handler is debounced because dockview (since the 4.10.0
  // `renderer: 'always'` oscillation fix) emits `onDidLayoutChange` many times
  // while a layout is still settling. Each run dispatches a global `resize`
  // (which makes every htmlwidget on the page redraw) and re-binds every panel
  // via `Shiny.bindAll`. Dispatching `resize` nudges widgets, which nudges the
  // layout, which re-fires this handler -- a feedback loop that pegs the main
  // thread on boards with many resize-sensitive widgets (e.g. ECharts). The
  // debounce runs the expensive work once, after the layout has settled,
  // instead of on every intermediate frame.
  // The debounce alone only PACES the loop, it does not BREAK it: the work
  // below dispatches a global `resize` that nudges widgets, which nudge the
  // layout, which re-fires this handler. On a fast client the widget sizes
  // converge in a cycle or two and dockview stops emitting; on a slow client
  // (Safari, CPU contention) they never converge -> it churns forever,
  // continuously re-rendering Shiny outputs (R pegged at 100%, laggy view
  // switches). Two guards actually break the feedback:
  //   (1) coarse signature: skip when the layout STRUCTURE + integer-rounded
  //       sizes are unchanged since we last acted -- the sub-pixel size drift
  //       the loop feeds on is then a no-op, so a pure echo terminates;
  //   (2) re-entrancy window: ignore the onDidLayoutChange echo our own resize
  //       provokes for a short period right after we act.
  // Genuine changes (real resize, add/remove, restore) still pass both.
  let lastSig = null;
  let suppressUntil = 0;
  const layoutSig = () => {
    try {
      return JSON.stringify(api.toJSON(), (k, v) =>
        ((k === 'width' || k === 'height' || k === 'size') && typeof v === 'number')
          ? Math.round(v) : v);
    } catch (e) {
      return null;
    }
  };
  const onLayoutSettled = debounce(() => {
    const now = Date.now();
    if (now < suppressUntil) return;          // our own resize echo -- ignore
    const sig = layoutSig();
    if (sig !== null && sig === lastSig) return; // no real change -- break loop
    lastSig = sig;
    suppressUntil = now + 600;                 // absorb the echo from our resize
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