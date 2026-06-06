//
//  ProTip365App.swift
//  ProTip365
//
//  Created by Jacques Bolduc on 2025-08-29.
//

import SwiftUI
import UserNotifications

@main
struct ProTip365App: App {
    @AppStorage("language") private var language = "en"
    @AppStorage("hasInitializedLanguage") private var hasInitializedLanguage = false
    @State private var showSplash = true

    init() {
        // Initialize language from iOS settings on first launch
        if !hasInitializedLanguage {
            initializeLanguageFromSystem()
            hasInitializedLanguage = true
        }

        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

    var body: some Scene {
        WindowGroup {
            if showSplash {
                SplashScreenView(isActive: $showSplash)
                    .transition(.opacity)
            } else {
                ContentView()
                    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                        // Clear app badge when app becomes active
                        NotificationManager.shared.clearAppBadge()

                        // Re-sync when app becomes active in case user changed language in iOS Settings
                        syncWithSystemLanguage()

                        // Check for missing shift entries when app becomes active
                        Task {
                            await AlertManager.shared.checkYesterdayShifts()
                        }
                    }
                    .onAppear {
                        // Clear app badge on app launch
                        NotificationManager.shared.clearAppBadge()

                        // Request notification permissions on first launch
                        AlertManager.shared.requestNotificationPermission()
                    }
            }
        }
    }

    private func initializeLanguageFromSystem() {
        // Get the preferred language from iOS Settings
        if let preferredLanguage = Locale.preferredLanguages.first {
            // Extract the language code (e.g., "en-US" -> "en", "fr-CA" -> "fr")
            let languageCode = String(preferredLanguage.prefix(2))

            // Set to the system language if supported, otherwise default to English
            if ["fr", "es"].contains(languageCode) {
                language = languageCode
                print("📱 Initialized app language from iOS Settings: \(languageCode)")
            } else {
                language = "en"
                print("📱 Initialized app language to English (system language '\(languageCode)' not supported)")
            }
        } else {
            // Default to English if we can't determine system language
            language = "en"
            print("📱 Initialized app language to English (default)")
        }
    }

    private func syncWithSystemLanguage() {
        // Get the preferred language from iOS Settings
        if let preferredLanguage = Locale.preferredLanguages.first {
            // Extract the language code (e.g., "en-US" -> "en", "fr-CA" -> "fr")
            let languageCode = String(preferredLanguage.prefix(2))

            // Update to system language if supported, otherwise default to English
            let targetLanguage = ["fr", "es"].contains(languageCode) ? languageCode : "en"

            // Only update if different from current
            if language != targetLanguage {
                language = targetLanguage
                print("📱 Synced app language with iOS Settings: \(targetLanguage)")
            }
        }
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("📱 NotificationDelegate: Notification will present (foreground)")
        // Forward to NotificationManager to handle adding to bell icon
        NotificationManager.shared.userNotificationCenter(center, willPresent: notification, withCompletionHandler: completionHandler)
    }

    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        print("📱 NotificationDelegate: User tapped notification")
        // Clear app badge when user interacts with notification
        NotificationManager.shared.clearAppBadge()

        // Forward to NotificationManager to handle adding to bell icon
        NotificationManager.shared.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
    }
}
