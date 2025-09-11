import SwiftUI
import Supabase

struct CalendarShiftsView: View {
    @State private var selectedDate = Date()
    @State private var allShifts: [ShiftIncome] = []
    @State private var showingAddShift = false
    @State private var showingAddEntry = false
    @AppStorage("language") private var language = "en"
    
    // Calendar date range - show current month plus/minus 2 months
    private var calendarInterval: DateInterval {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: Date())?.start ?? Date()
        let startDate = calendar.date(byAdding: .month, value: -2, to: startOfMonth) ?? Date()
        let endDate = calendar.date(byAdding: .month, value: 3, to: startOfMonth) ?? Date()
        return DateInterval(start: startDate, end: endDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Custom Calendar Grid
                CustomCalendarView(
                    selectedDate: $selectedDate,
                    shiftsForDate: shiftsForDate
                )
                .frame(height: 400)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                .padding(.horizontal)
                
                // Selected date info
                if !shiftsForDate(selectedDate).isEmpty {
                    selectedDateShiftsView
                }
                
                // Action buttons (like dashboard)
                actionButtonsView
                
                Spacer()
            }
            .navigationTitle(calendarTitle)
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(UIColor.systemGroupedBackground))
            .task {
                await loadAllShifts()
            }
            .sheet(isPresented: $showingAddShift) {
                AddShiftView(
                    selectedDate: selectedDate,
                    isPresented: $showingAddShift,
                    onSave: {
                        Task { await loadAllShifts() }
                    }
                )
            }
            .sheet(isPresented: $showingAddEntry) {
                AddShiftView(
                    selectedDate: selectedDate,
                    isPresented: $showingAddEntry,
                    onSave: {
                        Task { await loadAllShifts() }
                    }
                )
            }
        }
    }
    
    // MARK: - Selected Date Shifts View
    private var selectedDateShiftsView: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDateTitle)
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text(formatDate(selectedDate))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            ForEach(shiftsForDate(selectedDate), id: \.id) { shift in
                ShiftRowView(shift: shift)
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
    }
    
    // MARK: - Action Buttons (like Dashboard)
    private var actionButtonsView: some View {
        HStack(spacing: 16) {
            // Add Entry Button (only enabled for past dates)
            Button(action: {
                showingAddEntry = true
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                    Text(addEntryText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(isPastDate ? Color(hex: "0288FF") : .secondary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
            .disabled(!isPastDate)
            
            // Add Shift Button (always enabled)
            Button(action: {
                showingAddShift = true
            }) {
                HStack {
                    Image(systemName: "calendar.badge.plus")
                        .font(.title2)
                    Text(addShiftText)
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(Color(hex: "0288FF"))
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Helper Functions
    private func shiftsForDate(_ date: Date) -> [ShiftIncome] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: date)
        return allShifts.filter { $0.shift_date == dateString }
    }
    
    private var isPastDate: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let selected = calendar.startOfDay(for: selectedDate)
        return selected < today
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
    
    private func loadAllShifts() async {
        do {
            let userId = try await SupabaseManager.shared.client.auth.session.user.id
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            // Load shifts for a broader range to cover the calendar view
            let startDate = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
            let endDate = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
            
            allShifts = try await SupabaseManager.shared.client
                .from("v_shift_income")
                .select()
                .eq("user_id", value: userId)
                .gte("shift_date", value: dateFormatter.string(from: startDate))
                .lte("shift_date", value: dateFormatter.string(from: endDate))
                .execute()
                .value
        } catch {
            print("Error loading shifts: \(error)")
        }
    }
    
    // MARK: - Localization
    private var calendarTitle: String {
        switch language {
        case "fr": return "Calendrier des quarts"
        case "es": return "Calendario de turnos"
        default: return "Shift Calendar"
        }
    }
    
    private var selectedDateTitle: String {
        switch language {
        case "fr": return "Quarts sélectionnés"
        case "es": return "Turnos seleccionados"
        default: return "Selected Date Shifts"
        }
    }
    
    private var addEntryText: String {
        switch language {
        case "fr": return "Ajouter entrée"
        case "es": return "Agregar entrada"
        default: return "Add Entry"
        }
    }
    
    private var addShiftText: String {
        switch language {
        case "fr": return "Ajouter quart"
        case "es": return "Agregar turno"
        default: return "Add Shift"
        }
    }
}

// MARK: - Calendar Date View
struct CalendarDateView: View {
    let date: Date
    let shifts: [ShiftIncome]
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(Calendar.current.component(.day, from: date))")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isToday ? .white : .primary)
            
            if !shifts.isEmpty {
                // Show shift indicator
                if shifts.count == 1 {
                    // Single shift - show time or hours
                    if let shift = shifts.first {
                        if let startTime = shift.start_time, let endTime = shift.end_time {
                            Text(formatTimeRange(startTime, endTime))
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(isToday ? .white : Color(hex: "0288FF"))
                        } else {
                            Text("\(shift.hours, specifier: "%.0f")h")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(isToday ? .white : Color(hex: "0288FF"))
                        }
                    }
                } else {
                    // Multiple shifts - show count
                    Text("\(shifts.count) shifts")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.orange)
                        .cornerRadius(4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColorForDate)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColorForDate, lineWidth: 1)
        )
    }
    
    private var isToday: Bool {
        Calendar.current.isDate(date, inSameDayAs: Date())
    }
    
    private var backgroundColorForDate: Color {
        if isToday {
            return Color(hex: "0288FF")
        } else if !shifts.isEmpty {
            return Color(hex: "0288FF").opacity(0.1)
        } else {
            return Color.clear
        }
    }
    
    private var borderColorForDate: Color {
        if !shifts.isEmpty {
            return Color(hex: "0288FF")
        } else {
            return Color.gray.opacity(0.3)
        }
    }
    
    private func formatTimeRange(_ startTime: String, _ endTime: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        
        if let start = formatter.date(from: startTime),
           let end = formatter.date(from: endTime) {
            let startString = displayFormatter.string(from: start)
            let endString = displayFormatter.string(from: end)
            return "\(startString)-\(endString)"
        }
        return ""
    }
}

// MARK: - Shift Row View
struct ShiftRowView: View {
    let shift: ShiftIncome
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                if let startTime = shift.start_time, let endTime = shift.end_time {
                    Text(formatTimeRange(startTime, endTime))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                } else {
                    Text("\(shift.hours, specifier: "%.1f") hours")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                }
                
                if let employer = shift.employer_name {
                    Text(employer)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                if shift.has_earnings {
                    Text(formatCurrency(shift.total_income ?? 0))
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color(hex: "0288FF"))
                    
                    if shift.tips > 0 {
                        Text("Tips: \(formatCurrency(shift.tips))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    Text("Planned")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatTimeRange(_ startTime: String, _ endTime: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        
        if let start = formatter.date(from: startTime),
           let end = formatter.date(from: endTime) {
            return "\(displayFormatter.string(from: start)) - \(displayFormatter.string(from: end))"
        }
        return ""
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.2f", amount)
    }
}

// MARK: - Custom Calendar View
struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let shiftsForDate: (Date) -> [ShiftIncome]
    
    @State private var currentMonth = Date()
    private let calendar = Calendar.current
    
    var body: some View {
        VStack(spacing: 16) {
            // Month header with navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .foregroundColor(Color(hex: "0288FF"))
                }
                
                Spacer()
                
                Text(monthYearText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.title2)
                        .foregroundColor(Color(hex: "0288FF"))
                }
            }
            .padding(.horizontal)
            
            // Day headers
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            
            // Calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(monthDates, id: \.self) { date in
                    CalendarDateView(date: date, shifts: shiftsForDate(date))
                        .frame(height: 50)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDate = date
                        }
                        .opacity(calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? 1.0 : 0.3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: "0288FF"), lineWidth: calendar.isDate(date, inSameDayAs: selectedDate) ? 2 : 0)
                        )
                }
            }
            .padding(.horizontal, 4)
        }
        .padding()
    }
    
    private var monthDates: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }
        
        let firstOfMonth = monthInterval.start
        let firstWeekday = calendar.component(.weekday, from: firstOfMonth)
        let daysFromPreviousMonth = (firstWeekday - 1)
        
        let startDate = calendar.date(byAdding: .day, value: -daysFromPreviousMonth, to: firstOfMonth) ?? firstOfMonth
        
        var dates: [Date] = []
        var current = startDate
        
        // Generate 42 days (6 weeks) to fill the calendar grid
        for _ in 0..<42 {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }
        
        return dates
    }
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: currentMonth)
    }
    
    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }
    
    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}

