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
  const onLayoutSettled = debounce(() => {
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