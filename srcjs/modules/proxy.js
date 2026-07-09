const sendNotification = (message, type = "error", duration = null) => {
  if (HTMLWidgets.shinyMode) {
    Shiny.notifications.show({
      html: message,
      type: type,
      duration: duration
    });
  } else {
    alert(message);
  }
}

const isEmptyObj = (obj) => {
  return Object.keys(obj).length === 0;
}

// Custom eval depending on dockViewR mode
const evalDockView = (callback, mode) => {
  switch (mode) {
    case 'dev':
      try {
        callback();
      } catch (error) {
        // Get the caller function name from stack trace
        const stack = new Error().stack;
        const callerMatch = stack.split('\n')[2]?.match(/at (\w+)/);
        const callerName = callerMatch ? callerMatch[1] : 'unknown';

        sendNotification(`Error in ${callerName}: ${error.message}`);
      }
      break;
    case 'prod':
      callback();
      break;
    default:
      break;
  }
}

const validatedDockElement = (api, id, type, context = '') => {
  let fun;
  switch (type) {
    case 'panel':
      fun = (id) => api.getPanel(id);
      break;
    case 'group':
      fun = (id) => api.getGroup(id);
      break;
    default:
      break;
  }
  const res = fun(id);
  if (!res) {
    throw new Error(`${context}${type} with ID '${id}' not found`);
  }
  return res;
};

const addPanel = (panel, mode, api) => {
  let internals = {
    component: 'default',
    params: {
      content: panel.content,
      style: panel.style
    }
  }

  // Handle removable option. If no,
  // use the default tab component without the close panel button.
  if (!panel.remove.enable) {
    internals.tabComponent = 'custom';
  } else {
    if (panel.remove.mode === 'manual') {
      internals.tabComponent = 'manual';
      if (panel.remove.callback !== undefined) {
        internals.params.removeCallback = panel.remove.callback;
      }
    }
  }
  let props = { ...panel, ...internals };
  evalDockView(() => api.addPanel(props), mode)
}

const removePanel = (id, mode, api) => {
  evalDockView(() => {
    let panel = validatedDockElement(api, id, 'panel');
    api.removePanel(panel);
  }, mode)
}

const selectPanel = (id, mode, api) => {
  evalDockView(() => {
    let panel = validatedDockElement(api, id, 'panel');
    panel.api.setActive();
  }, mode);
}

// add_panel places panels by referencePanel/referenceGroup + direction; moveTo
// only understands a target group + Position, so translate: the reference
// resolves to the group to move next to, and direction maps onto Position.
const directionToPosition = {
  above: 'top',
  below: 'bottom',
  left: 'left',
  right: 'right',
  within: 'center'
};

const movePanel = (m, mode, api) => {
  evalDockView(() => {
    let panel = validatedDockElement(api, m.id, 'panel');
    let position = m.position;

    let group;
    if (position.referenceGroup !== undefined) {
      group = validatedDockElement(
        api, position.referenceGroup, 'group', 'Reference '
      );
    } else if (position.referencePanel !== undefined) {
      group = validatedDockElement(
        api, position.referencePanel, 'panel', 'Reference '
      ).api.group;
    }

    panel.api.moveTo({
      group: group,
      position: directionToPosition[position.direction],
      index: position.index
    });
  }, mode);
}

const moveGroup = (m, mode, api) => {
  evalDockView(() => {
    let from = validatedDockElement(api, m.id, 'group');
    // Move relative to another group
    let target = validatedDockElement(api, m.options.to, 'group');
    from.api.moveTo({
      group: target,
      position: m.options.position
    });
  }, mode)
}

const moveGroup2 = (m, mode, api) => {
  evalDockView(() => {
    let panel = validatedDockElement(api, m.id, 'panel');
    // Move relative to another group
    let groupTarget = validatedDockElement(
      api,
      m.options.to,
      'panel',
      'Target group'
    );
    panel.group.api.moveTo({
      group: groupTarget.api.group,
      position: m.options.position
    });
  }, mode)
}

const orthogonal = (o) => (o === 'HORIZONTAL' ? 'VERTICAL' : 'HORIZONTAL');

const firstLeafId = (node) =>
  node.type === 'leaf' ? node.data.id : firstLeafId(node.data[0]);

// Locate the splitview that directly contains `groupId` and describe it: the
// axis it lays panels out along, each member in visual order (a group to resize
// -- the member itself, or a representative leaf when the member is a nested
// split -- plus its content size along the axis, verbatim from the serialized
// size), and the split's per-cell `gap`.
//
// Two coordinate spaces are in play. The serialized sizes are content pixels;
// `setSize()` is instead given a cell allocation = content + an equal share of
// the split's inter-group gap (the rendered extent minus the summed content).
// So proportions are computed from the verbatim content sizes, but every
// `setSize()` input has `gap` added back -- otherwise the requested fraction is
// off by the gap and repeated calls drift. The rendered extent is tracked down
// the tree (a horizontal split's width shrinks only under horizontal ancestors,
// etc.); at the root it is `api.width` / `api.height`.
const findSplit = (root, orientation, rootWidth, rootHeight, groupId) => {
  let found = null;

  const walk = (node, axisOrientation, box) => {
    if (node.type === 'leaf') return;

    const children = node.data;
    const contents = children.map((c) => c.size || 0);
    const rendered = axisOrientation === 'HORIZONTAL' ? box.width : box.height;
    const gap = children.length
      ? (rendered - contents.reduce((a, b) => a + b, 0)) / children.length
      : 0;

    const targetIndex = children.findIndex(
      (c) => c.type === 'leaf' && c.data.id === groupId
    );

    if (targetIndex >= 0 && found === null) {
      found = {
        axis: axisOrientation === 'HORIZONTAL' ? 'width' : 'height',
        targetIndex,
        gap,
        members: children.map((c, i) => ({ id: firstLeafId(c), size: contents[i] }))
      };
    }

    children.forEach((c, i) => {
      if (c.type === 'branch') {
        const extent = contents[i] + gap;
        const childBox = axisOrientation === 'HORIZONTAL'
          ? { width: extent, height: box.height }
          : { width: box.width, height: extent };
        walk(c, orthogonal(axisOrientation), childBox);
      }
    });
  };

  walk(root, orientation, { width: rootWidth, height: rootHeight });
  return found;
};

// Size the panel's group to `m.size` of its splitview along the split axis,
// keeping the other members' relative sizes (they share the remaining
// `1 - m.size`). dockview's setSize only moves a view's trailing edge, so
// applying the targets leading -> trailing makes each final for everything
// before it; the last member inherits the remainder.
const setSize = (m, mode, api) => {
  evalDockView(() => {
    const panel = validatedDockElement(api, m.id, 'panel');
    const grid = api.toJSON().grid;
    const split = findSplit(
      grid.root, grid.orientation, api.width, api.height, panel.group.id
    );

    if (!split || split.members.length < 2) {
      return;
    }

    const { axis, members, targetIndex, gap } = split;
    const extent = members.reduce((sum, x) => sum + x.size, 0);
    const target = m.size * extent;
    const others = extent - members[targetIndex].size;
    const scale = others > 0 ? (extent - target) / others : 0;

    for (let i = 0; i < members.length - 1; i++) {
      const to = (i === targetIndex ? target : members[i].size * scale) + gap;
      api.getGroup(members[i].id).api.setSize(
        axis === 'width' ? { width: to } : { height: to }
      );
    }
  }, mode);
};

const serializeFunction = (func) => {
  if (typeof func === 'function') {
    return {
      __IS_FUNCTION__: true,
      source: func.toString()
    };
  }
  // do not process if not a function
  return func;
};

const clean_dock_state = (state) => {
  // Strip out unecessary information (deps, head, singletons...)
  if (isEmptyObj(state.panels)) return state;

  state.panels = Object.fromEntries(
    Object.entries(state.panels).map(([key, value]) => {

      // Create a new params object based on the old one
      const newParams = {
        ...value.params,
        content: {
          html: value.params.content.html
        }
      };

      // Modify removCallback if it exists
      if (newParams.removeCallback) {
        newParams.removeCallback = serializeFunction(newParams.removeCallback);
      }

      return [
        key,
        {
          ...value,
          params: newParams
        }
      ];
    })
  );
  return state;
};

// Provenance for `_state`. dockview delivers onDidLayoutChange -- where
// saveDock() runs -- on a microtask: its AsapEvent coalesces a burst of layout
// mutations into one notification fired via queueMicrotask, *after* the api
// call that caused them has returned. A flag set and cleared around the
// synchronous call would already be down by then, so withServerDriven() instead
// clears it on a microtask queued right after the call. Microtasks drain FIFO
// and dockview enqueues its notification during the mutation -- ahead of this
// clear -- so saveDock() sees the flag up for exactly the changes the server
// initiated, then it goes down. A user gesture (drag, tab close) reaches
// dockview without this wrapper and is reported as "client". Attribution is
// causal, not timed: there are no wall-clock windows.
const serverDriven = {};

const serverDrivenFor = (id) => serverDriven[id] === true;

const runServerDriven = (id, value, fn) => {
  const prev = serverDrivenFor(id);
  serverDriven[id] = value;
  try {
    return fn();
  } finally {
    queueMicrotask(() => {
      serverDriven[id] = prev;
    });
  }
};

const withServerDriven = (id, fn) => runServerDriven(id, true, fn);

const saveDock = (id, api) => {
  const state = clean_dock_state(api.toJSON());
  Shiny.setInputValue(id + "_state-source", serverDrivenFor(id) ? "server" : "client");
  Shiny.setInputValue(id + "_state", state);
}

export { addPanel, removePanel, selectPanel, movePanel, saveDock, moveGroup, moveGroup2, setSize, withServerDriven, runServerDriven, serverDrivenFor };
