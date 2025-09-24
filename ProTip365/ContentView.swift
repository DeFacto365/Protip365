import SwiftUI
import Supabase

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var showOnboarding = false
    @StateObject private var securityManager = SecurityManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var alertManager = AlertManager.shared
    @AppStorage("language") private var language = "en"
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false // Added to check setting
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            // Full screen background that extends to all edges
            Color(.systemGroupedBackground)
                .ignoresSafeArea(.all)

            Group {
                // Check security lock first
                if securityManager.currentSecurityType != .none && !securityManager.isUnlocked {
                    EnhancedLockScreenView(securityManager: securityManager)
                } else if isAuthenticated {
                    if showOnboarding {
                        OnboardingView(isAuthenticated: $isAuthenticated, showOnboarding: $showOnboarding)
                    } else {
                        // TEMPORARILY DISABLED: Skip subscription checks for testing
                        // Show main app directly without subscription validation
                        mainAppView
                    }
                } else {
                    AuthView(isAuthenticated: $isAuthenticated)
                }
            }
        }
        .task {
            await checkAuth()
            if securityManager.currentSecurityType != .none && !securityManager.isUnlocked {
                securityManager.authenticate()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidSignOut)) { _ in
            isAuthenticated = false
            showOnboarding = false
            securityManager.isUnlocked = false
            // Reset subscription state when user signs out to prevent subscription carryover
            subscriptionManager.resetSubscriptionState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidDeleteAccount)) { _ in
            isAuthenticated = false
            showOnboarding = false
            securityManager.isUnlocked = false
            // Reset subscription state to ensure clean slate for new accounts
            subscriptionManager.resetSubscriptionState()
        }
        .onAppear {
            // Force check authentication state on app appear
            Task {
                await checkAuth()
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // If security is enabled and app is locked, trigger authentication
                if securityManager.currentSecurityType != .none && !securityManager.isUnlocked {
                    securityManager.authenticate()
                }

                // Refresh subscription status when app becomes active
                Task {
                    await subscriptionManager.refreshSubscriptionStatus()

                    // Also reload language preference when app becomes active
                    if let session = try? await SupabaseManager.shared.client.auth.session {
                        await loadUserLanguage(userId: session.user.id)
                    }

                    // Refresh alerts from database
                    await alertManager.refreshAlerts()

                    // Update app badge using recommended iOS 17+ method
                    alertManager.updateAppBadge()
                }
            case .inactive:
                // Lock the app when it becomes inactive
                if securityManager.currentSecurityType != .none {
                    securityManager.isUnlocked = false
                    securityManager.showPINEntry = false
                }
            case .background:
                // Also lock when entering background
                if securityManager.currentSecurityType != .none {
                    securityManager.isUnlocked = false
                    securityManager.showPINEntry = false
                }
            @unknown default:
                break
            }
        }
    }

    // Localization
    var dashboardTab: String {
        switch language {
        case "fr": return "Tableau"
        case "es": return "Panel"
        default: return "Dashboard"
        }
    }

    var calendarTab: String {
        switch language {
        case "fr": return "Calendrier"
        case "es": return "Calendario"
        default: return "Calendar"
        }
    }

    var employersTab: String {
        switch language {
        case "fr": return "Employeurs"
        case "es": return "Empleadores"
        default: return "Employers"
        }
    }

    var calculatorTab: String {
        switch language {
        case "fr": return "Calculer"
        case "es": return "Calcular"
        default: return "Calculator"
        }
    }

    var settingsTab: String {
        switch language {
        case "fr": return "Réglages"
        case "es": return "Ajustes"
        default: return "Settings"
        }
    }

    var mainAppView: some View {
        Group {
            if sizeClass == .regular {
                // iPad Layout - Use sidebar navigation
                NavigationSplitView {
                    List {
                        NavigationLink(destination: DashboardView()) {
                            Label(dashboardTab, systemImage: IconNames.Navigation.dashboard)
                        }

                        NavigationLink(destination: CalendarShiftsView(navigateToShiftId: .constant(nil))) {
                            Label(calendarTab, systemImage: IconNames.Navigation.calendar)
                        }

                        // Only show Employers if enabled
                        if useMultipleEmployers {
                            NavigationLink(destination: EmployersView()) {
                                Label(employersTab, systemImage: IconNames.Navigation.employers)
                            }
                        }

                        NavigationLink(destination: TipCalculatorView()) {
                            Label(calculatorTab, systemImage: IconNames.Navigation.calculator)
                        }
                        NavigationLink(destination: SettingsViewWrapper()) {
                            Label(settingsTab, systemImage: IconNames.Navigation.settings)
                        }
                    }
                    .navigationTitle("ProTip365")
                    .listStyle(.sidebar)
                } detail: {
                    DashboardView()
                }
            } else {
                // iPhone Layout - Use Liquid Glass Navigation
                iOS26LiquidGlassMainView()
            }
        }
        .environmentObject(subscriptionManager)
        .environmentObject(SupabaseManager.shared)
        .environmentObject(alertManager)
        .alert(alertManager.currentAlert?.title ?? "", isPresented: $alertManager.showAlert) {
            Button("OK") {
                if let alert = alertManager.currentAlert {
                    Task {
                        await alertManager.clearAlert(alert)
                    }
                }
            }
            if let alert = alertManager.currentAlert,
               let action = alert.action, !action.isEmpty {
                Button(action) {
                    handleAlertAction(alert)
                    Task {
                        await alertManager.clearAlert(alert)
                    }
                }
            }
        } message: {
            if let alert = alertManager.currentAlert {
                Text(alert.message)
            }
        }
    }

    func handleAlertAction(_ alert: DatabaseAlert) {
        switch alert.alert_type {
        case "missingShift", "incompleteShift":
            // Navigate to calendar for adding entry
            navigateToCalendar()
        case "targetAchieved", "personalBest":
            break
        case "reminder":
            break
        case "shiftReminder":
            // Navigate to the specific shift for editing
            if let shiftId = alert.getShiftId() {
                navigateToShift(shiftId: shiftId)
            } else {
                // Fallback to calendar if no specific shift ID
                navigateToCalendar()
            }
        default:
            break
        }
    }

    private func navigateToCalendar() {
        // Post notification to change tab to calendar
        NotificationCenter.default.post(name: .navigateToCalendar, object: nil)
    }

    private func navigateToShift(shiftId: UUID) {
        // Post notification to navigate to specific shift
        NotificationCenter.default.post(name: .navigateToShift, object: shiftId)
    }

    func checkAuth() async {
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            print("🔍 Auth check - Session found: \(session.user.id), expires: \(session.expiresAt)")
            
            // Additional check: ensure session is valid and not expired
            if Date(timeIntervalSince1970: session.expiresAt) > Date() {
                await MainActor.run {
                    isAuthenticated = true
                }
                print("✅ User authenticated successfully")
                // Load user's language preference from database
                await loadUserLanguage(userId: session.user.id)
                // Check if user needs onboarding
                await checkIfOnboardingNeeded(userId: session.user.id)
                // TEMPORARILY DISABLED: Skip subscription checking for testing
                // await subscriptionManager.startSubscriptionChecking()
            } else {
                // Session is invalid or expired
                await MainActor.run {
                    isAuthenticated = false
                }
                print("❌ Session invalid or expired")
            }
        } catch {
            // No session or error - ensure we're not authenticated
            await MainActor.run {
                isAuthenticated = false
            }
            print("❌ No session found: \(error)")
        }

        // Listen for auth state changes
        for await state in SupabaseManager.shared.client.auth.authStateChanges {
            await MainActor.run {
                // Only set authenticated if we have a valid, non-expired session
                isAuthenticated = state.session != nil && 
                                (state.session?.expiresAt).map { Date(timeIntervalSince1970: $0) > Date() } ?? false
            }

            // Reload language preference when auth state changes to authenticated
            if let session = state.session, Date(timeIntervalSince1970: session.expiresAt) > Date() {
                await loadUserLanguage(userId: session.user.id)
                // Check if user needs onboarding when auth state changes
                await checkIfOnboardingNeeded(userId: session.user.id)
                // TEMPORARILY DISABLED: Skip subscription checking for testing
                // await subscriptionManager.startSubscriptionChecking()
            }
        }
    }

    func loadUserLanguage(userId: UUID) async {
        struct UserLanguage: Decodable {
            let preferred_language: String?
        }

        // Try to get user's language preference
        do {
            let userLanguage: UserLanguage = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("preferred_language")
                .eq("user_id", value: userId)
                .single()
                .execute()
                .value

            if let preferredLanguage = userLanguage.preferred_language {
                await MainActor.run {
                    language = preferredLanguage
                    print("Loaded language preference from database: \(preferredLanguage)")
                }
            } else {
                print("No language preference set, using default")
            }
        } catch {
            // Profile might not exist yet or language not set
            print("No language preference found, using default: \(error.localizedDescription)")
        }
    }
    
    func checkIfOnboardingNeeded(userId: UUID) async {
        // Check if user has completed onboarding by looking for key profile fields
        do {
            let response = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("tip_target_percentage, target_sales_daily, target_hours_daily")
                .eq("user_id", value: userId)
                .single()
                .execute()
            
            // If we get here, profile exists - check if onboarding fields are set
            let decoder = JSONDecoder()
            if let profileData = try? decoder.decode(OnboardingCheck.self, from: response.data) {
                // If key onboarding fields are missing or default, show onboarding
                let needsOnboarding = profileData.tip_target_percentage == nil || 
                                    profileData.tip_target_percentage == 0 ||
                                    profileData.target_sales_daily == nil ||
                                    profileData.target_hours_daily == nil
                
                await MainActor.run {
                    showOnboarding = needsOnboarding
                    if needsOnboarding {
                        print("🎯 User needs onboarding - showing onboarding flow")
                    } else {
                        print("✅ User has completed onboarding")
                    }
                }
            }
        } catch {
            // Profile doesn't exist or error - show onboarding
            await MainActor.run {
                showOnboarding = true
                print("🎯 New user detected - showing onboarding flow")
            }
        }
    }
    
    struct OnboardingCheck: Decodable {
        let tip_target_percentage: Double?
        let target_sales_daily: Double?
        let target_hours_daily: Double?
    }
}

// Wrapper for SettingsView on iPad that doesn't need selectedTab
struct SettingsViewWrapper: View {
    @State private var dummySelectedTab = "settings"

    var body: some View {
        SettingsView(selectedTab: $dummySelectedTab)
    }
}

