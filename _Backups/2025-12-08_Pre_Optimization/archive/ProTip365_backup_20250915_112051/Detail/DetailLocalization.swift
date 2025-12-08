import SwiftUI

struct DetailLocalization {
    let language: String

    init(language: String) {
        self.language = language
    }

    var noDataText: String {
        switch language {
        case "fr": return "Aucune donnée"
        case "es": return "Sin datos"
        default: return "No data"
        }
    }

    var doneText: String {
        switch language {
        case "fr": return "Terminé"
        case "es": return "Listo"
        default: return "Done"
        }
    }

    var salesText: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
        }
    }

    var tipsText: String {
        switch language {
        case "fr": return "Pourboires"
        case "es": return "Propinas"
        default: return "Tips"
        }
    }

    var detailsText: String {
        switch language {
        case "fr": return "Détails"
        case "es": return "Detalles"
        default: return "Details"
        }
    }

    var incomeBreakdownText: String {
        switch language {
        case "fr": return "RÉPARTITION DES REVENUS"
        case "es": return "DESGLOSE DE INGRESOS"
        default: return "INCOME BREAKDOWN"
        }
    }

    var performanceMetricsText: String {
        switch language {
        case "fr": return "MÉTRIQUES DE PERFORMANCE"
        case "es": return "MÉTRICAS DE RENDIMIENTO"
        default: return "PERFORMANCE METRICS"
        }
    }

    var shiftDetailsText: String {
        switch language {
        case "fr": return "DÉTAILS DES QUARTS"
        case "es": return "DETALLES DE TURNOS"
        default: return "SHIFT DETAILS"
        }
    }

    var salaryText: String {
        switch language {
        case "fr": return "Salaire"
        case "es": return "Salario"
        default: return "Salary"
        }
    }

    var grossSalaryText: String {
        switch language {
        case "fr": return "Salaire brut"
        case "es": return "Salario bruto"
        default: return "Gross Salary"
        }
    }

    var netSalaryText: String {
        switch language {
        case "fr": return "Salaire net"
        case "es": return "Salario neto"
        default: return "Net Salary"
        }
    }

    var hoursText: String {
        switch language {
        case "fr": return "Heures"
        case "es": return "Horas"
        default: return "Hours"
        }
    }

    var totalText: String {
        switch language {
        case "fr": return "Total"
        case "es": return "Total"
        default: return "Total"
        }
    }

    var otherText: String {
        switch language {
        case "fr": return "Autre"
        case "es": return "Otro"
        default: return "Other"
        }
    }

    var tipOutText: String {
        switch language {
        case "fr": return "Partage"
        case "es": return "Reparto"
        default: return "Tip Out"
        }
    }

    var totalIncomeText: String {
        switch language {
        case "fr": return "Revenu total"
        case "es": return "Ingresos totales"
        default: return "Total Income"
        }
    }

    var totalHoursText: String {
        switch language {
        case "fr": return "Heures totales"
        case "es": return "Horas totales"
        default: return "Total Hours"
        }
    }

    var totalSalesText: String {
        switch language {
        case "fr": return "Ventes totales"
        case "es": return "Ventas totales"
        default: return "Total Sales"
        }
    }

    var tipPercentText: String {
        switch language {
        case "fr": return "% Pourboire"
        case "es": return "% Propina"
        default: return "Tip %"
        }
    }

    var targetText: String {
        switch language {
        case "fr": return "Objectif"
        case "es": return "Objetivo"
        default: return "Target"
        }
    }

    var noShiftsRecordedText: String {
        switch language {
        case "fr": return "Aucun quart enregistré pour cette période"
        case "es": return "No hay turnos registrados para este período"
        default: return "No shifts recorded for this period"
        }
    }

    var incomeText: String {
        switch language {
        case "fr": return "Revenu"
        case "es": return "Ingresos"
        default: return "Income"
        }
    }

    var summaryText: String {
        switch language {
        case "fr": return "Résumé"
        case "es": return "Resumen"
        default: return "Summary"
        }
    }

    func detailTitle(for detailType: String) -> String {
        switch detailType {
        case "income": return incomeText
        case "tips": return tipsText
        case "sales": return salesText
        case "hours": return hoursText
        case "total": return summaryText
        case "other": return otherText
        default: return detailsText
        }
    }
}