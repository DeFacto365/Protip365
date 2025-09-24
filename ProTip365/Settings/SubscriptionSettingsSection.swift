import SwiftUI

struct SubscriptionSettingsSection: View {
    @EnvironmentObject var subscriptionManager: SubscriptionManager
    @State private var showSubscriptionView = false
    let language: String

    private var localization: SubscriptionSectionLocalization {
        SubscriptionSectionLocalization(language: language)
    }

    var body: some View {
        VStack(spacing: 20) {
            // Section header
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(.yellow)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 28, height: 28)
                Text(localization.subscriptionSection)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Spacer()
            }

            // Current subscription status
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(localization.currentPlanLabel)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(currentPlanName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(planColor)
                }

                // Show limits for part-time tier
                if subscriptionManager.currentTier == .partTime {
                    VStack(spacing: 8) {
                        // Weekly limits
                        HStack {
                            Label(localization.weeklyLimitsLabel, systemImage: "calendar.badge.clock")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }

                        HStack(spacing: 20) {
                            // Shifts limit
                            HStack(spacing: 4) {
                                Text("\(subscriptionManager.currentWeekShifts)/3")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                Text(localization.shiftsText)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }

                            // Entries limit
                            HStack(spacing: 4) {
                                Text("\(subscriptionManager.currentWeekEntries)/3")
                                    .font(.footnote)
                                    .fontWeight(.medium)
                                Text(localization.entriesText)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Action button
                if subscriptionManager.currentTier == .none {
                    // Subscribe button
                    Button(action: {
                        HapticFeedback.selection()
                        showSubscriptionView = true
                    }) {
                        HStack {
                            Text(localization.subscribeButton)
                                .foregroundStyle(.white)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: IconNames.Form.next)
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if subscriptionManager.currentTier == .partTime {
                    // Upgrade button
                    Button(action: {
                        HapticFeedback.selection()
                        showSubscriptionView = true
                    }) {
                        HStack {
                            Text(localization.upgradeButton)
                                .foregroundStyle(.white)
                                .font(.body)
                                .fontWeight(.medium)
                            Spacer()
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundStyle(.white)
                                .font(.body)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(
                        colors: [Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else {
                    // Manage subscription button
                    Button(action: {
                        HapticFeedback.selection()
                        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text(localization.manageButton)
                                .foregroundStyle(.primary)
                                .font(.body)
                            Spacer()
                            Image(systemName: IconNames.Form.next)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: Constants.cornerRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .sheet(isPresented: $showSubscriptionView) {
            SubscriptionTiersView(subscriptionManager: subscriptionManager)
        }
    }

    private var currentPlanName: String {
        switch subscriptionManager.currentTier {
        case .none:
            return localization.noPlanText
        case .partTime:
            return localization.partTimePlanText
        case .fullAccess:
            if subscriptionManager.isInTrialPeriod {
                return localization.fullAccessTrialText
            } else {
                return localization.fullAccessPlanText
            }
        }
    }

    private var planColor: Color {
        switch subscriptionManager.currentTier {
        case .none:
            return .secondary
        case .partTime:
            return .blue
        case .fullAccess:
            return .green
        }
    }
}

// MARK: - Localization

struct SubscriptionSectionLocalization {
    let language: String

    var subscriptionSection: String {
        switch language {
        case "fr": return "Abonnement"
        case "es": return "Suscripción"
        default: return "Subscription"
        }
    }

    var currentPlanLabel: String {
        switch language {
        case "fr": return "Forfait actuel"
        case "es": return "Plan actual"
        default: return "Current Plan"
        }
    }

    var weeklyLimitsLabel: String {
        switch language {
        case "fr": return "Limites hebdomadaires"
        case "es": return "Límites semanales"
        default: return "Weekly Limits"
        }
    }

    var shiftsText: String {
        switch language {
        case "fr": return "quarts"
        case "es": return "turnos"
        default: return "shifts"
        }
    }

    var entriesText: String {
        switch language {
        case "fr": return "entrées"
        case "es": return "entradas"
        default: return "entries"
        }
    }

    var subscribeButton: String {
        switch language {
        case "fr": return "S'abonner"
        case "es": return "Suscribirse"
        default: return "Subscribe"
        }
    }

    var upgradeButton: String {
        switch language {
        case "fr": return "Passer à l'accès complet"
        case "es": return "Actualizar a acceso completo"
        default: return "Upgrade to Full Access"
        }
    }

    var manageButton: String {
        switch language {
        case "fr": return "Gérer l'abonnement"
        case "es": return "Gestionar suscripción"
        default: return "Manage Subscription"
        }
    }

    var noPlanText: String {
        switch language {
        case "fr": return "Aucun"
        case "es": return "Ninguno"
        default: return "None"
        }
    }

    var partTimePlanText: String {
        switch language {
        case "fr": return "Temps partiel"
        case "es": return "Tiempo parcial"
        default: return "Part-time"
        }
    }

    var fullAccessPlanText: String {
        switch language {
        case "fr": return "Accès complet"
        case "es": return "Acceso completo"
        default: return "Full Access"
        }
    }

    var fullAccessTrialText: String {
        switch language {
        case "fr": return "Accès complet (Essai)"
        case "es": return "Acceso completo (Prueba)"
        default: return "Full Access (Trial)"
        }
    }
}