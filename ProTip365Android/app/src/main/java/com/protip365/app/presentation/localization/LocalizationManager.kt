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