import {
    themeAbyss,
    themeAbyssSpaced,
    themeCatppuccinMocha,
    themeCatppuccinMochaSpaced,
    themeDark,
    themeDracula,
    themeGithubDark,
    themeGithubDarkSpaced,
    themeGithubLight,
    themeGithubLightSpaced,
    themeLight,
    themeLightSpaced,
    themeMonokai,
    themeNord,
    themeNordSpaced,
    themeSolarizedLight,
    themeSolarizedLightSpaced,
    themeVisualStudio
} from "dockview-core";

const themes = {
    'light': themeLight,
    'light-spaced': themeLightSpaced,
    'abyss': themeAbyss,
    'abyss-spaced': themeAbyssSpaced,
    'vs': themeVisualStudio,
    'dark': themeDark,
    'dracula': themeDracula,
    'nord': themeNord,
    'nord-spaced': themeNordSpaced,
    'catppuccin-mocha': themeCatppuccinMocha,
    'catppuccin-mocha-spaced': themeCatppuccinMochaSpaced,
    'monokai': themeMonokai,
    'solarized-light': themeSolarizedLight,
    'solarized-light-spaced': themeSolarizedLightSpaced,
    'github-dark': themeGithubDark,
    'github-dark-spaced': themeGithubDarkSpaced,
    'github-light': themeGithubLight,
    'github-light-spaced': themeGithubLightSpaced
};

const matchTheme = (theme) => {
    return themes[theme] ?? themeLightSpaced;
}

export { matchTheme }