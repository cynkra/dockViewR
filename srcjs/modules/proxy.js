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

const movePanel = (m, mode, api) => {
  evalDockView(() => {
    let panel = validatedDockElement(api, m.id, 'panel');
    // Move relative to another group
    if (m.options.group !== undefined) {
      let groupTarget = validatedDockElement(
        api,
        m.options.group,
        'panel',
        'Target group '
      );
      panel.api.moveTo({
        group: groupTarget.api.group,
        position: m.options.position,
      })
      return null;
    }
    // Move panel inside the same group using 'index' only
    panel.api.moveTo(m.options);
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

export { addPanel, removePanel, selectPanel, movePanel, saveDock, moveGroup, moveGroup2, withServerDriven, runServerDriven, serverDrivenFor };