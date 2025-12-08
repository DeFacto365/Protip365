import Foundation

// MARK: - Settings Localization

struct SettingsLocalization {
    let language: String

    init(language: String = "en") {
        self.language = language
    }

    // MARK: - General Settings

    var settingsTitle: String {
        switch language {
        case "fr": return "Réglages"
        case "es": return "Ajustes"
        default: return "Settings"
        }
    }

    var saveButton: String {
        switch language {
        case "fr": return "Sauvegarder"
        case "es": return "Guardar"
        default: return "Save"
        }
    }

    var savingButton: String {
        switch language {
        case "fr": return "Sauvegarde..."
        case "es": return "Guardando..."
        default: return "Saving..."
        }
    }

    var cancelButton: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

    var doneButton: String {
        switch language {
        case "fr": return "Terminé"
        case "es": return "Listo"
        default: return "Done"
        }
    }

    // MARK: - Profile Section

    var profileSection: String {
        switch language {
        case "fr": return "Profil"
        case "es": return "Perfil"
        default: return "Profile"
        }
    }

    var nameLabel: String {
        switch language {
        case "fr": return "Nom"
        case "es": return "Nombre"
        default: return "Name"
        }
    }

    var emailLabel: String {
        switch language {
        case "fr": return "Courriel"
        case "es": return "Correo electrónico"
        default: return "Email"
        }
    }

    var defaultHourlyRate: String {
        switch language {
        case "fr": return "Taux horaire par défaut"
        case "es": return "Tarifa por hora predeterminada"
        default: return "Default Hourly Rate"
        }
    }

    var tipTargetPercentage: String {
        switch language {
        case "fr": return "Objectif de pourboire (%)"
        case "es": return "Objetivo de propinas (%)"
        default: return "Tip Target Percentage (%)"
        }
    }

    var weekStartDay: String {
        switch language {
        case "fr": return "Début de semaine"
        case "es": return "Inicio de semana"
        default: return "Week Start Day"
        }
    }

    var useMultipleEmployers: String {
        switch language {
        case "fr": return "Utiliser plusieurs employeurs"
        case "es": return "Usar múltiples empleadores"
        default: return "Use Multiple Employers"
        }
    }

    var defaultEmployer: String {
        switch language {
        case "fr": return "Employeur par défaut"
        case "es": return "Empleador predeterminado"
        default: return "Default Employer"
        }
    }

    var defaultAlertLabel: String {
        switch language {
        case "fr": return "Alerte de quart par défaut"
        case "es": return "Alerta de turno predeterminada"
        default: return "Default Shift Alert"
        }
    }

    // MARK: - Targets Section

    var targetsSection: String {
        switch language {
        case "fr": return "Objectifs"
        case "es": return "Objetivos"
        default: return "Targets"
        }
    }

    var dailyTargets: String {
        switch language {
        case "fr": return "Objectifs quotidiens"
        case "es": return "Objetivos diarios"
        default: return "Daily Targets"
        }
    }

    var weeklyTargets: String {
        switch language {
        case "fr": return "Objectifs hebdomadaires"
        case "es": return "Objetivos semanales"
        default: return "Weekly Targets"
        }
    }

    var monthlyTargets: String {
        switch language {
        case "fr": return "Objectifs mensuels"
        case "es": return "Objetivos mensuales"
        default: return "Monthly Targets"
        }
    }

    var targetSales: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
        }
    }

    var targetHours: String {
        switch language {
        case "fr": return "Heures"
        case "es": return "Horas"
        default: return "Hours"
        }
    }

    // MARK: - Security Section

    var securitySection: String {
        switch language {
        case "fr": return "Sécurité"
        case "es": return "Seguridad"
        default: return "Security"
        }
    }

    var appLockSecurity: String {
        switch language {
        case "fr": return "Verrouillage d'application"
        case "es": return "Bloqueo de aplicación"
        default: return "App Lock Security"
        }
    }

    var noneSecurityType: String {
        switch language {
        case "fr": return "Aucun"
        case "es": return "Ninguno"
        default: return "None"
        }
    }

    var pinSecurityType: String {
        switch language {
        case "fr": return "Code PIN"
        case "es": return "Código PIN"
        default: return "PIN Code"
        }
    }

    var biometricSecurityType: String {
        switch language {
        case "fr": return "Biométrie"
        case "es": return "Biométrica"
        default: return "Biometric"
        }
    }

    var changePIN: String {
        switch language {
        case "fr": return "Changer le code PIN"
        case "es": return "Cambiar código PIN"
        default: return "Change PIN"
        }
    }

    // MARK: - Support Section

    var supportSection: String {
        switch language {
        case "fr": return "Support"
        case "es": return "Soporte"
        default: return "Support"
        }
    }

    var suggestIdeas: String {
        switch language {
        case "fr": return "Suggérer des idées"
        case "es": return "Sugerir ideas"
        default: return "Suggest Ideas"
        }
    }

    var exportData: String {
        switch language {
        case "fr": return "Exporter les données"
        case "es": return "Exportar datos"
        default: return "Export Data"
        }
    }

    var exportDataDescription: String {
        switch language {
        case "fr": return "CSV et autres formats"
        case "es": return "CSV y otros formatos"
        default: return "CSV and other formats"
        }
    }

    var onboardingGuide: String {
        switch language {
        case "fr": return "Guide de configuration"
        case "es": return "Guía de configuración"
        default: return "Setup Guide"
        }
    }

    var onboardingGuideSubtitle: String {
        switch language {
        case "fr": return "Revoir la configuration initiale"
        case "es": return "Revisar la configuración inicial"
        default: return "Review initial setup"
        }
    }

    var appTutorial: String {
        switch language {
        case "fr": return "Tutoriel de l'application"
        case "es": return "Tutorial de la aplicación"
        default: return "App Tutorial"
        }
    }

    // MARK: - Account Section

    var accountSection: String {
        switch language {
        case "fr": return "Compte"
        case "es": return "Cuenta"
        default: return "Account"
        }
    }

    var manageSubscription: String {
        switch language {
        case "fr": return "Gérer l'abonnement"
        case "es": return "Gestionar suscripción"
        default: return "Manage Subscription"
        }
    }

    var signOut: String {
        switch language {
        case "fr": return "Se déconnecter"
        case "es": return "Cerrar sesión"
        default: return "Sign Out"
        }
    }

    var deleteAccount: String {
        switch language {
        case "fr": return "Supprimer le compte"
        case "es": return "Eliminar cuenta"
        default: return "Delete Account"
        }
    }

    // MARK: - Work Defaults Section

    var workDefaultsSection: String {
        switch language {
        case "fr": return "Valeurs par défaut"
        case "es": return "Valores predeterminados"
        default: return "Work Defaults"
        }
    }

    var hourlyRateLabel: String {
        switch language {
        case "fr": return "Taux horaire"
        case "es": return "Tarifa por hora"
        default: return "Hourly Rate"
        }
    }

    var averageDeductionLabel: String {
        switch language {
        case "fr": return "Déductions AVG"
        case "es": return "Deducciones AVG"
        default: return "AVG deductions"
        }
    }

    var averageDeductionNoteTitle: String {
        switch language {
        case "fr": return "À propos des déductions"
        case "es": return "Acerca de las deducciones"
        default: return "About deductions"
        }
    }

    var averageDeductionNoteMessage: String {
        switch language {
        case "fr": return "Il s'agit de la déduction moyenne attendue sur votre salaire brut (impôts sur le revenu, cotisations sociales, etc.). Nous utiliserons ce pourcentage pour estimer votre salaire net, bien que le montant réel proviendra de votre bulletin de paie."
        case "es": return "Este es el porcentaje de deducción promedio esperado de su salario bruto (impuestos sobre la renta, seguridad social, etc.). Usaremos esto para estimar su salario neto, aunque el monto real vendrá de su nómina."
        default: return "This is the expected average deduction on your gross salary (income taxes, social security, etc.). We'll use this to estimate your net salary, though the actual amount will come from your payroll."
        }
    }

    var variableScheduleLabel: String {
        switch language {
        case "fr": return "Horaire variable"
        case "es": return "Horario variable"
        default: return "Variable Schedule"
        }
    }

    var variableScheduleDescription: String {
        switch language {
        case "fr": return "J'ai un horaire de travail variable"
        case "es": return "Tengo un horario de trabajo variable"
        default: return "I have a variable work schedule"
        }
    }

    var variableScheduleEnabledTitle: String {
        switch language {
        case "fr": return "Mode horaire variable activé"
        case "es": return "Modo horario variable activado"
        default: return "Variable Schedule Mode Active"
        }
    }

    var variableScheduleEnabledMessage: String {
        switch language {
        case "fr": return "Les objectifs hebdomadaires et mensuels pour les ventes et les heures sont désactivés. Seuls les objectifs quotidiens sont visibles car ils sont plus pertinents pour les horaires variables."
        case "es": return "Los objetivos semanales y mensuales para ventas y horas están desactivados. Solo los objetivos diarios son visibles porque son más relevantes para horarios variables."
        default: return "Weekly and monthly targets for sales and hours are hidden. Only daily targets are shown as they're more relevant for variable schedules."
        }
    }

    var variableScheduleNoteTitle: String {
        switch language {
        case "fr": return "Horaire variable"
        case "es": return "Horario variable"
        default: return "Variable Schedule"
        }
    }

    var variableScheduleNoteMessage: String {
        switch language {
        case "fr": return "Si vous avez un horaire variable, vous pouvez utiliser uniquement les objectifs quotidiens, qui seront plus pertinents. Les objectifs hebdomadaires et mensuels ne sont pas significatifs si vous ne travaillez pas un nombre fixe de jours."
        case "es": return "Si tienes un horario variable, puedes usar solo los objetivos diarios, que serán más relevantes. Los objetivos semanales y mensuales no tienen sentido si no trabajas un número fijo de días."
        default: return "If you have a variable schedule, you can just use daily targets, which will be more relevant. Weekly and monthly targets don't make sense if you don't work a fixed number of days."
        }
    }

    var variableScheduleHoursNoteMessage: String {
        switch language {
        case "fr": return "Si vous avez un horaire variable, vous pouvez utiliser uniquement les objectifs d'heures quotidiens, qui seront plus pertinents. Les objectifs hebdomadaires et mensuels ne sont pas significatifs si vous ne travaillez pas un nombre fixe de jours."
        case "es": return "Si tienes un horario variable, puedes usar solo los objetivos de horas diarios, que serán más relevantes. Los objetivos semanales y mensuales no tienen sentido si no trabajas un número fijo de días."
        default: return "If you have a variable schedule, you can just use daily hours targets, which will be more relevant. Weekly and monthly targets don't make sense if you don't work a fixed number of days."
        }
    }

    // MARK: - Targets Section

    var yourTargetsTitle: String {
        switch language {
        case "fr": return "Vos objectifs"
        case "es": return "Tus objetivos"
        default: return "Your Targets"
        }
    }

    var tipTargetsSection: String {
        switch language {
        case "fr": return "Objectifs de pourboires"
        case "es": return "Objetivos de propinas"
        default: return "Tip Targets"
        }
    }

    var tipPercentageTargetLabel: String {
        switch language {
        case "fr": return "Pourcentage de pourboire cible"
        case "es": return "Porcentaje objetivo de propinas"
        default: return "Target Tip Percentage"
        }
    }

    var tipPercentageShortLabel: String {
        switch language {
        case "fr": return "Pourboire %"
        case "es": return "Propina %"
        default: return "Tip %"
        }
    }

    var tipPercentageNoteTitle: String {
        switch language {
        case "fr": return "Pourcentage des ventes"
        case "es": return "Porcentaje de ventas"
        default: return "Percentage of Sales"
        }
    }

    var tipPercentageNoteMessage: String {
        switch language {
        case "fr": return "Définissez votre objectif de pourboire en pourcentage de vos ventes totales. Par exemple, 15% signifie que vous visez 15% de vos ventes en pourboires."
        case "es": return "Establezca su objetivo de propinas como porcentaje de sus ventas totales. Por ejemplo, 15% significa que apunta a 15% de sus ventas en propinas."
        default: return "Set your tip goal as a percentage of your total sales. For example, 15% means you aim for 15% of your sales in tips."
        }
    }

    var salesTargetsSection: String {
        switch language {
        case "fr": return "Objectifs de ventes"
        case "es": return "Objetivos de ventas"
        default: return "Sales Targets"
        }
    }

    var hoursTargetsSection: String {
        switch language {
        case "fr": return "Objectifs d'heures"
        case "es": return "Objetivos de horas"
        default: return "Hours Targets"
        }
    }

    var dailySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes quotidiennes"
        case "es": return "Ventas diarias"
        default: return "Daily Sales"
        }
    }

    var weeklySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes hebdomadaires"
        case "es": return "Ventas semanales"
        default: return "Weekly Sales"
        }
    }

    var monthlySalesTargetLabel: String {
        switch language {
        case "fr": return "Ventes mensuelles"
        case "es": return "Ventas mensuales"
        default: return "Monthly Sales"
        }
    }

    var dailyHoursTargetLabel: String {
        switch language {
        case "fr": return "Heures quotidiennes"
        case "es": return "Horas diarias"
        default: return "Daily Hours"
        }
    }

    var weeklyHoursTargetLabel: String {
        switch language {
        case "fr": return "Heures hebdomadaires"
        case "es": return "Horas semanales"
        default: return "Weekly Hours"
        }
    }

    var monthlyHoursTargetLabel: String {
        switch language {
        case "fr": return "Heures mensuelles"
        case "es": return "Horas mensuales"
        default: return "Monthly Hours"
        }
    }

    var setYourGoalsTitle: String {
        switch language {
        case "fr": return "🎯 Fixez vos objectifs"
        case "es": return "🎯 Establece tus metas"
        default: return "🎯 Set your goals"
        }
    }

    var setYourGoalsDescription: String {
        switch language {
        case "fr": return "Définissez des objectifs quotidiens, hebdomadaires et mensuels. Votre tableau de bord affichera les progrès comme '2.0/8h' pour les heures travaillées vs prévues."
        case "es": return "Establezca objetivos diarios, semanales y mensuales. Su panel mostrará el progreso como '2.0/8h' para horas trabajadas vs esperadas."
        default: return "Set daily, weekly, and monthly targets. Your dashboard will show progress like '2.0/8h' for hours worked vs expected."
        }
    }

    // MARK: - Language Section

    var languageSection: String {
        switch language {
        case "fr": return "Langue"
        case "es": return "Idioma"
        default: return "Language"
        }
    }

    var languageLabel: String {
        switch language {
        case "fr": return "Choisir la langue"
        case "es": return "Elegir idioma"
        default: return "Choose Language"
        }
    }

    // MARK: - App Info Section

    var howToUseText: String {
        switch language {
        case "fr": return "Comment utiliser ProTip365"
        case "es": return "Cómo usar ProTip365"
        default: return "How to Use ProTip365"
        }
    }

    // MARK: - Subscription Section

    var cancelSubscriptionTitle: String {
        switch language {
        case "fr": return "Annuler l'abonnement"
        case "es": return "Cancelar suscripción"
        default: return "Cancel Subscription"
        }
    }

    var cancelSubscriptionInstructions: String {
        switch language {
        case "fr": return "Allez dans votre compte Apple pour gérer votre abonnement. Puisque l'abonnement est géré par Apple, vous devez l'annuler directement dans vos paramètres Apple."
        case "es": return "Ve a tu cuenta de Apple para gestionar tu suscripción. Como la suscripción es gestionada por Apple, debes cancelarla directamente en tu configuración de Apple."
        default: return "Go to your Apple account to manage your subscription. Since the subscription is managed by Apple, you must cancel it directly in your Apple settings."
        }
    }

    var cancelSubscriptionWarning: String {
        switch language {
        case "fr": return "⚠️ Important: Vous ne pourrez plus utiliser l'application après l'annulation. Pensez à exporter vos données avant de procéder."
        case "es": return "⚠️ Importante: No podrás usar la aplicación después de cancelar. Considera exportar tus datos antes de proceder."
        default: return "⚠️ Important: You will not be able to use the app after canceling. Consider exporting your data before proceeding."
        }
    }

    var goToAppleAccountText: String {
        switch language {
        case "fr": return "Aller aux paramètres Apple"
        case "es": return "Ir a configuración de Apple"
        default: return "Go to Apple Settings"
        }
    }

    // MARK: - Suggestion Section

    var suggestionEmailPlaceholder: String {
        switch language {
        case "fr": return "Votre adresse email"
        case "es": return "Su dirección de correo"
        default: return "Your email address"
        }
    }

    var yourSuggestionHeader: String {
        switch language {
        case "fr": return "Votre suggestion"
        case "es": return "Su sugerencia"
        default: return "Your suggestion"
        }
    }

    var suggestionFooter: String {
        switch language {
        case "fr": return "Partagez vos idées pour améliorer ProTip365"
        case "es": return "Comparta sus ideas para mejorar ProTip365"
        default: return "Share your ideas to improve ProTip365"
        }
    }

    var sendSuggestionButton: String {
        switch language {
        case "fr": return "Envoyer"
        case "es": return "Enviar"
        default: return "Send"
        }
    }

    var thankYouTitle: String {
        switch language {
        case "fr": return "Merci!"
        case "es": return "¡Gracias!"
        default: return "Thank You!"
        }
    }

    var thankYouMessage: String {
        switch language {
        case "fr": return "Merci pour vos commentaires, nous l'apprécions."
        case "es": return "Gracias por sus comentarios, lo apreciamos."
        default: return "Thank you for your feedback, we appreciate it."
        }
    }

    var contactSupport: String {
        switch language {
        case "fr": return "Contacter le support"
        case "es": return "Contactar soporte"
        default: return "Contact Support"
        }
    }

    var supportDescription: String {
        switch language {
        case "fr": return "Décrivez votre problème et nous vous répondrons dans les plus brefs délais."
        case "es": return "Describa su problema y le responderemos lo antes posible."
        default: return "Describe your issue and we'll get back to you as soon as possible."
        }
    }

    var yourMessage: String {
        switch language {
        case "fr": return "Votre message"
        case "es": return "Su mensaje"
        default: return "Your message"
        }
    }

    var describeYourIssue: String {
        switch language {
        case "fr": return "Décrivez votre problème..."
        case "es": return "Describa su problema..."
        default: return "Describe your issue..."
        }
    }

    var writeYourSuggestion: String {
        switch language {
        case "fr": return "Écrivez votre suggestion..."
        case "es": return "Escriba su sugerencia..."
        default: return "Write your suggestion..."
        }
    }

    // MARK: - Common Labels

    var noneLabel: String {
        switch language {
        case "fr": return "Aucun"
        case "es": return "Ninguno"
        default: return "None"
        }
    }

    var saveSettingsText: String {
        switch language {
        case "fr": return "Enregistrer"
        case "es": return "Guardar"
        default: return "Save"
        }
    }

    var savedText: String {
        switch language {
        case "fr": return "Enregistré!"
        case "es": return "¡Guardado!"
        default: return "Saved!"
        }
    }

    var discardButton: String {
        switch language {
        case "fr": return "Ignorer"
        case "es": return "Descartar"
        default: return "Discard"
        }
    }

    // MARK: - Messages

    var unsavedChangesTitle: String {
        switch language {
        case "fr": return "Modifications non sauvegardées"
        case "es": return "Cambios no guardados"
        default: return "Unsaved Changes"
        }
    }

    var unsavedChangesMessage: String {
        switch language {
        case "fr": return "Vous avez des modifications non sauvegardées. Voulez-vous les sauvegarder avant de continuer?"
        case "es": return "Tienes cambios sin guardar. ¿Quieres guardarlos antes de continuar?"
        default: return "You have unsaved changes. Would you like to save them before continuing?"
        }
    }

    var settingsUpdated: String {
        switch language {
        case "fr": return "Réglages mis à jour!"
        case "es": return "¡Ajustes actualizados!"
        default: return "Settings Updated!"
        }
    }

    var errorSavingSettings: String {
        switch language {
        case "fr": return "Erreur lors de la sauvegarde"
        case "es": return "Error al guardar"
        default: return "Error saving settings"
        }
    }

    // MARK: - Alert Messages

    var signOutConfirmTitle: String {
        switch language {
        case "fr": return "Confirmer"
        case "es": return "Confirmar"
        default: return "Confirm"
        }
    }

    var signOutConfirmMessage: String {
        switch language {
        case "fr": return "Voulez-vous vraiment vous déconnecter?"
        case "es": return "¿Realmente quieres cerrar sesión?"
        default: return "Are you sure you want to sign out?"
        }
    }

    var deleteAccountConfirmTitle: String {
        switch language {
        case "fr": return "Supprimer le compte"
        case "es": return "Eliminar cuenta"
        default: return "Delete Account"
        }
    }

    var deleteAccountConfirmMessage: String {
        switch language {
        case "fr": return "Êtes-vous sûr de vouloir supprimer votre compte? Cette action est irréversible.\n\nRappel: Vous devez également aller dans votre compte Apple pour annuler votre abonnement."
        case "es": return "¿Está seguro de que desea eliminar su cuenta? Esta acción es irreversible.\n\nRecordatorio: También debe ir a su cuenta de Apple para cancelar su suscripción."
        default: return "Are you sure you want to delete your account? This action cannot be undone.\n\nReminder: You must also go to your Apple account to cancel your subscription."
        }
    }
}