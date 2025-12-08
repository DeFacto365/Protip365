import SwiftUI

/// Period selector component for Dashboard view
struct DashboardPeriodSelector: View {
    @Binding var selectedPeriod: Int
    @Binding var monthViewType: Int

    let localization: DashboardLocalization
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("language") private var language = "en"

    var body: some View {
        VStack(spacing: 12) {
            // Main period selector
            Picker("Period", selection: $selectedPeriod) {
                Text(localization.todayText).tag(0)
                Text(localization.weekText).tag(1)
                Text(localization.monthText).tag(2)
                Text(localization.yearText).tag(3)
            }
            .id(language) // Force refresh when language changes
            .pickerStyle(.segmented)
            .padding()
            .padding(.horizontal)
            .frame(maxWidth: horizontalSizeClass == .regular ? 600 : .infinity)
            .onChange(of: selectedPeriod) { _, _ in
                HapticFeedback.selection()
            }

            // Month type toggle - show only when Month is selected
            if selectedPeriod == 2 {
                monthTypeSelector
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var monthTypeSelector: some View {
        HStack(spacing: 16) {
            Button(action: {
                monthViewType = 0
                HapticFeedback.selection()
            }) {
                HStack {
                    Image(systemName: monthViewType == 0 ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(monthViewType == 0 ? Color.blue : Color.secondary)
                    Text(localization.calendarMonthText)
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(PlainButtonStyle())

            Spacer()

            Button(action: {
                monthViewType = 1
                HapticFeedback.selection()
            }) {
                HStack {
                    Image(systemName: monthViewType == 1 ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(monthViewType == 1 ? Color.blue : Color.secondary)
                    Text(localization.fourWeeksPayText)
                        .foregroundStyle(.primary)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .padding(.horizontal)
    }
}