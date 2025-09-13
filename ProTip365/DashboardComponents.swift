import SwiftUI

// MARK: - Enhanced Glass Stat Card Component
struct GlassStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let subtitle: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
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
