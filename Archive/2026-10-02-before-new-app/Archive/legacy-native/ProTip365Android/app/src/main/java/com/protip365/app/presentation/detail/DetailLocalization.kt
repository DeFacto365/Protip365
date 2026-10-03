package com.protip365.app.presentation.detail

class DetailLocalization(private val language: String) {
    
    val noDataText: String
        get() = when (language) {
            "fr" -> "Aucune donnée"
            "es" -> "Sin datos"
            else -> "No data"
        }
    
    val doneText: String
        get() = when (language) {
            "fr" -> "Terminé"
            "es" -> "Listo"
            else -> "Done"
        }
    
    val salesText: String
        get() = when (language) {
            "fr" -> "Ventes"
            "es" -> "Ventas"
            else -> "Sales"
        }
    
    val tipsText: String
        get() = when (language) {
            "fr" -> "Pourboires"
            "es" -> "Propinas"
            else -> "Tips"
        }
    
    val detailsText: String
        get() = when (language) {
            "fr" -> "Détails"
            "es" -> "Detalles"
            else -> "Details"
        }
    
    val incomeBreakdownText: String
        get() = when (language) {
            "fr" -> "RÉPARTITION DES REVENUS"
            "es" -> "DESGLOSE DE INGRESOS"
            else -> "INCOME BREAKDOWN"
        }
    
    val performanceMetricsText: String
        get() = when (language) {
            "fr" -> "MÉTRIQUES DE PERFORMANCE"
            "es" -> "MÉTRICAS DE RENDIMIENTO"
            else -> "PERFORMANCE METRICS"
        }
    
    val shiftDetailsText: String
        get() = when (language) {
            "fr" -> "DÉTAILS DES QUARTS"
            "es" -> "DETALLES DE TURNOS"
            else -> "SHIFT DETAILS"
        }
    
    val salaryText: String
        get() = when (language) {
            "fr" -> "Salaire"
            "es" -> "Salario"
            else -> "Salary"
        }
    
    val grossSalaryText: String
        get() = when (language) {
            "fr" -> "Salaire brut"
            "es" -> "Salario bruto"
            else -> "Gross Salary"
        }
    
    val netSalaryText: String
        get() = when (language) {
            "fr" -> "Salaire net"
            "es" -> "Salario neto"
            else -> "Net Salary"
        }
    
    val hoursText: String
        get() = when (language) {
            "fr" -> "Heures"
            "es" -> "Horas"
            else -> "Hours"
        }
    
    val totalText: String
        get() = when (language) {
            "fr" -> "Total"
            "es" -> "Total"
            else -> "Total"
        }
    
    val otherText: String
        get() = when (language) {
            "fr" -> "Autre"
            "es" -> "Otro"
            else -> "Other"
        }
    
    val tipOutText: String
        get() = when (language) {
            "fr" -> "Partage"
            "es" -> "Reparto"
            else -> "Tip Out"
        }
    
    val totalIncomeText: String
        get() = when (language) {
            "fr" -> "Revenu total"
            "es" -> "Ingresos totales"
            else -> "Total Income"
        }
    
    val totalHoursText: String
        get() = when (language) {
            "fr" -> "Heures totales"
            "es" -> "Horas totales"
            else -> "Total Hours"
        }
    
    val totalSalesText: String
        get() = when (language) {
            "fr" -> "Ventes totales"
            "es" -> "Ventas totales"
            else -> "Total Sales"
        }
    
    val tipPercentText: String
        get() = when (language) {
            "fr" -> "% Pourboire"
            "es" -> "% Propina"
            else -> "Tip %"
        }
    
    val targetText: String
        get() = when (language) {
            "fr" -> "Objectif"
            "es" -> "Objetivo"
            else -> "Target"
        }
    
    val noShiftsRecordedText: String
        get() = when (language) {
            "fr" -> "Aucun quart enregistré pour cette période"
            "es" -> "No hay turnos registrados para este período"
            else -> "No shifts recorded for this period"
        }
    
    val incomeText: String
        get() = when (language) {
            "fr" -> "Revenu"
            "es" -> "Ingresos"
            else -> "Income"
        }
    
    val summaryText: String
        get() = when (language) {
            "fr" -> "Résumé"
            "es" -> "Resumen"
            else -> "Summary"
        }
    
    val avgHourlyRateText: String
        get() = when (language) {
            "fr" -> "Taux horaire moyen"
            "es" -> "Tarifa horaria promedio"
            else -> "Avg Hourly Rate"
        }
    
    val shiftsText: String
        get() = when (language) {
            "fr" -> "quarts"
            "es" -> "turnos"
            else -> "shifts"
        }
    
    val shiftText: String
        get() = when (language) {
            "fr" -> "quart"
            "es" -> "turno"
            else -> "shift"
        }
    
    fun detailTitle(detailType: String): String {
        return when (detailType) {
            "income" -> incomeText
            "tips" -> tipsText
            "sales" -> salesText
            "hours" -> hoursText
            "total" -> summaryText
            "other" -> otherText
            else -> detailsText
        }
    }
    
    fun getPeriodText(period: String): String {
        return when (period.lowercase()) {
            "today" -> when (language) {
                "fr" -> "Aujourd'hui"
                "es" -> "Hoy"
                else -> "Today"
            }
            "week" -> when (language) {
                "fr" -> "Semaine"
                "es" -> "Semana"
                else -> "Week"
            }
            "month" -> when (language) {
                "fr" -> "Mois"
                "es" -> "Mes"
                else -> "Month"
            }
            "year" -> when (language) {
                "fr" -> "Année"
                "es" -> "Año"
                else -> "Year"
            }
            else -> period
        }
    }
}

