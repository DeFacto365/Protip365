const {
  AndroidConfig,
  withAndroidColors,
  withAndroidColorsNight,
  withAndroidStyles,
} = require('expo/config-plugins');

const MATERIAL_THEME_PARENT = 'Theme.Material3.DayNight.NoActionBar';

const DAY_COLORS = {
  protip_primary: '#20211E',
  protip_on_primary: '#F6F2E9',
  protip_primary_container: '#E9E4D7',
  protip_on_primary_container: '#20211E',
  protip_secondary: '#2E7D4F',
  protip_on_secondary: '#F6F2E9',
  protip_tertiary: '#D8472B',
  protip_on_tertiary: '#F6F2E9',
  protip_surface: '#F6F2E9',
  protip_on_surface: '#20211E',
};

const NIGHT_COLORS = {
  protip_primary: '#F0EEE6',
  protip_on_primary: '#171714',
  protip_primary_container: '#24231F',
  protip_on_primary_container: '#F0EEE6',
  protip_secondary: '#5CD69B',
  protip_on_secondary: '#171714',
  protip_tertiary: '#FF7A5C',
  protip_on_tertiary: '#171714',
  protip_surface: '#24231F',
  protip_on_surface: '#F0EEE6',
};

const THEME_COLORS = {
  colorPrimary: 'protip_primary',
  colorOnPrimary: 'protip_on_primary',
  colorPrimaryContainer: 'protip_primary_container',
  colorOnPrimaryContainer: 'protip_on_primary_container',
  colorSecondary: 'protip_secondary',
  colorOnSecondary: 'protip_on_secondary',
  colorTertiary: 'protip_tertiary',
  colorOnTertiary: 'protip_on_tertiary',
  colorSurface: 'protip_surface',
  colorOnSurface: 'protip_on_surface',
};

function withReceiptColors(config, mod, colors) {
  return mod(config, (result) => {
    for (const [name, value] of Object.entries(colors)) {
      result.modResults = AndroidConfig.Colors.assignColorValue(result.modResults, { name, value });
    }
    return result;
  });
}

module.exports = function withMaterial3AndroidTheme(config) {
  config = withReceiptColors(config, withAndroidColors, DAY_COLORS);
  config = withReceiptColors(config, withAndroidColorsNight, NIGHT_COLORS);

  return withAndroidStyles(config, (mod) => {
    const appTheme = AndroidConfig.Styles.getStyleParent(
      mod.modResults,
      AndroidConfig.Styles.getAppThemeGroup()
    );

    if (!appTheme) {
      throw new Error('Unable to find AppTheme in the generated Android styles.xml.');
    }

    appTheme.$.parent = MATERIAL_THEME_PARENT;
    for (const [name, resource] of Object.entries(THEME_COLORS)) {
      mod.modResults = AndroidConfig.Styles.assignStylesValue(mod.modResults, {
        add: true,
        parent: AndroidConfig.Styles.getAppThemeGroup(),
        name,
        value: `@color/${resource}`,
      });
    }
    return mod;
  });
};
