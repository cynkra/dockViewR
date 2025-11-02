import { addPanel, removePanel, selectPanel, movePanel, saveDock, moveGroup, moveGroup2 } from '../modules/proxy';

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
  let res = api.fromJSON(state);
  Shiny.setInputValue(id + '_restored', true, { priority: 'event' });
  return res;
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
    movePanel(m, mode, api)
  })

  Shiny.addCustomMessageHandler(id + '_select-panel', (m) => {
    selectPanel(m, mode, api);
  })

  // Force save dock
  Shiny.addCustomMessageHandler(id + '_save-state', (m) => {
    saveDock(id, api)
  })

  // Restore layout
  Shiny.addCustomMessageHandler(id + '_restore-state', (m) => {
    restoreDock(id, m, api);
  })

  Shiny.addCustomMessageHandler(id + '_move-group2', (m) => {
    moveGroup2(m, mode, api)
  })

  Shiny.addCustomMessageHandler(id + '_move-group', (m) => {
    moveGroup(m, mode, api)
  })

  Shiny.addCustomMessageHandler(id + '_update-options', (m) => {
    if (m.hasOwnProperty('theme')) {
      m.theme = matchTheme(m.theme);
    }
    api.updateOptions(m);
  })
}

export { setShinyHandlers };