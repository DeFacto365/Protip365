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
}