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

// An edge group's `initialSize` is a request against the splitview's available
// space, so it is only honoured once there is space to take it from. The grid is
// not that space at every moment: the container has its real size from the
// start, but the grid stays at its 100x100 default until the ResizeObserver
// seeds it, and a rail sized against an unseeded grid gets a proportional share
// instead of the pixels it asked for -- 87px for a 260px request -- which
// nothing re-flows once the grid reaches its real width. Laying the grid out
// against the container first is what makes `initialSize` mean pixels. A
// container measuring 0x0 (a dock inside a hidden tab) has no space to divide
// either way, so skip it and let the seed lay it out later.
//
// Both paths that size an edge group need this: construction here, and
// `restoreDock()`, where dockview's `fromJSON` lays the shell out from
// `this.width` before it deserializes the edges.
const layoutFromContainer = (id, api) => {
  const container = document.getElementById(id);
  if (container && container.clientWidth > 0 && container.clientHeight > 0) {
    api.layout(container.clientWidth, container.clientHeight);
  }
}

// Edge groups are created before the panels so a panel can name one in
// `position.referenceGroup` and land in the rail on the first pass.
const initEdgeGroups = (id, x, api) => {
  if (!Array.isArray(x.edgeGroups) || x.edgeGroups.length === 0) return;

  layoutFromContainer(id, api);

  x.edgeGroups.forEach((eg) => {
    addEdgeGroup(eg, x.mode, api);
  });
}

const initDockPanels = (x, api) => {
  x.panels.map((panel) => {
    addPanel(panel, x.mode, api);
  });
}

export { instantiateDock, initDockPanels, initEdgeGroups, layoutFromContainer };