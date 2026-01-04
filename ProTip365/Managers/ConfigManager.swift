import Foundation

class ConfigManager {
    static let shared = ConfigManager()

    private init() {
        // Configuration is handled through build settings and Info.plist
        // This approach is more secure and iOS-friendly than .env files
    }

    // MARK: - Supabase Configuration
    // These values can be overridden in build configurations or Info.plist

    public var supabaseURL: String {
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

    public var supabaseAnonKey: String {
        // Try Info.plist first
        if let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
           key != "YOUR_SUPABASE_ANON_KEY_HERE",
           !key.isEmpty {
            return key
        }

        // IMPORTANT: You need to add your actual Supabase anon key
        // Get it from: https://supabase.com/dashboard/project/ztzpjsbfzcccvbacgskc/settings/api
        // The anon key should be a JWT token that starts with "eyJ"

        // Fallback to the actual anon key
        #if DEBUG
        return "sb_publishable_6lBH6DSnvQ9hTY_3k5Gsfg_RdGVc95c"
        #else
        return "sb_publishable_6lBH6DSnvQ9hTY_3k5Gsfg_RdGVc95c"
        #endif
    }

    public var appStoreSharedSecret: String {
        // Try Info.plist first
        if let secret = Bundle.main.object(forInfoDictionaryKey: "APP_STORE_SHARED_SECRET") as? String,
           secret != "YOUR_SHARED_SECRET_HERE",
           !secret.isEmpty {
            return secret
        }
        
        // Fallback to the hardcoded secret (moved from SubscriptionManager)
        return "0b3c33127296426f9846d484f520f693"
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
