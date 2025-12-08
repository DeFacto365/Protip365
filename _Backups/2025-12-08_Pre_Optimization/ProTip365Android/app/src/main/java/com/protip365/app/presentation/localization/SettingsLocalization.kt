package com.protip365.app.presentation.localization

class SettingsLocalization(private val language: String) {

    // MARK: - General Settings
    val settingsTitle: String
        get() = when (language) {
            "fr" -> "Réglages"
            "es" -> "Ajustes"
            else -> "Settings"
        }

    val saveButton: String
        get() = when (language) {
            "fr" -> "Sauvegarder"
            "es" -> "Guardar"
            else -> "Save"
        }

    val savingButton: String
        get() = when (language) {
            "fr" -> "Sauvegarde..."
            "es" -> "Guardando..."
            else -> "Saving..."
        }

    val cancelButton: String
        get() = when (language) {
            "fr" -> "Annuler"
            "es" -> "Cancelar"
            else -> "Cancel"
        }

    val doneButton: String
        get() = when (language) {
            "fr" -> "Terminé"
            "es" -> "Listo"
            else -> "Done"
        }

    // MARK: - Sections
    val profileSection: String
        get() = when (language) {
            "fr" -> "Profil"
            "es" -> "Perfil"
            else -> "Profile"
        }

    val workDefaultsSection: String
        get() = when (language) {
            "fr" -> "Défauts de travail"
            "es" -> "Configuración de trabajo"
            else -> "Work Defaults"
        }

    val securitySection: String
        get() = when (language) {
            "fr" -> "Sécurité"
            "es" -> "Seguridad"
            else -> "Security"
        }

    val subscriptionSection: String
        get() = when (language) {
            "fr" -> "Abonnement"
            "es" -> "Suscripción"
            else -> "Subscription"
        }

    val supportSection: String
        get() = when (language) {
            "fr" -> "Support"
            "es" -> "Soporte"
            else -> "Support"
        }

    val aboutSection: String
        get() = when (language) {
            "fr" -> "À propos"
            "es" -> "Acerca de"
            else -> "About"
        }

    // MARK: - Alert Settings
    val alertLabel: String
        get() = when (language) {
            "fr" -> "Alerte"
            "es" -> "Alerta"
            else -> "Alert"
        }

    val alertNone: String
        get() = when (language) {
            "fr" -> "Aucune"
            "es" -> "Ninguna"
            else -> "None"
        }

    val alert15Minutes: String
        get() = when (language) {
            "fr" -> "15 minutes avant"
            "es" -> "15 minutos antes"
            else -> "15 minutes before"
        }

    val alert30Minutes: String
        get() = when (language) {
            "fr" -> "30 minutes avant"
            "es" -> "30 minutos antes"
            else -> "30 minutes before"
        }

    val alert1Hour: String
        get() = when (language) {
            "fr" -> "1 heure avant"
            "es" -> "1 hora antes"
            else -> "1 hour before"
        }

    val alert1Day: String
        get() = when (language) {
            "fr" -> "1 jour avant"
            "es" -> "1 día antes"
            else -> "1 day before"
        }

    val defaultAlertLabel: String
        get() = when (language) {
            "fr" -> "Alerte par défaut"
            "es" -> "Alerta predeterminada"
            else -> "Default Alert"
        }

    // MARK: - Profile Settings
    val setNameText: String
        get() = when (language) {
            "fr" -> "Définir votre nom"
            "es" -> "Establecer tu nombre"
            else -> "Set your name"
        }

    val tapToSetProfileText: String
        get() = when (language) {
            "fr" -> "Appuyez pour définir votre profil"
            "es" -> "Toca para establecer tu perfil"
            else -> "Tap to set your profile"
        }

    val tapToUpdateProfileText: String
        get() = when (language) {
            "fr" -> "Appuyez pour mettre à jour le profil"
            "es" -> "Toca para actualizar el perfil"
            else -> "Tap to update profile"
        }

    val changePasswordText: String
        get() = when (language) {
            "fr" -> "Changer le mot de passe"
            "es" -> "Cambiar contraseña"
            else -> "Change Password"
        }

    val updateAccountPasswordText: String
        get() = when (language) {
            "fr" -> "Mettre à jour le mot de passe de votre compte"
            "es" -> "Actualizar la contraseña de tu cuenta"
            else -> "Update your account password"
        }

    // MARK: - Work Defaults
    val defaultHourlyRateText: String
        get() = when (language) {
            "fr" -> "Taux horaire par défaut"
            "es" -> "Tarifa por hora predeterminada"
            else -> "Default Hourly Rate"
        }

    val multipleEmployersText: String
        get() = when (language) {
            "fr" -> "Employeurs multiples"
            "es" -> "Empleadores múltiples"
            else -> "Multiple Employers"
        }

    val enabledText: String
        get() = when (language) {
            "fr" -> "Activé"
            "es" -> "Habilitado"
            else -> "Enabled"
        }

    val disabledText: String
        get() = when (language) {
            "fr" -> "Désactivé"
            "es" -> "Deshabilitado"
            else -> "Disabled"
        }

    val cashOutText: String
        get() = when (language) {
            "fr" -> "Encaissement"
            "es" -> "Cobro"
            else -> "Cash Out"
        }

    val trackingEnabledText: String
        get() = when (language) {
            "fr" -> "Suivi activé"
            "es" -> "Seguimiento habilitado"
            else -> "Tracking enabled"
        }

    val trackingDisabledText: String
        get() = when (language) {
            "fr" -> "Suivi désactivé"
            "es" -> "Seguimiento deshabilitado"
            else -> "Tracking disabled"
        }

    // MARK: - Security
    val pinProtectionText: String
        get() = when (language) {
            "fr" -> "Protection par code PIN"
            "es" -> "Protección con PIN"
            else -> "PIN Protection"
        }

    val biometricAuthenticationText: String
        get() = when (language) {
            "fr" -> "Authentification biométrique"
            "es" -> "Autenticación biométrica"
            else -> "Biometric Authentication"
        }

    // MARK: - Subscription
    val fullAccessText: String
        get() = when (language) {
            "fr" -> "Accès complet"
            "es" -> "Acceso completo"
            else -> "Full Access"
        }

    val partTimeProText: String
        get() = when (language) {
            "fr" -> "Pro à temps partiel"
            "es" -> "Pro de medio tiempo"
            else -> "Part-Time Pro"
        }

    val freeTrialText: String
        get() = when (language) {
            "fr" -> "Essai gratuit"
            "es" -> "Prueba gratuita"
            else -> "Free Trial"
        }

    val unlimitedShiftsEntriesText: String
        get() = when (language) {
            "fr" -> "Quarts et entrées illimités"
            "es" -> "Turnos y entradas ilimitados"
            else -> "Unlimited shifts & entries"
        }

    val limitedFeaturesText: String
        get() = when (language) {
            "fr" -> "Fonctionnalités limitées"
            "es" -> "Características limitadas"
            else -> "Limited features"
        }

    val upgradeToFullAccessText: String
        get() = when (language) {
            "fr" -> "Passer à l'accès complet"
            "es" -> "Actualizar a acceso completo"
            else -> "Upgrade to Full Access"
        }

    val unlimitedEverythingText: String
        get() = when (language) {
            "fr" -> "Tout illimité"
            "es" -> "Todo ilimitado"
            else -> "Unlimited everything"
        }

    // MARK: - Support
    val helpCenterText: String
        get() = when (language) {
            "fr" -> "Centre d'aide"
            "es" -> "Centro de ayuda"
            else -> "Help Center"
        }

    val viewGuidesTutorialsText: String
        get() = when (language) {
            "fr" -> "Voir les guides et tutoriels"
            "es" -> "Ver guías y tutoriales"
            else -> "View guides and tutorials"
        }

    val contactSupportText: String
        get() = when (language) {
            "fr" -> "Contacter le support"
            "es" -> "Contactar soporte"
            else -> "Contact Support"
        }

    val getHelpFromTeamText: String
        get() = when (language) {
            "fr" -> "Obtenir de l'aide de notre équipe"
            "es" -> "Obtener ayuda de nuestro equipo"
            else -> "Get help from our team"
        }

    val privacyPolicyText: String
        get() = when (language) {
            "fr" -> "Politique de confidentialité"
            "es" -> "Política de privacidad"
            else -> "Privacy Policy"
        }

    val viewPrivacyPolicyText: String
        get() = when (language) {
            "fr" -> "Voir notre politique de confidentialité"
            "es" -> "Ver nuestra política de privacidad"
            else -> "View our privacy policy"
        }

    val termsOfServiceText: String
        get() = when (language) {
            "fr" -> "Conditions d'utilisation"
            "es" -> "Términos de servicio"
            else -> "Terms of Service"
        }

    val viewTermsConditionsText: String
        get() = when (language) {
            "fr" -> "Voir les termes et conditions"
            "es" -> "Ver términos y condiciones"
            else -> "View terms and conditions"
        }

    // MARK: - Account Actions
    val signOutText: String
        get() = when (language) {
            "fr" -> "Se déconnecter"
            "es" -> "Cerrar sesión"
            else -> "Sign Out"
        }

    val signOutAccountText: String
        get() = when (language) {
            "fr" -> "Se déconnecter de votre compte"
            "es" -> "Cerrar sesión de tu cuenta"
            else -> "Sign out of your account"
        }

    val deleteAccountText: String
        get() = when (language) {
            "fr" -> "Supprimer le compte"
            "es" -> "Eliminar cuenta"
            else -> "Delete Account"
        }

    val permanentlyDeleteAccountText: String
        get() = when (language) {
            "fr" -> "Supprimer définitivement votre compte"
            "es" -> "Eliminar permanentemente tu cuenta"
            else -> "Permanently delete your account"
        }

    // MARK: - App Settings
    val appSettingsText: String
        get() = when (language) {
            "fr" -> "Paramètres de l'application"
            "es" -> "Configuración de la aplicación"
            else -> "App Settings"
        }

    val languageText: String
        get() = when (language) {
            "fr" -> "Langue"
            "es" -> "Idioma"
            else -> "Language"
        }

    val choosePreferredLanguageText: String
        get() = when (language) {
            "fr" -> "Choisissez votre langue préférée"
            "es" -> "Elige tu idioma preferido"
            else -> "Choose your preferred language"
        }

    // MARK: - About
    val versionText: String
        get() = when (language) {
            "fr" -> "Version"
            "es" -> "Versión"
            else -> "Version"
        }

    // MARK: - Variable Schedule
    val variableScheduleLabel: String
        get() = when (language) {
            "fr" -> "J'ai un horaire de travail variable"
            "es" -> "Tengo un horario de trabajo variable"
            else -> "I have a variable work schedule"
        }

    val variableScheduleDescription: String
        get() = when (language) {
            "fr" -> "Les objectifs hebdomadaires et mensuels pour les ventes et les heures sont masqués. Seuls les objectifs quotidiens sont affichés car ils sont plus pertinents pour les horaires variables."
            "es" -> "Los objetivos semanales y mensuales para ventas y horas están ocultos. Solo se muestran los objetivos diarios ya que son más relevantes para horarios variables."
            else -> "Weekly and monthly targets for sales and hours are hidden. Only daily targets are shown as they're more relevant for variable schedules."
        }

    val variableScheduleEnabledTitle: String
        get() = when (language) {
            "fr" -> "Horaires variables activés"
            "es" -> "Horario variable habilitado"
            else -> "Variable schedule enabled"
        }

    val variableScheduleEnabledMessage: String
        get() = when (language) {
            "fr" -> "Si vous avez un horaire variable, vous pouvez simplement utiliser les objectifs quotidiens, qui seront plus pertinents. Les objectifs hebdomadaires et mensuels n'ont pas de sens si vous ne travaillez pas un nombre fixe de jours."
            "es" -> "Si tienes un horario variable, puedes simplemente usar objetivos diarios, que serán más relevantes. Los objetivos semanales y mensuales no tienen sentido si no trabajas un número fijo de días."
            else -> "If you have a variable schedule, you can just use daily targets, which will be more relevant. Weekly and monthly targets don't make sense if you don't work a fixed number of days."
        }
}
