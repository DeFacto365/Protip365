import SwiftUI

struct EmployersLocalization {
    @AppStorage("language") private var language = "en"

    // MARK: - Main View Strings
    var employersTitle: String {
        switch language {
        case "fr": return "Employeurs"
        case "es": return "Empleadores"
        default: return "Employers"
        }
    }

    var addEmployerButton: String {
        switch language {
        case "fr": return "Ajouter un employeur"
        case "es": return "Agregar empleador"
        default: return "Add Employer"
        }
    }

    var noEmployersText: String {
        switch language {
        case "fr": return "Aucun employeur"
        case "es": return "Sin empleadores"
        default: return "No Employers"
        }
    }

    var noEmployersMessage: String {
        switch language {
        case "fr": return "Ajoutez votre premier employeur pour commencer"
        case "es": return "Agregue su primer empleador para comenzar"
        default: return "Add your first employer to get started"
        }
    }

    // MARK: - Delete Confirmation Strings
    var deleteConfirmTitle: String {
        switch language {
        case "fr": return "Confirmer la suppression"
        case "es": return "Confirmar eliminación"
        default: return "Confirm Delete"
        }
    }

    var deleteConfirmMessage: String {
        switch language {
        case "fr": return "Êtes-vous sûr de vouloir supprimer cet employeur?"
        case "es": return "¿Está seguro de que desea eliminar este empleador?"
        default: return "Are you sure you want to delete this employer?"
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

    var cannotDeleteTitle: String {
        switch language {
        case "fr": return "Impossible de supprimer"
        case "es": return "No se puede eliminar"
        default: return "Cannot Delete"
        }
    }

    var cannotDeleteMessage: String {
        switch language {
        case "fr": return "Cet employeur a des entrées dans la base de données et ne peut pas être supprimé. Voulez-vous le désactiver à la place pour qu'il n'apparaisse plus dans les listes de sélection?"
        case "es": return "Este empleador tiene entradas en la base de datos y no se puede eliminar. ¿Desea desactivarlo para que no aparezca en las listas de selección?"
        default: return "This employer has database entries and cannot be deleted. Would you like to deactivate it instead so it no longer appears in selection lists?"
        }
    }

    var deactivateText: String {
        switch language {
        case "fr": return "Désactiver"
        case "es": return "Desactivar"
        default: return "Deactivate"
        }
    }

    // MARK: - Card Strings
    var inactiveLabel: String {
        switch language {
        case "fr": return "Inactif"
        case "es": return "Inactivo"
        default: return "Inactive"
        }
    }

    var shiftCountSingular: String {
        switch language {
        case "fr": return "1 entrée"
        case "es": return "1 entrada"
        default: return "1 entry"
        }
    }

    var shiftCountPlural: String {
        switch language {
        case "fr": return "%d entrées"
        case "es": return "%d entradas"
        default: return "%d entries"
        }
    }

    // MARK: - Sheet Form Strings
    var addEmployerTitle: String {
        switch language {
        case "fr": return "Nouvel Employeur"
        case "es": return "Nuevo Empleador"
        default: return "New Employer"
        }
    }

    var editEmployerTitle: String {
        switch language {
        case "fr": return "Modifier l'employeur"
        case "es": return "Editar empleador"
        default: return "Edit Employer"
        }
    }

    var employerNameSection: String {
        switch language {
        case "fr": return "Nom de l'employeur"
        case "es": return "Nombre del empleador"
        default: return "Employer Name"
        }
    }

    var employerNamePlaceholder: String {
        switch language {
        case "fr": return "Restaurant ABC"
        case "es": return "Restaurante ABC"
        default: return "Restaurant ABC"
        }
    }

    var hourlyRateSection: String {
        switch language {
        case "fr": return "Taux horaire"
        case "es": return "Tarifa por hora"
        default: return "Hourly Rate"
        }
    }

    var activeSection: String {
        switch language {
        case "fr": return "Actif"
        case "es": return "Activo"
        default: return "Active"
        }
    }

    var saveButton: String {
        switch language {
        case "fr": return "Sauvegarder"
        case "es": return "Guardar"
        default: return "Save"
        }
    }

    var cancelButton: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }
}

// MARK: - Convenience Extensions
extension EmployersLocalization {
    static let shared = EmployersLocalization()
}