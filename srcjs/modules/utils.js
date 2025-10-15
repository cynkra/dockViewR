import {
  themeAbyss,
  themeDark,
  themeLight,
  themeVisualStudio,
  themeDracula,
  themeReplit,
  themeAbyssSpaced,
  themeLightSpaced
} from "dockview-core";

const matchTheme = (theme) => {
  let res;
  switch (theme) {
    case 'light':
      res = themeLight
      break
    case 'light-spaced':
      res = themeLightSpaced
      break
    case 'abyss':
      res = themeAbyss
      break
    case 'abyss/spaced':
      res = themeAbyssSpaced
      break
    case 'vs':
      res = themeVisualStudio
      break
    case 'dark':
      res = themeDark
      break
    case 'dracula':
      res = themeDracula
      break
    case 'replit':
      res = themeReplit
      break
    default:
      res = themeLightSpaced
  }
  return (res)
}

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

const defaultPanel = (pnId) => {
  return (`
    <p>Exchange me by running:</p>
    <p>removeUI(<br>
      &nbsp;&nbsp;selector = "#${pnId} > *",<br>
      &nbsp;&nbsp;multiple = TRUE<br>
    )</p>
    <p>shiny::insertUI(<br>
          &nbsp;&nbsp;selector = "#${pnId}",<br>
          &nbsp;&nbsp;where = "beforeEnd",<br>
          &nbsp;&nbsp;ui = "your ui code here"<br>
    )</p>
  `)
}

const clean_dock_state = (state) => {
  // Strip out unecessary information (deps, head, singletons as they should be already inserted
  // in the DOM when the widget is created, so no need to keep them forever)
  state.panels = Object.fromEntries(
    Object.entries(state.panels).map(([key, value]) => [
      key,
      {
        ...value,
        params: {
          ...value.params,
          content: {
            html: value.params.content.html // only need the HTML content
          }
        }
      }
    ])
  );
  return (state)
}

const saveDock = (id, api) => {
  const state = clean_dock_state(api.toJSON())
  Shiny.setInputValue(id + "_state", state, { priority: 'event' });
}

export { matchTheme, addPanel, removePanel, selectPanel, movePanel, defaultPanel, saveDock, moveGroup, moveGroup2 };