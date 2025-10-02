import SwiftUI

struct SubscriptionManagementSection: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let language: String

    private var localization: SettingsLocalization {
        SettingsLocalization(language: language)
    }

    var body: some View {
        // Only show this section if user has an active subscription or is in trial
        if subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod {
            VStack(alignment: .leading, spacing: 16) {
                // Section Header with Icon
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(.yellow)
                        .symbolRenderingMode(.hierarchical)
                        .frame(width: 28, height: 28)
                    Text(subscriptionTitle)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }

                // Subscription Status
                HStack {
                    Text(statusLabel)
                        .foregroundStyle(.primary)
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: statusIcon)
                            .font(.caption)
                            .foregroundStyle(statusColor)
                        Text(statusText)
                            .font(.subheadline)
                            .foregroundStyle(statusColor)
                    }
                }

            // Trial Days Remaining (if in trial)
            if subscriptionManager.isInTrialPeriod {
                HStack {
                    Text(trialLabel)
                        .foregroundStyle(.primary)
                    Spacer()
                    Text(trialDaysText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

                // Manage Subscription Button
                Button(action: {
                    if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                        UIApplication.shared.open(url)
                    }
                }) {
                    HStack {
                        Text(manageButtonText)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "arrow.up.forward.square")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
            .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        }
    }

    // MARK: - Computed Properties

    private var subscriptionTitle: String {
        switch language {
        case "fr": return "Abonnement"
        case "es": return "Suscripción"
        default: return "Subscription"
        }
    }

    private var statusLabel: String {
        switch language {
        case "fr": return "Statut"
        case "es": return "Estado"
        default: return "Status"
        }
    }

    private var trialLabel: String {
        switch language {
        case "fr": return "Essai restant"
        case "es": return "Prueba restante"
        default: return "Trial Remaining"
        }
    }

    private var manageButtonText: String {
        switch language {
        case "fr": return "Gérer l'abonnement"
        case "es": return "Administrar suscripción"
        default: return "Manage Subscription"
        }
    }

    private var statusText: String {
        if subscriptionManager.isInTrialPeriod {
            switch language {
            case "fr": return "Période d'essai"
            case "es": return "Período de prueba"
            default: return "Trial Period"
            }
        } else if subscriptionManager.isSubscribed {
            switch language {
            case "fr": return "Premium Actif"
            case "es": return "Premium Activo"
            default: return "Premium Active"
            }
        } else {
            switch language {
            case "fr": return "Inactif"
            case "es": return "Inactivo"
            default: return "Inactive"
            }
        }
    }

    private var statusIcon: String {
        if subscriptionManager.isInTrialPeriod {
            return "clock.fill"
        } else if subscriptionManager.isSubscribed {
            return "checkmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        if subscriptionManager.isInTrialPeriod {
            return .blue
        } else if subscriptionManager.isSubscribed {
            return .green
        } else {
            return .red
        }
    }

    private var trialDaysText: String {
        let days = subscriptionManager.trialDaysRemaining
        switch language {
        case "fr": return "\(days) jour\(days > 1 ? "s" : "")"
        case "es": return "\(days) día\(days > 1 ? "s" : "")"
        default: return "\(days) day\(days > 1 ? "s" : "")"
        }
    }
}
