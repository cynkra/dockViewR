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

const addPanel = (api, panel) => {
  let internals = {
    component: 'default',
    params: {
      content: panel.content,
      id: panel.id
    }
  }
  let props = { ...panel, ...internals }
  return (api.addPanel(props))
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

export { matchTheme, addPanel, defaultPanel };