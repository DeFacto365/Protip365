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

    private let localization = EmployersLocalization.shared

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Add Employer Button - iOS 26 Liquid Glass Style
                        Button(action: {
                            HapticFeedback.light()
                            showAddEmployer = true
                        }) {
                            HStack {
                                Image(systemName: IconNames.Actions.add)
                                    .font(.body)
                                Text(localization.addEmployerButton)
                                    .font(.body)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(.white)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(.tint)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                        .padding(.top)

                        if employers.isEmpty && !isLoading {
                            EmptyStateView()
                        } else {
                            EmployersListView()
                        }
                    }
                    .padding(.bottom)
                }
            }
            .navigationTitle(localization.employersTitle)
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showAddEmployer) {
                AddEmployerSheet(
                    name: $newEmployerName,
                    rate: $newEmployerRate,
                    active: $newEmployerActive,
                    onSave: addEmployer,
                    onCancel: resetAddEmployerForm
                )
            }
            .sheet(isPresented: $showEditEmployer) {
                EditEmployerSheet(
                    name: $editEmployerName,
                    rate: $editEmployerRate,
                    active: $editEmployerActive,
                    onSave: updateEmployer,
                    onCancel: resetEditEmployerForm
                )
            }
            .alert(localization.deleteConfirmTitle, isPresented: $showDeleteAlert) {
                Button(localization.cancelText, role: .cancel) {
                    employerToDelete = nil
                }
                Button(localization.deleteText, role: .destructive) {
                    if let employer = employerToDelete {
                        deleteEmployer(employer)
                    }
                }
            } message: {
                Text(localization.deleteConfirmMessage)
            }
            .alert(localization.cannotDeleteTitle, isPresented: $showCannotDeleteAlert) {
                Button(localization.cancelText, role: .cancel) {
                    employerToDelete = nil
                }
                Button(localization.deactivateText) {
                    if let employer = employerToDelete {
                        updateEmployerActiveStatus(employer, isActive: false)
                        employerToDelete = nil
                    }
                }
            } message: {
                Text(localization.cannotDeleteMessage)
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

    // MARK: - View Components
    @ViewBuilder
    private func EmptyStateView() -> some View {
        VStack(spacing: 20) {
            Image(systemName: "building.2.crop.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue.gradient)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 8) {
                Text(localization.noEmployersText)
                    .font(.headline)
                    .foregroundColor(.primary)

                Text(localization.noEmployersMessage)
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
    }

    @ViewBuilder
    private func EmployersListView() -> some View {
        ForEach(employers) { employer in
            EmployerCard(
                employer: employer,
                shiftCount: employerShiftCounts[employer.id] ?? 0,
                onEdit: { startEditingEmployer(employer) },
                onDelete: { handleEmployerDeletion(employer) }
            )
            .padding(.horizontal)
        }
    }

    // MARK: - Data Loading
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

    // MARK: - CRUD Operations
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

            resetAddEmployerForm()
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

            resetEditEmployerForm()
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

    // MARK: - Helper Methods
    private func startEditingEmployer(_ employer: Employer) {
        editingEmployer = employer
        editEmployerName = employer.name
        editEmployerRate = String(format: "%.2f", employer.hourly_rate)
        editEmployerActive = employer.active
        showEditEmployer = true
    }

    private func handleEmployerDeletion(_ employer: Employer) {
        let shiftCount = employerShiftCounts[employer.id] ?? 0
        employerToDelete = employer

        if shiftCount > 0 {
            showCannotDeleteAlert = true
        } else {
            showDeleteAlert = true
        }
    }

    private func resetAddEmployerForm() {
        showAddEmployer = false
        newEmployerName = ""
        newEmployerRate = ""
        newEmployerActive = true
    }

    private func resetEditEmployerForm() {
        showEditEmployer = false
        editingEmployer = nil
        editEmployerName = ""
        editEmployerRate = ""
        editEmployerActive = true
    }
}