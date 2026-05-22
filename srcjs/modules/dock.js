import { createDockview } from "dockview-core";
import { matchTheme } from './themes.js';
import { Panel, RightHeader, LeftHeader, CustomTab, DefaultTab } from './components.js';
import { addPanel, addEdgeGroup } from './proxy.js';

const instantiateDock = (id, x) => {
  return (createDockview(document.getElementById(id), {
    theme: matchTheme(x.theme),
    createRightHeaderActionComponent: (options) => {
      return new RightHeader(options)
    },
    createLeftHeaderActionComponent: (options) => {
      options._params.params.addTab = x.addTab;
      return new LeftHeader(options)
    },
    createComponent: (options) => {
      switch (options.name) {
        case 'default':
          return new Panel(options)
      }
    },
    createTabComponent: (options) => {
      switch (options.name) {
        case 'manual':
          return new DefaultTab();
        case 'custom':
          return new CustomTab();
      }
    },
    // Spread operator to include all other options from x
    ...Object.keys(x).reduce((acc, key) => {
      if (!['theme', 'addTab', 'edgeGroups'].includes(key)) {
        acc[key] = x[key];
      }
      return acc;
    }, {})
  }))
}

const initDockPanels = (x, api) => {
  x.panels.map((panel) => {
    addPanel(panel, x.mode, api);
  });
}

const initEdgeGroups = (x, api) => {
  if (!Array.isArray(x.edgeGroups) || x.edgeGroups.length === 0) return;
  x.edgeGroups.forEach((eg) => {
    addEdgeGroup(eg, x.mode, api);
  });
}

export { instantiateDock, initDockPanels, initEdgeGroups };