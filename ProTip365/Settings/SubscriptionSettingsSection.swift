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

                // Show trial status if in trial
                if subscriptionManager.isInTrialPeriod {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text(localization.trialDaysRemaining(subscriptionManager.trialDaysRemaining))
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Show benefits for premium subscribers
                if subscriptionManager.currentTier == .premium && !subscriptionManager.isInTrialPeriod {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(localization.unlimitedTracking, systemImage: "infinity")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Label(localization.allFeaturesUnlocked, systemImage: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color.green.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                // Action button
                if subscriptionManager.currentTier == .none {
                    // Subscribe button with trial info
                    Button(action: {
                        HapticFeedback.selection()
                        showSubscriptionView = true
                    }) {
                        VStack(spacing: 4) {
                            HStack {
                                Text(localization.startFreeTrialButton)
                                    .foregroundStyle(.white)
                                    .font(.body)
                                    .fontWeight(.medium)
                                Spacer()
                                Image(systemName: "arrow.right.circle.fill")
                                    .foregroundStyle(.white)
                                    .font(.body)
                            }
                            Text(localization.trialInfoText)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.9))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                } else if subscriptionManager.isInTrialPeriod {
                    // View subscription button during trial
                    Button(action: {
                        HapticFeedback.selection()
                        showSubscriptionView = true
                    }) {
                        HStack {
                            Text(localization.viewSubscriptionButton)
                                .foregroundStyle(.primary)
                                .font(.body)
                            Spacer()
                            Text(localization.priceText)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Image(systemName: IconNames.Form.next)
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                } else {
                    // Manage subscription button for active subscribers - now shows in-app management
                    Button(action: {
                        HapticFeedback.selection()
                        // Navigate to in-app subscription management
                        NotificationCenter.default.post(name: NSNotification.Name("ShowSubscriptionManagement"), object: nil)
                    }) {
                        HStack {
                            Text("Manage Subscription")
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
        case .premium:
            if subscriptionManager.isInTrialPeriod {
                return localization.premiumTrialText
            } else {
                return localization.premiumPlanText
            }
        case .free:
            return localization.noPlanText
        }
    }

    private var planColor: Color {
        switch subscriptionManager.currentTier {
        case .none:
            return .secondary
        case .premium:
            return subscriptionManager.isInTrialPeriod ? .blue : .green
        case .free:
            return .secondary
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

    var startFreeTrialButton: String {
        switch language {
        case "fr": return "Commencer l'essai gratuit"
        case "es": return "Comenzar prueba gratis"
        default: return "Start Free Trial"
        }
    }

    var trialInfoText: String {
        switch language {
        case "fr": return "7 jours gratuits, puis 3,99$/mois"
        case "es": return "7 días gratis, luego $3.99/mes"
        default: return "7 days free, then $3.99/month"
        }
    }

    var viewSubscriptionButton: String {
        switch language {
        case "fr": return "Voir l'abonnement"
        case "es": return "Ver suscripción"
        default: return "View Subscription"
        }
    }

    var priceText: String {
        switch language {
        case "fr": return "3,99$/mois"
        case "es": return "$3.99/mes"
        default: return "$3.99/mo"
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

    var premiumPlanText: String {
        switch language {
        case "fr": return "Premium"
        case "es": return "Premium"
        default: return "Premium"
        }
    }

    var premiumTrialText: String {
        switch language {
        case "fr": return "Premium (Essai)"
        case "es": return "Premium (Prueba)"
        default: return "Premium (Trial)"
        }
    }

    func trialDaysRemaining(_ days: Int) -> String {
        switch language {
        case "fr": return "\(days) jours restants"
        case "es": return "\(days) días restantes"
        default: return "\(days) days remaining"
        }
    }

    var unlimitedTracking: String {
        switch language {
        case "fr": return "Suivi illimité"
        case "es": return "Seguimiento ilimitado"
        default: return "Unlimited tracking"
        }
    }

    var allFeaturesUnlocked: String {
        switch language {
        case "fr": return "Toutes les fonctionnalités débloquées"
        case "es": return "Todas las funciones desbloqueadas"
        default: return "All features unlocked"
        }
    }
}