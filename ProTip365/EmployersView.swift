import SwiftUI
import Supabase

struct EmployersView: View {
    @State private var employers: [Employer] = []
    @State private var showAddEmployer = false
    @State private var showEditEmployer = false
    @State private var editingEmployer: Employer?
    @State private var newEmployerName = ""
    @State private var newEmployerRate = ""
    @State private var editEmployerName = ""
    @State private var editEmployerRate = ""
    @State private var editEmployerActive = true
    @State private var newEmployerActive = true
    @State private var isLoading = false
    @State private var showDeleteAlert = false
    @State private var showCannotDeleteAlert = false
    @State private var employerToDelete: Employer?
    @State private var employerShiftCounts: [UUID: Int] = [:]
    @AppStorage("language") private var language = "en"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Add Employer Button - iOS 26 Liquid Glass Style (same as Calendar)
                        Button(action: {
                            HapticFeedback.light()
                            showAddEmployer = true
                        }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.body)
                                Text(addEmployerButton)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        .padding(.top)
                        
                        if employers.isEmpty && !isLoading {
                            // Empty State - iOS 26 Style
                            VStack(spacing: 20) {
                                Image(systemName: "building.2.crop.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundStyle(.blue.gradient)
                                    .symbolRenderingMode(.hierarchical)
                                
                                VStack(spacing: 8) {
                                    Text(noEmployersText)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(noEmployersMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(.quaternary, lineWidth: 0.5)
                            )
                            .padding(.horizontal)
                            .padding(.top, 40)
                        } else {
                            // Employers List
                            ForEach(employers) { employer in
                                EmployerCard(
                                    employer: employer,
                                    shiftCount: employerShiftCounts[employer.id] ?? 0,
                                    onEdit: {
                                        editingEmployer = employer
                                        editEmployerName = employer.name
                                        editEmployerRate = String(format: "%.2f", employer.hourly_rate)
                                        editEmployerActive = employer.active
                                        showEditEmployer = true
                                    },
                                    onDelete: {
                                        let shiftCount = employerShiftCounts[employer.id] ?? 0
                                        if shiftCount > 0 {
                                            employerToDelete = employer
                                            showCannotDeleteAlert = true
                                        } else {
                                            employerToDelete = employer
                                            showDeleteAlert = true
                                        }
                                    }
                                )
                                .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle(employersTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddEmployer) {
                AddEmployerSheet(
                    name: $newEmployerName,
                    rate: $newEmployerRate,
                    active: $newEmployerActive,
                    onSave: addEmployer,
                    onCancel: {
                        showAddEmployer = false
                        newEmployerName = ""
                        newEmployerRate = ""
                        newEmployerActive = true
                    }
                )
            }
            .sheet(isPresented: $showEditEmployer) {
                EditEmployerSheet(
                    name: $editEmployerName,
                    rate: $editEmployerRate,
                    active: $editEmployerActive,
                    onSave: updateEmployer,
                    onCancel: {
                        showEditEmployer = false
                        editingEmployer = nil
                        editEmployerName = ""
                        editEmployerRate = ""
                        editEmployerActive = true
                    }
                )
            }
            .alert(deleteConfirmTitle, isPresented: $showDeleteAlert) {
                Button(cancelText, role: .cancel) {
                    employerToDelete = nil
                }
                Button(deleteText, role: .destructive) {
                    if let employer = employerToDelete {
                        deleteEmployer(employer)
                    }
                }
            } message: {
                Text(deleteConfirmMessage)
            }
            .alert(cannotDeleteTitle, isPresented: $showCannotDeleteAlert) {
                Button(cancelText, role: .cancel) {
                    employerToDelete = nil
                }
                Button(deactivateText) {
                    if let employer = employerToDelete {
                        updateEmployerActiveStatus(employer, isActive: false)
                        employerToDelete = nil
                    }
                }
            } message: {
                Text(cannotDeleteMessage)
            }
            .overlay {
                if isLoading {
                    LoadingOverlay(isLoading: $isLoading)
                }
            }
        }
        .task {
            await loadEmployers()
        }
    }
    
    func loadEmployers() async {
        isLoading = true
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            // Load all employers (both active and inactive)
            employers = try await SupabaseManager.shared.client
                .from("employers")
                .select()
                .eq("user_id", value: userId)
                .order("active", ascending: false) // Show active first
                .order("name", ascending: true)
                .execute()
                .value

            // Load shift counts for each employer
            await loadShiftCounts(for: employers)

            isLoading = false
        } catch {
            print("Error loading employers: \(error)")
            isLoading = false
        }
    }

    func loadShiftCounts(for employers: [Employer]) async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id

            for employer in employers {
                // Count all income entries for this employer from the view
                struct CountResult: Decodable {
                    let shift_id: UUID?
                }

                let entries: [CountResult] = try await SupabaseManager.shared.client
                    .from("v_shift_income")
                    .select("shift_id")
                    .eq("user_id", value: userId)
                    .eq("employer_id", value: employer.id)
                    .execute()
                    .value

                employerShiftCounts[employer.id] = entries.count

                if entries.count > 0 {
                    print("Employer \(employer.name) has \(entries.count) entries")
                }
            }
        } catch {
            print("Error loading shift counts: \(error)")
        }
    }
    
    func addEmployer() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            struct NewEmployer: Encodable {
                let user_id: String
                let name: String
                let hourly_rate: Double
                let active: Bool
            }
            
            let newEmployer = NewEmployer(
                user_id: userId.uuidString,
                name: newEmployerName,
                hourly_rate: Double(newEmployerRate) ?? 15.00,
                active: newEmployerActive
            )
            
            try await SupabaseManager.shared.client
                .from("employers")
                .insert(newEmployer)
                .execute()
            
            showAddEmployer = false
            newEmployerName = ""
            newEmployerRate = ""
            newEmployerActive = true
            await loadEmployers()
            
            HapticFeedback.success()
        } catch {
            print("Error adding employer: \(error)")
            HapticFeedback.error()
        }
    }
    
    func updateEmployer() async {
        guard let employer = editingEmployer else { return }
        
        do {
            struct EmployerUpdate: Encodable {
                let name: String
                let hourly_rate: Double
                let active: Bool
            }

            let update = EmployerUpdate(
                name: editEmployerName,
                hourly_rate: Double(editEmployerRate) ?? 15.00,
                active: editEmployerActive
            )
            
            try await SupabaseManager.shared.client
                .from("employers")
                .update(update)
                .eq("id", value: employer.id)
                .execute()
            
            showEditEmployer = false
            editingEmployer = nil
            editEmployerName = ""
            editEmployerRate = ""
            editEmployerActive = true
            await loadEmployers()
            
            HapticFeedback.success()
        } catch {
            print("Error updating employer: \(error)")
            HapticFeedback.error()
        }
    }
    
    func updateEmployerActiveStatus(_ employer: Employer, isActive: Bool) {
        Task {
            do {
                struct EmployerUpdate: Encodable {
                    let active: Bool
                }

                let update = EmployerUpdate(active: isActive)

                try await SupabaseManager.shared.client
                    .from("employers")
                    .update(update)
                    .eq("id", value: employer.id)
                    .execute()

                await loadEmployers()
                HapticFeedback.success()
            } catch {
                print("Error updating employer active status: \(error)")
                HapticFeedback.error()
            }
        }
    }

    func deleteEmployer(_ employer: Employer) {
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("employers")
                    .delete()
                    .eq("id", value: employer.id)
                    .execute()

                await loadEmployers()
                employerToDelete = nil
                HapticFeedback.success()
            } catch {
                print("Error deleting employer: \(error)")
                HapticFeedback.error()
            }
        }
    }

    // Localization
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
}

// MARK: - Components

struct EmployerCard: View {
    let employer: Employer
    let shiftCount: Int
    let onEdit: () -> Void
    let onDelete: () -> Void
    @AppStorage("language") private var language = "en"
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Text(employer.name)
                        .font(.headline)
                        .foregroundColor(employer.active ? .primary : .secondary)
                        .strikethrough(!employer.active)

                    if !employer.active {
                        Text("(\(inactiveLabel))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 6) {
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(employer.active ? .green : .gray)
                    Text("$\(employer.hourly_rate, specifier: "%.2f")/hr")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(employer.active ? .secondary : Color(.tertiaryLabel))
                }

                if shiftCount > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(shiftCount == 1 ? shiftCountSingular : String(format: shiftCountPlural, shiftCount))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 12) {
                Button(action: {
                    HapticFeedback.light()
                    onEdit()
                }) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .symbolRenderingMode(.hierarchical)
                }

                Button(action: {
                    HapticFeedback.light()
                    onDelete()
                }) {
                    Image(systemName: "trash.circle.fill")
                        .font(.title2)
                        .foregroundStyle(shiftCount > 0 ? .gray : .red)
                        .symbolRenderingMode(.hierarchical)
                }
                .disabled(shiftCount > 0)
                .opacity(shiftCount > 0 ? 0.5 : 1.0)
            }
        }
        .padding()
        .background(employer.active ? Color(.systemBackground) : Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(employer.active ? 0.05 : 0.02), radius: 2, x: 0, y: 1)
    }

    // Localization
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
}

struct AddEmployerSheet: View {
    @Binding var name: String
    @Binding var rate: String
    @Binding var active: Bool
    let onSave: () async -> Void
    let onCancel: () -> Void
    @State private var isSaving = false
    @AppStorage("language") private var language = "en"
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss
    
    enum Field {
        case name, rate
    }
    
    var body: some View {
        ZStack {
            // iOS 26 Gray Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // iOS 26 Style Header
                HStack {
                    // Cancel Button with iOS 26 style
                    Button(action: {
                        onCancel()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(addEmployerTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Save Button with iOS 26 style
                    Button(action: {
                        Task {
                            isSaving = true
                            await onSave()
                            isSaving = false
                        }
                    }) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
                    .disabled(name.isEmpty || rate.isEmpty || isSaving)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemGroupedBackground))
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Employer Info Card - iOS 26 Style
                        VStack(spacing: 0) {
                            // Name Row
                            HStack {
                                Text(employerNameSection)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                TextField(employerNamePlaceholder, text: $name)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .name)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            // Rate Row
                            HStack {
                                Text(hourlyRateSection)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack {
                                    Text("$")
                                        .foregroundColor(.secondary)
                                    TextField("15.00", text: $rate)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .rate)
                                        .frame(width: 80)
                                    Text("/hr")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            Divider()
                                .padding(.horizontal, 16)

                            // Active Toggle Row
                            HStack {
                                Text(activeSection)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                CompactLiquidGlassToggle(isOn: $active)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .name
            }
        }
    }
    
    // Localization
    var addEmployerTitle: String {
        switch language {
        case "fr": return "Nouvel Employeur"
        case "es": return "Nuevo Empleador"
        default: return "New Employer"
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

// Edit Employer Sheet - iOS 26 Style
struct EditEmployerSheet: View {
    @Binding var name: String
    @Binding var rate: String
    @Binding var active: Bool
    let onSave: () async -> Void
    let onCancel: () -> Void
    @State private var isSaving = false
    @AppStorage("language") private var language = "en"
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) private var dismiss
    
    enum Field {
        case name, rate
    }
    
    var body: some View {
        ZStack {
            // iOS 26 Gray Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // iOS 26 Style Header
                HStack {
                    // Cancel Button with iOS 26 style
                    Button(action: {
                        onCancel()
                    }) {
                        Image(systemName: "xmark")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                            .frame(width: 32, height: 32)
                            .background(Color(.systemGray5))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Text(editEmployerTitle)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Save Button with iOS 26 style
                    Button(action: {
                        Task {
                            isSaving = true
                            await onSave()
                            isSaving = false
                        }
                    }) {
                        if isSaving {
                            ProgressView()
                                .scaleEffect(0.8)
                                .frame(width: 32, height: 32)
                        } else {
                            Image(systemName: "checkmark")
                                .font(.title2)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .frame(width: 32, height: 32)
                        }
                    }
                    .background(Color(.systemGray5))
                    .clipShape(Circle())
                    .disabled(name.isEmpty || rate.isEmpty || isSaving)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.systemGroupedBackground))
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Employer Info Card - iOS 26 Style
                        VStack(spacing: 0) {
                            // Name Row
                            HStack {
                                Text(employerNameSection)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                TextField(employerNamePlaceholder, text: $name)
                                    .multilineTextAlignment(.trailing)
                                    .focused($focusedField, equals: .name)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            
                            Divider()
                                .padding(.horizontal, 16)
                            
                            // Rate Row
                            HStack {
                                Text(hourlyRateSection)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                HStack {
                                    Text("$")
                                        .foregroundColor(.secondary)
                                    TextField("15.00", text: $rate)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .focused($focusedField, equals: .rate)
                                        .frame(width: 80)
                                    Text("/hr")
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)

                            Divider()
                                .padding(.horizontal, 16)

                            // Active Toggle Row
                            HStack {
                                Text(activeSection)
                                    .font(.body)
                                    .foregroundColor(.primary)

                                Spacer()

                                CompactLiquidGlassToggle(isOn: $active)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(Color(.systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                focusedField = .name
            }
        }
    }
    
    // Localization
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
