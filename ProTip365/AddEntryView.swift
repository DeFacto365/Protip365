import SwiftUI
import Supabase
import UIKit

struct AddEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    // MARK: - Parameters
    let editingShift: ShiftIncome?
    let initialDate: Date?

    // MARK: - State Variables
    @State private var selectedDate = Date()
    @State private var selectedEndDate = Date()  // Separate end date for shifts crossing midnight
    @State private var selectedEmployer: Employer?
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var selectedLunchBreak = "None"
    @State private var hoursWorked: Double = 0.0
    @State private var sales: String = ""
    @State private var tips: String = ""
    @State private var tipOut: String = ""
    @State private var other: String = ""
    @State private var comments = ""
    @State private var employers: [Employer] = []
    @State private var isLoading = false
    @State private var showDatePicker = false
    @State private var showEndDatePicker = false
    @State private var showStartTimePicker = false
    @State private var showEndTimePicker = false
    @State private var showEmployerPicker = false
    @State private var showLunchBreakPicker = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var didntWork = false
    @State private var missedReason = ""
    @State private var showReasonPicker = false
    
    @AppStorage("defaultHourlyRate") private var defaultHourlyRate: Double = 15.00
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false
    @AppStorage("language") private var language = "en"
    
    // MARK: - Computed Properties
    private var lunchBreakOptions = ["None", "15 min", "30 min", "45 min", "60 min"]

    private var missedReasonOptions: [String] {
        switch language {
        case "fr":
            return ["Malade", "Quart annulé", "Urgence personnelle", "Absent", "Météo", "Autre"]
        case "es":
            return ["Enfermo", "Turno cancelado", "Emergencia personal", "No presentado", "Clima", "Otro"]
        default:
            return ["Sick", "Shift Cancelled", "Personal Emergency", "No Show", "Weather", "Other"]
        }
    }

    // MARK: - Translation Properties
    private var didntWorkText: String {
        switch language {
        case "fr": return "N'a pas travaillé"
        case "es": return "No trabajó"
        default: return "Didn't Work"
        }
    }

    private var reasonText: String {
        switch language {
        case "fr": return "Raison"
        case "es": return "Razón"
        default: return "Reason"
        }
    }

    private var selectReasonText: String {
        switch language {
        case "fr": return "Sélectionner raison"
        case "es": return "Seleccionar razón"
        default: return "Select Reason"
        }
    }

    private var statusText: String {
        switch language {
        case "fr": return "Statut"
        case "es": return "Estado"
        default: return "Status"
        }
    }
    
    private var calculatedHours: Double {
        // Return 0 hours if didn't work
        if didntWork {
            return 0
        }

        let calendar = Calendar.current

        // Combine date and time components for start
        var startComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
        let startTimeComponents = calendar.dateComponents([.hour, .minute], from: startTime)
        startComponents.hour = startTimeComponents.hour
        startComponents.minute = startTimeComponents.minute

        // Combine date and time components for end
        var endComponents = calendar.dateComponents([.year, .month, .day], from: selectedEndDate)
        let endTimeComponents = calendar.dateComponents([.hour, .minute], from: endTime)
        endComponents.hour = endTimeComponents.hour
        endComponents.minute = endTimeComponents.minute

        let startDateTime = calendar.date(from: startComponents) ?? Date()
        let endDateTime = calendar.date(from: endComponents) ?? Date()

        let duration = endDateTime.timeIntervalSince(startDateTime)
        let hoursWorked = duration / 3600

        // Subtract lunch break
        let netHours = hoursWorked - (Double(lunchBreakMinutes) / 60.0)
        return max(0, netHours)
    }
    
    private var lunchBreakMinutes: Int {
        switch selectedLunchBreak {
        case "15 min": return 15
        case "30 min": return 30
        case "45 min": return 45
        case "60 min": return 60
        default: return 0
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }
    
    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }
    
    private var totalEarnings: Double {
        let tipsAmount = Double(tips) ?? 0
        let tipOutAmount = Double(tipOut) ?? 0
        let otherAmount = Double(other) ?? 0
        let hourlyRate = selectedEmployer?.hourly_rate ?? defaultHourlyRate
        let salary = calculatedHours * hourlyRate
        return salary + tipsAmount + otherAmount - tipOutAmount
    }
    
    // MARK: - Initializer
    init(editingShift: ShiftIncome? = nil, initialDate: Date? = nil) {
        self.editingShift = editingShift
        self.initialDate = initialDate
    }
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // iOS 26 Gray Background
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // iOS 26 Style Header
                headerView
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Work Info Card - iOS 26 Style
                        workInfoCard

                        // Earnings Card - iOS 26 Style (only show if worked)
                        if !didntWork {
                            earningsCard
                        }

                        // Summary Card - iOS 26 Style
                        summaryCard
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
        }
        .onAppear {
            Task {
                await loadEmployers()
                if let shift = editingShift {
                    populateFieldsForEditing(shift: shift)
                } else {
                    setupDefaultTimes()
                }
            }
        }
        .alert("Error Saving Entry", isPresented: $showErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
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
            
            Text(editingShift != nil ? "Edit Entry" : "New Entry")
                .font(.headline)
                .fontWeight(.semibold)
            
            Spacer()
            
            // Save Button with iOS 26 style
            Button(action: {
                saveEntry()
            }) {
                if isLoading {
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
            .disabled(isLoading)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Work Info Card
    private var workInfoCard: some View {
        VStack(spacing: 0) {
            // Employer Row (if enabled)
            if useMultipleEmployers {
                HStack {
                    Text("Employer")
                        .font(.body)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEmployerPicker.toggle()
                            // Close other pickers
                            showDatePicker = false
                            showStartTimePicker = false
                            showEndTimePicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(selectedEmployer?.name ?? "Select Employer")
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                
                // Inline Employer Picker
                if showEmployerPicker {
                    Picker("Select Employer", selection: $selectedEmployer) {
                        ForEach(employers, id: \.id) { employer in
                            Text(employer.name)
                                .tag(employer as Employer?)
                        }
                    }
                    .pickerStyle(.wheel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
                
                Divider()
                    .padding(.horizontal, 16)
            }

            // Didn't Work Toggle
            HStack {
                Text(didntWorkText)
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                Toggle("", isOn: $didntWork)
                    .labelsHidden()
                    .onChange(of: didntWork) { _, newValue in
                        if !newValue {
                            missedReason = ""
                            showReasonPicker = false
                        }
                    }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Reason Picker (shown when Didn't Work is toggled)
            if didntWork {
                HStack {
                    Text(reasonText)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showReasonPicker.toggle()
                            // Close other pickers
                            showDatePicker = false
                            showEndDatePicker = false
                            showStartTimePicker = false
                            showEndTimePicker = false
                            showEmployerPicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        HStack {
                            Text(missedReason.isEmpty ? selectReasonText : missedReason)
                                .font(.body)
                                .foregroundColor(missedReason.isEmpty ? .secondary : .primary)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

                // Inline Reason Picker
                if showReasonPicker {
                    Picker(selectReasonText, selection: $missedReason) {
                        Text(selectReasonText).tag("")
                        ForEach(missedReasonOptions, id: \.self) { reason in
                            Text(reason).tag(reason)
                        }
                    }
                    .pickerStyle(.wheel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: missedReason) { _, _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showReasonPicker = false
                        }
                    }
                }

                Divider()
                    .padding(.horizontal, 16)
            }

            // Only show time fields if didn't work is false
            if !didntWork {
            // Starts Row (Date and Time on same line - like AddShiftView)
            HStack {
                Text("Starts")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Date Button (disabled when editing)
                    if editingShift != nil {
                        // Show as non-clickable text when editing
                        Text(dateFormatter.string(from: selectedDate))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Allow date selection for new entries
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showDatePicker.toggle()
                                // Close other pickers
                                showStartTimePicker = false
                                showEndTimePicker = false
                                showEmployerPicker = false
                                showLunchBreakPicker = false
                                showEndDatePicker = false
                            }
                        }) {
                            Text(dateFormatter.string(from: selectedDate))
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    // Time Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showStartTimePicker.toggle()
                            // Close other pickers
                            showDatePicker = false
                            showEndTimePicker = false
                            showEmployerPicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(timeFormatter.string(from: startTime))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Inline Date Picker
            if showDatePicker {
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Inline Start Time Picker
            if showStartTimePicker {
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: startTime) { _, newValue in
                        // Check if we need to adjust end date for overnight shifts
                        let calendar = Calendar.current
                        let startComponents = calendar.dateComponents([.hour, .minute], from: newValue)
                        let endComponents = calendar.dateComponents([.hour, .minute], from: endTime)

                        let startHour = startComponents.hour ?? 0
                        let startMinute = startComponents.minute ?? 0
                        let endHour = endComponents.hour ?? 0
                        let endMinute = endComponents.minute ?? 0

                        // If end time is before or equal to start time, assume it's next day
                        if endHour < startHour || (endHour == startHour && endMinute <= startMinute) {
                            // Only update if not already set to next day
                            let daysDiff = calendar.dateComponents([.day], from: selectedDate, to: selectedEndDate).day ?? 0
                            if daysDiff == 0 {
                                selectedEndDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                            }
                        } else {
                            // If end time is after start time and dates are different, reset to same day
                            let daysDiff = calendar.dateComponents([.day], from: selectedDate, to: selectedEndDate).day ?? 0
                            if daysDiff > 0 {
                                selectedEndDate = selectedDate
                            }
                        }
                    }
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            // Ends Row (Date and Time on same line - like AddShiftView)
            HStack {
                Text("Ends")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack(spacing: 8) {
                    // End Date Button (can be different for overnight shifts, disabled when editing)
                    if editingShift != nil {
                        // Show as non-clickable text when editing
                        Text(dateFormatter.string(from: selectedEndDate))
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6).opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        // Allow end date selection for new entries
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showEndDatePicker.toggle()
                                // Close other pickers
                                showDatePicker = false
                                showStartTimePicker = false
                                showEndTimePicker = false
                                showEmployerPicker = false
                                showLunchBreakPicker = false
                            }
                        }) {
                            Text(dateFormatter.string(from: selectedEndDate))
                                .font(.body)
                                .foregroundColor(.primary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray6))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    
                    // Time Button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEndTimePicker.toggle()
                            // Close other pickers
                            showDatePicker = false
                            showStartTimePicker = false
                            showEmployerPicker = false
                            showLunchBreakPicker = false
                        }
                    }) {
                        Text(timeFormatter.string(from: endTime))
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Inline End Date Picker
            if showEndDatePicker {
                DatePicker("Select End Date", selection: $selectedEndDate, displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: selectedEndDate) { _, _ in
                        // Close the date picker when a date is selected
                        withAnimation(.easeInOut(duration: 0.3)) {
                            showEndDatePicker = false
                        }
                    }
            }

            // Inline End Time Picker
            if showEndTimePicker {
                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .onChange(of: endTime) { _, newValue in
                        // Check if we need to adjust end date for overnight shifts
                        let calendar = Calendar.current
                        let startComponents = calendar.dateComponents([.hour, .minute], from: startTime)
                        let endComponents = calendar.dateComponents([.hour, .minute], from: newValue)

                        let startHour = startComponents.hour ?? 0
                        let startMinute = startComponents.minute ?? 0
                        let endHour = endComponents.hour ?? 0
                        let endMinute = endComponents.minute ?? 0

                        // If end time is before or equal to start time, assume it's next day
                        if endHour < startHour || (endHour == startHour && endMinute <= startMinute) {
                            selectedEndDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                        } else {
                            // If end time is after start time, use same day
                            selectedEndDate = selectedDate
                        }
                    }
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            // Lunch Break Row
            HStack {
                Text("Lunch Break")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showLunchBreakPicker.toggle()
                        // Close other pickers
                        showDatePicker = false
                        showStartTimePicker = false
                        showEndTimePicker = false
                        showEmployerPicker = false
                    }
                }) {
                    Text(selectedLunchBreak)
                        .font(.body)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            
            // Inline Lunch Break Picker
            if showLunchBreakPicker {
                Picker("Select Lunch Break", selection: $selectedLunchBreak) {
                    ForEach(lunchBreakOptions, id: \.self) { option in
                        Text(option).tag(option)
                    }
                }
                .pickerStyle(.wheel)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            Divider()
                .padding(.horizontal, 16)
            
            } // End of if !didntWork

            // Status Display - Show even when didn't work
            HStack {
                if didntWork {
                    Text(statusText)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    HStack(spacing: 8) {
                        Text(didntWorkText.uppercased())
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                        if !missedReason.isEmpty {
                            Text("(\(missedReason))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    Text("Total Hours")
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    Text(String(format: "%.1f hours", calculatedHours))
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Earnings Card
    private var earningsCard: some View {
        VStack(spacing: 0) {
            // Sales Row
            HStack {
                Text("Sales")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack {
                    Text("$")
                        .foregroundColor(.blue)
                    SelectableTextField(text: $sales, placeholder: "0.00", keyboardType: .decimalPad)
                        .frame(width: 100)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 16)

            // Tips Row
            HStack {
                Text("Tips")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack {
                    Text("$")
                        .foregroundColor(.blue)
                    SelectableTextField(text: $tips, placeholder: "0.00", keyboardType: .decimalPad)
                        .frame(width: 100)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 16)

            // Tip Out Row
            HStack {
                Text("Tip Out")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack {
                    Text("$")
                        .foregroundColor(.blue)
                    SelectableTextField(text: $tipOut, placeholder: "0.00", keyboardType: .decimalPad)
                        .frame(width: 100)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 16)

            // Other Row
            HStack {
                Text("Other")
                    .font(.body)
                    .foregroundColor(.primary)

                Spacer()

                HStack {
                    Text("$")
                        .foregroundColor(.blue)
                    SelectableTextField(text: $other, placeholder: "0.00", keyboardType: .decimalPad)
                        .frame(width: 100)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()
                .padding(.horizontal, 16)

            // Comments Row
            HStack(alignment: .top) {
                Text("Notes")
                    .font(.body)
                    .foregroundColor(.primary)
                
                Spacer()
                
                TextField("Optional notes", text: $comments, axis: .vertical)
                    .lineLimit(3...6)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(minWidth: 200)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Summary")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()

                // Show status badge if didn't work
                if didntWork {
                    Text(didntWorkText.uppercased())
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.red)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            // Show reason if didn't work
            if didntWork && !missedReason.isEmpty {
                HStack {
                    Text(reasonText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(missedReason)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }

                Divider()
            }

            // Sales at the top (stats only)
            if !didntWork {
                HStack {
                    Text("Sales")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", Double(sales) ?? 0))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }

                Divider()
            }

            // Income components
            // Gross Pay (Base Pay)
            HStack {
                Text("Gross Pay")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "$%.2f", calculatedHours * (selectedEmployer?.hourly_rate ?? defaultHourlyRate)))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Tips
            HStack {
                Text("Tips")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                Text(String(format: "$%.2f", Double(tips) ?? 0))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }

            // Other
            if Double(other) ?? 0 > 0 {
                HStack {
                    Text("Other")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "$%.2f", Double(other) ?? 0))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            // Tip Out (negative)
            if Double(tipOut) ?? 0 > 0 {
                HStack {
                    Text("Tip Out")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "-$%.2f", Double(tipOut) ?? 0))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }

            Divider()

            // Total Earnings at the bottom
            HStack {
                Text("Total Earnings")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(String(format: "$%.2f", totalEarnings))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Functions
    private func setupDefaultTimes() {
        let calendar = Calendar.current
        // Use initialDate if provided, otherwise use today
        let baseDate = initialDate ?? Date()
        selectedDate = baseDate
        selectedEndDate = baseDate  // Default to same date

        var components = calendar.dateComponents([.year, .month, .day], from: baseDate)

        // Set default start time to 5:00 PM on the selected date
        components.hour = 17
        components.minute = 0
        startTime = calendar.date(from: components) ?? baseDate

        // Set default end time to 10:00 PM on the selected date
        components.hour = 22
        components.minute = 0
        endTime = calendar.date(from: components) ?? baseDate
    }
    
    private func loadEmployers() async {
        do {
            let userId = try await supabaseManager.client.auth.session.user.id
            employers = try await supabaseManager.client
                .from("employers")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value

            // If editing, find and set the employer after loading
            if let shift = editingShift, let employerId = shift.employer_id {
                selectedEmployer = employers.first { $0.id == employerId }
            } else if editingShift == nil && !employers.isEmpty {
                // For new entries, set the first employer as default
                selectedEmployer = employers.first
            }
        } catch {
            print("Error loading employers: \(error)")
        }
    }
    
    private func populateFieldsForEditing(shift: ShiftIncome) {
        // Set the date
        selectedDate = dateStringToDate(shift.shift_date) ?? Date()
        selectedEndDate = selectedDate  // Default to same date initially

        // Parse times
        if let startTimeStr = shift.start_time,
           let endTimeStr = shift.end_time {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"

            var startHour = 0
            var startMinute = 0
            var endHour = 0
            var endMinute = 0

            if let parsedStartTime = timeFormatter.date(from: startTimeStr) {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: parsedStartTime)
                startHour = components.hour ?? 0
                startMinute = components.minute ?? 0
                var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedDate)
                dateComponents.hour = startHour
                dateComponents.minute = startMinute
                startTime = calendar.date(from: dateComponents) ?? Date()
            }

            if let parsedEndTime = timeFormatter.date(from: endTimeStr) {
                let calendar = Calendar.current
                let components = calendar.dateComponents([.hour, .minute], from: parsedEndTime)
                endHour = components.hour ?? 0
                endMinute = components.minute ?? 0

                // Check if shift crosses midnight (end time is before start time)
                if endHour < startHour || (endHour == startHour && endMinute <= startMinute) {
                    // Shift crosses midnight, set end date to next day
                    selectedEndDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
                }

                var dateComponents = calendar.dateComponents([.year, .month, .day], from: selectedEndDate)
                dateComponents.hour = endHour
                dateComponents.minute = endMinute
                endTime = calendar.date(from: dateComponents) ?? Date()
            }
        } else {
            // If no times stored, use default times
            setupDefaultTimes()
        }

        // Set the values from the shift
        hoursWorked = shift.hours
        sales = shift.sales > 0 ? String(format: "%.2f", shift.sales) : ""
        tips = shift.tips > 0 ? String(format: "%.2f", shift.tips) : ""
        tipOut = (shift.cash_out ?? 0) > 0 ? String(format: "%.2f", shift.cash_out ?? 0) : ""
        other = (shift.other ?? 0) > 0 ? String(format: "%.2f", shift.other ?? 0) : ""

        // Set lunch break from shift data
        if let lunchMinutes = shift.lunch_break_minutes {
            switch lunchMinutes {
            case 15: selectedLunchBreak = "15 min"
            case 30: selectedLunchBreak = "30 min"
            case 45: selectedLunchBreak = "45 min"
            case 60: selectedLunchBreak = "60 min"
            default: selectedLunchBreak = "None"
            }
        } else {
            selectedLunchBreak = "None"
        }

        // Load notes separately from shifts table
        Task {
            await loadNotesForShift(shiftId: shift.id)
        }

        // Find employer - this will be set after employers are loaded
        if let employerId = shift.employer_id {
            selectedEmployer = employers.first { $0.id == employerId }
        }
    }

    private func loadNotesForShift(shiftId: UUID) async {
        do {
            // Create a simple struct just for notes
            struct NoteOnly: Decodable {
                let notes: String?
            }

            let result: NoteOnly = try await supabaseManager.client
                .from("shifts")
                .select("notes")
                .eq("id", value: shiftId)
                .single()
                .execute()
                .value

            if let notes = result.notes {
                await MainActor.run {
                    comments = notes
                    print("📝 Loaded notes: \(notes)")
                }
            } else {
                print("📝 No notes found for shift")
            }
        } catch {
            print("Error loading notes: \(error)")
        }
    }
    
    private func dateStringToDate(_ dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: dateString)
    }
    
    private func saveEntry() {
        Task {
            do {
                isLoading = true

                let userId = try await supabaseManager.client.auth.session.user.id

                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let shiftDate = dateFormatter.string(from: selectedDate)

                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                let startTimeStr = timeFormatter.string(from: startTime)
                let endTimeStr = timeFormatter.string(from: endTime)

                // NEW ARCHITECTURE:
                // 1. Find or create expected shift in 'shifts' table
                // 2. Create/update actual earnings in 'shift_income' table

                // First, check if there's an expected shift for this date
                struct ShiftCheck: Decodable {
                    let id: UUID
                    let expected_hours: Double?
                    let employer_id: UUID?
                    let hourly_rate: Double
                }

                let existingShifts: [ShiftCheck] = try await supabaseManager.client
                    .from("shifts")
                    .select("id, expected_hours, employer_id, hourly_rate")
                    .eq("user_id", value: userId)
                    .eq("shift_date", value: shiftDate)
                    .execute()
                    .value

                let shiftId: UUID

                // If we're editing an existing shift, use its shift_id directly
                if let editingShift = editingShift, let existingShiftId = editingShift.shift_id {
                    shiftId = existingShiftId

                    // Update the shift's date if it has changed
                    struct ShiftDateUpdate: Encodable {
                        let shift_date: String
                    }

                    try await supabaseManager.client
                        .from("shifts")
                        .update(ShiftDateUpdate(shift_date: shiftDate))
                        .eq("id", value: shiftId)
                        .execute()
                } else {
                    // For new entries, determine if we're using an existing shift or need to create one
                    if let existingShift = existingShifts.first(where: {
                        selectedEmployer == nil || $0.employer_id == selectedEmployer?.id
                    }) {
                        // Use existing expected shift
                        shiftId = existingShift.id
                    } else if let existingShift = existingShifts.first {
                        // Use any existing shift for this date
                        shiftId = existingShift.id
                    } else {
                    // Create new shift record (this happens when entering actual data without pre-planning)
                    struct ShiftInsert: Encodable {
                        let user_id: UUID
                        let shift_date: String
                        let expected_hours: Double
                        let hours: Double  // Required field
                        let start_time: String
                        let end_time: String
                        let hourly_rate: Double
                        let employer_id: UUID?
                        let status: String
                        let notes: String?
                    }

                    let shiftData = ShiftInsert(
                        user_id: userId,
                        shift_date: shiftDate,
                        expected_hours: calculatedHours, // Use actual as expected since not pre-planned
                        hours: calculatedHours,  // Set the required hours field
                        start_time: startTimeStr,
                        end_time: endTimeStr,
                        hourly_rate: selectedEmployer?.hourly_rate ?? defaultHourlyRate,
                        employer_id: selectedEmployer?.id,
                        status: "completed",
                        notes: nil // Notes go in shift_income
                    )

                    struct ShiftResponse: Decodable {
                        let id: UUID
                    }

                    let response: [ShiftResponse] = try await supabaseManager.client
                        .from("shifts")
                        .insert(shiftData)
                        .select("id")
                        .execute()
                        .value

                    guard let newShiftId = response.first?.id else {
                        throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to create shift"])
                    }

                        shiftId = newShiftId
                    }
                }

                // Now handle the actual earnings data in shift_income table (only if worked)
                // Skip income record if didn't work
                if !didntWork {
                // Check if income record already exists for this shift
                struct IncomeCheck: Decodable {
                    let id: UUID
                }

                let incomeResults: [IncomeCheck] = try await supabaseManager.client
                    .from("shift_income")
                    .select("id")
                    .eq("shift_id", value: shiftId)
                    .execute()
                    .value

                if let incomeId = incomeResults.first?.id {
                    // Update existing income record
                    struct IncomeUpdate: Encodable {
                        let actual_hours: Double
                        let sales: Double
                        let tips: Double
                        let cash_out: Double
                        let other: Double
                        let actual_start_time: String
                        let actual_end_time: String
                        let notes: String?
                        let updated_at: String
                    }

                    let updateData = IncomeUpdate(
                        actual_hours: calculatedHours,
                        sales: Double(sales) ?? 0,
                        tips: Double(tips) ?? 0,
                        cash_out: Double(tipOut) ?? 0,
                        other: Double(other) ?? 0,
                        actual_start_time: startTimeStr,
                        actual_end_time: endTimeStr,
                        notes: comments.isEmpty ? nil : comments,
                        updated_at: ISO8601DateFormatter().string(from: Date())
                    )

                    try await supabaseManager.client
                        .from("shift_income")
                        .update(updateData)
                        .eq("id", value: incomeId)
                        .execute()
                } else {
                    // Create new income record
                    struct IncomeInsert: Encodable {
                        let shift_id: UUID
                        let user_id: UUID
                        let actual_hours: Double
                        let sales: Double
                        let tips: Double
                        let cash_out: Double
                        let other: Double
                        let actual_start_time: String
                        let actual_end_time: String
                        let notes: String?
                    }

                    let incomeData = IncomeInsert(
                        shift_id: shiftId,
                        user_id: userId,
                        actual_hours: calculatedHours,
                        sales: Double(sales) ?? 0,
                        tips: Double(tips) ?? 0,
                        cash_out: Double(tipOut) ?? 0,
                        other: Double(other) ?? 0,
                        actual_start_time: startTimeStr,
                        actual_end_time: endTimeStr,
                        notes: comments.isEmpty ? nil : comments
                    )

                    try await supabaseManager.client
                        .from("shift_income")
                        .insert(incomeData)
                        .execute()
                }
                } // End of if !didntWork

                // Update shift record with actual times and lunch break
                struct ShiftUpdate: Encodable {
                    let start_time: String
                    let end_time: String
                    let lunch_break_minutes: Int
                    let expected_hours: Double
                    let status: String
                    let employer_id: UUID?
                    let hourly_rate: Double
                    let notes: String?
                }

                let shiftUpdate = ShiftUpdate(
                    start_time: startTimeStr,
                    end_time: endTimeStr,
                    lunch_break_minutes: lunchBreakMinutes,
                    expected_hours: calculatedHours, // Use actual hours as expected for completed shifts
                    status: didntWork ? "missed" : "completed",
                    employer_id: selectedEmployer?.id,
                    hourly_rate: selectedEmployer?.hourly_rate ?? defaultHourlyRate,
                    notes: didntWork ? missedReason : (comments.isEmpty ? nil : comments)
                )

                try await supabaseManager.client
                    .from("shifts")
                    .update(shiftUpdate)
                    .eq("id", value: shiftId)
                    .execute()

                await MainActor.run {
                    dismiss()
                    HapticFeedback.success()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                    HapticFeedback.error()
                }
            }
        }
    }
}

// Custom TextField that automatically selects all text when tapped
struct SelectableTextField: UIViewRepresentable {
    @Binding var text: String
    let placeholder: String
    let keyboardType: UIKeyboardType

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.placeholder = placeholder
        textField.keyboardType = keyboardType
        textField.textAlignment = .right
        textField.delegate = context.coordinator
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textFieldDidChange(_:)), for: .editingChanged)

        // Set placeholder text color to blue
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.systemBlue]
        )

        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        let parent: SelectableTextField

        init(_ parent: SelectableTextField) {
            self.parent = parent
        }

        @objc func textFieldDidChange(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidBeginEditing(_ textField: UITextField) {
            // Select all text when the field begins editing
            DispatchQueue.main.async {
                textField.selectAll(nil)
            }
        }
    }
}