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
    @State private var isLoading = false
    @State private var showDeleteAlert = false
    @State private var employerToDelete: Employer?
    @AppStorage("language") private var language = "en"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Add Employer Button
                        Button(action: { showAddEmployer = true }) {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                Text(addEmployerButton)
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .blue.opacity(0.8)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        
                        if employers.isEmpty && !isLoading {
                            // Empty State
                            VStack(spacing: 16) {
                                Image(systemName: "building.2.crop.circle")
                                    .font(.system(size: 60))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.blue, .purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                
                                Text(noEmployersText)
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text(noEmployersMessage)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(40)
                            .frame(maxWidth: .infinity)
                            .glassCard()
                            .padding(.horizontal)
                            .padding(.top, 40)
                        } else {
                            // Employers List
                            ForEach(employers) { employer in
                                EmployerCard(
                                    employer: employer,
                                    onEdit: {
                                        editingEmployer = employer
                                        editEmployerName = employer.name
                                        editEmployerRate = String(format: "%.2f", employer.hourly_rate)
                                        showEditEmployer = true
                                    },
                                    onDelete: {
                                        employerToDelete = employer
                                        showDeleteAlert = true
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
                    onSave: addEmployer,
                    onCancel: {
                        showAddEmployer = false
                        newEmployerName = ""
                        newEmployerRate = ""
                    }
                )
            }
            .sheet(isPresented: $showEditEmployer) {
                EditEmployerSheet(
                    name: $editEmployerName,
                    rate: $editEmployerRate,
                    onSave: updateEmployer,
                    onCancel: {
                        showEditEmployer = false
                        editingEmployer = nil
                        editEmployerName = ""
                        editEmployerRate = ""
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
            employers = try await SupabaseManager.shared.client
                .from("employers")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
            isLoading = false
        } catch {
            print("Error loading employers: \(error)")
            isLoading = false
        }
    }
    
    func addEmployer() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            struct NewEmployer: Encodable {
                let user_id: String
                let name: String
                let hourly_rate: Double
            }
            
            let newEmployer = NewEmployer(
                user_id: userId.uuidString,
                name: newEmployerName,
                hourly_rate: Double(newEmployerRate) ?? 15.00
            )
            
            try await SupabaseManager.shared.client
                .from("employers")
                .insert(newEmployer)
                .execute()
            
            showAddEmployer = false
            newEmployerName = ""
            newEmployerRate = ""
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
            }
            
            let update = EmployerUpdate(
                name: editEmployerName,
                hourly_rate: Double(editEmployerRate) ?? 15.00
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
            await loadEmployers()
            
            HapticFeedback.success()
        } catch {
            print("Error updating employer: \(error)")
            HapticFeedback.error()
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
}

// MARK: - Components

struct EmployerCard: View {
    let employer: Employer
    let onEdit: () -> Void
    let onDelete: () -> Void
    @AppStorage("language") private var language = "en"
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(employer.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign.circle")
                        .font(.caption)
                        .foregroundColor(.green)
                    Text("\(employer.hourly_rate, specifier: "%.2f")/hr")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.body)
                        .foregroundColor(.blue)
                        .padding(8)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.body)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .padding()
        .glassCard()
    }
}

struct AddEmployerSheet: View {
    @Binding var name: String
    @Binding var rate: String
    let onSave: () async -> Void
    let onCancel: () -> Void
    @State private var isSaving = false
    @AppStorage("language") private var language = "en"
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, rate
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(employerNamePlaceholder, text: $name)
                        .focused($focusedField, equals: .name)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                focusedField = .name
                            }
                        }
                } header: {
                    Text(employerNameSection)
                }
                
                Section {
                    HStack {
                        Text("$")
                        TextField("15.00", text: $rate)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .rate)
                        Text("/hr")
                    }
                } header: {
                    Text(hourlyRateSection)
                }
            }
            .navigationTitle(addEmployerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancelButton) {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButton) {
                        Task {
                            isSaving = true
                            await onSave()
                            isSaving = false
                        }
                    }
                    .disabled(name.isEmpty || rate.isEmpty || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
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

// Edit Employer Sheet - NEW
struct EditEmployerSheet: View {
    @Binding var name: String
    @Binding var rate: String
    let onSave: () async -> Void
    let onCancel: () -> Void
    @State private var isSaving = false
    @AppStorage("language") private var language = "en"
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, rate
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField(employerNamePlaceholder, text: $name)
                        .focused($focusedField, equals: .name)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                focusedField = .name
                            }
                        }
                } header: {
                    Text(employerNameSection)
                }
                
                Section {
                    HStack {
                        Text("$")
                        TextField("15.00", text: $rate)
                            .keyboardType(.decimalPad)
                            .focused($focusedField, equals: .rate)
                        Text("/hr")
                    }
                } header: {
                    Text(hourlyRateSection)
                }
            }
            .navigationTitle(editEmployerTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(cancelButton) {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(saveButton) {
                        Task {
                            isSaving = true
                            await onSave()
                            isSaving = false
                        }
                    }
                    .disabled(name.isEmpty || rate.isEmpty || isSaving)
                }
            }
            .overlay {
                if isSaving {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.2)
                }
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
