import * as Localization from "expo-localization";

export type SupportedLocale = "en" | "fr" | "es";

const translations = {
  en: {
    appName: "ProTip365",
    foundationSubtitle: "Shared mobile rebuild foundation",
    foundationBody: "Expo React Native and TypeScript are ready for the iOS and Android rebuild.",
    tabs: { today: "Today", calendar: "Calendar", add: "Add", reports: "Reports", settings: "Settings" },
    screens: {
      today: "Today",
      calendar: "Calendar",
      add: "Add",
      addShift: "Add shift",
      addIncome: "Add income",
      reports: "Reports",
      weeklyReport: "Weekly report",
      monthlyReport: "Monthly report",
      yearlyReport: "Yearly report",
      history: "History",
      settings: "Settings",
      onboarding: "Onboarding",
      paywall: "Premium",
    },
    actions: {
      addShift: "Add shift",
      addIncome: "Add income",
      viewWeekly: "View weekly report",
      viewMonthly: "View monthly report",
      viewYearly: "View yearly report",
      viewHistory: "View history",
    },
    placeholders: {
      today: "Daily tip entry, real hourly income, missed shift state, and quick edit links will live here.",
      calendar: "Calendar status indicators, shift days, and edit navigation will live here.",
      add: "Choose the shift or income workflow.",
      addShift: "Shift time, role, employer, sales, tips, tip-out, notes, and did-not-work behavior will live here.",
      addIncome: "Other income entries and adjustment flows will live here.",
      reports: "Today, weekly, monthly, and yearly reporting entry points will live here.",
      history: "Search, filter, and edit previous entries from here.",
      settings: "Account, jobs, defaults, language, support, privacy, and subscription links will live here.",
      onboarding: "First-run setup and product education will live here.",
      paywall: "Free and premium tier comparison will live here.",
    },
  },
  fr: {
    appName: "ProTip365",
    foundationSubtitle: "Base mobile commune",
    foundationBody: "Expo React Native et TypeScript sont prêts pour la reconstruction iOS et Android.",
    tabs: { today: "Aujourd'hui", calendar: "Calendrier", add: "Ajouter", reports: "Rapports", settings: "Réglages" },
    screens: {
      today: "Aujourd'hui",
      calendar: "Calendrier",
      add: "Ajouter",
      addShift: "Ajouter un quart",
      addIncome: "Ajouter un revenu",
      reports: "Rapports",
      weeklyReport: "Rapport hebdomadaire",
      monthlyReport: "Rapport mensuel",
      yearlyReport: "Rapport annuel",
      history: "Historique",
      settings: "Réglages",
      onboarding: "Accueil",
      paywall: "Premium",
    },
    actions: {
      addShift: "Ajouter un quart",
      addIncome: "Ajouter un revenu",
      viewWeekly: "Voir la semaine",
      viewMonthly: "Voir le mois",
      viewYearly: "Voir l'annee",
      viewHistory: "Voir l'historique",
    },
    placeholders: {
      today: "La saisie quotidienne, le taux horaire reel, les quarts manques et les liens de modification seront ici.",
      calendar: "Les indicateurs du calendrier, les jours travailles et la modification des quarts seront ici.",
      add: "Choisissez le flux de quart ou de revenu.",
      addShift: "Les heures, le role, l'employeur, les ventes, les pourboires, les retraits, les notes et les absences seront ici.",
      addIncome: "Les autres revenus et les ajustements seront ici.",
      reports: "Les rapports du jour, de la semaine, du mois et de l'annee seront ici.",
      history: "La recherche, les filtres et la modification des entrees passees seront ici.",
      settings: "Le compte, les emplois, les valeurs par defaut, la langue, le support, la confidentialite et l'abonnement seront ici.",
      onboarding: "La configuration initiale et l'introduction au produit seront ici.",
      paywall: "La comparaison entre l'offre gratuite et premium sera ici.",
    },
  },
  es: {
    appName: "ProTip365",
    foundationSubtitle: "Base movil compartida",
    foundationBody: "Expo React Native y TypeScript estan listos para la reconstruccion de iOS y Android.",
    tabs: { today: "Hoy", calendar: "Calendario", add: "Agregar", reports: "Reportes", settings: "Ajustes" },
    screens: {
      today: "Hoy",
      calendar: "Calendario",
      add: "Agregar",
      addShift: "Agregar turno",
      addIncome: "Agregar ingreso",
      reports: "Reportes",
      weeklyReport: "Reporte semanal",
      monthlyReport: "Reporte mensual",
      yearlyReport: "Reporte anual",
      history: "Historial",
      settings: "Ajustes",
      onboarding: "Inicio",
      paywall: "Premium",
    },
    actions: {
      addShift: "Agregar turno",
      addIncome: "Agregar ingreso",
      viewWeekly: "Ver semana",
      viewMonthly: "Ver mes",
      viewYearly: "Ver ano",
      viewHistory: "Ver historial",
    },
    placeholders: {
      today: "El registro diario, el ingreso real por hora, los turnos perdidos y los enlaces de edicion estaran aqui.",
      calendar: "Los indicadores del calendario, los dias de turno y la navegacion de edicion estaran aqui.",
      add: "Elija el flujo de turno o ingreso.",
      addShift: "Hora, rol, empleador, ventas, propinas, reparto, notas y ausencias estaran aqui.",
      addIncome: "Otros ingresos y ajustes estaran aqui.",
      reports: "Los reportes diarios, semanales, mensuales y anuales estaran aqui.",
      history: "La busqueda, los filtros y la edicion de entradas anteriores estaran aqui.",
      settings: "Cuenta, empleos, valores predeterminados, idioma, soporte, privacidad y suscripcion estaran aqui.",
      onboarding: "La configuracion inicial y la introduccion al producto estaran aqui.",
      paywall: "La comparacion entre el plan gratis y premium estara aqui.",
    },
  },
};

export type Translation = (typeof translations)["en"];

export function getDeviceLocale(): SupportedLocale {
  const code = Localization.getLocales()[0]?.languageCode?.toLowerCase();
  return code === "fr" || code === "es" ? code : "en";
}

export function getStrings(locale: SupportedLocale = getDeviceLocale()): Translation {
  return translations[locale];
}
