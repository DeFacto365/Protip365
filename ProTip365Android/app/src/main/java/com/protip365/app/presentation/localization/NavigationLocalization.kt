package com.protip365.app.presentation.localization

class NavigationLocalization(private val language: String) {

    // MARK: - Bottom Navigation Tabs
    val dashboardTab: String
        get() = when (language) {
            "fr" -> "Tableau"
            "es" -> "Panel"
            else -> "Dashboard"
        }

    val calendarTab: String
        get() = when (language) {
            "fr" -> "Calendrier"
            "es" -> "Calendario"
            else -> "Calendar"
        }

    val employersTab: String
        get() = when (language) {
            "fr" -> "Employeurs"
            "es" -> "Empleadores"
            else -> "Employers"
        }

    val calculatorTab: String
        get() = when (language) {
            "fr" -> "Calculer"
            "es" -> "Calcular"
            else -> "Calculator"
        }

    val settingsTab: String
        get() = when (language) {
            "fr" -> "Réglages"
            "es" -> "Ajustes"
            else -> "Settings"
        }

    // MARK: - Common Actions
    val addShiftText: String
        get() = when (language) {
            "fr" -> "Ajouter un quart"
            "es" -> "Agregar turno"
            else -> "Add Shift"
        }

    val editText: String
        get() = when (language) {
            "fr" -> "Modifier"
            "es" -> "Editar"
            else -> "Edit"
        }

    val deleteText: String
        get() = when (language) {
            "fr" -> "Supprimer"
            "es" -> "Eliminar"
            else -> "Delete"
        }

    val saveText: String
        get() = when (language) {
            "fr" -> "Sauvegarder"
            "es" -> "Guardar"
            else -> "Save"
        }

    val cancelText: String
        get() = when (language) {
            "fr" -> "Annuler"
            "es" -> "Cancelar"
            else -> "Cancel"
        }

    val doneText: String
        get() = when (language) {
            "fr" -> "Terminé"
            "es" -> "Listo"
            else -> "Done"
        }

    val closeText: String
        get() = when (language) {
            "fr" -> "Fermer"
            "es" -> "Cerrar"
            else -> "Close"
        }

    // MARK: - Status Messages
    val loadingText: String
        get() = when (language) {
            "fr" -> "Chargement..."
            "es" -> "Cargando..."
            else -> "Loading..."
        }

    val errorText: String
        get() = when (language) {
            "fr" -> "Erreur"
            "es" -> "Error"
            else -> "Error"
        }

    val successText: String
        get() = when (language) {
            "fr" -> "Succès"
            "es" -> "Éxito"
            else -> "Success"
        }

    val warningText: String
        get() = when (language) {
            "fr" -> "Avertissement"
            "es" -> "Advertencia"
            else -> "Warning"
        }
}




