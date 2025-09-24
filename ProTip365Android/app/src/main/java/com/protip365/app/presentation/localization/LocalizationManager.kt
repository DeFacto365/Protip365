package com.protip365.app.presentation.localization

import android.content.Context
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

enum class SupportedLanguage(val code: String, val displayName: String, val shortCode: String) {
    ENGLISH("en", "English", "EN"),
    FRENCH("fr", "Français", "FR"),
    SPANISH("es", "Español", "ES")
}

data class LocalizationState(
    val currentLanguage: SupportedLanguage = SupportedLanguage.ENGLISH,
    val isLoaded: Boolean = false
)

@Singleton
class LocalizationManager @Inject constructor() {
    private val _state = MutableStateFlow(LocalizationState())
    val state: StateFlow<LocalizationState> = _state.asStateFlow()

    var currentLanguage by mutableStateOf(SupportedLanguage.ENGLISH)
        private set

    init {
        // Initialize with system language
        val systemLanguage = Locale.getDefault().language
        currentLanguage = when (systemLanguage) {
            "fr" -> SupportedLanguage.FRENCH
            "es" -> SupportedLanguage.SPANISH
            else -> SupportedLanguage.ENGLISH
        }
        _state.value = _state.value.copy(currentLanguage = currentLanguage, isLoaded = true)
    }

    fun setLanguage(language: SupportedLanguage) {
        currentLanguage = language
        _state.value = _state.value.copy(currentLanguage = language)
        
        // Update system locale
        val locale = when (language) {
            SupportedLanguage.FRENCH -> Locale("fr")
            SupportedLanguage.SPANISH -> Locale("es")
            SupportedLanguage.ENGLISH -> Locale("en")
        }
        Locale.setDefault(locale)
    }

    fun applyLanguage(context: Context, languageCode: String): Context {
        val locale = Locale(languageCode)
        val config = context.resources.configuration
        config.setLocale(locale)
        return context.createConfigurationContext(config)
    }

    fun getString(key: String, vararg args: Any): String {
        return when (currentLanguage) {
            SupportedLanguage.ENGLISH -> getEnglishString(key, *args)
            SupportedLanguage.FRENCH -> getFrenchString(key, *args)
            SupportedLanguage.SPANISH -> getSpanishString(key, *args)
        }
    }

    private fun getEnglishString(key: String, vararg args: Any): String {
        val string = when (key) {
            "dashboard" -> "Dashboard"
            "calendar" -> "Calendar"
            "employers" -> "Employers"
            "calculator" -> "Calculator"
            "settings" -> "Settings"
            "add_shift" -> "Add Shift"
            "quick_entry" -> "Quick Entry"
            "total_revenue" -> "Total Revenue"
            "salary_wages" -> "Salary/Wages"
            "tips" -> "Tips"
            "hours" -> "Hours"
            "sales" -> "Sales"
            "tip_out" -> "Tip-out"
            "other_income" -> "Other"
            "today" -> "Today"
            "week" -> "Week"
            "month" -> "Month"
            "year" -> "Year"
            "custom" -> "Custom"
            "no_data_yet" -> "No data yet"
            "add_first_shift" -> "Add First Shift"
            "sign_in" -> "Sign In"
            "sign_up" -> "Sign Up"
            "email" -> "Email"
            "password" -> "Password"
            "forgot_password" -> "Forgot Password?"
            "language" -> "Language"
            "profile" -> "Profile"
            "targets" -> "Targets"
            "security" -> "Security"
            "subscription" -> "Subscription"
            "support" -> "Support"
            "account" -> "Account"
            "export_data" -> "Export Data"
            "sign_out" -> "Sign Out"
            "delete_account" -> "Delete Account"
            "version" -> "Version"
            "help_center" -> "Help Center"
            "contact_support" -> "Contact Support"
            "privacy_policy" -> "Privacy Policy"
            "terms_of_service" -> "Terms of Service"
            "achievements" -> "Achievements"
            "achievement_progress" -> "Achievement Progress"
            "achievements_unlocked" -> "achievements unlocked"
            // Alert System
            "alert_label" -> "Alert"
            "alert_none" -> "None"
            "alert_15_minutes" -> "15 minutes before"
            "alert_30_minutes" -> "30 minutes before"
            "alert_60_minutes" -> "1 hour before"
            "alert_1_day" -> "1 day before"
            "default_alert_label" -> "Default Alert"
            "notification_title" -> "Upcoming Shift"
            "notification_body" -> "Your shift at %1$s starts at %2$s"
            // Error Messages
            "error_shift_not_found" -> "Shift not found"
            "error_user_not_logged_in" -> "User not logged in"
            "error_failed_to_save_shift" -> "Failed to save shift"
            "error_failed_to_save_entry" -> "Failed to save entry"
            "error_failed_to_delete_shift" -> "Failed to delete shift"
            "error_shift_limit_reached" -> "You've reached your weekly shift limit. Upgrade to Full Access for unlimited shifts."
            "error_entry_limit_reached" -> "You've reached your weekly entry limit. Upgrade to Full Access for unlimited entries."
            "default_employer_name" -> "Work"
            else -> key
        }
        
        return if (args.isNotEmpty()) {
            try {
                string.format(*args)
            } catch (e: Exception) {
                string
            }
        } else {
            string
        }
    }

    private fun getFrenchString(key: String, vararg args: Any): String {
        val string = when (key) {
            "dashboard" -> "Tableau"
            "calendar" -> "Calendrier"
            "employers" -> "Employeurs"
            "calculator" -> "Calculer"
            "settings" -> "Réglages"
            "add_shift" -> "Ajouter un quart"
            "quick_entry" -> "Entrée rapide"
            "total_revenue" -> "Revenus totaux"
            "salary_wages" -> "Salaire/Honoraires"
            "tips" -> "Pourboires"
            "hours" -> "Heures"
            "sales" -> "Ventes"
            "tip_out" -> "Partage de pourboires"
            "other_income" -> "Autres"
            "today" -> "Aujourd'hui"
            "week" -> "Semaine"
            "month" -> "Mois"
            "year" -> "Année"
            "custom" -> "Personnalisé"
            "no_data_yet" -> "Aucune donnée pour le moment"
            "add_first_shift" -> "Ajouter le premier quart"
            "sign_in" -> "Se connecter"
            "sign_up" -> "S'inscrire"
            "email" -> "Courriel"
            "password" -> "Mot de passe"
            "forgot_password" -> "Mot de passe oublié?"
            "language" -> "Langue"
            "profile" -> "Profil"
            "targets" -> "Objectifs"
            "security" -> "Sécurité"
            "subscription" -> "Abonnement"
            "support" -> "Support"
            "account" -> "Compte"
            "export_data" -> "Exporter les données"
            "sign_out" -> "Se déconnecter"
            "delete_account" -> "Supprimer le compte"
            "version" -> "Version"
            "help_center" -> "Centre d'aide"
            "contact_support" -> "Contacter le support"
            "privacy_policy" -> "Politique de confidentialité"
            "terms_of_service" -> "Conditions d'utilisation"
            "achievements" -> "Réalisations"
            "achievement_progress" -> "Progrès des réalisations"
            "achievements_unlocked" -> "réalisations débloquées"
            // Alert System
            "alert_label" -> "Alerte"
            "alert_none" -> "Aucune"
            "alert_15_minutes" -> "15 minutes avant"
            "alert_30_minutes" -> "30 minutes avant"
            "alert_60_minutes" -> "1 heure avant"
            "alert_1_day" -> "1 jour avant"
            "default_alert_label" -> "Alerte par défaut"
            "notification_title" -> "Quart à venir"
            "notification_body" -> "Votre quart chez %1$s commence à %2$s"
            // Error Messages
            "error_shift_not_found" -> "Quart non trouvé"
            "error_user_not_logged_in" -> "Utilisateur non connecté"
            "error_failed_to_save_shift" -> "Échec de la sauvegarde du quart"
            "error_failed_to_save_entry" -> "Échec de la sauvegarde de l'entrée"
            "error_failed_to_delete_shift" -> "Échec de la suppression du quart"
            "error_shift_limit_reached" -> "Vous avez atteint votre limite hebdomadaire de quarts. Passez à l'accès complet pour des quarts illimités."
            "error_entry_limit_reached" -> "Vous avez atteint votre limite hebdomadaire d'entrées. Passez à l'accès complet pour des entrées illimitées."
            "default_employer_name" -> "Travail"
            else -> key
        }
        
        return if (args.isNotEmpty()) {
            try {
                string.format(*args)
            } catch (e: Exception) {
                string
            }
        } else {
            string
        }
    }

    private fun getSpanishString(key: String, vararg args: Any): String {
        val string = when (key) {
            "dashboard" -> "Panel"
            "calendar" -> "Calendario"
            "employers" -> "Empleadores"
            "calculator" -> "Calcular"
            "settings" -> "Ajustes"
            "add_shift" -> "Agregar turno"
            "quick_entry" -> "Entrada rápida"
            "total_revenue" -> "Ingresos totales"
            "salary_wages" -> "Salario/Sueldos"
            "tips" -> "Propinas"
            "hours" -> "Horas"
            "sales" -> "Ventas"
            "tip_out" -> "Reparto de propinas"
            "other_income" -> "Otros"
            "today" -> "Hoy"
            "week" -> "Semana"
            "month" -> "Mes"
            "year" -> "Año"
            "custom" -> "Personalizado"
            "no_data_yet" -> "Sin datos aún"
            "add_first_shift" -> "Agregar primer turno"
            "sign_in" -> "Iniciar sesión"
            "sign_up" -> "Registrarse"
            "email" -> "Correo electrónico"
            "password" -> "Contraseña"
            "forgot_password" -> "¿Olvidaste tu contraseña?"
            "language" -> "Idioma"
            "profile" -> "Perfil"
            "targets" -> "Objetivos"
            "security" -> "Seguridad"
            "subscription" -> "Suscripción"
            "support" -> "Soporte"
            "account" -> "Cuenta"
            "export_data" -> "Exportar datos"
            "sign_out" -> "Cerrar sesión"
            "delete_account" -> "Eliminar cuenta"
            "version" -> "Versión"
            "help_center" -> "Centro de ayuda"
            "contact_support" -> "Contactar soporte"
            "privacy_policy" -> "Política de privacidad"
            "terms_of_service" -> "Términos de servicio"
            "achievements" -> "Logros"
            "achievement_progress" -> "Progreso de logros"
            "achievements_unlocked" -> "logros desbloqueados"
            // Alert System
            "alert_label" -> "Alerta"
            "alert_none" -> "Ninguna"
            "alert_15_minutes" -> "15 minutos antes"
            "alert_30_minutes" -> "30 minutos antes"
            "alert_60_minutes" -> "1 hora antes"
            "alert_1_day" -> "1 día antes"
            "default_alert_label" -> "Alerta por defecto"
            "notification_title" -> "Turno próximo"
            "notification_body" -> "Tu turno en %1$s comienza a las %2$s"
            // Error Messages
            "error_shift_not_found" -> "Turno no encontrado"
            "error_user_not_logged_in" -> "Usuario no conectado"
            "error_failed_to_save_shift" -> "Error al guardar turno"
            "error_failed_to_save_entry" -> "Error al guardar entrada"
            "error_failed_to_delete_shift" -> "Error al eliminar turno"
            "error_shift_limit_reached" -> "Has alcanzado tu límite semanal de turnos. Actualiza a Acceso Completo para turnos ilimitados."
            "error_entry_limit_reached" -> "Has alcanzado tu límite semanal de entradas. Actualiza a Acceso Completo para entradas ilimitadas."
            "default_employer_name" -> "Trabajo"
            else -> key
        }
        
        return if (args.isNotEmpty()) {
            try {
                string.format(*args)
            } catch (e: Exception) {
                string
            }
        } else {
            string
        }
    }
}