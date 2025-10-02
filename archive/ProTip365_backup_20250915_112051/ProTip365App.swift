//
//  ProTip365App.swift
//  ProTip365
//
//  Created by Jacques Bolduc on 2025-08-29.
//

import SwiftUI

@main
struct ProTip365App: App {
    @AppStorage("language") private var language = "en"
    @AppStorage("hasInitializedLanguage") private var hasInitializedLanguage = false

    init() {
        // Initialize language from iOS settings on first launch
        if !hasInitializedLanguage {
            initializeLanguageFromSystem()
            hasInitializedLanguage = true
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Re-sync when app becomes active in case user changed language in iOS Settings
                    syncWithSystemLanguage()
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
