import SwiftUI
import StoreKit

struct SubscriptionManagementView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) private var dismiss
    @AppStorage("language") private var language = "en"
    @State private var showManageSubscriptions = false
    @State private var showCancellationAlert = false
    @State private var showUpgradeAlert = false

    private var localization: SubscriptionManagementLocalization {
        SubscriptionManagementLocalization(language: language)
    }

    var body: some View {
        NavigationView {
            List {
                // Subscription Status Section
                Section {
                    SubscriptionStatusCard(subscriptionManager: subscriptionManager, localization: localization)
                }

                // Subscription Management Section
                Section(localization.manageSubscription) {
                    Button(action: {
                        showManageSubscriptions = true
                    }) {
                        HStack {
                            Text(localization.manageInAppStore)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.blue)
                        }
                    }

                    if subscriptionManager.isInTrialPeriod {
                        Button(action: {
                            showUpgradeAlert = true
                        }) {
                            HStack {
                                Text(localization.upgradeToPremium)
                                    .foregroundColor(.blue)
                                Spacer()
                                Text(subscriptionManager.product?.displayPrice ?? "N/A")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }

                // Usage Information Section
                Section("Usage Information") {
                    UsageStatsCard(subscriptionManager: subscriptionManager, localization: localization)

                    if subscriptionManager.isInTrialPeriod {
                        TrialProgressCard(subscriptionManager: subscriptionManager, localization: localization)
                    }
                }

                // Support Section
                Section("Support") {
                    NavigationLink(localization.subscriptionFAQ) {
                        SubscriptionFAQView(localization: localization, subscriptionManager: subscriptionManager)
                    }

                    Button(action: {
                        // Contact support
                        if let url = URL(string: "mailto:support@protip365.com?subject=Subscription%20Support") {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text(localization.contactSupport)
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle(localization.subscriptionTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showManageSubscriptions) {
                ManageSubscriptionsView(localization: localization)
            }
            .alert("Upgrade to Premium?", isPresented: $showUpgradeAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Upgrade") {
                    // Trigger upgrade flow
                    Task {
                        await subscriptionManager.purchase(productId: "com.protip365.premium.monthly")
                    }
                }
            } message: {
                Text(localization.upgradeMessage(for: subscriptionManager.product))
            }
        }
    }
}

struct SubscriptionStatusCard: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let localization: SubscriptionManagementLocalization

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(localization.currentPlan)
                    .font(.headline)
                Spacer()
                StatusBadge(status: subscriptionManager.getSubscriptionStatusText(), language: localization.language)
            }

            if subscriptionManager.isInTrialPeriod {
                Text("\(localization.trialEndsIn) \(subscriptionManager.trialDaysRemaining) \(localization.daysRemaining)")
                    .font(.subheadline)
                    .foregroundColor(.blue)
            } else if subscriptionManager.isSubscribed {
                Text(localization.premiumActive)
                    .font(.subheadline)
                    .foregroundColor(.green)
            }

            ProgressView(value: subscriptionManager.isInTrialPeriod ? Double(subscriptionManager.trialDaysRemaining) / 7.0 : 1.0)
                .tint(subscriptionManager.isInTrialPeriod ? .blue : .green)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatusBadge: View {
    let status: String
    let language: String

    var body: some View {
        Text(status)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(status.contains("Trial") || status.contains("Essai") ? Color.blue : Color.green)
            .foregroundColor(.white)
            .cornerRadius(8)
    }
}

struct UsageStatsCard: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let localization: SubscriptionManagementLocalization

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(localization.thisMonth)
                .font(.headline)

            HStack {
                VStack(alignment: .leading) {
                    Text(localization.shiftsLogged)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("12")
                        .font(.title2)
                        .bold()
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text(localization.earningsTracked)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("$2,847")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct TrialProgressCard: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    let localization: SubscriptionManagementLocalization

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(localization.trialProgress)
                .font(.headline)

            ProgressView(value: Double(subscriptionManager.trialDaysRemaining) / 7.0)
                .tint(.blue)

            Text("\(subscriptionManager.trialDaysRemaining) \(localization.daysRemaining)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}

struct ManageSubscriptionsView: View {
    @Environment(\.dismiss) private var dismiss
    let localization: SubscriptionManagementLocalization

    var body: some View {
        VStack {
            Text(localization.manageSubscriptions)
                .font(.headline)
                .padding()

            Text(localization.manageDescription)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)

            Spacer()

            Button(action: {
                // This would typically use SKPaymentQueue.showManageSubscriptions(in: .appStore)
                // For now, we'll just dismiss
                dismiss()
            }) {
                Text(localization.openAppStore)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
        .padding()
    }
}

struct SubscriptionFAQView: View {
    let localization: SubscriptionManagementLocalization
    @ObservedObject var subscriptionManager: SubscriptionManager
    
    var body: some View {
        List {
            Section(localization.trialSection) {
                FAQRow(question: localization.trialQuestion,
                       answer: localization.trialAnswer(for: subscriptionManager.product))

                FAQRow(question: localization.cancelQuestion,
                       answer: localization.cancelAnswer)

                FAQRow(question: localization.afterTrialQuestion,
                       answer: localization.afterTrialAnswer(for: subscriptionManager.product))
            }

            Section(localization.featuresSection) {
                FAQRow(question: localization.premiumQuestion,
                       answer: localization.premiumAnswer)

                FAQRow(question: localization.manageQuestion,
                       answer: localization.manageAnswer)

                FAQRow(question: localization.multipleDevicesQuestion,
                       answer: localization.multipleDevicesAnswer)
            }
        }
        .navigationTitle(localization.subscriptionFAQ)
    }
}

struct FAQRow: View {
    let question: String
    let answer: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question)
                .font(.headline)
            Text(answer)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Localization

struct SubscriptionManagementLocalization {
    let language: String

    var subscriptionTitle: String {
        switch language {
        case "fr": return "Abonnement"
        case "es": return "Suscripción"
        default: return "Subscription"
        }
    }

    var manageSubscription: String {
        switch language {
        case "fr": return "Gérer l'abonnement"
        case "es": return "Gestionar suscripción"
        default: return "Manage Subscription"
        }
    }

    var manageInAppStore: String {
        switch language {
        case "fr": return "Gérer dans l'App Store"
        case "es": return "Gestionar en App Store"
        default: return "Manage in App Store"
        }
    }

    var upgradeToPremium: String {
        switch language {
        case "fr": return "Passer à Premium"
        case "es": return "Actualizar a Premium"
        default: return "Upgrade to Premium"
        }
    }

    func upgradeMessage(for product: Product?) -> String {
        let priceString: String
        if let displayPrice = product?.displayPrice {
            priceString = displayPrice // Automatically localized
        } else {
            priceString = "$3.99" // fallback
        }
        
        switch language {
        case "fr":
            return "Convertir votre essai en un abonnement Premium complet pour \(priceString)/mois."
        case "es":
            return "Convierte tu prueba en una suscripción Premium completa por \(priceString)/mes."
        default:
            return "Convert your trial to a full Premium subscription for \(priceString)/month."
        }
    }


    var currentPlan: String {
        switch language {
        case "fr": return "Forfait actuel"
        case "es": return "Plan actual"
        default: return "Current Plan"
        }
    }

    var premiumActive: String {
        switch language {
        case "fr": return "Abonnement Premium actif"
        case "es": return "Suscripción Premium activa"
        default: return "Premium subscription active"
        }
    }

    var trialEndsIn: String {
        switch language {
        case "fr": return "L'essai se termine dans"
        case "es": return "La prueba termina en"
        default: return "Trial ends in"
        }
    }

    var thisMonth: String {
        switch language {
        case "fr": return "Ce mois"
        case "es": return "Este mes"
        default: return "This Month"
        }
    }

    var shiftsLogged: String {
        switch language {
        case "fr": return "Quarts enregistrés"
        case "es": return "Turnos registrados"
        default: return "Shifts Logged"
        }
    }

    var earningsTracked: String {
        switch language {
        case "fr": return "Revenus suivis"
        case "es": return "Ingresos rastreados"
        default: return "Earnings Tracked"
        }
    }

    var trialProgress: String {
        switch language {
        case "fr": return "Progression de l'essai"
        case "es": return "Progreso de la prueba"
        default: return "Trial Progress"
        }
    }

    var daysRemaining: String {
        switch language {
        case "fr": return "jours restants"
        case "es": return "días restantes"
        default: return "days remaining"
        }
    }

    var manageSubscriptions: String {
        switch language {
        case "fr": return "Gérer les abonnements"
        case "es": return "Gestionar suscripciones"
        default: return "Manage Subscriptions"
        }
    }

    var openAppStore: String {
        switch language {
        case "fr": return "Ouvrir l'App Store"
        case "es": return "Abrir App Store"
        default: return "Open App Store"
        }
    }

    var manageDescription: String {
        switch language {
        case "fr": return "Ouvrez l'App Store pour gérer les paramètres de votre abonnement, la facturation et les méthodes de paiement."
        case "es": return "Abre App Store para gestionar la configuración de tu suscripción, facturación y métodos de pago."
        default: return "Open App Store to manage your subscription settings, billing, and payment methods."
        }
    }

    var subscriptionFAQ: String {
        switch language {
        case "fr": return "FAQ Abonnement"
        case "es": return "FAQ de Suscripción"
        default: return "Subscription FAQ"
        }
    }

    var trialSection: String {
        switch language {
        case "fr": return "Essai et abonnement"
        case "es": return "Prueba y suscripción"
        default: return "Trial & Subscription"
        }
    }

    var featuresSection: String {
        switch language {
        case "fr": return "Fonctionnalités et facturation"
        case "es": return "Características y facturación"
        default: return "Features & Billing"
        }
    }

    var trialQuestion: String {
        switch language {
        case "fr": return "Comment fonctionne l'essai ?"
        case "es": return "¿Cómo funciona la prueba?"
        default: return "How does the trial work?"
        }
    }

    func trialAnswer(for product: Product?) -> String {
        let priceString: String
        if let displayPrice = product?.displayPrice {
            priceString = displayPrice // localized automatically
        } else {
            priceString = "$3.99" // fallback
        }

        switch language {
        case "fr":
            return "Vous bénéficiez de 7 jours d'accès Premium complet gratuit. Après l'essai, vous serez facturé \(priceString)/mois, sauf si vous annulez."
        case "es":
            return "Obtienes 7 días de acceso Premium completo gratis. Después de la prueba, se te cobrará \(priceString)/mes a menos que canceles."
        default:
            return "You get 7 days of full Premium access completely free. After the trial, you'll be charged \(priceString)/month unless you cancel."
        }
    }

    var cancelQuestion: String {
        switch language {
        case "fr": return "Puis-je annuler à tout moment ?"
        case "es": return "¿Puedo cancelar en cualquier momento?"
        default: return "Can I cancel anytime?"
        }
    }

    var cancelAnswer: String {
        switch language {
        case "fr": return "Oui ! Annulez à tout moment dans les paramètres de l'App Store. Vous garderez l'accès Premium jusqu'à la fin de votre période de facturation en cours."
        case "es": return "¡Sí! Cancela en cualquier momento en la configuración de App Store. Mantendrás el acceso Premium hasta el final de tu período de facturación actual."
        default: return "Yes! Cancel anytime in your App Store settings. You'll keep Premium access until the end of your current billing period."
        }
    }

    var afterTrialQuestion: String {
        switch language {
        case "fr": return "Que se passe-t-il après l'essai ?"
        case "es": return "¿Qué pasa después de la prueba?"
        default: return "What happens after the trial?"
        }
    }

    func afterTrialAnswer(for product: Product?) -> String {
        let priceString: String
        if let displayPrice = product?.displayPrice {
            priceString = displayPrice // localized automatically
        } else {
            priceString = "$3.99" // fallback
        }

        switch language {
        case "fr":
            return "Votre abonnement se convertira automatiquement en \(priceString)/mois. Vous pouvez annuler avant la fin de l'essai pour éviter les frais."
        case "es":
            return "Tu suscripción se convertirá automáticamente en \(priceString)/mes. Puedes cancelar antes de que termine la prueba para evitar cargos."
        default:
            return "Your subscription automatically converts to \(priceString)/month. You can cancel before the trial ends to avoid charges."
        }
    }


    var premiumQuestion: String {
        switch language {
        case "fr": return "Qu'est-ce qui est inclus dans Premium ?"
        case "es": return "¿Qué está incluido en Premium?"
        default: return "What's included in Premium?"
        }
    }

    var premiumAnswer: String {
        switch language {
        case "fr": return "Quarts illimités, employeurs multiples, analyses avancées, export de données et synchronisation cloud sur tous les appareils."
        case "es": return "Turnos ilimitados, múltiples empleadores, análisis avanzados, exportación de datos y sincronización en la nube en todos los dispositivos."
        default: return "Unlimited shifts, multiple employers, advanced analytics, data export, and cloud sync across devices."
        }
    }

    var manageQuestion: String {
        switch language {
        case "fr": return "Comment gérer mon abonnement ?"
        case "es": return "¿Cómo gestiono mi suscripción?"
        default: return "How do I manage my subscription?"
        }
    }

    var manageAnswer: String {
        switch language {
        case "fr": return "Allez dans Paramètres > Abonnement dans l'app, ou gérez via les paramètres d'abonnement de l'App Store."
        case "es": return "Ve a Configuración > Suscripción en la app, o gestiona a través de la configuración de suscripción de App Store."
        default: return "Go to Settings > Subscription in the app, or manage through the App Store subscription settings."
        }
    }

    var multipleDevicesQuestion: String {
        switch language {
        case "fr": return "Puis-je l'utiliser sur plusieurs appareils ?"
        case "es": return "¿Puedo usarlo en múltiples dispositivos?"
        default: return "Can I use it on multiple devices?"
        }
    }

    var multipleDevicesAnswer: String {
        switch language {
        case "fr": return "Oui ! Votre abonnement se synchronise sur tous vos appareils iOS utilisant le même Apple ID."
        case "es": return "¡Sí! Tu suscripción se sincroniza en todos tus dispositivos iOS usando el mismo Apple ID."
        default: return "Yes! Your subscription syncs across all your iOS devices using the same Apple ID."
        }
    }

    var contactSupport: String {
        switch language {
        case "fr": return "Contacter le support"
        case "es": return "Contactar soporte"
        default: return "Contact Support"
        }
    }
}
