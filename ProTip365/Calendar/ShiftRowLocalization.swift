import Foundation

// MARK: - Shift Row Localization
struct ShiftRowLocalization {
    let language: String

    init(language: String = "en") {
        self.language = language
    }

    var salesText: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
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

    var estNetSalaryText: String {
        switch language {
        case "fr": return "Salaire net est."
        case "es": return "Salario neto est."
        default: return "Est. Net Salary"
        }
    }

    var tipsText: String {
        switch language {
        case "fr": return "Pourboires"
        case "es": return "Propinas"
        default: return "Tips"
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

    var totalText: String {
        switch language {
        case "fr": return "TOTAL"
        case "es": return "TOTAL"
        default: return "TOTAL"
        }
    }

    var editText: String {
        switch language {
        case "fr": return "Modifier"
        case "es": return "Editar"
        default: return "Edit"
        }
    }

    var deleteText: String {
        switch language {
        case "fr": return "Supprimer"
        case "es": return "Eliminar"
        default: return "Delete"
        }
    }

    // Predefined reasons for "didn't work" shifts in all languages
    var didntWorkReasons: [String] {
        [
            "Sick", "Shift Cancelled", "Personal Day", "Holiday", "No-Show", "Other",
            "Malade", "Quart annulé", "Jour personnel", "Jour férié", "Absence", "Autre",
            "Enfermo", "Turno cancelado", "Día personal", "Día festivo", "Ausencia", "Otro"
        ]
    }
}