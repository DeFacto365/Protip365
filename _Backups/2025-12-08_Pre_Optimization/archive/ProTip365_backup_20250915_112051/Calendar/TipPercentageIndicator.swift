import SwiftUI

// MARK: - Tip Percentage Indicator
struct TipPercentageIndicator: View {
    let tips: Double
    let sales: Double
    let targetPercentage: Double
    @AppStorage("language") private var language = "en"

    private var actualPercentage: Double {
        guard sales > 0 else { return 0 }
        return (tips / sales) * 100
    }

    private var displayValue: String {
        String(format: "%.1f", actualPercentage)
    }

    private var progressColor: Color {
        if actualPercentage >= targetPercentage {
            return .green
        } else if actualPercentage >= targetPercentage * 0.8 { // Within 80% of target
            return .orange
        } else {
            return .red
        }
    }

    private var label: String {
        switch language {
        case "fr": return "Pourb. %"
        case "es": return "Prop. %"
        default: return "Tip %"
        }
    }

    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9))
                .fontWeight(.medium)
                .foregroundStyle(.secondary)

            ZStack {
                Circle()
                    .stroke(progressColor.opacity(0.2), lineWidth: 3)
                    .frame(width: 36, height: 36)

                Circle()
                    .trim(from: 0, to: min(actualPercentage / max(targetPercentage, 1), 1.0))
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: actualPercentage)

                VStack(spacing: 0) {
                    Text(displayValue)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("%")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.primary)
                }
            }

            Text("/ \(Int(targetPercentage))%")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}