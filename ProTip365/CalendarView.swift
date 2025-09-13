import SwiftUI

struct CalendarView: View {
    @State private var selectedDate = Date()
    @State private var showingAddEntry = false
    @State private var showingAddShift = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Calendar Header
            Text("Shift Calendar")
                .font(.title)
                .fontWeight(.semibold)
                .padding(.top)
            
            // Calendar
            VStack(spacing: 16) {
                // Month/Year Header with Navigation
                HStack {
                    Button(action: {
                        changeMonth(-1)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    
                    Spacer()
                    
                    Text(monthYearText)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button(action: {
                        changeMonth(1)
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Calendar Grid
                VStack(spacing: 8) {
                    // Day headers
                    HStack {
                        ForEach(["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"], id: \.self) { day in
                            Text(day)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    
                    // Calendar days
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
                        ForEach(calendarDays, id: \.self) { day in
                            if day == 0 {
                                Text("")
                                    .frame(width: 40, height: 40)
                            } else {
                                Button(action: {
                                    selectDate(day)
                                }) {
                                    Text("\(day)")
                                        .font(.system(.body, design: .rounded))
                                        .fontWeight(isSelectedDay(day) ? .bold : .regular)
                                        .foregroundColor(isSelectedDay(day) ? .white : (isToday(day) ? .blue : .primary))
                                        .frame(width: 40, height: 40)
                                        .background(
                                            Circle()
                                                .fill(isSelectedDay(day) ? .blue : (isToday(day) ? .blue.opacity(0.1) : .clear))
                                        )
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(.regularMaterial)
                .cornerRadius(16)
                .padding(.horizontal)
            }
            
            Spacer()
            
            // Bottom Buttons
            HStack(spacing: 12) {
                // Add Entry Button
                Button(action: {
                    showingAddEntry = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        Text("Add Entry")
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
                
                // Add Shift Button
                Button(action: {
                    showingAddShift = true
                }) {
                    HStack {
                        Image(systemName: "calendar.badge.plus")
                            .font(.title2)
                        Text("Add Shift")
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
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showingAddEntry) {
            AddEntryView()
        }
        .sheet(isPresented: $showingAddShift) {
            AddShiftView()
        }
    }
    
    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    private var calendarDays: [Int] {
        let calendar = Calendar.current
        let startOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.start ?? selectedDate
        let endOfMonth = calendar.dateInterval(of: .month, for: selectedDate)?.end ?? selectedDate
        
        let firstWeekday = calendar.component(.weekday, from: startOfMonth)
        let numberOfDays = calendar.dateComponents([.day], from: startOfMonth, to: endOfMonth).day ?? 0
        
        var days: [Int] = []
        
        // Add empty days for the beginning of the month
        for _ in 1..<firstWeekday {
            days.append(0)
        }
        
        // Add actual days
        for day in 1...numberOfDays {
            days.append(day)
        }
        
        return days
    }
    
    private func changeMonth(_ increment: Int) {
        let calendar = Calendar.current
        if let newDate = calendar.date(byAdding: .month, value: increment, to: selectedDate) {
            selectedDate = newDate
        }
    }
    
    private func selectDate(_ day: Int) {
        let calendar = Calendar.current
        let currentMonth = calendar.component(.month, from: selectedDate)
        let currentYear = calendar.component(.year, from: selectedDate)
        
        if let newDate = calendar.date(from: DateComponents(year: currentYear, month: currentMonth, day: day)) {
            selectedDate = newDate
        }
    }
    
    private func isSelectedDay(_ day: Int) -> Bool {
        let calendar = Calendar.current
        return calendar.component(.day, from: selectedDate) == day &&
               calendar.isDate(selectedDate, equalTo: Date(), toGranularity: .month)
    }
    
    private func isToday(_ day: Int) -> Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.component(.day, from: today) == day &&
               calendar.isDate(selectedDate, equalTo: today, toGranularity: .month)
    }
}

#Preview {
    CalendarView()
}