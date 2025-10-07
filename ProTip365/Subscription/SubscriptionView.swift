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
    @State private var isLoading = false
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
                    .padding(.top, 60)
                    .padding(.bottom, 30)

                    // Value Description (replacing icon)
                    VStack(spacing: 20) {
                        Text(detailedDescription)
                            .font(.system(size: 13))
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                            .padding(.horizontal, 50)
                            .fixedSize(horizontal: false, vertical: true)

                        // Page indicators
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.primary)
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                        .padding(.top, 10)
                    }
                    .padding(.vertical, 40)

                    Spacer()

                    // Bottom Section
                    VStack(spacing: 16) {
                        // Trial text (discrete, like Ocean Journal)
                        Text(trialText)
                            .font(.body)
                            .foregroundColor(.blue)

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

                        // Subscribe Button
                        Button(action: {
                            // Check if products are loaded first
                            if subscriptionManager.products.isEmpty {
                                print("❌ Cannot purchase - no products loaded")
                                return
                            }

                            isLoading = true
                            Task {
                                do {
                                    try await subscriptionManager.purchase(productId: "com.protip365.premium.monthly")
                                    await MainActor.run {
                                        isLoading = false
                                        if subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod {
                                            checkOnboardingStatus()
                                        }
                                    }
                                } catch {
                                    await MainActor.run {
                                        isLoading = false
                                        showErrorAlert = true  // Show alert on error
                                    }
                                }
                            }
                        }) {
                            Group {
                                if isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(subscribeButton(for: subscriptionManager.product))
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
                        .disabled(isLoading)
                        .padding(.horizontal, 30)

                        // Terms and Privacy (inline)
                        HStack(spacing: 6) {
                            Button(action: {
                                if let url = URL(string: "https://www.protip365.com/terms") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(termsLink)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }

                            Text("and")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Button(action: {
                                if let url = URL(string: "https://www.protip365.com/privacy") {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text(privacyLink)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 4)

                        // Sign Out Button
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
                                .foregroundColor(.blue)
                        }
                        .padding(.top, 20)

                        // Restore Purchases
                        Button(action: {
                            Task {
                                isLoading = true
                                await subscriptionManager.restorePurchases()
                                isLoading = false
                                if subscriptionManager.isSubscribed {
                                    HapticFeedback.success()
                                }
                            }
                        }) {
                            Text(restoreButton)
                                .font(.body)
                                .foregroundColor(.blue)
                        }
                        .disabled(isLoading)
                        .padding(.top, 8)
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
        case "fr": return "Commencez avec 7 jours d'essai gratuit."
        case "es": return "Comienza con 7 días de prueba gratis."
        default: return "Start with a 7 day free trial."
        }
    }

    func subscribeButton(for product: Product?) -> String {
        let priceString: String
        if let displayPrice = product?.displayPrice {
            priceString = displayPrice // Localized currency & formatting
        } else {
            priceString = "$3.99" // Fallback
        }

        switch language {
        case "fr":
            return "S'abonner pour \(priceString)/mois"
        case "es":
            return "Suscribirse por \(priceString)/mes"
        default:
            return "Subscribe for \(priceString)/month"
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


