import Foundation

class ConfigManager {
    static let shared = ConfigManager()

    private init() {
        // Configuration is handled through build settings and Info.plist
        // This approach is more secure and iOS-friendly than .env files
    }

    // MARK: - Supabase Configuration
    // These values can be overridden in build configurations or Info.plist

    var supabaseURL: String {
        // Try Info.plist first
        if let url = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String {
            return url
        }

        // Fallback to build-time configuration
        #if DEBUG
        return "YOUR_SUPABASE_URL"
        #else
        return "YOUR_SUPABASE_URL"
        #endif
    }

    var supabaseAnonKey: String {
        // Try Info.plist first
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
            return key
        }

        // Fallback to build-time configuration
        #if DEBUG
        return "YOUR_SUPABASE_PUBLISHABLE_KEY"
        #else
        return "YOUR_SUPABASE_PUBLISHABLE_KEY"
        #endif
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
}
