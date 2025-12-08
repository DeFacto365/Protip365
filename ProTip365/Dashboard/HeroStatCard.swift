import SwiftUI

// MARK: - Hero Stat Card (Total Earnings)
struct HeroStatCard: View {
    let title: String
    let value: String // Keep for fallback or other formatting
    let rawValue: Double // For animation
    let subtitle: String?
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.secondary)
                .tracking(1) // Add letter spacing for premium look
            
            RollingNumberText(value: rawValue, font: .system(size: 42, weight: .heavy, design: .rounded), weight: .heavy, color: .clear) // Color clear because we overlay gradient
                .foregroundStyle(
                    BreathingGradient(colors: [color, color.opacity(0.7), color.opacity(0.9)])
                )
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .padding(.vertical, 4)
            
            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground)
                    .opacity(0.7)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: color.opacity(0.15), radius: 15, x: 0, y: 8)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(LinearGradient(colors: [.white.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
}

// MARK: - Vertical Stat Card (Grid Item)
struct VerticalStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    var caption: String? = nil
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    
                    if let caption = caption {
                        Text(caption)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                Rectangle().fill(.ultraThinMaterial)
                Color(colorScheme == .dark ? .secondarySystemBackground : .systemBackground)
                    .opacity(0.7)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.white.opacity(0.2), lineWidth: 1)
        )
    }
}
