import { addPanel, removePanel, selectPanel, movePanel, saveDock, moveGroup, moveGroup2, setSize, setRestoring, addEdgeGroup, removeEdgeGroup, setEdgeGroupVisible } from '../modules/proxy';

const deserializeFunction = (obj) => {
  if (obj && typeof obj === 'object' && obj.__IS_FUNCTION__) {
    try {
      // Rebuild the function from its string source.
      return (new Function('return ' + obj.source))();
    } catch (e) {
      console.error("Error deserializing function:", e);
      // Return null on failure to prevent crashes
      return null;
    }
  }
  return obj;
};

const restoreDock = (id, state, api) => {

  // Avoid duplicate input/output warning when rebinding
  Shiny.unbindAll($(`#${id} .dockview-panel`))

  if (state && state.panels) {
    // Loop over all panel objects in the state
    Object.values(state.panels).forEach(panel => {
      // Check if the panel has a remove callback
      if (panel && panel.params && panel.params.removeCallback) {
        // Pass the removeCallback object to the deserializer
        panel.params.removeCallback = deserializeFunction(panel.params.removeCallback);
      }
    });
  }
  // fromJSON creates the edge groups the incoming state names, but leaves any
  // other edge in place, so a rail added since the save would survive a restore
  // that never knew about it. Drop those first, so the dock ends up as the
  // saved layout rather than the saved layout plus whatever has accumulated.
  const wanted = (state && state.edgeGroups) || {};
  const live = api.groups
    .map((group) => group.api.location)
    .filter((location) => location && location.type === 'edge')
    .map((location) => location.position);

  live.forEach((position) => {
    if (!wanted[position]) {
      api.removeEdgeGroup(position);
    }
  });

  return api.fromJSON(state);
}

const setShinyHandlers = (id, mode, api) => {
  Shiny.addCustomMessageHandler(id + '_add-panel', (m) => {
    // Transform the removeCallback string into a function
    HTMLWidgets.evaluateStringMember(m.panel, m.evals)
    addPanel(m.panel, mode, api);
  });

  Shiny.addCustomMessageHandler(id + '_rm-panel', (m) => {
    removePanel(m, mode, api);
  })

  Shiny.addCustomMessageHandler(id + '_move-panel', (m) => {
    movePanel(m, mode, api);
  })

  Shiny.addCustomMessageHandler(id + '_select-panel', (m) => {
    selectPanel(m, mode, api);
  })

  // Force save dock
  Shiny.addCustomMessageHandler(id + '_save-state', (m) => {
    saveDock(id, api)
  })

  // Restore layout. Raise `restoring` so no intermediate frame of fromJSON's
  // teardown/rebuild reaches `_state`; the onDidLayoutFromJSON callback lowers it
  // again and emits the settled layout. On a corrupted layout fromJSON reverts
  // and rethrows *before* firing that event, so the flag is cleared here too --
  // otherwise `_state` would stay gated for the rest of the session.
  Shiny.addCustomMessageHandler(id + '_restore-state', (m) => {
    setRestoring(id, true);
    try {
      restoreDock(id, m, api);
    } catch (e) {
      setRestoring(id, false);
      throw e;
    }
  })

  Shiny.addCustomMessageHandler(id + '_move-group2', (m) => {
    moveGroup2(m, mode, api);
  })

  Shiny.addCustomMessageHandler(id + '_move-group', (m) => {
    moveGroup(m, mode, api);
  })

  // A programmatic group resize fires only onDidLayoutChange, which no gesture
  // hooks, so persist explicitly, then re-fit widgets, as a gesture flush would.
  Shiny.addCustomMessageHandler(id + '_set-size', (m) => {
    setSize(m, mode, api);
    saveDock(id, api);
    window.dispatchEvent(new Event('resize'));
  })

  Shiny.addCustomMessageHandler(id + '_update-options', (m) => {
    if (m.hasOwnProperty('theme')) {
      m.theme = matchTheme(m.theme);
    }
    api.updateOptions(m);
  })

  // Set title. setTitle fires only onDidTitleChange, which no gesture hooks, so
  // persist explicitly so `_state` reflects the new title.
  Shiny.addCustomMessageHandler(id + '_set-panel-title', (m) => {
    api.getPanel(m.id).api.setTitle(m.title);
    saveDock(id, api);
  })

  // Edge groups. Adding or removing one adds or removes a dockview group, so
  // onDidAddGroup / onDidRemoveGroup carry it into the coalesced flush like any
  // other gesture. Toggling visibility fires nothing, so persist explicitly --
  // `_state` is where `is_edge_group_visible()` reads from.
  Shiny.addCustomMessageHandler(id + '_add-edge-group', (m) => {
    addEdgeGroup(m, mode, api);
  })

  Shiny.addCustomMessageHandler(id + '_rm-edge-group', (m) => {
    removeEdgeGroup(m, mode, api);
  })

  Shiny.addCustomMessageHandler(id + '_set-edge-group-visible', (m) => {
    setEdgeGroupVisible(m, mode, api);
    saveDock(id, api);
  })
}

export { setShinyHandlers };