import SwiftUI

// MARK: - AddShift Localization
struct AddShiftLocalization {
    let language: String

    init(language: String = "en") {
        self.language = language
    }

    // MARK: - Loading & Errors
    var loadingText: String {
        switch language {
        case "fr": return "Chargement..."
        case "es": return "Cargando..."
        default: return "Loading..."
        }
    }

    var errorSavingShiftText: String {
        switch language {
        case "fr": return "Erreur lors de l'enregistrement"
        case "es": return "Error al guardar"
        default: return "Error Saving Shift"
        }
    }

    var okButtonText: String {
        switch language {
        case "fr": return "OK"
        case "es": return "OK"
        default: return "OK"
        }
    }

    // MARK: - Delete Functionality
    var deleteShiftTitle: String {
        switch language {
        case "fr": return "Supprimer le quart"
        case "es": return "Eliminar turno"
        default: return "Delete Shift"
        }
    }

    var deleteButtonText: String {
        switch language {
        case "fr": return "Supprimer"
        case "es": return "Eliminar"
        default: return "Delete"
        }
    }

    var cancelButtonText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

    var deleteShiftMessage: String {
        switch language {
        case "fr": return "Êtes-vous sûr de vouloir supprimer ce quart?"
        case "es": return "¿Está seguro de que desea eliminar este turno?"
        default: return "Are you sure you want to delete this shift?"
        }
    }

    // MARK: - Navigation
    var editShiftText: String {
        switch language {
        case "fr": return "Modifier le quart"
        case "es": return "Editar turno"
        default: return "Edit Shift"
        }
    }

    var newShiftText: String {
        switch language {
        case "fr": return "Nouveau quart"
        case "es": return "Nuevo turno"
        default: return "New Shift"
        }
    }

    // MARK: - Form Fields
    var employerText: String {
        switch language {
        case "fr": return "Employeur"
        case "es": return "Empleador"
        default: return "Employer"
        }
    }

    var selectEmployerText: String {
        switch language {
        case "fr": return "Sélectionner un employeur"
        case "es": return "Seleccionar empleador"
        default: return "Select Employer"
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

    var selectLunchBreakText: String {
        switch language {
        case "fr": return "Sélectionner la pause déjeuner"
        case "es": return "Seleccionar descanso"
        default: return "Select Lunch Break"
        }
    }

    var shiftExpectedHoursText: String {
        switch language {
        case "fr": return "Heures prévues du quart"
        case "es": return "Horas esperadas del turno"
        default: return "Shift Expected Hours"
        }
    }

    var hoursText: String {
        switch language {
        case "fr": return "heures"
        case "es": return "horas"
        default: return "hours"
        }
    }

    var commentsText: String {
        switch language {
        case "fr": return "Commentaires"
        case "es": return "Comentarios"
        default: return "Comments"
        }
    }

    var addNotesText: String {
        switch language {
        case "fr": return "Ajouter des notes..."
        case "es": return "Agregar notas..."
        default: return "Add notes..."
        }
    }

    var selectDateText: String {
        switch language {
        case "fr": return "Sélectionner la date"
        case "es": return "Seleccionar fecha"
        default: return "Select Date"
        }
    }

    // MARK: - Alert Settings
    var alertText: String {
        switch language {
        case "fr": return "Alerte"
        case "es": return "Alerta"
        default: return "Alert"
        }
    }

    var selectAlertText: String {
        switch language {
        case "fr": return "Sélectionner l'alerte"
        case "es": return "Seleccionar alerta"
        default: return "Select Alert"
        }
    }

    // MARK: - Error Messages
    var selectEmployerError: String {
        switch language {
        case "fr": return "Veuillez sélectionner un employeur"
        case "es": return "Por favor seleccione un empleador"
        default: return "Please select an employer"
        }
    }

    // MARK: - Overlap Detection Messages
    var overlapErrorTitle: String {
        switch language {
        case "fr": return "Conflit d'horaire"
        case "es": return "Conflicto de horario"
        default: return "Schedule Conflict"
        }
    }

    func overlapErrorMessage(employerName: String, startTime: String, endTime: String) -> String {
        switch language {
        case "fr": return "Ce quart de travail chevauche avec un quart existant chez \(employerName) de \(startTime) à \(endTime)"
        case "es": return "Este turno se superpone con un turno existente en \(employerName) de \(startTime) a \(endTime)"
        default: return "This shift overlaps with an existing shift at \(employerName) from \(startTime) to \(endTime)"
        }
    }
}