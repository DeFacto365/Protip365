import SwiftUI
import Supabase

struct ShiftsCalendarView: View {
    @State private var selectedDate = Date()
    @State private var weekOffset = 0
    @State private var allShifts: [ShiftIncome] = []
    @State private var dailyShifts: [ShiftIncome] = []
    @State private var editingShift: ShiftIncome? = nil
    @State private var showDeleteAlert = false
    @State private var isAddingNew = false
    
    // Form fields
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var hours = ""
    @State private var sales = ""
    @State private var tips = ""
    @State private var tipOut = ""
    @State private var selectedEmployerId: UUID? = nil
    @State private var employers: [Employer] = []
    @State private var didntWork = false
    @State private var didntWorkReason = ""
    @State private var isSaving = false
    
    @AppStorage("language") private var language = "en"
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false
    @AppStorage("defaultHourlyRate") private var defaultHourlyRate: Double = 15.00
    @AppStorage("defaultEmployerId") private var defaultEmployerIdString: String?
    @FocusState private var focusedTimePicker: TimePickerField?
    
    enum TimePickerField {
        case start, end
    }
    
    enum DidntWorkReason: String, CaseIterable {
        case sick = "sick"
        case cancelledByEmployer = "cancelled_by_employer"
        case cancelledByMe = "cancelled_by_me"
        
        func localizedText(for language: String) -> String {
            switch self {
            case .sick:
                switch language {
                case "fr": return "J'étais malade"
                case "es": return "Estaba enfermo"
                default: return "I was sick"
                }
            case .cancelledByEmployer:
                switch language {
                case "fr": return "Mon quart a été annulé par l'employeur"
                case "es": return "Mi turno fue cancelado por el empleador"
                default: return "My shift was cancelled by employer"
                }
            case .cancelledByMe:
                switch language {
                case "fr": return "J'ai dû annuler mon quart"
                case "es": return "Tuve que cancelar mi turno"
                default: return "I had to cancel my shift"
                }
            }
        }
    }
    
    // Check if date is in the future
    var isFutureDate: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected > today
    }
    
    // Check if date is in the past (not today or future)
    var isPastDate: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected < today
    }
    
    // Check if current shift has data that prevents deletion
    var hasShiftData: Bool {
        guard let shift = editingShift else { return false }
        return shift.hours > 0 || shift.sales > 0 || shift.tips > 0 || (shift.cash_out ?? 0) > 0
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week Calendar at the top
                weekCalendarView
                    .padding(.vertical, 12)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                
                // Form Section
                ScrollView {
                    VStack(spacing: 20) {
                        // Daily Shifts Section (shown first for consistency with other pages)
                        if !dailyShifts.isEmpty {
                            dailyShiftsView
                        }
                        
                        // Helpful explanation
                        if dailyShifts.isEmpty && !isAddingNew {
                            VStack(spacing: 8) {
                                Text("📅 Schedule your shifts")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text("• Future dates: Schedule expected shifts (no earnings shown)\n• Past dates: Record actual work with earnings")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.leading)
                            }
                            .padding()
                            .liquidGlassCard(material: .ultraThin)
                            .padding(.horizontal)
                        }
                        
                        // Show form if editing/adding or no shifts
                        if editingShift != nil || isAddingNew || dailyShifts.isEmpty {
                            shiftFormView
                        }
                    }
                    .padding(.vertical)
                    .padding(.bottom, 100) // Extra space to avoid bottom tab bar
                }
            }
            .navigationTitle("Shifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Cancel (X) button - top left when editing
                ToolbarItem(placement: .navigationBarLeading) {
                    if editingShift != nil || isAddingNew {
                        Button(action: {
                            HapticFeedback.selection()
                            cancelEditing()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Save (checkmark) button - top right when editing  
                ToolbarItem(placement: .navigationBarTrailing) {
                    if editingShift != nil || isAddingNew || dailyShifts.isEmpty {
                        Button(action: {
                            HapticFeedback.medium()
                            saveShift()
                        }) {
                            if isSaving {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .tint(Color(hex: "0288FF"))
                            } else {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(Color(hex: "0288FF"))
                            }
                        }
                        .disabled(!isFormValid || isSaving)
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .alert("Delete Shift", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteShift()
                }
            } message: {
                Text("Are you sure you want to delete this shift?")
            }
        }
        .task {
            await loadShifts()
            await loadEmployers()
            loadShiftsForDate(selectedDate)
            
            // Initialize default employer after loading employers
            if dailyShifts.isEmpty {
                resetFormForNewEntry()
            }
        }
    }
    
    // MARK: - Shift Form View
    var shiftFormView: some View {
        VStack(spacing: 0) {
            // Date Display
            HStack {
                Text(formatDateLong(selectedDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
                if editingShift != nil {
                    Text("Editing")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(6)
                } else if isAddingNew || dailyShifts.isEmpty {
                    Text("New")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(hex: "0288FF").opacity(0.2))
                        .foregroundColor(Color(hex: "0288FF"))
                        .cornerRadius(6)
                }
            }
            .padding()
            
            Divider()
            
            // Employer Selection
            if useMultipleEmployers && !employers.isEmpty {
                employerSelectionView
                Divider()
            }
            
            // Didn't Work Section (only for past dates, not today or future)
            if isPastDate {
                Divider()
                didntWorkSection
            }
            
            // Time Section
            timeSelectionView
            
            // Earnings Section
            if !isFutureDate && !didntWork {
                Divider()
                earningsFormView
            }
            
            // Delete button
            if editingShift != nil {
                Divider()
                
                if hasShiftData {
                    // Show message when shift has data
                    VStack(spacing: 8) {
                        Text(cannotDeleteText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {}) {
                            Text(deleteShiftText)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding()
                        }
                        .disabled(true)
                        .background(Color(UIColor.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                } else {
                    // Normal delete button when no data
                    Button(action: {
                        showDeleteAlert = true
                    }) {
                        Text(deleteShiftText)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                    }
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
            }
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
    }
    
    // MARK: - Employer Selection View
    var employerSelectionView: some View {
        HStack {
            Text(employerText)
                .foregroundColor(.primary)
            Spacer()
            Picker("", selection: $selectedEmployerId) {
                Text("None").tag(nil as UUID?)
                ForEach(employers) { employer in
                    Text(employer.name).tag(employer.id as UUID?)
                }
            }
            .pickerStyle(.menu)
            .tint(.blue)
        }
        .padding()
    }
    
    // MARK: - Didn't Work Section
    var didntWorkSection: some View {
        VStack(spacing: 12) {
            // Didn't Work Toggle
            HStack {
                Toggle(isOn: $didntWork) {
                    Text(didntWorkText)
                        .foregroundColor(.primary)
                }
                .onChange(of: didntWork) { _, newValue in
                    HapticFeedback.selection()
                    if newValue {
                        // Clear time and earnings when didn't work is selected
                        startTime = Date()
                        endTime = Date()
                        hours = ""
                        sales = ""
                        tips = ""
                        tipOut = ""
                    }
                }
            }
            
            // Reason Dropdown (only show if didn't work is selected)
            if didntWork {
                HStack {
                    Text(reasonText)
                        .foregroundColor(.primary)
                    Spacer()
                    Picker("", selection: $didntWorkReason) {
                        ForEach(DidntWorkReason.allCases, id: \.self) { reason in
                            Text(reason.localizedText(for: language)).tag(reason.rawValue)
                        }
                    }
                    .pickerStyle(.menu)
                    .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .onChange(of: selectedEmployerId) { _, _ in
                        HapticFeedback.selection()
                    }
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Time Selection View
    var timeSelectionView: some View {
        Group {
            // Start Time
            HStack {
                Text(startsText)
                    .foregroundColor(.primary)
                Spacer()
                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .disabled(didntWork)
                    .focused($focusedTimePicker, equals: .start)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .onChange(of: startTime) { _, _ in
                        HapticFeedback.selection()
                        calculateHours()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedTimePicker = nil
                        }
                    }
            }
            .padding()
            
            Divider()
            
            // End Time
            HStack {
                Text(endsText)
                    .foregroundColor(.primary)
                Spacer()
                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .disabled(didntWork)
                    .focused($focusedTimePicker, equals: .end)
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(8)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    .onChange(of: endTime) { _, _ in
                        HapticFeedback.selection()
                        calculateHours()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            focusedTimePicker = nil
                        }
                    }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Divider()
            
            // Hours (calculated)
            HStack {
                Text(isFutureDate ? expectedHoursText : hoursText)
                    .foregroundColor(.secondary)
                Spacer()
                Text(hours.isEmpty ? "0.0" : hours)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Earnings Form View
    var earningsFormView: some View {
        Group {
            // Sales
            HStack {
                Text("Sales")
                    .foregroundColor(.primary)
                Spacer()
                TextField("$0.00", text: $sales)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .textFieldStyle(WhiteBackgroundTextFieldStyle())
                    .onChange(of: sales) { _, newValue in
                        sales = formatPositiveNumber(newValue)
                    }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Divider()
            
            // Tips
            HStack {
                Text("Tips")
                    .foregroundColor(.primary)
                Spacer()
                TextField("$0.00", text: $tips)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .textFieldStyle(WhiteBackgroundTextFieldStyle())
                    .onChange(of: tips) { _, newValue in
                        tips = formatPositiveNumber(newValue)
                    }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Divider()
            
            // Tip Out
            HStack {
                Text("Tip Out")
                    .foregroundColor(.primary)
                Spacer()
                TextField("$0.00", text: $tipOut)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 120)
                    .textFieldStyle(WhiteBackgroundTextFieldStyle())
                    .onChange(of: tipOut) { _, newValue in
                        tipOut = formatPositiveNumber(newValue)
                    }
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
    
    // MARK: - Daily Shifts View
    var dailyShiftsView: some View {
        VStack(spacing: 0) {
            HStack {
                Text(entriesForDayText)
                    .font(.headline)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(dailyShifts.count) \(dailyShifts.count == 1 ? entryText : entriesText)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            Divider()
            
            ForEach(dailyShifts.sorted(by: { $0.start_time ?? "" < $1.start_time ?? "" }), id: \.id) { shift in
                shiftRowView(shift: shift)
                
                if shift.id != dailyShifts.sorted(by: { $0.start_time ?? "" < $1.start_time ?? "" }).last?.id {
                    Divider()
                }
            }
            
            // Add New Entry Button
            Divider()
            
            Button(action: {
                resetFormForNewEntry()
                HapticFeedback.light()
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(Color(hex: "0288FF"))
                    Text(addNewEntryText)
                        .foregroundColor(Color(hex: "0288FF"))
                    Spacer()
                }
                .padding()
            }
            .background(Color(UIColor.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.horizontal)
    }
    
    // MARK: - Shift Row View
    func shiftRowView(shift: ShiftIncome) -> some View {
        Button(action: {
            selectShiftForEditing(shift)
            HapticFeedback.light()
        }) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Time range if available
                    if let startTimeStr = shift.start_time, let endTimeStr = shift.end_time {
                        Text(formatTimeRange(startTimeStr, endTimeStr))
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    } else {
                        Text("\(shift.hours, specifier: "%.1f") hours")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Check if this is a future shift (expected vs actual)
                    let isFutureShift = isShiftInFuture(shift.shift_date)
                    
                    if isFutureShift {
                        // Future shift - show expected hours only
                        Text(expectedText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(6)
                    } else {
                        // Past/today shift - show actual earnings
                        Text(formatCurrency(shift.total_income ?? 0))
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(Color(hex: "0288FF"))
                    }
                }
                
                // Employer if enabled
                if useMultipleEmployers, let employer = shift.employer_name {
                    HStack {
                        Image(systemName: "building.2")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text(employer)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                
                // Details row - only show for actual shifts (past/today)
                let isFutureShift = isShiftInFuture(shift.shift_date)
                
                if !isFutureShift {
                    HStack(spacing: 20) {
                        VStack(alignment: .leading) {
                            Text("Sales")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(shift.sales))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Tips")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(formatCurrency(shift.tips))
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        if (shift.cash_out ?? 0) > 0 {
                            VStack(alignment: .leading) {
                                Text("Tip Out")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(formatCurrency(shift.cash_out ?? 0))
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                } else {
                    // Future shift - show expected hours only
                    HStack {
                        Text(expectedHoursText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(shift.hours, specifier: "%.1f")h")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.blue)
                    }
                }
                
                // Selection indicator
                if editingShift?.id == shift.id {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Currently editing")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(editingShift?.id == shift.id ? Color.blue.opacity(0.1) : Color(UIColor.secondarySystemGroupedBackground))
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Week Calendar View
    var weekCalendarView: some View {
        VStack(spacing: 12) {
            // Week navigation
            HStack {
                Button(action: {
                    weekOffset -= 1
                    Task { await loadShifts() }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(Color(hex: "0288FF"))
                }
                
                Spacer()
                
                Text(weekRangeText)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    weekOffset += 1
                    Task { await loadShifts() }
                }) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color(hex: "0288FF"))
                }
            }
            .padding(.horizontal)
            
            // Days of week
            HStack(spacing: 4) {
                ForEach(weekDays, id: \.self) { date in
                    dayButtonView(date: date)
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Day Button View
    func dayButtonView(date: Date) -> some View {
        VStack(spacing: 4) {
            Text(dayOfWeekText(date))
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: {
                selectedDate = date
                loadShiftsForDate(date)
            }) {
                VStack(spacing: 2) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.headline)
                        .foregroundColor(isTodayDate(date) ? .white : .primary)
                    
                    if let hoursText = getTotalHoursForDate(date) {
                        Text(hoursText)
                            .font(.caption2)
                            .foregroundColor(isTodayDate(date) ? .white : .blue)
                    }
                    
                    if getShiftCountForDate(date) > 1 {
                        Text("\(getShiftCountForDate(date))")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.orange)
                            .cornerRadius(4)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
            }
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isTodayDate(date) ? Color(hex: "0288FF") : (isSelected(date) ? Color(hex: "0288FF").opacity(0.1) : Color(UIColor.systemBackground)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected(date) ? Color(hex: "0288FF") : Color.gray.opacity(0.3), lineWidth: isSelected(date) ? 2 : 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
        }
    }
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        if didntWork {
            return !didntWorkReason.isEmpty
        }
        let calculatedHours = endTime.timeIntervalSince(startTime) / 3600
        return calculatedHours > 0
    }
    
    var weekDays: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let startOfWeek = calendar.dateInterval(of: .weekOfYear, for:
            calendar.date(byAdding: .weekOfYear, value: weekOffset, to: today) ?? today
        )?.start ?? today
        
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: startOfWeek)
        }
    }
    
    var weekRangeText: String {
        let days = weekDays
        guard let first = days.first, let last = days.last else { return "" }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        return "\(formatter.string(from: first)) - \(formatter.string(from: last))"
    }
    
    // MARK: - Helper Functions
    func isShiftInFuture(_ shiftDateString: String) -> Bool {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        guard let shiftDate = dateFormatter.date(from: shiftDateString) else { return false }
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let shiftDay = calendar.startOfDay(for: shiftDate)
        
        return shiftDay > today
    }
    
    func dayOfWeekText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).uppercased()
    }
    
    func isTodayDate(_ date: Date) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let checkDate = calendar.startOfDay(for: date)
        return today == checkDate
    }
    
    func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }
    
    func getTotalHoursForDate(_ date: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        let shiftsForDate = allShifts.filter { $0.shift_date == dateString }
        if !shiftsForDate.isEmpty {
            let totalHours = shiftsForDate.reduce(0) { $0 + $1.hours }
            return String(format: "%.1fh", totalHours)
        }
        return nil
    }
    
    func getShiftCountForDate(_ date: Date) -> Int {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        return allShifts.filter { $0.shift_date == dateString }.count
    }
    
    func formatDateLong(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: date)
    }
    
    func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    func formatTimeRange(_ startTimeStr: String, _ endTimeStr: String) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm:ss"
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        
        if let startTime = timeFormatter.date(from: startTimeStr),
           let endTime = timeFormatter.date(from: endTimeStr) {
            return "\(displayFormatter.string(from: startTime)) - \(displayFormatter.string(from: endTime))"
        }
        return ""
    }
    
    func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
    
    func formatPositiveNumber(_ input: String) -> String {
        let filtered = input.filter { "0123456789.".contains($0) }
        
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1...].joined()
        }
        
        if components.count == 2 && components[1].count > 2 {
            return components[0] + "." + String(components[1].prefix(2))
        }
        
        return filtered
    }
    
    func calculateHours() {
        let difference = endTime.timeIntervalSince(startTime) / 3600
        if difference > 0 {
            hours = String(format: "%.1f", difference)
        } else {
            hours = "0"
        }
    }
    
    // MARK: - Load Shifts for Date
    func loadShiftsForDate(_ date: Date) {
        selectedDate = date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        dailyShifts = allShifts.filter { $0.shift_date == dateString }
        
        editingShift = nil
        isAddingNew = false
        
        if dailyShifts.isEmpty {
            resetFormForNewEntry()
        } else {
            resetFormFields()
        }
    }
    
    // MARK: - Select Shift for Editing
    func selectShiftForEditing(_ shift: ShiftIncome) {
        editingShift = shift
        isAddingNew = false
        hours = String(format: "%.1f", shift.hours)
        
        selectedEmployerId = shift.employer_id
        
        sales = shift.sales > 0 ? String(format: "%.2f", shift.sales) : ""
        tips = shift.tips > 0 ? String(format: "%.2f", shift.tips) : ""
        tipOut = (shift.cash_out ?? 0) > 0 ? String(format: "%.2f", shift.cash_out ?? 0) : ""
        
        let calendar = Calendar.current
        
        if let startTimeStr = shift.start_time, let endTimeStr = shift.end_time {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm:ss"
            
            if let parsedStartTime = timeFormatter.date(from: startTimeStr),
               let parsedEndTime = timeFormatter.date(from: endTimeStr) {
                let startHour = calendar.component(.hour, from: parsedStartTime)
                let startMinute = calendar.component(.minute, from: parsedStartTime)
                let endHour = calendar.component(.hour, from: parsedEndTime)
                let endMinute = calendar.component(.minute, from: parsedEndTime)
                
                startTime = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: selectedDate) ?? selectedDate
                endTime = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: selectedDate) ?? selectedDate
            } else {
                startTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: selectedDate) ?? selectedDate
                endTime = calendar.date(byAdding: .hour, value: Int(shift.hours), to: startTime) ?? selectedDate
            }
        } else {
            startTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: selectedDate) ?? selectedDate
            endTime = calendar.date(byAdding: .hour, value: Int(shift.hours), to: startTime) ?? selectedDate
        }
    }
    
    // MARK: - Reset Functions
    func resetFormForNewEntry() {
        editingShift = nil
        isAddingNew = true
        resetFormFields()
    }
    
    func resetFormFields() {
        hours = ""
        sales = ""
        tips = ""
        tipOut = ""
        // selectedEmployerId is now set by loadUserProfile() - don't reset it here
        let calendar = Calendar.current
        startTime = calendar.date(bySettingHour: 8, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        endTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        calculateHours()
    }
    
    func cancelEditing() {
        editingShift = nil
        isAddingNew = false
        if dailyShifts.isEmpty {
            resetFormForNewEntry()
        } else {
            resetFormFields()
        }
    }
    
    // MARK: - Load Shifts
    func loadShifts() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let startDate = weekDays.first ?? Date()
            let endDate = weekDays.last ?? Date()
            
            allShifts = try await SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId)
                .gte("shift_date", value: dateFormatter.string(from: startDate))
                .lte("shift_date", value: dateFormatter.string(from: endDate))
                .execute()
                .value
            
            loadShiftsForDate(selectedDate)
        } catch {
            print("Error loading shifts: \(error)")
        }
    }
    
    // MARK: - Load Employers
    func loadEmployers() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            employers = try await SupabaseManager.shared.client
                .from("employers")
                .select()
                .eq("user_id", value: userId)
                .execute()
                .value
                
            // Load default employer from user profile
            await loadUserProfile()
        } catch {
            print("Error loading employers: \(error)")
        }
    }
    
    // MARK: - Load User Profile
    func loadUserProfile() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            struct Profile: Decodable {
                let default_employer_id: String?
            }
            
            let profiles: [Profile] = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("default_employer_id")
                .eq("user_id", value: userId)
                .execute()
                .value
                
            if let userProfile = profiles.first,
               let defaultEmployerIdString = userProfile.default_employer_id,
               let defaultEmployerId = UUID(uuidString: defaultEmployerIdString) {
                await MainActor.run {
                    selectedEmployerId = defaultEmployerId
                }
            }
        } catch {
            print("Error loading user profile: \(error)")
        }
    }
    
    // MARK: - Save Shift
    func saveShift() {
        Task {
            await MainActor.run {
                isSaving = true
            }
            
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                let startTimeString = timeFormatter.string(from: startTime)
                let endTimeString = timeFormatter.string(from: endTime)
                
                var hourlyRate = defaultHourlyRate
                if let employerId = selectedEmployerId,
                   let employer = employers.first(where: { $0.id == employerId }) {
                    hourlyRate = employer.hourly_rate
                }
                
                struct NewShift: Encodable {
                    let user_id: UUID
                    let shift_date: String
                    let hours: Double
                    let sales: Double
                    let tips: Double
                    let cash_out: Double?
                    let hourly_rate: Double
                    let employer_id: UUID?
                    let start_time: String?
                    let end_time: String?
                    let notes: String?
                }
                
                // Calculate hours from start/end time
                let calculatedHours = didntWork ? 0 : endTime.timeIntervalSince(startTime) / 3600
                
                let salesValue = isFutureDate || didntWork ? 0 : (Double(sales) ?? 0)
                let tipsValue = isFutureDate || didntWork ? 0 : (Double(tips) ?? 0)
                let tipOutValue = isFutureDate || didntWork ? nil : Double(tipOut)
                
                let newShift = NewShift(
                    user_id: userId,
                    shift_date: dateFormatter.string(from: selectedDate),
                    hours: calculatedHours,
                    sales: salesValue,
                    tips: tipsValue,
                    cash_out: tipOutValue,
                    hourly_rate: hourlyRate,
                    employer_id: selectedEmployerId,
                    start_time: didntWork ? nil : startTimeString,
                    end_time: didntWork ? nil : endTimeString,
                    notes: didntWork ? didntWorkReason : nil
                )
                
                if let editingShift = editingShift {
                    try await SupabaseManager.shared.client
                        .from("shifts")
                        .update(newShift)
                        .eq("id", value: editingShift.id)
                        .execute()
                } else {
                    try await SupabaseManager.shared.client
                        .from("shifts")
                        .insert(newShift)
                        .execute()
                }
                
                await loadShifts()
                
                await MainActor.run {
                    editingShift = nil
                    isAddingNew = false
                    isSaving = false
                    HapticFeedback.success()
                }
                
            } catch {
                await MainActor.run {
                    isSaving = false
                }
                print("Error saving shift: \(error)")
                HapticFeedback.error()
            }
        }
    }
    
    // MARK: - Delete Shift
    func deleteShift() {
        guard let shift = editingShift else { return }
        
        Task {
            do {
                try await SupabaseManager.shared.client
                    .from("shifts")
                    .delete()
                    .eq("id", value: shift.id)
                    .execute()
                
                await loadShifts()
                
                editingShift = nil
                isAddingNew = false
                
            } catch {
                print("Error deleting shift: \(error)")
            }
        }
    }
    
    // MARK: - Localization
    var entriesForDayText: String {
        switch language {
        case "fr": return "Entrées pour ce jour"
        case "es": return "Entradas para este día"
        default: return "Entries for this day"
        }
    }
    
    var entryText: String {
        switch language {
        case "fr": return "entrée"
        case "es": return "entrada"
        default: return "entry"
        }
    }
    
    var entriesText: String {
        switch language {
        case "fr": return "entrées"
        case "es": return "entradas"
        default: return "entries"
        }
    }
    
    var addNewEntryText: String {
        switch language {
        case "fr": return "Ajouter une nouvelle entrée"
        case "es": return "Agregar nueva entrada"
        default: return "Add New Entry"
        }
    }
    
    var expectedText: String {
        switch language {
        case "fr": return "Prévu"
        case "es": return "Previsto"
        default: return "Expected"
        }
    }
    
    var expectedHoursText: String {
        switch language {
        case "fr": return "Heures prévues"
        case "es": return "Horas previstas"
        default: return "Expected Hours"
        }
    }
    
    var hoursText: String {
        switch language {
        case "fr": return "Heures"
        case "es": return "Horas"
        default: return "Hours"
        }
    }
    
    var startsText: String {
        switch language {
        case "fr": return "Commence"
        case "es": return "Empieza"
        default: return "Starts"
        }
    }
    
    var endsText: String {
        switch language {
        case "fr": return "Termine"
        case "es": return "Termina"
        default: return "Ends"
        }
    }
    
    var employerText: String {
        switch language {
        case "fr": return "Employeur"
        case "es": return "Empleador"
        default: return "Employer"
        }
    }
    
    var deleteShiftText: String {
        switch language {
        case "fr": return "Supprimer le quart"
        case "es": return "Eliminar turno"
        default: return "Delete Shift"
        }
    }
    
    var cannotDeleteText: String {
        switch language {
        case "fr": return "Pour supprimer ce quart, vous devez d'abord supprimer les données (heures, ventes, pourboires)."
        case "es": return "Para eliminar este turno, primero debe eliminar los datos (horas, ventas, propinas)."
        default: return "To delete this shift, you must first delete the data (hours, sales, tips)."
        }
    }
    
    var didntWorkText: String {
        switch language {
        case "fr": return "Je n'ai pas travaillé"
        case "es": return "No trabajé"
        default: return "Didn't work"
        }
    }
    
    var reasonText: String {
        switch language {
        case "fr": return "Raison"
        case "es": return "Razón"
        default: return "Reason"
        }
    }
}


