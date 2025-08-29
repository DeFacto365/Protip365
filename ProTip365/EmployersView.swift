import SwiftUI
import Supabase

struct EmployersView: View {
    @State private var employers: [Employer] = []
    @State private var showAddEmployer = false
    @State private var newEmployerName = ""
    @State private var newEmployerRate = "15.00"
    @AppStorage("language") private var language = "en"
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(employers) { employer in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(employer.name)
                            .font(.headline)
                        HStack {
                            Text(hourlyRateText)
                            Text("$\(employer.hourly_rate, specifier: "%.2f")/hr")
                                .fontWeight(.semibold)
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .onDelete(perform: deleteEmployer)
            }
            .navigationTitle(employersTitle)
            .toolbar {
                Button(action: { showAddEmployer = true }) {
                    Image(systemName: "plus")
                }
            }
            .sheet(isPresented: $showAddEmployer) {
                NavigationStack {
                    Form {
                        TextField(employerNamePlaceholder, text: $newEmployerName)
                        TextField(hourlyRatePlaceholder, text: $newEmployerRate)
                            .keyboardType(.decimalPad)
                    }
                    .navigationTitle(addEmployerTitle)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button(cancelText) {
                                showAddEmployer = false
                                newEmployerName = ""
                                newEmployerRate = "15.00"
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button(saveText) {
                                Task {
                                    await addEmployer()
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadEmployers()
        }
    }
    
    func loadEmployers() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            employers = try await SupabaseManager.shared.client
                .from("employers")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
        } catch {
            print("Error loading employers: \(error)")
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
            newEmployerRate = "15.00"
            await loadEmployers()
        } catch {
            print("Error adding employer: \(error)")
        }
    }
    
    func deleteEmployer(at offsets: IndexSet) {
        Task {
            for index in offsets {
                let employer = employers[index]
                do {
                    try await SupabaseManager.shared.client
                        .from("employers")
                        .delete()
                        .eq("id", value: employer.id)
                        .execute()
                } catch {
                    print("Error deleting employer: \(error)")
                }
            }
            await loadEmployers()
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
    
    var addEmployerTitle: String {
        switch language {
        case "fr": return "Ajouter Employeur"
        case "es": return "Agregar Empleador"
        default: return "Add Employer"
        }
    }
    
    var employerNamePlaceholder: String {
        switch language {
        case "fr": return "Nom de l'employeur"
        case "es": return "Nombre del empleador"
        default: return "Employer name"
        }
    }
    
    var hourlyRatePlaceholder: String {
        switch language {
        case "fr": return "Taux horaire"
        case "es": return "Tarifa por hora"
        default: return "Hourly rate"
        }
    }
    
    var hourlyRateText: String {
        switch language {
        case "fr": return "Taux:"
        case "es": return "Tarifa:"
        default: return "Rate:"
        }
    }
    
    var cancelText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }
    
    var saveText: String {
        switch language {
        case "fr": return "Sauvegarder"
        case "es": return "Guardar"
        default: return "Save"
        }
    }
}
