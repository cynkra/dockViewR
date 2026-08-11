import {
  saveDock, isRestoring, setRestoring, isSeeded, setSeeded
} from '../modules/proxy';

const setDockViewCallbacks = (id, api) => {

  const container = document.getElementById(id);

  // A re-render builds a fresh dock, zero-sized until its ResizeObserver reports
  // geometry, so the previous render's gate must not carry over.
  setSeeded(id, false);

  // Re-fit embedded widgets (plots, ECharts, DT, ...) into their new panel
  // size. A render concern, kept off the per-frame layout stream.
  const refitWidgets = () => {
    window.dispatchEvent(new Event('resize'));
  };

  // Push the current layout to Shiny and rebind each panel's DOM, so inputs /
  // outputs inside moved or restored panels keep working. A state concern.
  // Binding is deliberately not gated: saveDock decides on its own whether the
  // layout is settled enough to publish, while a dock rendered inside a hidden
  // tab -- measuring 0x0, so never seeded -- still needs working inputs.
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

  // One settled `_state` per gesture. A single gesture fires several dockview
  // events (a tab move that splits a group fires onDidMovePanel, onDidAddGroup
  // and onDidActivePanelChange); persisting in each would emit several times and
  // push the coalescing onto every consumer. Instead each event flags a pending
  // flush, coalesced onto one microtask, so the burst becomes a single emit.
  // A restore is skipped wholesale: fromJSON replaces the panels' DOM as it goes,
  // so binding mid-rebuild would bind markup that is about to be discarded. The
  // settled callback below does the one persist the restore needs.
  const requestSync = () => {
    if (flushScheduled || persisting || isRestoring(id)) return;

    flushScheduled = true;
    queueMicrotask(() => {
      flushScheduled = false;
      persisting = true;
      try {
        persistState();

        // Nothing to re-fit into a dock that has no geometry yet, and the
        // `resize` it dispatches would restart the ResizeObserver's debounce --
        // delaying the very observation that settles the initial layout. The
        // seeding branch re-fits once the size is known.
        if (isSeeded(id)) refitWidgets();
      } finally {
        persisting = false;
      }
    });
  };

  api.onDidMovePanel(requestSync);

  // fromJSON fires this once the rebuild is complete, and nothing else calls
  // fromJSON, so this is the restore's settle boundary: reopen the gate, then
  // persist once. It has to be the full persist -- restoreDock unbinds the old
  // panels and fromJSON re-creates their bodies, so without the rebind the
  // restored panels come back as dead DOM -- plus the widget re-fit a gesture
  // flush would have done. The event fires synchronously from within fromJSON,
  // while the rebuilt panel bodies are still being attached, so the persist
  // waits for the microtask after it -- the same point the coalesced gesture
  // flush would have run.
  api.onDidLayoutFromJSON(() => {
    queueMicrotask(() => {
      setRestoring(id, false);

      persisting = true;
      try {
        persistState();
        if (isSeeded(id)) refitWidgets();
      } finally {
        persisting = false;
      }

      if (HTMLWidgets.shinyMode) {
        Shiny.setInputValue(id + '_restored', true, { priority: 'event' });
      }
    });
  });

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

    if (e === undefined) return;

    // Written before the dispatch below: `dispatchEvent` is synchronous, so a
    // listener that activates another panel re-enters this handler and writes the
    // newer id. Writing first lets that nested write land last and win, where
    // dispatching first would let this frame overwrite it with a superseded id.
    if (HTMLWidgets.shinyMode) {
      Shiny.setInputValue(id + '_active-panel', e.id);
    }

    // Re-broadcast activation as a DOM event on the container: the dockview `api`
    // is closure-private, so this is a consumer's only client-side handle onto
    // activation. A consumer listens to relocate deferred DOM into a panel on the
    // tick it mounts -- before paint, no server round-trip. Panel ids are unique
    // only within a dock, so `dock` tells a document-level listener which one
    // fired.
    if (container) {
      container.dispatchEvent(
        new CustomEvent('dockview:active-panel', {
          bubbles: true,
          detail: { id: e.id, dock: id }
        })
      );
    }
  });

  api.onDidActiveGroupChange((e) => {
    requestSync();
    if (HTMLWidgets.shinyMode && e !== undefined) {
      Shiny.setInputValue(id + '_active-group', e.id);
    }
  });

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
    // and to serialise -- so debounce the container's own resize and persist once
    // it settles. The debounce also lets dockview lay its grid out against the new
    // size before `saveDock` reads it, so the emitted geometry is real. A
    // container-only resize (a bslib sidebar toggle, a flex change) fires no
    // window `resize`, so re-fit embedded widgets here too -- guarded like the
    // gesture flush, since the re-fit and `toJSON` re-fire events while a group is
    // maximized. The first observation is the initial layout landing: it opens the
    // `seeded` gate and runs the full persist (binding the panels' inputs, which
    // the gated init flush no longer does); later ones are user resizes.
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

        persisting = true;
        try {
          if (seeding) setSeeded(id, true);

          persistState();
          refitWidgets();
        } finally {
          persisting = false;
        }
      }, 150);
    });
    resizeObserver.observe(container);

    disposeContainer = () => {
      container.removeEventListener('pointerup', onSashPointerup);
      clearTimeout(resizeTimer);
      resizeObserver.disconnect();
    };
  }

  return disposeContainer;
}

export { setDockViewCallbacks };
