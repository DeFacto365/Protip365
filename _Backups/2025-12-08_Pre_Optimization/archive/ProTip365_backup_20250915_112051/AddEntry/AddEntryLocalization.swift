import Foundation

struct AddEntryLocalizedStrings {
    let language: String

    init(language: String) {
        self.language = language
    }

    // MARK: - Missed Reason Options
    var missedReasonOptions: [String] {
        switch language {
        case "fr":
            return ["Malade", "Quart annulé", "Urgence personnelle", "Absent", "Météo", "Autre"]
        case "es":
            return ["Enfermo", "Turno cancelado", "Emergencia personal", "No presentado", "Clima", "Otro"]
        default:
            return ["Sick", "Shift Cancelled", "Personal Emergency", "No Show", "Weather", "Other"]
        }
    }

    // MARK: - Main UI Text
    var didntWorkText: String {
        switch language {
        case "fr": return "N'a pas travaillé"
        case "es": return "No trabajó"
        default: return "Didn't Work"
        }
    }

    var reasonText: String {
        switch language {
        case "fr": return "Raison"
        case "es": return "Razón"
        default: return "Reason"
        }
    }

    var selectReasonText: String {
        switch language {
        case "fr": return "Sélectionner raison"
        case "es": return "Seleccionar razón"
        default: return "Select Reason"
        }
    }

    var statusText: String {
        switch language {
        case "fr": return "Statut"
        case "es": return "Estado"
        default: return "Status"
        }
    }

    var okButtonText: String {
        switch language {
        case "fr": return "OK"
        case "es": return "OK"
        default: return "OK"
        }
    }

    var errorSavingEntryText: String {
        switch language {
        case "fr": return "Erreur lors de l'enregistrement"
        case "es": return "Error al guardar"
        default: return "Error Saving Entry"
        }
    }

    var editEntryText: String {
        switch language {
        case "fr": return "Modifier l'entrée"
        case "es": return "Editar entrada"
        default: return "Edit Entry"
        }
    }

    var newEntryText: String {
        switch language {
        case "fr": return "Nouvelle entrée"
        case "es": return "Nueva entrada"
        default: return "New Entry"
        }
    }

    var employerText: String {
        switch language {
        case "fr": return "Employeur"
        case "es": return "Empleador"
        default: return "Employer"
        }
    }

    var startsText: String {
        switch language {
        case "fr": return "Début"
        case "es": return "Inicio"
        default: return "Starts"
        }
    }

    var endsText: String {
        switch language {
        case "fr": return "Fin"
        case "es": return "Fin"
        default: return "Ends"
        }
    }

    var lunchBreakText: String {
        switch language {
        case "fr": return "Pause déjeuner"
        case "es": return "Descanso para almorzar"
        default: return "Lunch Break"
        }
    }

    var totalHoursText: String {
        switch language {
        case "fr": return "Heures totales"
        case "es": return "Horas totales"
        default: return "Total Hours"
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

    var tipOutText: String {
        switch language {
        case "fr": return "Partage de pourboires"
        case "es": return "Propinas compartidas"
        default: return "Tip Out"
        }
    }

    var otherText: String {
        switch language {
        case "fr": return "Autre"
        case "es": return "Otro"
        default: return "Other"
        }
    }

    var notesText: String {
        switch language {
        case "fr": return "Notes"
        case "es": return "Notas"
        default: return "Notes"
        }
    }

    var optionalNotesText: String {
        switch language {
        case "fr": return "Notes optionnelles"
        case "es": return "Notas opcionales"
        default: return "Optional notes"
        }
    }

    var summaryText: String {
        switch language {
        case "fr": return "Résumé"
        case "es": return "Resumen"
        default: return "Summary"
        }
    }

    var grossPayText: String {
        switch language {
        case "fr": return "Salaire brut"
        case "es": return "Pago bruto"
        default: return "Gross Pay"
        }
    }

    var totalEarningsText: String {
        switch language {
        case "fr": return "Gains totaux"
        case "es": return "Ganancias totales"
        default: return "Total Earnings"
        }
    }

    var hoursUnit: String {
        switch language {
        case "fr": return "hrs"
        case "es": return "hrs"
        default: return "hours"
        }
    }
}