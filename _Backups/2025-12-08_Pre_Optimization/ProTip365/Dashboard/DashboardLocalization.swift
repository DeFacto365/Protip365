import Foundation

/// Centralized localization for Dashboard components
struct DashboardLocalization {
    let language: String

    init(language: String) {
        self.language = language
    }

    // MARK: - Loading & Status Text

    var loadingStatsText: String {
        switch language {
        case "fr": return "Chargement des statistiques..."
        case "es": return "Cargando estadísticas..."
        default: return "Loading stats..."
        }
    }

    var proTip365Text: String {
        return "ProTip365" // App name should not be translated
    }

    // MARK: - Period Selection

    var weekText: String {
        switch language {
        case "fr": return "Semaine"
        case "es": return "Semana"
        default: return "Week"
        }
    }

    var monthText: String {
        switch language {
        case "fr": return "Mois"
        case "es": return "Mes"
        default: return "Month"
        }
    }

    var fourWeeksText: String {
        switch language {
        case "fr": return "4 Semaines"
        case "es": return "4 Semanas"
        default: return "4 Weeks"
        }
    }

    var yearText: String {
        switch language {
        case "fr": return "Année"
        case "es": return "Año"
        default: return "Year"
        }
    }

    var todayText: String {
        switch language {
        case "fr": return "Aujourd'hui"
        case "es": return "Hoy"
        default: return "Today"
        }
    }

    var calendarMonthText: String {
        switch language {
        case "fr": return "Mois calendrier"
        case "es": return "Mes calendario"
        default: return "Calendar Month"
        }
    }

    var fourWeeksPayText: String {
        switch language {
        case "fr": return "Paie 4 semaines"
        case "es": return "Pago 4 semanas"
        default: return "4 Weeks Pay"
        }
    }

    // MARK: - Financial Terms

    var totalGrossSalaryText: String {
        switch language {
        case "fr": return "Salaire brut"
        case "es": return "Salario bruto"
        default: return "Gross Salary"
        }
    }

    var expectedNetSalaryText: String {
        switch language {
        case "fr": return "Salaire net prévu"
        case "es": return "Salario neto esperado"
        default: return "Expected Net Salary"
        }
    }

    var basePayFromHoursText: String {
        switch language {
        case "fr": return "Salaire de base des heures travaillées"
        case "es": return "Pago base de horas trabajadas"
        default: return "Base pay from hours worked"
        }
    }

    var tipsText: String {
        switch language {
        case "fr": return "Pourboires"
        case "es": return "Propinas"
        default: return "Tips"
        }
    }

    var customerTipsReceivedText: String {
        switch language {
        case "fr": return "Pourboires clients reçus"
        case "es": return "Propinas de clientes recibidas"
        default: return "Customer tips received"
        }
    }

    var otherText: String {
        switch language {
        case "fr": return "Autre"
        case "es": return "Otro"
        default: return "Other"
        }
    }

    var otherAmountReceivedText: String {
        switch language {
        case "fr": return "Autre montant reçu"
        case "es": return "Otra cantidad recibida"
        default: return "Other amount received"
        }
    }

    var totalRevenueText: String {
        switch language {
        case "fr": return "Revenu total"
        case "es": return "Ingresos totales"
        default: return "Total Revenue"
        }
    }

    var salaryPlusTipsFormulaText: String {
        switch language {
        case "fr": return "Salaire + pourboires + autre - partage"
        case "es": return "Salario + propinas + otro - reparto"
        default: return "Salary + tips + other - tip out"
        }
    }

    var tipOutText: String {
        switch language {
        case "fr": return "Partage"
        case "es": return "Reparto"
        default: return "Tip Out"
        }
    }

    // MARK: - Time & Work

    var hoursWorkedText: String {
        switch language {
        case "fr": return "Heures travaillées"
        case "es": return "Horas trabajadas"
        default: return "Hours Worked"
        }
    }

    var actualVsExpectedHoursText: String {
        switch language {
        case "fr": return "Heures réelles vs prévues"
        case "es": return "Horas reales vs esperadas"
        default: return "Actual vs expected hours"
        }
    }

    var totalHoursCompletedText: String {
        switch language {
        case "fr": return "Total des heures complétées"
        case "es": return "Total de horas completadas"
        default: return "Total hours completed"
        }
    }

    var salesText: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
        }
    }

    var totalSalesServedText: String {
        switch language {
        case "fr": return "Total des ventes servies"
        case "es": return "Total de ventas servidas"
        default: return "Total sales served"
        }
    }

    // MARK: - UI Text

    var tapCardForDetailsText: String {
        switch language {
        case "fr": return "Appuyez sur une carte pour voir les détails"
        case "es": return "Toca una tarjeta para ver detalles"
        default: return "Tap a card to view details"
        }
    }

    var subtotalText: String {
        switch language {
        case "fr": return "SOUS-TOTAL"
        case "es": return "SUBTOTAL"
        default: return "SUBTOTAL"
        }
    }

    var totalIncomeText: String {
        switch language {
        case "fr": return "REVENU TOTAL"
        case "es": return "INGRESOS TOTALES"
        default: return "TOTAL INCOME"
        }
    }

    var showDetailsText: String {
        switch language {
        case "fr": return "Afficher les détails"
        case "es": return "Mostrar detalles"
        default: return "Show Details"
        }
    }

    var percentOfTargetText: String {
        switch language {
        case "fr": return "%d%% de l'objectif"
        case "es": return "%d%% del objetivo"
        default: return "%d%% of target"
        }
    }

    var percentOfSalesText: String {
        switch language {
        case "fr": return "%.1f%% des ventes"
        case "es": return "%.1f%% de las ventas"
        default: return "%.1f%% of sales"
        }
    }

    var targetText: String {
        switch language {
        case "fr": return "Objectif"
        case "es": return "Objetivo"
        default: return "Target"
        }
    }

    // MARK: - Performance Card

    var performanceText: String {
        switch language {
        case "fr": return "Performance"
        case "es": return "Rendimiento"
        default: return "Performance"
        }
    }

    var overallText: String {
        switch language {
        case "fr": return "Global"
        case "es": return "General"
        default: return "Overall"
        }
    }

    var setTargetsPromptText: String {
        switch language {
        case "fr": return "Définissez des objectifs dans les paramètres pour suivre vos performances"
        case "es": return "Establece objetivos en Configuración para rastrear tu rendimiento"
        default: return "Set targets in Settings to track your performance"
        }
    }

    var goToSettingsText: String {
        switch language {
        case "fr": return "Aller aux paramètres →"
        case "es": return "Ir a Configuración →"
        default: return "Go to Settings →"
        }
    }

    var tipPercentageText: String {
        switch language {
        case "fr": return "% Pourboires"
        case "es": return "% Propinas"
        default: return "Tip %"
        }
    }

    var hoursShortText: String {
        switch language {
        case "fr": return "hrs"
        case "es": return "hrs"
        default: return "hrs"
        }
    }

    var ofTargetText: String {
        switch language {
        case "fr": return "de l'objectif"
        case "es": return "del objetivo"
        default: return "of target"
        }
    }
}