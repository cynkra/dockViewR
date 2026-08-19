import { createDockview } from "dockview";
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
    }, {}),
    // A drag-and-drop gesture on a floating group does not yet signal a
    // `_state` update, so the layout could change without the server learning
    // of it. Keep floating groups off until that gesture is handled.
    disableFloatingGroups: true
  }))
}

// Edge groups are created before the panels so a panel can name one in
// `position.referenceGroup` and land in the rail on the first pass.
//
// `initialSize` is a request against the splitview's available space, so it is
// only honoured once there is space to take it from. dockview has not laid out
// yet at this point -- the container has its real size, but the grid is still
// zero-sized until the ResizeObserver seeds it -- and a rail created against
// that gets a proportional share instead of the pixels it asked for. Laying the
// grid out against the container first is what makes `initialSize` mean
// something here. A container measuring 0x0 (a dock inside a hidden tab) has no
// space to divide either way, so skip it and let the seed lay it out later.
const initEdgeGroups = (id, x, api) => {
  if (!Array.isArray(x.edgeGroups) || x.edgeGroups.length === 0) return;

  const container = document.getElementById(id);
  if (container && container.clientWidth > 0 && container.clientHeight > 0) {
    api.layout(container.clientWidth, container.clientHeight);
  }

  x.edgeGroups.forEach((eg) => {
    addEdgeGroup(eg, x.mode, api);
  });
}

const initDockPanels = (x, api) => {
  x.panels.map((panel) => {
    addPanel(panel, x.mode, api);
  });
}

export { instantiateDock, initDockPanels, initEdgeGroups };