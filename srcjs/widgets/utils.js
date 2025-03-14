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
    case 'light-spaced':
      res = themeLightSpaced
    case 'abyss':
      res = themeAbyss
    case 'abyss/spaced':
      res = themeAbyssSpaced
    case 'vs':
      res = themeVisualStudio
    case 'dark':
      res = themeDark
    case 'dracula':
      res = themeDracula
    case 'replit':
      res = themeReplit
    default:
      res = themeLightSpaced
  }
  return (res)
}

export { matchTheme };