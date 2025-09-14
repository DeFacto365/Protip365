import SwiftUI

// MARK: - Enhanced Glass Stat Card Component
struct GlassStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String?
    let budget: String? = nil // Optional budget value
    @AppStorage("language") private var language = "en"

    init(title: String, value: String, icon: String, color: Color, subtitle: String? = nil, budget: String? = nil) {
        self.title = title
        self.value = value
        self.icon = icon
        self.color = color
        self.subtitle = subtitle
    }

    private var actualText: String {
        switch language {
        case "fr": return "Actuel:"
        case "es": return "Real:"
        default: return "Actual:"
        }
    }

    private var budgetText: String {
        switch language {
        case "fr": return "Budget:"
        case "es": return "Presupuesto:"
        default: return "Budget:"
        }
    }

    var body: some View {
        let _ = print("🎯 GlassStatCard: \(title) = \(value), has slash: \(value.contains("/"))")
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .symbolRenderingMode(.hierarchical)
                    .modifier(GlassEffectModifier())
                    .frame(width: 32, height: 32)

                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)

                // Check if value contains "/" (indicating value/budget format)
                if value.contains("/") {
                    let components = value.split(separator: "/", maxSplits: 1)
                    if components.count == 2 {
                        // Two-row format for value and budget
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Text(actualText)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 45, alignment: .leading)
                                Text(String(components[0]))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            HStack(spacing: 8) {
                                Text(budgetText)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .frame(width: 45, alignment: .leading)
                                Text(String(components[1]))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.secondary)
                            }
                        }
                    } else {
                        Text(value)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(.primary)
                            .minimumScaleFactor(0.6)
                            .lineLimit(1)
                    }
                } else {
                    Text(value)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                }

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
        .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Compact Glass Stat Card (for Year View)
struct CompactGlassStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String?

    var body: some View {
        let _ = print("📊 Compact Card: \(title) = \(value)")
        return HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)
                .modifier(GlassEffectModifier())
                .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                if let subtitle = subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.primary)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    let period: Int
    let language: String
    
    var message: String {
        switch period {
        case 0:
            switch language {
            case "fr": return "Aucune donnée pour aujourd'hui"
            case "es": return "Sin datos para hoy"
            default: return "No shifts recorded today"
            }
        case 1:
            switch language {
            case "fr": return "Aucune donnée cette semaine"
            case "es": return "Sin datos esta semana"
            default: return "No shifts this week"
            }
        default:
            switch language {
            case "fr": return "Aucune donnée ce mois"
            case "es": return "Sin datos este mes"
            default: return "No shifts this month"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .modifier(GlassEffectModifier())
                .frame(width: 64, height: 64)
            
            Text(message)
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .modifier(GlassEffectRoundedModifier(cornerRadius: Constants.cornerRadius))
        .shadow(color: .blue.opacity(0.1), radius: 12, x: 0, y: 6)
    }
}
