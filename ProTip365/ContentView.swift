import SwiftUI
import Supabase

struct ContentView: View {
    @State private var isAuthenticated = false
    @State private var showOnboarding = false
    @State private var isCheckingSubscription = true
    @StateObject private var securityManager = SecurityManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var alertManager = AlertManager.shared
    @AppStorage("language") private var language = "en"
    @AppStorage("useMultipleEmployers") private var useMultipleEmployers = false // Added to check setting
    @AppStorage("keepMeSignedIn") private var keepMeSignedIn = true
    @Environment(\.horizontalSizeClass) var sizeClass
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            // Full screen background that extends to all edges
            Color(.systemGroupedBackground)
                .ignoresSafeArea(.all)

            Group {
                // Only check security lock AFTER user is authenticated
                if isAuthenticated && securityManager.currentSecurityType != .none && !securityManager.isUnlocked {
                    EnhancedLockScreenView(securityManager: securityManager)
                } else if isAuthenticated {
                    if isCheckingSubscription {
                        // Show loading while checking subscription (with timeout safeguard)
                        SubscriptionCheckingView(isCheckingSubscription: $isCheckingSubscription)
                    } else if !subscriptionManager.isSubscribed && !subscriptionManager.isInTrialPeriod {
                        // Show subscription screen - subscription required to access app
                        SubscriptionView(subscriptionManager: subscriptionManager, showOnboarding: $showOnboarding)
                    } else if showOnboarding {
                        // Has valid subscription but needs onboarding
                        OnboardingView(isAuthenticated: $isAuthenticated, showOnboarding: $showOnboarding)
                            .environmentObject(securityManager)
                    } else {
                        // Has valid subscription and completed onboarding - show main app
                        mainAppView
                    }
                } else {
                    AuthView(isAuthenticated: $isAuthenticated)
                }
            }
        }
        .task {
            await checkAuth()
            // Only trigger security authentication AFTER user is authenticated
            if isAuthenticated && securityManager.currentSecurityType != .none && !securityManager.isUnlocked {
                securityManager.authenticate()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidSignOut)) { _ in
            isAuthenticated = false
            showOnboarding = false
            securityManager.isUnlocked = false
            // CRITICAL: Clear security settings on sign out
            securityManager.clearSecuritySettings()
            // Reset subscription state when user signs out to prevent subscription carryover
            subscriptionManager.resetSubscriptionState()
        }
        .onReceive(NotificationCenter.default.publisher(for: .userDidDeleteAccount)) { _ in
            isAuthenticated = false
            showOnboarding = false
            securityManager.isUnlocked = false
            // CRITICAL: Clear security settings on account deletion
            securityManager.clearSecuritySettings()
            // Reset subscription state to ensure clean slate for new accounts
            subscriptionManager.resetSubscriptionState()
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .active:
                // If user is authenticated and security is enabled and app is locked, trigger authentication
                if isAuthenticated && securityManager.currentSecurityType != .none && !securityManager.isUnlocked {
                    securityManager.authenticate()
                }

                // Refresh subscription status when app becomes active (only if authenticated)
                if isAuthenticated {
                    Task {
                        // Refresh subscription status from server
                        await subscriptionManager.refreshSubscriptionStatus()

                        // Also reload language preference when app becomes active
                        if let session = try? await SupabaseManager.shared.client.auth.session {
                            await loadUserLanguage(userId: session.user.id)
                        }

                        // Refresh alerts from database (only if authenticated)
                        await alertManager.refreshAlerts()

                        // Update app badge using recommended iOS 17+ method
                        alertManager.updateAppBadge()
                    }
                }
            case .inactive:
                // Lock the app when it becomes inactive (only if user is authenticated)
                if isAuthenticated && securityManager.currentSecurityType != .none {
                    securityManager.isUnlocked = false
                    securityManager.showPINEntry = false
                }
            case .background:
                // Also lock when entering background (only if user is authenticated)
                if isAuthenticated && securityManager.currentSecurityType != .none {
                    securityManager.isUnlocked = false
                    securityManager.showPINEntry = false
                }

                // Sign out if "Keep me signed in" is disabled
                if isAuthenticated && !keepMeSignedIn {
                    Task {
                        print("🚪 Signing out: Keep me signed in is disabled")
                        try? await SupabaseManager.shared.client.auth.signOut()
                        await MainActor.run {
                            isAuthenticated = false
                            showOnboarding = false
                            securityManager.isUnlocked = false
                            securityManager.clearSecuritySettings()
                            subscriptionManager.resetSubscriptionState()
                        }
                    }
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
                    .environmentObject(subscriptionManager)
                    .environmentObject(securityManager)
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
                // Verify that the user actually exists in the database
                // This catches cases where user was deleted but session is cached
                do {
                    _ = try await SupabaseManager.shared.client
                        .from("users_profile")
                        .select("user_id")
                        .eq("user_id", value: session.user.id)
                        .single()
                        .execute()

                    // User exists - proceed with authentication
                    await MainActor.run {
                        isAuthenticated = true
                    }
                    print("✅ User authenticated successfully")
                    // Load user's language preference from database
                    await loadUserLanguage(userId: session.user.id)
                    // CRITICAL: Load user's security settings from database
                    await securityManager.loadSecuritySettings(for: session.user.id)
                    // Check if user needs onboarding
                    await checkIfOnboardingNeeded(userId: session.user.id)

                    // Start subscription checking in background (non-blocking)
                    // This allows user to access the app immediately while we validate
                    await MainActor.run {
                        isCheckingSubscription = false // Don't block the UI
                    }

                    // Check subscription status in background
                    Task {
                        await subscriptionManager.loadProducts()
                        await subscriptionManager.checkSubscriptionStatus()
                    }
                } catch {
                    // User profile doesn't exist - session is invalid, sign out
                    print("❌ User profile not found in database - signing out cached session: \(error)")
                    try? await SupabaseManager.shared.client.auth.signOut()
                    await MainActor.run {
                        isAuthenticated = false
                    }
                }
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
            // Check if we have a valid, non-expired session
            if let session = state.session, Date(timeIntervalSince1970: session.expiresAt) > Date() {
                // Verify that the user actually exists in the database
                do {
                    _ = try await SupabaseManager.shared.client
                        .from("users_profile")
                        .select("user_id")
                        .eq("user_id", value: session.user.id)
                        .single()
                        .execute()

                    // User exists - proceed with authentication
                    await MainActor.run {
                        isAuthenticated = true
                    }

                    await loadUserLanguage(userId: session.user.id)
                    // CRITICAL: Load user's security settings from database
                    await securityManager.loadSecuritySettings(for: session.user.id)
                    // Check if user needs onboarding when auth state changes
                    await checkIfOnboardingNeeded(userId: session.user.id)

                    // Check subscription status in background (non-blocking)
                    await MainActor.run {
                        isCheckingSubscription = false
                    }

                    Task {
                        await subscriptionManager.loadProducts()
                        await subscriptionManager.checkSubscriptionStatus()
                    }
                } catch {
                    // User profile doesn't exist - session is invalid, sign out
                    print("❌ Auth state change: User profile not found - signing out: \(error)")
                    try? await SupabaseManager.shared.client.auth.signOut()
                    await MainActor.run {
                        isAuthenticated = false
                    }
                }
            } else {
                // No session or expired session
                await MainActor.run {
                    isAuthenticated = false
                }
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
        // Check if user has completed onboarding using explicit flag
        do {
            let response = try await SupabaseManager.shared.client
                .from("users_profile")
                .select("onboarding_completed")
                .eq("user_id", value: userId)
                .single()
                .execute()

            print("🔍 DEBUG: Raw response data: \(String(data: response.data, encoding: .utf8) ?? "nil")")

            // If we get here, profile exists - check onboarding_completed flag
            let decoder = JSONDecoder()
            if let profileData = try? decoder.decode(OnboardingCheck.self, from: response.data) {
                print("🔍 DEBUG: Decoded onboarding_completed = \(profileData.onboarding_completed ?? false)")
                let needsOnboarding = !(profileData.onboarding_completed ?? false)

                await MainActor.run {
                    showOnboarding = needsOnboarding
                    if needsOnboarding {
                        print("🎯 User needs onboarding - showing onboarding flow")
                    } else {
                        print("✅ User has completed onboarding")
                    }
                }
            } else {
                print("❌ DEBUG: Failed to decode OnboardingCheck from response")
                await MainActor.run {
                    showOnboarding = true
                }
            }
        } catch {
            // Profile doesn't exist or error - show onboarding
            await MainActor.run {
                showOnboarding = true
                print("🎯 New user detected - showing onboarding flow: \(error.localizedDescription)")
            }
        }
    }

    struct OnboardingCheck: Decodable {
        let onboarding_completed: Bool?
    }
}

// Wrapper for SettingsView on iPad that doesn't need selectedTab
struct SettingsViewWrapper: View {
    @State private var dummySelectedTab = "settings"
    @StateObject private var subscriptionManager = SubscriptionManager()

    var body: some View {
        SettingsView(selectedTab: $dummySelectedTab)
            .environmentObject(subscriptionManager)
    }
}

// Loading view with automatic timeout
struct SubscriptionCheckingView: View {
    @Binding var isCheckingSubscription: Bool
    @State private var timeoutReached = false

    var body: some View {
        VStack(spacing: 20) {
            if !timeoutReached {
                ProgressView()
                    .scaleEffect(1.5)
                Text("Verifying subscription...")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 50))
                        .foregroundColor(.orange)

                    Text("Verification Taking Too Long")
                        .font(.headline)

                    Text("Subscription verification is taking longer than expected. You can continue without waiting.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    Button {
                        isCheckingSubscription = false
                    } label: {
                        Text("Continue Anyway")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .task {
            // Set timeout after 15 seconds
            try? await Task.sleep(nanoseconds: 15_000_000_000)
            timeoutReached = true
        }
    }
}

