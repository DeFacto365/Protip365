import SwiftUI

// MARK: - Custom Calendar View
struct CustomCalendarView: View {
    @Binding var selectedDate: Date
    let shiftsForDate: (Date) -> [ShiftIncome]
    let onDateTapped: (Date) -> Void
    let language: String

    @State private var currentMonth = Date()
    private let calendar = Calendar.current

    var body: some View {
        VStack(spacing: 16) {
            // Month header with navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: IconNames.Form.back)
                        .font(.title2)
                        .foregroundStyle(.tint)
                }

                Spacer()

                Text(monthYearText)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: IconNames.Form.next)
                        .font(.title2)
                        .foregroundStyle(.tint)
                }
            }
            .padding(.horizontal)

            // Day headers
            HStack(spacing: 0) {
                ForEach(localizedWeekdaySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)

            // iOS 26 style calendar grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 8) {
                ForEach(monthDates, id: \.self) { date in
                    CalendarDateView(date: date, shifts: shiftsForDate(date))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedDate = date
                            onDateTapped(date)
                        }
                        .opacity(calendar.isDate(date, equalTo: currentMonth, toGranularity: .month) ? 1.0 : 0.3)
                        .overlay(
                            // iOS 26 style selection indicator
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(.blue, lineWidth: calendar.isDate(date, inSameDayAs: selectedDate) ? 2 : 0)
                        )
                }
            }
            .padding(.horizontal)
        }
        .padding(.horizontal)
        .padding(.vertical, 16)
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

        // Generate 35 days (5 weeks) to fill the calendar grid
        for _ in 0..<35 {
            dates.append(current)
            current = calendar.date(byAdding: .day, value: 1, to: current) ?? current
        }

        return dates
    }

    private var monthYearText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"

        // Set locale based on app language setting
        switch language {
        case "fr":
            formatter.locale = Locale(identifier: "fr_FR")
        case "es":
            formatter.locale = Locale(identifier: "es_ES")
        default:
            formatter.locale = Locale(identifier: "en_US")
        }

        return formatter.string(from: currentMonth)
    }

    private var localizedWeekdaySymbols: [String] {
        let localizedCalendar = Calendar.current
        var calendar = localizedCalendar

        // Set locale based on app language setting
        switch language {
        case "fr":
            calendar.locale = Locale(identifier: "fr_FR")
        case "es":
            calendar.locale = Locale(identifier: "es_ES")
        default:
            calendar.locale = Locale(identifier: "en_US")
        }

        return calendar.shortWeekdaySymbols
    }

    private func previousMonth() {
        currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
    }

    private func nextMonth() {
        currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
    }
}