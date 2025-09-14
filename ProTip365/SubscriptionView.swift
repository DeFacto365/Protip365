import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @AppStorage("language") private var language = "en"
    @State private var isLoading = false
    @State private var showOnboarding = false
    
    var body: some View {
        VStack(spacing: 30) {
            // Header with glass effects
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.yellow)
                    .modifier(GlassEffectModifier())
                    .frame(width: 100, height: 100)
                
                Text("ProTip365 Premium")
                    .font(.largeTitle)
                    .bold()
                    .modifier(GlassEffectRoundedModifier(cornerRadius: 8))
                    .padding(.horizontal, 8)
            }
            .padding(.top, 40)
            
            // Features
            VStack(alignment: .leading, spacing: 20) {
                FeatureRow(icon: "chart.line.uptrend.xyaxis", text: unlimitedTracking)
                FeatureRow(icon: "dollarsign.circle.fill", text: advancedAnalytics)
                FeatureRow(icon: "calendar", text: fullHistory)
                FeatureRow(icon: "building.2.fill", text: multipleEmployers)
                FeatureRow(icon: "cloud", text: cloudSync)
            }
            .padding(.horizontal, 30)
            
            Spacer()
            
            // Pricing
            VStack(spacing: 10) {
                Text(trialText)
                    .font(.headline)
                Text(priceText)
                    .foregroundColor(.secondary)
            }
            
            // Purchase Button
            Button(action: {
                isLoading = true
                Task {
                    await subscriptionManager.purchase()
                    await MainActor.run {
                        isLoading = false
                        // Show onboarding after successful subscription
                        if subscriptionManager.isSubscribed || subscriptionManager.isInTrialPeriod {
                            showOnboarding = true
                        }
                    }
                }
            }) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Text(startTrialButton)
                        .bold()
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
            .padding(.horizontal, 30)
            .disabled(isLoading)
            
            // Restore Button
            Button(action: {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            }) {
                Text(restoreButton)
                    .foregroundColor(.blue)
            }
            
            // Terms
            Text(termsText)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingView(isAuthenticated: .constant(true), showOnboarding: $showOnboarding)
        }
    }
    
    // Localization
    var unlimitedTracking: String {
        switch language {
        case "fr": return "Suivi illimité des quarts"
        case "es": return "Seguimiento ilimitado de turnos"
        default: return "Unlimited shift tracking"
        }
    }
    
    var advancedAnalytics: String {
        switch language {
        case "fr": return "Analyses avancées"
        case "es": return "Análisis avanzado"
        default: return "Advanced analytics"
        }
    }
    
    var fullHistory: String {
        switch language {
        case "fr": return "Accès à l'historique complet"
        case "es": return "Acceso al historial completo"
        default: return "Full history access"
        }
    }
    
    var multipleEmployers: String {
        switch language {
        case "fr": return "Plusieurs employeurs"
        case "es": return "Múltiples empleadores"
        default: return "Multiple employers"
        }
    }
    
    var cloudSync: String {
        switch language {
        case "fr": return "Synchronisation cloud"
        case "es": return "Sincronización en la nube"
        default: return "Cloud sync"
        }
    }
    
    var trialText: String {
        switch language {
        case "fr": return "Essai gratuit de 7 jours"
        case "es": return "Prueba gratuita de 7 días"
        default: return "7-day free trial"
        }
    }
    
    var priceText: String {
        switch language {
        case "fr": return "Puis 4,99$/mois"
        case "es": return "Luego $4.99/mes"
        default: return "Then $4.99/month"
        }
    }
    
    var startTrialButton: String {
        switch language {
        case "fr": return "Commencer l'essai gratuit"
        case "es": return "Comenzar prueba gratis"
        default: return "Start Free Trial"
        }
    }
    
    var restoreButton: String {
        switch language {
        case "fr": return "Restaurer les achats"
        case "es": return "Restaurar compras"
        default: return "Restore Purchases"
        }
    }
    
    var termsText: String {
        switch language {
        case "fr": return "L'abonnement se renouvelle automatiquement. Annulez à tout moment dans les paramètres de l'App Store."
        case "es": return "La suscripción se renueva automáticamente. Cancele en cualquier momento en la configuración de App Store."
        default: return "Subscription auto-renews. Cancel anytime in App Store settings."
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .frame(width: 30)
                .foregroundColor(.blue)
                .font(.title3)
                .modifier(GlassEffectModifier())
                .frame(width: 40, height: 40)
            
            Text(text)
                .font(.body)
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .modifier(GlassEffectRoundedModifier(cornerRadius: 12))
        .shadow(color: .blue.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
