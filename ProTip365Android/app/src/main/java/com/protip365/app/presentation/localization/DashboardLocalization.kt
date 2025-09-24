package com.protip365.app.presentation.localization

class DashboardLocalization(private val language: String) {

    // MARK: - Loading & Status Text
    val loadingStatsText: String
        get() = when (language) {
            "fr" -> "Chargement des statistiques..."
            "es" -> "Cargando estadísticas..."
            else -> "Loading stats..."
        }

    val proTip365Text: String = "ProTip365" // App name should not be translated

    // MARK: - Period Selection
    val weekText: String
        get() = when (language) {
            "fr" -> "Semaine"
            "es" -> "Semana"
            else -> "Week"
        }

    val monthText: String
        get() = when (language) {
            "fr" -> "Mois"
            "es" -> "Mes"
            else -> "Month"
        }

    val fourWeeksText: String
        get() = when (language) {
            "fr" -> "4 Semaines"
            "es" -> "4 Semanas"
            else -> "4 Weeks"
        }

    val yearText: String
        get() = when (language) {
            "fr" -> "Année"
            "es" -> "Año"
            else -> "Year"
        }

    val todayText: String
        get() = when (language) {
            "fr" -> "Aujourd'hui"
            "es" -> "Hoy"
            else -> "Today"
        }

    // MARK: - Stats Labels
    val tipsLabel: String
        get() = when (language) {
            "fr" -> "Pourboires"
            "es" -> "Propinas"
            else -> "Tips"
        }

    val salesLabel: String
        get() = when (language) {
            "fr" -> "Ventes"
            "es" -> "Ventas"
            else -> "Sales"
        }

    val hoursLabel: String
        get() = when (language) {
            "fr" -> "Heures"
            "es" -> "Horas"
            else -> "Hours"
        }

    val earningsLabel: String
        get() = when (language) {
            "fr" -> "Gains"
            "es" -> "Ganancias"
            else -> "Earnings"
        }

    // MARK: - Targets
    val targetText: String
        get() = when (language) {
            "fr" -> "Objectif"
            "es" -> "Objetivo"
            else -> "Target"
        }

    val targetReachedText: String
        get() = when (language) {
            "fr" -> "Objectif atteint!"
            "es" -> "¡Objetivo alcanzado!"
            else -> "Target reached!"
        }

    // MARK: - Empty States
    val noShiftsThisWeekText: String
        get() = when (language) {
            "fr" -> "Aucune donnée cette semaine"
            "es" -> "Sin datos esta semana"
            else -> "No shifts this week"
        }

    val noShiftsThisMonthText: String
        get() = when (language) {
            "fr" -> "Aucune donnée ce mois"
            "es" -> "Sin datos este mes"
            else -> "No shifts this month"
        }

    val noShiftsThisYearText: String
        get() = when (language) {
            "fr" -> "Aucune donnée cette année"
            "es" -> "Sin datos este año"
            else -> "No shifts this year"
        }

    // MARK: - Performance Indicators
    val excellentText: String
        get() = when (language) {
            "fr" -> "Excellent"
            "es" -> "Excelente"
            else -> "Excellent"
        }

    val goodText: String
        get() = when (language) {
            "fr" -> "Bon"
            "es" -> "Bueno"
            else -> "Good"
        }

    val averageText: String
        get() = when (language) {
            "fr" -> "Moyen"
            "es" -> "Promedio"
            else -> "Average"
        }

    val needsImprovementText: String
        get() = when (language) {
            "fr" -> "À améliorer"
            "es" -> "Necesita mejorar"
            else -> "Needs Improvement"
        }

    // MARK: - Actions
    val addShiftText: String
        get() = when (language) {
            "fr" -> "Ajouter un quart"
            "es" -> "Agregar turno"
            else -> "Add Shift"
        }

    val viewDetailsText: String
        get() = when (language) {
            "fr" -> "Voir les détails"
            "es" -> "Ver detalles"
            else -> "View Details"
        }

    val exportDataText: String
        get() = when (language) {
            "fr" -> "Exporter les données"
            "es" -> "Exportar datos"
            else -> "Export Data"
        }
}




