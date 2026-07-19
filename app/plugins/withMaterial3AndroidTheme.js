const { AndroidConfig, withAndroidStyles } = require('expo/config-plugins');

const MATERIAL_THEME_PARENT = 'Theme.Material3.DayNight.NoActionBar';

module.exports = function withMaterial3AndroidTheme(config) {
  return withAndroidStyles(config, (mod) => {
    const appTheme = AndroidConfig.Styles.getStyleParent(
      mod.modResults,
      AndroidConfig.Styles.getAppThemeGroup()
    );

    if (!appTheme) {
      throw new Error('Unable to find AppTheme in the generated Android styles.xml.');
    }

    appTheme.$.parent = MATERIAL_THEME_PARENT;
    return mod;
  });
};
