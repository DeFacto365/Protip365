import SwiftUI

// MARK: - Sales Progress Indicator
struct SalesProgressIndicator: View {
    let actual: Double
    let target: Double
    @AppStorage("language") private var language = "en"

    private var percentage: Double {
        guard target > 0 else { return 0 }
        return (actual / target) * 100
    }

    private var displayValue: String {
        "\(Int(percentage))"
    }

    private var progressColor: Color {
        if percentage >= 100 {
            return .green
        } else if percentage >= 75 {
            return .blue
        } else if percentage >= 50 {
            return .orange
        } else {
            return .red
        }
    }

    private var label: String {
        switch language {
        case "fr": return "Ventes"
        case "es": return "Ventas"
        default: return "Sales"
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
                    .trim(from: 0, to: min(percentage / 100, 1.0))
                    .stroke(progressColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 36, height: 36)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.3), value: percentage)

                VStack(spacing: 0) {
                    Text(displayValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.primary)
                    Text("%")
                        .font(.system(size: 7, weight: .medium))
                        .foregroundStyle(.primary)
                }
            }

            Text("$\(Int(target))")
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
    }
}