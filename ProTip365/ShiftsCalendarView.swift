import SwiftUI
import Supabase

struct ShiftsCalendarView: View {  // Fixed typo - was ShiftCalendarView
    @State private var selectedDate = Date()
    @State private var weekOffset = 0
    @State private var shifts: [ShiftIncome] = []
    @State private var editingShift: ShiftIncome? = nil
    @State private var isEditMode = false
    @State private var showDeleteAlert = false
    
    // Form fields
    @State private var startTime = Date()
    @State private var endTime = Date()
    @State private var hours = ""
    @State private var sales = ""
    @State private var tips = ""
    @State private var tipOut = ""
    @State private var selectedEmployerIndex = 0
    @State private var employers: [Employer] = []
    
    @AppStorage("language") private var language = "en"
    
    // Check if date is in the future
    var isFutureDate: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected > today
    }
    
    // Check if current shift has data
    var hasShiftData: Bool {
        editingShift != nil
    }
    
    // Determine if form should be editable
    var shouldBeInEditMode: Bool {
        // Always edit mode for future dates
        if isFutureDate { return true }
        
        // Always edit mode for dates without data
        if !hasShiftData { return true }
        
        // Otherwise use the edit mode state
        return isEditMode
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Week Calendar at the top
                weekCalendarView
                    .padding(.vertical, 12)
                    .background(Color(.systemGroupedBackground))
                
                // Form Section
                ScrollView {
                    VStack(spacing: 20) {
                        // Shift Form
                        VStack(spacing: 0) {
                            // Date Display
                            HStack {
                                Text(formatDateLong(selectedDate))
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemGroupedBackground))
                            
                            Divider()
                            
                            // Time Section - Always visible
                            Group {
                                // Start Time
                                HStack {
                                    Text("Starts")
                                        .foregroundColor(shouldBeInEditMode ? .primary : .secondary)
                                    Spacer()
                                    if shouldBeInEditMode {
                                        DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                            .onChange(of: startTime) {
                                                calculateHours()
                                            }
                                    } else {
                                        Text(formatTime(startTime))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                
                                Divider()
                                
                                // End Time
                                HStack {
                                    Text("Ends")
                                        .foregroundColor(shouldBeInEditMode ? .primary : .secondary)
                                    Spacer()
                                    if shouldBeInEditMode {
                                        DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                            .labelsHidden()
                                            .onChange(of: endTime) {
                                                calculateHours()
                                            }
                                    } else {
                                        Text(formatTime(endTime))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                
                                Divider()
                                
                                // Hours (calculated)
                                HStack {
                                    Text("Hours")
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(hours.isEmpty ? "0.0" : hours)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                            }
                            
                            // Earnings Section - Only show for today or past dates
                            if !isFutureDate {
                                Divider()
                                
                                // Sales
                                HStack {
                                    Text("Sales")
                                        .foregroundColor(shouldBeInEditMode ? .primary : .secondary)
                                    Spacer()
                                    if shouldBeInEditMode {
                                        TextField("$0.00", text: $sales)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 120)
                                            .onChange(of: sales) { _, newValue in
                                                sales = formatPositiveNumber(newValue)
                                            }
                                    } else {
                                        Text(getDisplayValue(sales))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                
                                Divider()
                                
                                // Tips
                                HStack {
                                    Text("Tips")
                                        .foregroundColor(shouldBeInEditMode ? .primary : .secondary)
                                    Spacer()
                                    if shouldBeInEditMode {
                                        TextField("$0.00", text: $tips)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 120)
                                            .onChange(of: tips) { _, newValue in
                                                tips = formatPositiveNumber(newValue)
                                            }
                                    } else {
                                        Text(getDisplayValue(tips))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                                
                                Divider()
                                
                                // Tip Out
                                HStack {
                                    Text("Tip Out")
                                        .foregroundColor(shouldBeInEditMode ? .primary : .secondary)
                                    Spacer()
                                    if shouldBeInEditMode {
                                        TextField("$0.00", text: $tipOut)
                                            .keyboardType(.decimalPad)
                                            .multilineTextAlignment(.trailing)
                                            .frame(width: 120)
                                            .onChange(of: tipOut) { _, newValue in
                                                tipOut = formatPositiveNumber(newValue)
                                            }
                                    } else {
                                        Text(getDisplayValue(tipOut))
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .background(Color(.secondarySystemGroupedBackground))
                            }
                            
                            // Delete button when editing existing shift
                            if shouldBeInEditMode && editingShift != nil {
                                Divider()
                                
                                Button(action: {
                                    showDeleteAlert = true
                                }) {
                                    Text("Delete Shift")
                                        .foregroundColor(.red)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                }
                                .background(Color(.secondarySystemGroupedBackground))
                            }
                        }
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(10)
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Shifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Only show Cancel for manual edit mode (not auto-edit mode)
                    if isEditMode && hasShiftData && !isFutureDate {
                        Button("Cancel") {
                            // Reset to original values
                            loadShiftForDate(selectedDate)
                            isEditMode = false
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if shouldBeInEditMode {
                        Button("Save") {
                            saveShift()
                            if hasShiftData && !isFutureDate {
                                isEditMode = false
                            }
                        }
                        .disabled(!isFormValid)
                    } else {
                        // Only show Edit button for past dates with existing data
                        Button("Edit") {
                            isEditMode = true
                        }
                    }
                }
            }
            .background(Color(.systemGroupedBackground))
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
            // Load today's shift data if exists
            loadTodayShift()
        }
    }
    
    var weekCalendarView: some View {
        VStack(spacing: 12) {
            // Week navigation
            HStack {
                Button(action: {
                    weekOffset -= 1
                    Task { await loadShifts() }
                }) {
                    Image(systemName: "chevron.left")
                        .foregroundColor(.blue)
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
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal)
            
            // Days of week
            HStack(spacing: 4) {
                ForEach(weekDays, id: \.self) { date in
                    VStack(spacing: 4) {
                        Text(dayOfWeekText(date))
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button(action: {
                            selectedDate = date
                            isEditMode = false  // Reset manual edit mode when changing dates
                            loadShiftForDate(date)
                        }) {
                            VStack(spacing: 2) {
                                Text("\(Calendar.current.component(.day, from: date))")
                                    .font(.headline)
                                    .foregroundColor(isTodayDate(date) ? .white : .primary)
                                
                                if let hoursText = getHoursForDate(date) {
                                    Text(hoursText)
                                        .font(.caption2)
                                        .foregroundColor(isTodayDate(date) ? .white : .blue)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(isTodayDate(date) ? Color.blue :
                                          isSelected(date) ? Color.blue.opacity(0.2) :
                                          Color(.secondarySystemGroupedBackground))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(isSelected(date) && !isTodayDate(date) ? Color.blue : Color.clear, lineWidth: 2)
                            )
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
    
    var isFormValid: Bool {
        !hours.isEmpty && hours != "0" && hours != "0.0"
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
    
    func getHoursForDate(_ date: Date) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        if let shift = shifts.first(where: { $0.shift_date == dateString }) {
            return String(format: "%.1fh", shift.hours)
        }
        return nil
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
    
    func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
    
    // Format number input to only allow positive numbers
    func formatPositiveNumber(_ input: String) -> String {
        // Remove non-numeric characters except decimal point
        let filtered = input.filter { "0123456789.".contains($0) }
        
        // Ensure only one decimal point
        let components = filtered.components(separatedBy: ".")
        if components.count > 2 {
            return components[0] + "." + components[1...].joined()
        }
        
        // Limit to 2 decimal places
        if components.count == 2 && components[1].count > 2 {
            return components[0] + "." + String(components[1].prefix(2))
        }
        
        return filtered
    }
    
    // Get display value with currency formatting
    func getDisplayValue(_ value: String) -> String {
        if value.isEmpty { return "$0.00" }
        if let doubleValue = Double(value) {
            return formatCurrency(doubleValue)
        }
        return "$0.00"
    }
    
    func calculateHours() {
        let difference = endTime.timeIntervalSince(startTime) / 3600
        if difference > 0 {
            hours = String(format: "%.1f", difference)
        } else {
            hours = "0"
        }
    }
    
    func loadTodayShift() {
        // Set default times for new shift
        let calendar = Calendar.current
        startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        endTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: selectedDate) ?? selectedDate
        calculateHours()
        
        // Load existing shift if any
        loadShiftForDate(selectedDate)
    }
    
    func loadShiftForDate(_ date: Date) {
        selectedDate = date  // Update the selected date
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        
        if let shift = shifts.first(where: { $0.shift_date == dateString }) {
            // Found existing shift
            editingShift = shift
            hours = String(format: "%.1f", shift.hours)
            
            // Load earnings data
            sales = shift.sales > 0 ? String(format: "%.2f", shift.sales) : ""
            tips = shift.tips > 0 ? String(format: "%.2f", shift.tips) : ""
            tipOut = (shift.cash_out ?? 0) > 0 ? String(format: "%.2f", shift.cash_out ?? 0) : ""
            
            // Load times if available, otherwise calculate based on hours
            let calendar = Calendar.current
            
            // Check if we have stored start_time and end_time
            if let startTimeStr = shift.start_time, let endTimeStr = shift.end_time {
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                
                if let parsedStartTime = timeFormatter.date(from: startTimeStr),
                   let parsedEndTime = timeFormatter.date(from: endTimeStr) {
                    let startHour = calendar.component(.hour, from: parsedStartTime)
                    let startMinute = calendar.component(.minute, from: parsedStartTime)
                    let endHour = calendar.component(.hour, from: parsedEndTime)
                    let endMinute = calendar.component(.minute, from: parsedEndTime)
                    
                    startTime = calendar.date(bySettingHour: startHour, minute: startMinute, second: 0, of: date) ?? date
                    endTime = calendar.date(bySettingHour: endHour, minute: endMinute, second: 0, of: date) ?? date
                } else {
                    // Fallback to default times
                    startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
                    endTime = calendar.date(byAdding: .hour, value: Int(shift.hours), to: startTime) ?? date
                }
            } else {
                // No stored times, calculate based on hours
                startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
                endTime = calendar.date(byAdding: .hour, value: Int(shift.hours), to: startTime) ?? date
            }
        } else {
            // No existing shift - reset form
            editingShift = nil
            hours = ""
            sales = ""
            tips = ""
            tipOut = ""
            let calendar = Calendar.current
            startTime = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
            endTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: date) ?? date
            calculateHours()
        }
    }
    
    func loadShifts() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            let startDate = weekDays.first ?? Date()
            let endDate = weekDays.last ?? Date()
            
            shifts = try await SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId.uuidString)
                .gte("shift_date", value: dateFormatter.string(from: startDate))
                .lte("shift_date", value: dateFormatter.string(from: endDate))
                .execute()
                .value
        } catch {
            print("Error loading shifts: \(error)")
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
    
    func saveShift() {
        Task {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                
                // Create time strings for storage
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "HH:mm:ss"
                let startTimeString = timeFormatter.string(from: startTime)
                let endTimeString = timeFormatter.string(from: endTime)
                
                struct NewShift: Encodable {
                    let user_id: String
                    let shift_date: String
                    let hours: Double
                    let sales: Double
                    let tips: Double
                    let cash_out: Double?
                    let hourly_rate: Double
                    let start_time: String?
                    let end_time: String?
                }
                
                let newShift = NewShift(
                    user_id: userId.uuidString,
                    shift_date: dateFormatter.string(from: selectedDate),
                    hours: Double(hours) ?? 0,
                    sales: isFutureDate ? 0 : (Double(sales) ?? 0),
                    tips: isFutureDate ? 0 : (Double(tips) ?? 0),
                    cash_out: isFutureDate ? nil : Double(tipOut),
                    hourly_rate: 15.00, // Default, should come from settings
                    start_time: startTimeString,
                    end_time: endTimeString
                )
                
                if editingShift != nil {
                    // Update existing
                    try await SupabaseManager.shared.client
                        .from("shifts")
                        .update(newShift)
                        .eq("id", value: editingShift!.id)
                        .execute()
                } else {
                    // Insert new
                    try await SupabaseManager.shared.client
                        .from("shifts")
                        .insert(newShift)
                        .execute()
                }
                
                await loadShifts()
                loadShiftForDate(selectedDate)  // Reload to refresh the view
                
            } catch {
                print("Error saving shift: \(error)")
            }
        }
    }
    
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
                
                // Reset form
                editingShift = nil
                hours = ""
                sales = ""
                tips = ""
                tipOut = ""
                isEditMode = false
                
                // Reload for current date
                loadShiftForDate(selectedDate)
                
            } catch {
                print("Error deleting shift: \(error)")
            }
        }
    }
}
