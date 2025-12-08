import SwiftUI

struct AddShiftView: View {
    @Environment(\.dismiss) private var dismiss

    // MARK: - Parameters
    let editingShift: ShiftIncome?
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
    @AppStorage("language") private var language = "en"

    // MARK: - Initializer with StateObject
    init(editingShift: ShiftIncome? = nil, initialDate: Date? = nil) {
        self.editingShift = editingShift
        self.initialDate = initialDate
        self._dataManager = StateObject(wrappedValue: AddShiftDataManager(editingShift: editingShift, initialDate: initialDate))
    }

    // MARK: - Computed Properties
    private var localization: AddShiftLocalization {
        AddShiftLocalization(language: language)
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

            // Save Button with iOS 26 style
            Button(action: {
                Task {
                    let success = await dataManager.saveShift()
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
                showEmployerPicker: $showEmployerPicker,
                showStartDatePicker: $showStartDatePicker,
                showEndDatePicker: $showEndDatePicker,
                showStartTimePicker: $showStartTimePicker,
                showEndTimePicker: $showEndTimePicker,
                showLunchBreakPicker: $showLunchBreakPicker,
                employers: dataManager.employers,
                localization: localization
            )

            // Time Selection Section
            ShiftTimeSection(
                selectedDate: $dataManager.selectedDate,
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

            // Summary Section
            ShiftSummarySection(
                startTime: dataManager.startTime,
                endTime: dataManager.endTime,
                selectedLunchBreak: dataManager.selectedLunchBreak,
                localization: localization
            )
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
    }
}

#Preview {
    AddShiftView()
}