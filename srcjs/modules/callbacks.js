import { saveDock } from '../modules/proxy';

const setDockViewCallbacks = (id, api) => {
  // Resize panel content on layout change
  // (useful so that plots or widgets resize correctly)
  // Also update the dock state.
  api.onDidLayoutChange(() => {
    window.dispatchEvent(new Event('resize'));
    if (HTMLWidgets.shinyMode) {
      saveDock(id, api)
      api.panels.map((panel) => {
        let pane = `#${id}-${panel.id}`;
        Shiny.initializeInputs($(pane));
        Shiny.bindAll($(pane));
      })
    }
  })

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