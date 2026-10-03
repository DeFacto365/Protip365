import SwiftUI
import StoreKit

// Helper struct for decoding onboarding status
private struct OnboardingCheck: Decodable {
    let onboarding_completed: Bool?
}

struct SubscriptionView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Binding var showOnboarding: Bool
    @AppStorage("language") private var language = "en"
    @State private var isLoadingMonthly = false
    @State private var isLoadingYearly = false
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            // Background color
            Color(.systemGroupedBackground)
                .ignoresSafeArea()

            // Gradient overlay
            LinearGradient(
                colors: [
                    Color(red: 0.6, green: 0.8, blue: 1.0),     // Light blue
                    Color(red: 1.0, green: 0.7, blue: 0.9),     // Light pink
                    Color(red: 0.8, green: 0.7, blue: 1.0)      // Light purple
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .opacity(0.2)
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Logo and Branding
                    VStack(spacing: 20) {
                        Image("Logo2")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                            .clipShape(RoundedRectangle(cornerRadius: 22))
                            .shadow(radius: 8)

                        HStack(spacing: 0) {
                            Text("ProTip")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("365")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                        }

                        Text(valueProposition)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 30)

                    // Value Description
                    VStack(spacing: 20) {
                        Text(detailedDescription)
                            .font(.system(size: 13))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 50)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 20)

                    Spacer()

                    // Bottom Section
                    VStack(spacing: 16) {
                        
                        // Debug info (only show if products failed to load)
                        if subscriptionManager.products.isEmpty {
                            VStack(spacing: 12) {
                                Text("⚠️ Unable to load subscription products")
                                    .font(.caption)
                                    .foregroundColor(.orange)

                                Button(action: {
                                    Task {
                                        await subscriptionManager.loadProducts()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "arrow.clockwise")
                                        Text("Retry Loading Products")
                                    }
                                    .font(.caption)
                                    .foregroundColor(.blue)
                                }
                                .padding(.bottom, 8)
                            }
                        }

                        // Annual Plan Button (Featured - Better Deal)
                        Button(action: {
                            if subscriptionManager.products.isEmpty {
                                print("❌ Cannot purchase - no products loaded")
                                return
                            }

                            isLoadingYearly = true
                            Task {
                                do {
                                    try await subscriptionManager.purchase(productId: subscriptionManager.premiumYearlyId)
                                    await MainActor.run {
                                        isLoadingYearly = false
                                        if subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod {
                                            checkOnboardingStatus()
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        isLoadingYearly = false
                                        showErrorAlert = true
                                    }
                                }
                            }
                        }) {
                            Group {
                                if isLoadingYearly {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    VStack(spacing: 4) {
                                        Text(subscribeButtonYearly(for: subscriptionManager.productYearly))
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                        Text(bestValueText)
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.blue.opacity(0.5), lineWidth: 2)
                            )
                        }
                        .disabled(isLoadingYearly)
                        .padding(.horizontal, 30)
                        
                        // Monthly Plan Button
                        Button(action: {
                            if subscriptionManager.products.isEmpty {
                                print("❌ Cannot purchase - no products loaded")
                                return
                            }

                            isLoadingMonthly = true
                            Task {
                                do {
                                    try await subscriptionManager.purchase(productId: subscriptionManager.premiumMonthlyId)
                                    await MainActor.run {
                                        isLoadingMonthly = false
                                        if subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod {
                                            checkOnboardingStatus()
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        isLoadingMonthly = false
                                        showErrorAlert = true
                                    }
                                }
                            }
                        }) {
                            Group {
                                if isLoadingMonthly {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(subscribeButtonMonthly(for: subscriptionManager.productMonthly))
                                        .font(.headline)
                                        .fontWeight(.semibold)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isLoadingMonthly)
                        .padding(.horizontal, 30)

                        
                        // Trial text
                        Text(trialText)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                        
                        // Terms and Privacy (inline)
                        HStack(spacing: 6) {
                            Button(action: {
                                if let url = URL(string: "https://www.protip365.com/terms") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(termsLink)
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                            }

                            Text("•")
                                .font(.footnote)
                                .foregroundColor(.secondary)

                            Button(action: {
                                if let url = URL(string: "https://www.protip365.com/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(privacyLink)
                                    .font(.footnote)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 4)

                        // Divider for visual separation
                        Divider()
                            .padding(.vertical, 16)
                            .padding(.horizontal, 30)

                        // Restore Purchases (subscription-related action)
                        Button(action: {
                            Task {
                                isLoadingMonthly = true
                                isLoadingYearly = true
                                await subscriptionManager.restorePurchases()
                                isLoadingMonthly = false
                                isLoadingYearly = false
                                if subscriptionManager.isSubscribed {
                                    HapticFeedback.success()
                                }
                            }
                        }) {
                            Text(restoreButton)
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                        .disabled(isLoadingMonthly || isLoadingYearly)

                        // Sign Out Button (account action)
                        Button(action: {
                            Task {
                                do {
                                    try await SupabaseManager.shared.client.auth.signOut()
                                    NotificationCenter.default.post(name: .userDidSignOut, object: nil)
                                } catch {
                                    print("Error signing out: \(error)")
                                }
                            }
                        }) {
                            Text(signOutButton)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(.top, 12)
                    }
                    .padding(.bottom, 40)
                }
            }
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
    }

    private func checkOnboardingStatus() {
        Task {
            do {
                let userId = try await SupabaseManager.shared.client.auth.session.user.id
                let response = try await SupabaseManager.shared.client
                    .from("users_profile")
                    .select("onboarding_completed")
                    .eq("user_id", value: userId)
                    .single()
                    .execute()

                let decoder = JSONDecoder()
                if let profileData = try? decoder.decode(OnboardingCheck.self, from: response.data) {
                    await MainActor.run {
                        showOnboarding = !(profileData.onboarding_completed ?? false)
                    }
                }
            } catch {
                await MainActor.run {
                    showOnboarding = true
                }
            }
        }
    }
    
    // MARK: - Localization

    var valueProposition: String {
        switch language {
        case "fr": return "Accès Complet Premium"
        case "es": return "Acceso Premium Completo"
        default: return "Unlock All Access"
        }
    }

    var detailedDescription: String {
        switch language {
        case "fr": return "ProTip365 transforme la gestion des données de pourboires pour serveurs, barmans, livreurs et professionnels du service. Remplacez les papiers éparpillés et fichiers Excel obsolètes par une gestion en temps réel des pourboires, planification des quarts et rapports complets quotidiens/hebdomadaires/mensuels/annuels accessibles depuis iPhone, Android, tablette ou iPad, n'importe où."
        case "es": return "ProTip365 transforma cómo meseros, cantineros, repartidores y profesionales del servicio gestionan sus datos de propinas. Reemplace papeles dispersos y archivos Excel obsoletos con gestión de propinas en tiempo real, programación de turnos e informes completos diarios/semanales/mensuales/anuales accesibles desde iPhone, Android, tableta o iPad en cualquier lugar."
        default: return "ProTip365 transforms how servers, bartenders, delivery drivers, and service professionals manage their tip data. Replace scattered paper slips and outdated Excel files with real-time tip management, shift scheduling, and comprehensive daily/weekly/monthly/yearly reports accessible from iPhone, Android, tablet, or iPad anywhere."
        }
    }

    var trialText: String {
        switch language {
        case "fr":
            return "Les deux forfaits incluent un essai gratuit de 7 jours. Annulez à tout moment."
        case "es":
            return "Ambos planes incluyen una prueba gratuita de 7 días. Cancela en cualquier momento."
        default:
            return "Both plans include a 7-day free trial. Cancel anytime."
        }
    }

    var bestValueText: String {
        switch language {
        case "fr": return "Meilleure valeur"
        case "es": return "Mejor valor"
        default: return "Best Value"
        }
    }

    func subscribeButtonMonthly(for product: Product?) -> String {
        let priceString: String
        if let displayPrice = product?.displayPrice {
            priceString = displayPrice
        } else {
            priceString = "$3.99"
        }

        switch language {
        case "fr":
            return "Forfait mensuel - \(priceString)/mois"
        case "es":
            return "Plan mensual - \(priceString)/mes"
        default:
            return "Monthly Plan - \(priceString)/month"
        }
    }

    func subscribeButtonYearly(for product: Product?) -> String {
        let priceString: String
        if let displayPrice = product?.displayPrice {
            priceString = displayPrice
        } else {
            priceString = "$34.99"
        }

        switch language {
        case "fr":
            return "Forfait annuel - \(priceString)/an (Économisez 27 %)"
        case "es":
            return "Plan anual - \(priceString)/año (Ahorra 27 %)"
        default:
            return "Annual Plan - \(priceString)/year (Save 27%)"
        }
    }

    var termsLink: String {
        switch language {
        case "fr": return "Conditions d'utilisation"
        case "es": return "Términos de servicio"
        default: return "Terms of Service"
        }
    }

    var privacyLink: String {
        switch language {
        case "fr": return "Politique de confidentialité"
        case "es": return "Política de privacidad"
        default: return "Privacy Policy"
        }
    }

    var signOutButton: String {
        switch language {
        case "fr": return "Se déconnecter"
        case "es": return "Cerrar sesión"
        default: return "Sign Out"
        }
    }

    var restoreButton: String {
        switch language {
        case "fr": return "Restaurer les achats"
        case "es": return "Restaurar compras"
        default: return "Restore Purchases"
        }
    }
}


