import Foundation

class ConfigManager {
    static let shared = ConfigManager()

    private init() {
        // Configuration is handled through build settings and Info.plist
        // This approach is more secure and iOS-friendly than .env files
    }

    // MARK: - Supabase Configuration
    // Values are injected through build settings into Info.plist.

    public var supabaseURL: String {
        if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
           isConfigured(url) {
            return url
        }

        return ""
    }

    public var supabaseAnonKey: String {
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           isConfigured(key) {
            return key
        }

        return ""
    }

    public var appStoreSharedSecret: String {
        if let secret = Bundle.main.object(forInfoDictionaryKey: "APP_STORE_SHARED_SECRET") as? String,
           isConfigured(secret) {
            return secret
        }

        return ""
    }

    // MARK: - Configuration Status

    var isUsingProductionConfig: Bool {
        return supabaseURL.contains("prod") || supabaseURL.contains("production")
    }

    func printConfigurationStatus() {
        #if DEBUG
        print("🔧 Configuration Status: OK")
        print("   Environment: \(isUsingProductionConfig ? "Production" : "Development")")
        #endif
    }

    func validateConfiguration() -> Bool {
        #if DEBUG
        print("🔍 Validating Configuration...")
        #endif

        guard !supabaseURL.isEmpty else {
            #if DEBUG
            print("❌ ERROR: Configuration issue detected")
            #endif
            return false
        }

        guard !supabaseAnonKey.isEmpty else {
            #if DEBUG
            print("❌ ERROR: Configuration issue detected")
            #endif
            return false
        }

        guard supabaseURL.hasPrefix("https://") else {
            #if DEBUG
            print("❌ ERROR: Configuration issue detected")
            #endif
            return false
        }

        guard supabaseAnonKey.count > 20 else {
            #if DEBUG
            print("❌ ERROR: Configuration issue detected")
            #endif
            return false
        }

        #if DEBUG
        print("✅ Configuration validation passed")
        #endif
        return true
    }

    private func isConfigured(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && !trimmed.hasPrefix("$(") && !trimmed.contains("_HERE")
    }
}
