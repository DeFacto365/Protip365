import SwiftUI
import StoreKit

struct SubscriptionTiersView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @AppStorage("language") private var language = "en"
    @State private var isLoading = false
    @State private var selectedProductId: String? = nil
    @State private var showOnboarding = false
    @State private var loadError: String? = nil
    @State private var isLoadingProducts = false
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 30) {
                    // Header
                    headerView

                    // Current subscription status (if applicable)
                    if subscriptionManager.currentTier == .partTime {
                        currentSubscriptionView
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
                        VStack(spacing: 20) {
                            Image(systemName: "cart.badge.questionmark")
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                            Text(noProductsText)
                                .font(.headline)
                            Text(noProductsDetailText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            Button(retryText) {
                                Task {
                                    await loadProductsWithTimeout()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        .padding(.vertical, 40)
                        .padding(.horizontal)
                    } else {
                    // Subscription tiers
                    VStack(spacing: 20) {
                        // Part-time tier
                        SubscriptionTierCard(
                            tierName: partTimeTitle,
                            description: partTimeDescription,
                            features: partTimeFeatures,
                            monthlyPrice: "$2.99",
                            yearlyPrice: "$30",
                            monthlyProductId: "com.protip365.parttime.monthly",
                            yearlyProductId: "com.protip365.parttime.Annual",
                            isCurrentTier: subscriptionManager.currentTier == .partTime,
                            isLoading: isLoading,
                            selectedProductId: $selectedProductId,
                            language: language,
                            onPurchase: { productId in
                                await purchase(productId: productId)
                            }
                        )

                        // Full access tier
                        SubscriptionTierCard(
                            tierName: fullAccessTitle,
                            description: fullAccessDescription,
                            features: fullAccessFeatures,
                            monthlyPrice: "$4.99",
                            yearlyPrice: "$49.99",
                            monthlyProductId: "com.protip365.monthly",
                            yearlyProductId: "com.protip365.annual",
                            isCurrentTier: subscriptionManager.currentTier == .fullAccess,
                            isUpgrade: subscriptionManager.currentTier == .partTime,
                            hasTrial: true,
                            isLoading: isLoading,
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

            Text("ProTip365")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text(chooseYourPlan)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top)
    }

    private var currentSubscriptionView: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                Text(currentPlanText)
                    .fontWeight(.medium)
            }

            if let remainingShifts = subscriptionManager.getRemainingShifts(),
               let remainingEntries = subscriptionManager.getRemainingEntries() {
                HStack(spacing: 20) {
                    VStack {
                        Text("\(remainingShifts)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(shiftsRemainingText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Divider()
                        .frame(height: 40)

                    VStack {
                        Text("\(remainingEntries)")
                            .font(.title2)
                            .fontWeight(.bold)
                        Text(entriesRemainingText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(upgradeToUnlimitedText)
                .font(.caption)
                .foregroundStyle(.tint)
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
        Text(termsString)
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

        await subscriptionManager.purchase(productId: productId)

        await MainActor.run {
            isLoading = false
            selectedProductId = nil

            // After purchase attempt, check subscription status
            // This handles both new purchases and existing subscriptions
            if subscriptionManager.isSubscribed {
                // If we now have a subscription, dismiss or show onboarding
                if !subscriptionManager.isInTrialPeriod && subscriptionManager.currentTier == .none {
                    showOnboarding = true
                } else {
                    dismiss()
                }
            }
        }
    }

    // MARK: - Localization

    var navigationTitle: String {
        switch language {
        case "fr": return "Abonnements"
        case "es": return "Suscripciones"
        default: return "Subscriptions"
        }
    }

    var cancelText: String {
        switch language {
        case "fr": return "Annuler"
        case "es": return "Cancelar"
        default: return "Cancel"
        }
    }

    var chooseYourPlan: String {
        switch language {
        case "fr": return "Choisissez votre forfait"
        case "es": return "Elige tu plan"
        default: return "Choose your plan"
        }
    }

    var currentPlanText: String {
        switch language {
        case "fr": return "Forfait actuel: Temps partiel"
        case "es": return "Plan actual: Tiempo parcial"
        default: return "Current Plan: Part-time"
        }
    }

    var shiftsRemainingText: String {
        switch language {
        case "fr": return "quarts restants"
        case "es": return "turnos restantes"
        default: return "shifts remaining"
        }
    }

    var entriesRemainingText: String {
        switch language {
        case "fr": return "entrées restantes"
        case "es": return "entradas restantes"
        default: return "entries remaining"
        }
    }

    var upgradeToUnlimitedText: String {
        switch language {
        case "fr": return "Passez à l'accès illimité ci-dessous"
        case "es": return "Actualiza a acceso ilimitado a continuación"
        default: return "Upgrade to unlimited access below"
        }
    }

    var partTimeTitle: String {
        switch language {
        case "fr": return "Temps partiel"
        case "es": return "Tiempo parcial"
        default: return "Part-time"
        }
    }

    var partTimeDescription: String {
        switch language {
        case "fr": return "Parfait pour les employés à temps partiel"
        case "es": return "Perfecto para empleados a tiempo parcial"
        default: return "Perfect for part-time employees"
        }
    }

    var partTimeFeatures: [String] {
        switch language {
        case "fr": return [
            "3 quarts par semaine",
            "3 entrées par semaine",
            "Analyses de base",
            "Synchronisation cloud"
        ]
        case "es": return [
            "3 turnos por semana",
            "3 entradas por semana",
            "Análisis básico",
            "Sincronización en la nube"
        ]
        default: return [
            "3 shifts per week",
            "3 entries per week",
            "Basic analytics",
            "Cloud sync"
        ]
        }
    }

    var fullAccessTitle: String {
        switch language {
        case "fr": return "Accès complet"
        case "es": return "Acceso completo"
        default: return "Full Access"
        }
    }

    var fullAccessDescription: String {
        switch language {
        case "fr": return "Illimité pour les professionnels"
        case "es": return "Ilimitado para profesionales"
        default: return "Unlimited for professionals"
        }
    }

    var fullAccessFeatures: [String] {
        switch language {
        case "fr": return [
            "Quarts illimités",
            "Entrées illimitées",
            "Analyses avancées",
            "Historique complet",
            "Plusieurs employeurs",
            "Synchronisation cloud"
        ]
        case "es": return [
            "Turnos ilimitados",
            "Entradas ilimitadas",
            "Análisis avanzado",
            "Historial completo",
            "Múltiples empleadores",
            "Sincronización en la nube"
        ]
        default: return [
            "Unlimited shifts",
            "Unlimited entries",
            "Advanced analytics",
            "Full history",
            "Multiple employers",
            "Cloud sync"
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

    var termsString: String {
        switch language {
        case "fr": return "Les abonnements se renouvellent automatiquement. Annulez à tout moment dans les paramètres de l'App Store."
        case "es": return "Las suscripciones se renuevan automáticamente. Cancele en cualquier momento en la configuración de App Store."
        default: return "Subscriptions auto-renew. Cancel anytime in App Store settings."
        }
    }

    var loadingProductsText: String {
        switch language {
        case "fr": return "Chargement des forfaits..."
        case "es": return "Cargando planes..."
        default: return "Loading subscription plans..."
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
        case "fr": return "Aucun forfait disponible"
        case "es": return "No hay planes disponibles"
        default: return "No Plans Available"
        }
    }

    var noProductsDetailText: String {
        switch language {
        case "fr": return "Vérifiez votre connexion Internet et réessayez"
        case "es": return "Verifique su conexión a Internet e intente nuevamente"
        default: return "Check your internet connection and try again"
        }
    }

    var retryText: String {
        switch language {
        case "fr": return "Réessayer"
        case "es": return "Reintentar"
        default: return "Retry"
        }
    }

    var timeoutErrorText: String {
        switch language {
        case "fr": return "Le chargement a pris trop de temps. Vérifiez votre connexion."
        case "es": return "La carga tardó demasiado. Verifique su conexión."
        default: return "Loading took too long. Check your connection."
        }
    }

    var noProductsFoundText: String {
        switch language {
        case "fr": return "Aucun produit trouvé. Les abonnements peuvent ne pas être disponibles dans votre région."
        case "es": return "No se encontraron productos. Las suscripciones pueden no estar disponibles en su región."
        default: return "No products found. Subscriptions may not be available in your region."
        }
    }
}

// MARK: - Subscription Tier Card

struct SubscriptionTierCard: View {
    let tierName: String
    let description: String
    let features: [String]
    let monthlyPrice: String?
    let yearlyPrice: String?
    let monthlyProductId: String?
    let yearlyProductId: String?
    let isCurrentTier: Bool
    var isUpgrade: Bool = false
    var hasTrial: Bool = false
    let isLoading: Bool
    @Binding var selectedProductId: String?
    let language: String
    let onPurchase: (String) async -> Void

    @State private var selectedBilling: String = "monthly"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(tierName)
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if isCurrentTier {
                    Text(currentText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundStyle(.green)
                        .clipShape(Capsule())
                }
            }

            // Features
            VStack(alignment: .leading, spacing: 10) {
                ForEach(features, id: \.self) { feature in
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                        Text(feature)
                            .font(.subheadline)
                    }
                }
            }

            // Pricing options
            if yearlyPrice != nil {
                Picker("Billing", selection: $selectedBilling) {
                    Text(monthlyText).tag("monthly")
                    Text(yearlyText).tag("yearly")
                }
                .pickerStyle(.segmented)
            }

            // Price and purchase button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(selectedBilling == "monthly" ? (monthlyPrice ?? "") : (yearlyPrice ?? ""))
                        .font(.title3)
                        .fontWeight(.bold)
                    Text(selectedBilling == "monthly" ? perMonthText : perYearText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if hasTrial && !isCurrentTier && !isUpgrade {
                        Text(trialText)
                            .font(.caption2)
                            .foregroundStyle(.tint)
                    }
                }

                Spacer()

                Button(action: {
                    let productId = selectedBilling == "monthly" ? monthlyProductId : yearlyProductId
                    if let productId = productId {
                        Task {
                            await onPurchase(productId)
                        }
                    }
                }) {
                    if isLoading && selectedProductId == (selectedBilling == "monthly" ? monthlyProductId : yearlyProductId) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Text(buttonText)
                            .fontWeight(.medium)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isCurrentTier || isLoading)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isCurrentTier ? Color.green : Color.clear, lineWidth: 2)
        )
    }

    // Localization
    var currentText: String {
        switch language {
        case "fr": return "ACTUEL"
        case "es": return "ACTUAL"
        default: return "CURRENT"
        }
    }

    var monthlyText: String {
        switch language {
        case "fr": return "Mensuel"
        case "es": return "Mensual"
        default: return "Monthly"
        }
    }

    var yearlyText: String {
        switch language {
        case "fr": return "Annuel"
        case "es": return "Anual"
        default: return "Yearly"
        }
    }

    var perMonthText: String {
        switch language {
        case "fr": return "par mois"
        case "es": return "por mes"
        default: return "per month"
        }
    }

    var perYearText: String {
        switch language {
        case "fr": return "par an (économisez 20%)"
        case "es": return "por año (ahorra 20%)"
        default: return "per year (save 20%)"
        }
    }

    var trialText: String {
        switch language {
        case "fr": return "Essai gratuit de 7 jours"
        case "es": return "Prueba gratis de 7 días"
        default: return "7-day free trial"
        }
    }

    var buttonText: String {
        if isCurrentTier {
            switch language {
            case "fr": return "Actuel"
            case "es": return "Actual"
            default: return "Current"
            }
        } else if isUpgrade {
            switch language {
            case "fr": return "Améliorer"
            case "es": return "Mejorar"
            default: return "Upgrade"
            }
        } else {
            switch language {
            case "fr": return "S'abonner"
            case "es": return "Suscribir"
            default: return "Subscribe"
            }
        }
    }
}