import SwiftUI
import StoreKit

struct SubscriptionTiersView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    var onContinueAnyway: (() -> Void)?
    @AppStorage("language") private var language = "en"
    @State private var isLoading = false
    @State private var selectedProductId: String? = nil
    @State private var showOnboarding = false
    @State private var loadError: String? = nil
    @State private var isLoadingProducts = false
    @Environment(\.dismiss) private var dismiss
    @State private var showErrorAlert = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    headerView

                    // Current subscription status (if applicable)
                    if subscriptionManager.isSubscribed && !subscriptionManager.isInTrialPeriod {
                        currentSubscriptionView
                    } else if subscriptionManager.isInTrialPeriod {
                        trialStatusView
                    }

                    // Show loading state if products aren't loaded
                    if isLoadingProducts {
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.2)
                            Text(loadingProductsText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 40)
                    } else if let error = loadError {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.largeTitle)
                                .foregroundStyle(.orange)
                            Text(errorLoadingText)
                                .font(.headline)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button(retryText) {
                                Task {
                                    await loadProductsWithTimeout()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(.vertical, 40)
                        .padding(.horizontal)
                    } else if subscriptionManager.products.isEmpty {
                        // Products failed to load - show clear message
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.orange)

                            Text("Can't Connect to App Store")
                                .font(.title2)
                                .fontWeight(.bold)

                            Text("We're having trouble loading subscription options. You can try again or continue using the app.")
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)

                            VStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        await loadProductsWithTimeout()
                                    }
                                }) {
                                    Label("Try Again", systemImage: "arrow.clockwise")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }

                                Button(action: {
                                    // Use the callback to bypass subscription
                                    if let onContinueAnyway = onContinueAnyway {
                                        onContinueAnyway()
                                    } else {
                                        dismiss()
                                    }
                                }) {
                                    Text("Continue Without Subscription")
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.green)
                                        .foregroundStyle(.white)
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 40)
                    } else {
                        // Single Premium tier
                        VStack(spacing: 20) {
                            SubscriptionTierCard(
                                tierName: premiumTitle,
                                description: premiumDescription,
                                features: premiumFeatures,
                                monthlyPrice: "$3.99",
                                yearlyPrice: nil, // No yearly option for now
                                monthlyProductId: "com.protip365.premium.monthly",
                                yearlyProductId: nil,
                                isCurrentTier: subscriptionManager.currentTier == .premium,
                                hasTrial: true,
                                isLoading: $isLoading,
                                selectedProductId: $selectedProductId,
                                language: language,
                                onPurchase: { productId in
                                    await purchase(productId: productId)
                                }
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Restore purchases button
                    restorePurchasesButton

                    // Don't show duplicate continue button since we already have it above

                    // Terms
                    termsText
                }
                .padding(.vertical, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if subscriptionManager.isSubscribed {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(cancelText) {
                            dismiss()
                        }
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isAuthenticated: .constant(true), showOnboarding: $showOnboarding)
        }
        .alert("Purchase Failed", isPresented: $showErrorAlert) {
                    Button("OK", role: .cancel) { }
                } message: {
                    if let errorMessage = subscriptionManager.purchaseError {
                        Text(errorMessage)
                    } else {
                        Text("An error occurred. Please try again.")
                    }
                }
        .task {
            await loadProductsWithTimeout()
        }
    }

    // MARK: - Views

    private var headerView: some View {
        VStack(spacing: 15) {
            Image("Logo2")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Text(headerTitle)
                .font(.system(size: 28, weight: .bold))
                .multilineTextAlignment(.center)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)

            Text(headerSubtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineLimit(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 20)
        }
        .padding(.top)
        .padding(.horizontal)
    }

    private var currentSubscriptionView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(currentPlanText)
                    .fontWeight(.medium)
            }

            Text(enjoyingPremiumText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var trialStatusView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .foregroundStyle(.blue)
                Text(trialStatusText)
                    .fontWeight(.medium)
            }

            Text("\(subscriptionManager.trialDaysRemaining) \(daysRemainingText)")
                .font(.title2)
                .fontWeight(.bold)

            Text(trialInfoText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
    }

    private var restorePurchasesButton: some View {
        VStack(spacing: 10) {
            Button(action: {
                Task {
                    isLoading = true
                    // First try to restore/sync existing purchases
                    await subscriptionManager.checkAndSyncExistingSubscription()
                    // Then check subscription status
                    await subscriptionManager.checkSubscriptionStatus()
                    isLoading = false

                    if subscriptionManager.isSubscribed {
                        HapticFeedback.success()
                        dismiss()
                    }
                }
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise.circle.fill")
                    Text(restoreButton)
                }
                .foregroundStyle(.tint)
            }
            .disabled(isLoading)

            Text(restoreHelpText)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var termsText: some View {
        Text(termsString(for: subscriptionManager.product))
            .font(.caption)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 40)
    }

    // MARK: - Actions

    private func loadProductsWithTimeout() async {
        guard !isLoadingProducts else { return }

        await MainActor.run {
            isLoadingProducts = true
            loadError = nil
        }

        // Create a timeout task
        let timeoutTask = Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
            await MainActor.run {
                if isLoadingProducts {
                    loadError = timeoutErrorText
                    isLoadingProducts = false
                }
            }
        }

        // Try to load products
        await subscriptionManager.loadProducts()
        timeoutTask.cancel()

        await MainActor.run {
            isLoadingProducts = false
            if subscriptionManager.products.isEmpty {
                loadError = noProductsFoundText
            }
        }
    }

    private func purchase(productId: String) async {
        isLoading = true
        selectedProductId = productId

        do {
            try await subscriptionManager.purchase(productId: productId)
            
            await MainActor.run {
                isLoading = false
                selectedProductId = nil

                if subscriptionManager.isSubscribed {
                    if !subscriptionManager.isInTrialPeriod {
                        dismiss()
                    } else {
                        showOnboarding = true
                    }
                }
            }
        } catch {
            await MainActor.run {
                isLoading = false
                selectedProductId = nil
                showErrorAlert = true  // Show alert on error
            }
        }
    }

    // MARK: - Localization

    var navigationTitle: String {
        switch language {
        case "fr": return "Abonnement Premium"
        case "es": return "Suscripción Premium"
        default: return "Premium Subscription"
        }
    }

    var cancelText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

    var headerTitle: String {
        switch language {
        case "fr": return "Suivez Chaque Pourboire.\nGérez Chaque Quart.\nAccédez à Vos Données Partout."
        case "es": return "Rastrea Cada Propina.\nGestiona Cada Turno.\nAccede a Tus Datos en Todas Partes."
        default: return "Track Every Tip.\nManage Every Shift.\nAccess Your Data Anywhere."
        }
    }

    var headerSubtitle: String {
        switch language {
        case "fr": return "L'application intelligente de suivi des pourboires conçue pour les professionnels de l'industrie des services qui veulent remplacer les reçus papier et les fichiers Excel par une gestion des données en temps réel sur tous leurs appareils."
        case "es": return "La aplicación inteligente de seguimiento de propinas diseñada para profesionales de la industria de servicios que desean reemplazar recibos de papel y archivos de Excel con gestión de datos en tiempo real en todos sus dispositivos."
        default: return "The smart tip tracking app designed for service industry professionals who want to replace paper slips and Excel files with real-time data management across all their devices."
        }
    }

    var currentPlanText: String {
        switch language {
        case "fr": return "Abonnement Premium Actif"
        case "es": return "Suscripción Premium Activa"
        default: return "Premium Subscription Active"
        }
    }

    var enjoyingPremiumText: String {
        switch language {
        case "fr": return "Profitez de toutes les fonctionnalités premium"
        case "es": return "Disfruta de todas las funciones premium"
        default: return "Enjoying all premium features"
        }
    }

    var trialStatusText: String {
        switch language {
        case "fr": return "Période d'essai"
        case "es": return "Período de prueba"
        default: return "Trial Period"
        }
    }

    var daysRemainingText: String {
        switch language {
        case "fr": return "jours restants"
        case "es": return "días restantes"
        default: return "days remaining"
        }
    }

    var trialInfoText: String {
        switch language {
        case "fr": return "Profitez de toutes les fonctionnalités. Annulez à tout moment."
        case "es": return "Disfruta de todas las funciones. Cancela en cualquier momento."
        default: return "Enjoy all features. Cancel anytime."
        }
    }

    var premiumTitle: String {
        switch language {
        case "fr": return "ProTip365 Premium"
        case "es": return "ProTip365 Premium"
        default: return "ProTip365 Premium"
        }
    }

    var premiumDescription: String {
        switch language {
        case "fr": return "Tout ce dont vous avez besoin pour gérer vos revenus de pourboires"
        case "es": return "Todo lo que necesitas para gestionar tus ingresos por propinas"
        default: return "Everything you need to manage your tip income"
        }
    }

    var premiumFeatures: [String] {
        switch language {
        case "fr": return [
            "Suivi illimité des quarts de travail par jour",
            "Gestion de plusieurs employeurs",
            "Analyses avancées et rapports détaillés",
            "Export de données (CSV/PDF)",
            "Synchronisation automatique dans le cloud",
            "Support prioritaire"
        ]
        case "es": return [
            "Turnos ilimitados por día",
            "Gestión de múltiples empleadores",
            "Análisis avanzados e informes detallados",
            "Exportación de datos (CSV/PDF)",
            "Sincronización automática en la nube",
            "Soporte prioritario"
        ]
        default: return [
            "Unlimited shifts per day",
            "Multiple employer management",
            "Advanced analytics and detailed reports",
            "Data export (CSV/PDF)",
            "Automatic cloud synchronization",
            "Priority support"
        ]
        }
    }

    var restoreButton: String {
        switch language {
        case "fr": return "Restaurer les achats"
        case "es": return "Restaurar compras"
        default: return "Restore Purchases"
        }
    }

    var restoreHelpText: String {
        switch language {
        case "fr": return "Si vous avez déjà un abonnement, cliquez ici pour l'activer"
        case "es": return "Si ya tiene una suscripción, haga clic aquí para activarla"
        default: return "If you already have a subscription, tap here to activate it"
        }
    }

    func termsString(for product: Product?) -> String {
        let priceString: String
        if let displayPrice = product?.displayPrice {
            priceString = displayPrice // Auto-localized by App Store region
        } else {
            priceString = "$3.99" // Fallback
        }

        switch language {
        case "fr":
            return "Essai gratuit de 7 jours, puis \(priceString)/mois. L'abonnement se renouvelle automatiquement. Annulez à tout moment dans les paramètres de l'App Store."
        case "es":
            return "Prueba gratuita de 7 días, luego \(priceString)/mes. La suscripción se renueva automáticamente. Cancele en cualquier momento en la configuración de App Store."
        default:
            return "7-day free trial, then \(priceString)/month. Subscription auto-renews. Cancel anytime in App Store settings."
        }
    }

    var retryText: String {
        switch language {
        case "fr": return "Réessayer"
        case "es": return "Reintentar"
        default: return "Retry"
        }
    }

    var loadingProductsText: String {
        switch language {
        case "fr": return "Chargement de l'abonnement..."
        case "es": return "Cargando suscripción..."
        default: return "Loading subscription..."
        }
    }

    var errorLoadingText: String {
        switch language {
        case "fr": return "Erreur de chargement"
        case "es": return "Error al cargar"
        default: return "Loading Error"
        }
    }

    var noProductsText: String {
        switch language {
        case "fr": return "Abonnement non disponible"
        case "es": return "Suscripción no disponible"
        default: return "Subscription Unavailable"
        }
    }

    var noProductsDetailText: String {
        switch language {
        case "fr": return "Veuillez vérifier votre connexion et réessayer"
        case "es": return "Por favor, verifique su conexión e intente nuevamente"
        default: return "Please check your connection and try again"
        }
    }

    var timeoutErrorText: String {
        switch language {
        case "fr": return "Le chargement a pris trop de temps. Veuillez réessayer."
        case "es": return "La carga tardó demasiado. Por favor, inténtelo de nuevo."
        default: return "Loading took too long. Please try again."
        }
    }

    var noProductsFoundText: String {
        switch language {
        case "fr": return "Aucun abonnement trouvé. Assurez-vous d'être connecté à l'App Store."
        case "es": return "No se encontró ninguna suscripción. Asegúrese de estar conectado a App Store."
        default: return "No subscription found. Make sure you're connected to App Store."
        }
    }
}

// Simplified Subscription Tier Card for single tier
struct SubscriptionTierCard: View {
    let tierName: String
    let description: String
    let features: [String]
    let monthlyPrice: String
    let yearlyPrice: String?
    let monthlyProductId: String
    let yearlyProductId: String?
    let isCurrentTier: Bool
    var isUpgrade: Bool = false
    var hasTrial: Bool = false
    @Binding var isLoading: Bool
    @Binding var selectedProductId: String?
    let language: String
    let onPurchase: (String) async -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 8) {
                Text(tierName)
                    .font(.title2)
                    .fontWeight(.bold)

                if hasTrial {
                    HStack {
                        Image(systemName: "gift.fill")
                            .foregroundStyle(.green)
                        Text(trialBadgeText)
                            .foregroundStyle(.green)
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                }

                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Price
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(monthlyPrice)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text(perMonthText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if hasTrial {
                    Text(afterTrialText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            // Features
            VStack(alignment: .leading, spacing: 12) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.system(size: 20))
                        Text(feature)
                            .font(.subheadline)
                        Spacer()
                    }
                }
            }
            .padding()
            .background(Color(.tertiarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 10))

            // Purchase button
            if !isCurrentTier {
                Button(action: {
                    Task {
                        await onPurchase(monthlyProductId)
                    }
                }) {
                    if isLoading && selectedProductId == monthlyProductId {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(subscribeButtonText)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .disabled(isLoading)
            } else {
                // Current plan indicator
                Label(currentPlanText, systemImage: "checkmark.circle.fill")
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.green.opacity(0.1))
                    .foregroundStyle(.green)
                    .fontWeight(.medium)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // Localization
    var trialBadgeText: String {
        switch language {
        case "fr": return "7 JOURS GRATUITS"
        case "es": return "7 DÍAS GRATIS"
        default: return "7 DAYS FREE"
        }
    }

    var perMonthText: String {
        switch language {
        case "fr": return "/mois"
        case "es": return "/mes"
        default: return "/month"
        }
    }

    var afterTrialText: String {
        switch language {
        case "fr": return "après l'essai gratuit"
        case "es": return "después de la prueba gratuita"
        default: return "after free trial"
        }
    }

    var subscribeButtonText: String {
        switch language {
        case "fr": return "Commencer l'essai gratuit"
        case "es": return "Comenzar prueba gratis"
        default: return "Start Free Trial"
        }
    }

    var currentPlanText: String {
        switch language {
        case "fr": return "Plan actuel"
        case "es": return "Plan actual"
        default: return "Current Plan"
        }
    }
}
