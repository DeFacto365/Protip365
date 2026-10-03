import SwiftUI

/// Period selector component for Dashboard view
struct DashboardPeriodSelector: View {
    @Binding var selectedPeriod: Int
    @Binding var monthViewType: Int

    let localization: DashboardLocalization
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: 12) {
            // Main period selector
            Picker("Period", selection: $selectedPeriod) {
                Text("Today").tag(0)
                Text("Week").tag(1)
                Text("Month").tag(2)
                Text("Year").tag(3)
            }
            .pickerStyle(.segmented)
            .padding()
            .liquidGlassCard()
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
        .liquidGlassCard()
        .padding(.horizontal)
    }
}