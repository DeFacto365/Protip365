import Foundation

// MARK: - Calendar Localization
struct CalendarLocalization {
    let language: String

    init(language: String = "en") {
        self.language = language
    }

    // MARK: - Calendar Title and Navigation
    var calendarTitle: String {
        switch language {
        case "fr": return "Calendrier des quarts"
        case "es": return "Calendario de turnos"
        default: return "Shift Calendar"
        }
    }

    var selectedDateTitle: String {
        switch language {
        case "fr": return "Quarts sélectionnés"
        case "es": return "Turnos seleccionados"
        default: return "Selected Date Shifts"
        }
    }

    // MARK: - Actions
    var addEntryText: String {
        switch language {
        case "fr": return "Ajouter entrée"
        case "es": return "Agregar entrada"
        default: return "Add Entry"
        }
    }

    var addShiftText: String {
        switch language {
        case "fr": return "Ajouter quart"
        case "es": return "Agregar turno"
        default: return "Add Shift"
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

    var cancelText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

    // MARK: - Deletion
    var deleteShiftTitle: String {
        switch language {
        case "fr": return "Supprimer le quart"
        case "es": return "Eliminar turno"
        default: return "Delete Shift"
        }
    }

    var deleteConfirmationMessage: String {
        switch language {
        case "fr": return "Êtes-vous sûr de vouloir supprimer ce quart?"
        case "es": return "¿Está seguro de que desea eliminar este turno?"
        default: return "Are you sure you want to delete this shift?"
        }
    }

    // MARK: - Legend
    var completedText: String {
        switch language {
        case "fr": return "Complété"
        case "es": return "Completado"
        default: return "Completed"
        }
    }

    var scheduledText: String {
        switch language {
        case "fr": return "Planifié"
        case "es": return "Programado"
        default: return "Scheduled"
        }
    }

    var missedText: String {
        switch language {
        case "fr": return "Manqué"
        case "es": return "Perdido"
        default: return "Missed"
        }
    }

    // MARK: - Financial Terms
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

    // MARK: - Progress Indicators
    var salesProgressLabel: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
        }
    }

    var tipPercentageLabel: String {
        switch language {
        case "fr": return "Pourb. %"
        case "es": return "Prop. %"
        default: return "Tip %"
        }
    }
}