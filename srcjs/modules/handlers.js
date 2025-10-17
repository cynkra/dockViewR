import { addPanel, removePanel, selectPanel, movePanel, saveDock, moveGroup, moveGroup2 } from '../modules/proxy';


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
    // Avoid duplicate input/output warning when rebinding
    Shiny.unbindAll($(`#${id} .dockview-panel`))
    api.fromJSON(m)
    Shiny.setInputValue(id + '_restored', true, { priority: 'event' });
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