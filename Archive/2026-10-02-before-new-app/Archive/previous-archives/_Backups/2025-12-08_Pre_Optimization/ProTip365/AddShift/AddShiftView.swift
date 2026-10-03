import SwiftUI

struct AddShiftView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var subscriptionManager: SubscriptionManager

    // MARK: - Parameters
    let editingShift: ShiftWithEntry?
    let initialDate: Date?


    // MARK: - State Variables
    @StateObject private var dataManager: AddShiftDataManager
    @State private var showDatePicker = false
    @State private var showStartDatePicker = false
    @State private var showEndDatePicker = false
    @State private var showEmployerPicker = false
    @State private var showStartTimePicker = false
    @State private var showEndTimePicker = false
    @State private var showLunchBreakPicker = false
    @State private var showAlertPicker = false
    @State private var showingDeleteConfirmation = false
    @AppStorage("language") private var language = "en"
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: - Initializer with StateObject
    init(editingShift: ShiftWithEntry? = nil, initialDate: Date? = nil) {
        self.editingShift = editingShift
        self.initialDate = initialDate
        self._dataManager = StateObject(wrappedValue: AddShiftDataManager(editingShift: editingShift, initialDate: initialDate))
    }

    // MARK: - Computed Properties
    private var localization: AddShiftLocalization {
        AddShiftLocalization(language: language)
    }
    
    // MARK: - Delete Function
    private func deleteShift() async {
        guard let shift = editingShift else { return }

        do {
            // Delete shift entry if it exists
            if let entry = shift.entry {
                try await SupabaseManager.shared.deleteShiftEntry(id: entry.id)
                DashboardCharts.invalidateCache()
            }

            // Delete expected shift
            try await SupabaseManager.shared.deleteExpectedShift(id: shift.id)

            dismiss()
        } catch {
            print("❌ Error deleting shift: \(error)")
            dataManager.errorMessage = "Failed to delete shift"
            dataManager.showErrorAlert = true
        }
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // iOS 26 Gray Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            if dataManager.isInitializing {
                // Show loading state while initializing
                VStack {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    Text(localization.loadingText)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                VStack(spacing: 0) {
                    // iOS 26 Style Header
                    headerView

                    ScrollView {
                        VStack(spacing: 0) {
                            // Main Form Card - iOS 26 Style
                            mainFormCard
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 20)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await dataManager.initializeView()
            }
        }
        .alert(localization.errorSavingShiftText, isPresented: $dataManager.showErrorAlert) {
            Button(localization.okButtonText) { }
        } message: {
            Text(dataManager.errorMessage)
        }
        .alert(localization.deleteShiftTitle, isPresented: $showingDeleteConfirmation) {
            Button(localization.deleteButtonText, role: .destructive) {
                Task {
                    await deleteShift()
                }
            }
            Button(localization.cancelButtonText, role: .cancel) { }
        } message: {
            Text(localization.deleteShiftMessage)
        }
    }
    
    // MARK: - iOS 26 Style Header
    private var headerView: some View {
        HStack {
            // Cancel Button with iOS 26 style
            Button(action: {
                dismiss()
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

            Text(editingShift != nil ? localization.editShiftText : localization.newShiftText)
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            // Delete button (only when editing)
            if editingShift != nil {
                Button(action: {
                    showingDeleteConfirmation = true
                }) {
                    Image(systemName: "trash")
                        .font(.title3)
                        .foregroundColor(.red)
                        .frame(width: 32, height: 32)
                        .background(Color(.systemGray5))
                        .clipShape(Circle())
                }
                .padding(.trailing, 8)
            }

            // Save Button with iOS 26 style
            Button(action: {
                Task {
                    let success = await dataManager.saveShift(subscriptionManager: subscriptionManager)
                    if success {
                        dismiss()
                    }
                }
            }) {
                if dataManager.isLoading {
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
            .disabled(dataManager.isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Main Form Card - iOS 26 Style
    private var mainFormCard: some View {
        VStack(spacing: 0) {
            // Employer and Notes Section
            ShiftDetailsSection(
                selectedEmployer: $dataManager.selectedEmployer,
                comments: $dataManager.comments,
                salesTarget: $dataManager.salesTarget,
                showEmployerPicker: $showEmployerPicker,
                showStartDatePicker: $showStartDatePicker,
                showEndDatePicker: $showEndDatePicker,
                showStartTimePicker: $showStartTimePicker,
                showEndTimePicker: $showEndTimePicker,
                showLunchBreakPicker: $showLunchBreakPicker,
                employers: dataManager.employers,
                localization: localization,
                defaultSalesTarget: dataManager.defaultDailySalesTarget
            )

            // Time Selection Section
            ShiftTimeSection(
                selectedDate: $dataManager.selectedDate,
                endDate: $dataManager.endDate,
                startTime: $dataManager.startTime,
                endTime: $dataManager.endTime,
                selectedLunchBreak: $dataManager.selectedLunchBreak,
                showStartDatePicker: $showStartDatePicker,
                showEndDatePicker: $showEndDatePicker,
                showStartTimePicker: $showStartTimePicker,
                showEndTimePicker: $showEndTimePicker,
                showLunchBreakPicker: $showLunchBreakPicker,
                localization: localization
            )

            // Alert Section
            ShiftAlertSection(
                selectedAlert: $dataManager.selectedAlert,
                showAlertPicker: $showAlertPicker,
                localization: localization
            )

            // Summary Section
            ShiftSummarySection(
                startTime: dataManager.startTime,
                endTime: dataManager.endTime,
                selectedLunchBreak: dataManager.selectedLunchBreak,
                localization: localization
            )
        }
        .background(colorScheme == .dark ? Color(.secondarySystemBackground) : Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    AddShiftView()
}
