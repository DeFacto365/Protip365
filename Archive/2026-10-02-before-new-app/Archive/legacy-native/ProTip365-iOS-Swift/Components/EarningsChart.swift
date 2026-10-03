import SwiftUI
import Charts

struct DailyEarnings: Identifiable {
    let id = UUID()
    let day: String
    let amount: Double
    let isToday: Bool
}

struct EarningsChart: View {
    // Week Data: Mon -> Sun
    let data: [DailyEarnings]
    let totalForWeek: Double
    
    // Aesthetic: "Liquid Glass" Theme
    // We use a gradient for the bars
    let barGradient = LinearGradient(
        colors: [
            Color.blue.opacity(0.8),
            Color.cyan.opacity(0.6)
        ],
        startPoint: .bottom,
        endPoint: .top
    )
    
    let highlightGradient = LinearGradient(
        colors: [
            Color.yellow.opacity(0.9),
            Color.orange.opacity(0.7)
        ],
        startPoint: .bottom,
        endPoint: .top
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Weekly Trend")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .textCase(.uppercase)
                    
                    Text(formatCurrency(totalForWeek))
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
                Spacer()
                
                // Trend Indicator (Mock for now, easy to wire up later)
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                    Text("12%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .foregroundStyle(.green)
            }
            
            // Chart
            Chart {
                ForEach(data) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Earnings", item.amount)
                    )
                    .foregroundStyle(item.isToday ? highlightGradient : barGradient)
                    .cornerRadius(4)
                }
                
                // Rule mark for average (optional, adds context)
                if !data.isEmpty {
                    let avg = totalForWeek / Double(data.count)
                    RuleMark(y: .value("Average", avg))
                        .foregroundStyle(.gray.opacity(0.3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        .annotation(position: .leading) {
                            Text("Avg")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                }
            }
            .chartYAxis(.hidden) // Cleaner look
            .chartXAxis {
                AxisMarks(values: .automatic) { _ in
                    AxisValueLabel()
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
        // Add subtle border for glass effect
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(.white.opacity(0.2), lineWidth: 1)
        )
        // Shadow for depth
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: amount)) ?? "$0"
    }
}

// Preview Provider
#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        EarningsChart(data: [
            DailyEarnings(day: "Mon", amount: 150, isToday: false),
            DailyEarnings(day: "Tue", amount: 320, isToday: false),
            DailyEarnings(day: "Wed", amount: 0, isToday: false),
            DailyEarnings(day: "Thu", amount: 410, isToday: false),
            DailyEarnings(day: "Fri", amount: 550, isToday: true), // Highlight
            DailyEarnings(day: "Sat", amount: 0, isToday: false),
            DailyEarnings(day: "Sun", amount: 0, isToday: false)
        ], totalForWeek: 1430)
        .padding()
    }
}
