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
        return "https://ztzpjsbfzcccvbacgskc.supabase.co"
        #else
        return "https://ztzpjsbfzcccvbacgskc.supabase.co"
        #endif
    }

    var supabaseAnonKey: String {
        // Try Info.plist first
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String {
            return key
        }

        // Fallback to build-time configuration
        #if DEBUG
        return "sb_publishable_6lBH6DSnvQ9hTY_3k5Gsfg_RdGVc95c"
        #else
        return "sb_publishable_6lBH6DSnvQ9hTY_3k5Gsfg_RdGVc95c"
        #endif
    }

    // MARK: - Configuration Status

    var isUsingProductionConfig: Bool {
        return supabaseURL.contains("prod") || supabaseURL.contains("production")
    }

    func printConfigurationStatus() {
        print("🔧 Configuration Status:")
        print("   Supabase URL: \(supabaseURL)")
        print("   Anon Key: \(supabaseAnonKey.prefix(10))...\(supabaseAnonKey.suffix(10))")
        print("   Key Length: \(supabaseAnonKey.count) characters")
        print("   Key Format: \(supabaseAnonKey.hasPrefix("sb_") ? "Publishable" : supabaseAnonKey.hasPrefix("eyJ") ? "JWT" : "Unknown")")
        print("   Environment: \(isUsingProductionConfig ? "Production" : "Development")")
        print("   Info.plist Values:")
        print("     SUPABASE_URL: \(Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? "Not found")")
        print("     SUPABASE_ANON_KEY: \((Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String)?.prefix(10) ?? "Not found")...")
    }

    func validateConfiguration() -> Bool {
        print("🔍 Validating Configuration...")

        guard !supabaseURL.isEmpty else {
            print("❌ ERROR: Supabase URL is empty!")
            return false
        }

        guard !supabaseAnonKey.isEmpty else {
            print("❌ ERROR: Supabase Anon Key is empty!")
            return false
        }

        guard supabaseURL.hasPrefix("https://") else {
            print("❌ ERROR: Supabase URL must start with https://")
            return false
        }

        guard supabaseAnonKey.count > 20 else {
            print("❌ ERROR: Supabase Anon Key seems too short!")
            return false
        }

        print("✅ Configuration validation passed")
        return true
    }
}
