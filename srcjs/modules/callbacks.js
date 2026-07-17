import { saveDock } from '../modules/proxy';

const setDockViewCallbacks = (id, api) => {

  // Re-fit embedded widgets (plots, ECharts, DT, ...) into their new panel
  // size. A render concern, kept off the per-frame layout stream.
  const refitWidgets = () => {
    window.dispatchEvent(new Event('resize'));
  };

  // Push the current layout to Shiny and rebind each panel's DOM, so inputs /
  // outputs inside moved or restored panels keep working. A state concern.
  const persistState = () => {
    if (!HTMLWidgets.shinyMode) return;

    saveDock(id, api);
    api.panels.map((panel) => {
      let pane = `#${id}-${panel.id}`;
      Shiny.initializeInputs($(pane));
      Shiny.bindAll($(pane));
    });
  };

  // While a group is maximized, `api.toJSON()` (read by saveDock) re-fires
  // onDidMaximizedGroupChange -- it momentarily exits and re-enters the maximized
  // state to serialise correct dimensions. Driving the flush off that event then
  // loops the persist with itself (saveDock -> toJSON -> event -> saveDock).
  // `persisting` marks the window in which a flush runs; events that fire inside
  // it are byproducts of the persist, not gestures, so they are ignored. (Real
  // gestures fire outside it.) This is a dockview bug, fixed in dockview-core
  // 6.1.1; once the bundled dockview is >= 6.1.1 this guard can be removed.
  let flushScheduled = false;
  let persisting = false;

  const persist = () => {
    persisting = true;
    try {
      persistState();
    } finally {
      persisting = false;
    }
  };

  // One settled `_state` per gesture. A single gesture fires several dockview
  // events (a tab move that splits a group fires onDidMovePanel, onDidAddGroup
  // and onDidActivePanelChange); persisting in each would emit several times and
  // push the coalescing onto every consumer. Instead each event flags a pending
  // flush, coalesced onto one microtask. The microtask drains within the same
  // task as the events that scheduled it -- inside the server op's provenance
  // window, ahead of its clear -- so `saveDock` reads the correct
  // `_state-source`; a separate gesture runs in a later task and gets its own
  // flush, so two gestures never merge into one (mis)tagged emit.
  const requestSync = () => {
    if (flushScheduled || persisting) return;

    flushScheduled = true;
    queueMicrotask(() => {
      flushScheduled = false;
      persisting = true;
      try {
        persistState();
        refitWidgets();
      } finally {
        persisting = false;
      }
    });
  };

  api.onDidMovePanel(requestSync);

  api.onDidLayoutFromJSON(requestSync);

  api.onDidMaximizedGroupChange(requestSync);

  api.onDidAddPanel((e) => {
    requestSync();
    if (HTMLWidgets.shinyMode) {
      Shiny.setInputValue(id + '_added-panel', e.id);
      Shiny.setInputValue(id + '_n-panels', api.totalPanels);
    }
  });

  api.onDidRemovePanel((e) => {
    requestSync();
    if (HTMLWidgets.shinyMode) {
      Shiny.setInputValue(id + '_removed-panel', e.id);
      Shiny.setInputValue(id + '_n-panels', api.totalPanels);
    }
  });

  api.onDidAddGroup(() => {
    requestSync();
    if (HTMLWidgets.shinyMode) {
      Shiny.setInputValue(id + '_n-groups', api.groups.length);
    }
  });

  api.onDidRemoveGroup(() => {
    requestSync();
    if (HTMLWidgets.shinyMode) {
      Shiny.setInputValue(id + '_n-groups', api.groups.length);
    }
  });

  api.onDidActivePanelChange((e) => {
    requestSync();
    if (HTMLWidgets.shinyMode && e !== undefined) {
      Shiny.setInputValue(id + '_active-panel', e.id);
    }
  });

  api.onDidActiveGroupChange((e) => {
    requestSync();
    if (HTMLWidgets.shinyMode && e !== undefined) {
      Shiny.setInputValue(id + '_active-group', e.id);
    }
  });

  const container = document.getElementById(id);

  // The pointerup listener and ResizeObserver live on the container element,
  // which outlives the dock api across a reactive re-render -- unlike the api's
  // onDid* subscriptions, which die with `api.dispose()`. Return them for
  // explicit teardown so they don't accumulate and re-emit superseded state.
  let disposeContainer = () => {};
  if (container) {

    // Resize is the only continuous gesture and dockview does not surface its
    // pointer-up boundary (`onDidSashEnd`) on the public api, so close it on
    // the sash `pointerup` directly. Delegated on the container to catch
    // sashes created later as groups split.
    const onSashPointerup = (e) => {
      if (e.target && e.target.closest && e.target.closest('.dv-sash')) {
        requestSync();
      }
    };
    container.addEventListener('pointerup', onSashPointerup);

    // A container / window resize changes the layout but has no gesture, and no
    // event-driven end (the window-drag-end belongs to the OS). `_state` must
    // still reflect it -- consumers read the input directly, to drive observers
    // and to serialise -- so debounce the container's own resize and persist
    // once it settles. It is environmental, not server-initiated, so it reads
    // as "client". `persist` (saveDock only, no re-fit) -- guarded, since its
    // `toJSON` re-fires events while maximized just like the gesture flush. The
    // first settled size is the initial layout the one-shot below already
    // persisted, so it seeds the baseline without re-emitting; only later do.
    let resizeBaseline = null;
    let resizeTimer = null;
    const resizeObserver = new ResizeObserver((entries) => {
      const rect = entries[0].contentRect;
      if (rect.width === 0 || rect.height === 0) return;

      const size = Math.round(rect.width) + 'x' + Math.round(rect.height);
      clearTimeout(resizeTimer);
      resizeTimer = setTimeout(() => {
        if (size === resizeBaseline) return;

        const seeding = resizeBaseline === null;
        resizeBaseline = size;
        if (!seeding) persist();
      }, 150);
    });
    resizeObserver.observe(container);

    disposeContainer = () => {
      container.removeEventListener('pointerup', onSashPointerup);
      clearTimeout(resizeTimer);
      resizeObserver.disconnect();
    };
  }

  // The initial layout (0 -> real size) has no gesture, and the captures during
  // the synchronous render all read a zero-sized dock. Subscribe to
  // `onDidLayoutChange` only long enough to persist the first laid-out state,
  // then dispose -- the per-frame stream is never consumed past that point, so
  // the storm this issue is about cannot return. It routes through the same
  // coalescer, so it folds into any gesture it lands inside.
  const firstLayout = api.onDidLayoutChange(() => {
    if (api.width > 0 && api.height > 0) {
      firstLayout.dispose();
      requestSync();
    }
  });

  return () => {
    disposeContainer();
    firstLayout.dispose();
  };
}

export { setDockViewCallbacks };
