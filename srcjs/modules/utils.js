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

const addPanel = (panel, api) => {
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
  let props = { ...panel, ...internals }
  return (api.addPanel(props))
}

const movePanel = (m, api) => {
  let panel = api.getPanel(`${m.id}`);
  // Move relative to another group
  if (m.options.group !== undefined) {
    let groupTarget = api.getPanel(`${m.options.group}`)
    panel.api.moveTo({
      group: groupTarget.api.group,
      position: m.options.position,
    })
    return null;
  }
  // Moce panel inside the same group using 'index' only
  panel.api.moveTo(m.options);
}

const moveGroup = (m, api) => {
  let from = api.getGroup(`${m.id}`);
  // Move relative to another group
  let target = api.getGroup(`${m.options.to}`);
  from.api.moveTo({
    group: target,
    position: m.options.position
  });
  return null;
}

const moveGroup2 = (m, api) => {
  let panel = api.getPanel(`${m.id}`);
  // Move relative to another group
  let groupTarget = api.getPanel(`${m.options.to}`);
  panel.group.api.moveTo({
    group: groupTarget.api.group,
    position: m.options.position
  });
  return null;
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

export { matchTheme, addPanel, movePanel, defaultPanel, saveDock, moveGroup, moveGroup2 };