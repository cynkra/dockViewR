import { addPanel, removePanel, selectPanel, movePanel, saveDock, moveGroup, moveGroup2, setSize, setRestoring } from '../modules/proxy';

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
}

export { setShinyHandlers };