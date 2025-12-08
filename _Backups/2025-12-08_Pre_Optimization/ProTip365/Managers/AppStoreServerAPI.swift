import Foundation
import StoreKit
import CryptoKit

// App Store Server API integration for real-time subscription monitoring
class AppStoreServerAPI {
    static let shared = AppStoreServerAPI()

    private let environment: AppStoreEnvironment
    private let bundleId: String
    private let keyId: String
    private let issuerId: String
    private let privateKey: String

    init(environment: AppStoreEnvironment = .sandbox) {
        self.environment = environment
        self.bundleId = Bundle.main.bundleIdentifier ?? "com.protip365.monthly"
        
        // These should be loaded from environment variables or secure storage
        // For now, using placeholder values - in production, these must be properly configured
        self.keyId = "YOUR_KEY_ID" // App Store Connect API Key ID
        self.issuerId = "YOUR_ISSUER_ID" // App Store Connect Issuer ID
        self.privateKey = "YOUR_PRIVATE_KEY" // App Store Connect Private Key (P8 format)
    }
    
    // Generate JWT token for App Store Server API authentication
    private func generateJWT() throws -> String {
        // In production, implement proper JWT signing with ES256
        // For now, return a placeholder token
        print("⚠️ JWT token generation not fully implemented - requires proper ES256 signing")
        return "placeholder_jwt_token"
    }

    // Get subscription status for a specific transaction
    func getSubscriptionStatus(transactionId: String) async throws -> SubscriptionStatusResponse {
        let url = URL(string: "\(environment.baseURL)/inApps/v1/subscriptions/\(transactionId)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(bundleId, forHTTPHeaderField: "X-Apple-Bundle-ID")
        
        // Add JWT authentication
        let jwtToken = try generateJWT()
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        return try decoder.decode(SubscriptionStatusResponse.self, from: data)
    }

    // Get all subscription statuses for the app
    func getAllSubscriptionStatuses() async throws -> [SubscriptionStatusResponse] {
        let url = URL(string: "\(environment.baseURL)/inApps/v1/subscriptions")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(bundleId, forHTTPHeaderField: "X-Apple-Bundle-ID")
        
        // Add JWT authentication
        let jwtToken = try generateJWT()
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        let responseData = try decoder.decode(SubscriptionStatusesResponse.self, from: data)
        return responseData.data
    }

    // Extend subscription renewal date
    func extendRenewalDate(transactionId: String, newDate: Date) async throws {
        let url = URL(string: "\(environment.baseURL)/inApps/v1/subscriptions/\(transactionId)/extendRenewalDate")!

        let requestBody: [String: Any] = [
            "extendByDays": 7,
            "extendReasonCode": 1, // Customer satisfaction
            "requestIdentifier": UUID().uuidString
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(bundleId, forHTTPHeaderField: "X-Apple-Bundle-ID")
        
        // Add JWT authentication
        let jwtToken = try generateJWT()
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }

    // Send consumption information
    func sendConsumptionInfo(transactionId: String, consumptionInfo: ConsumptionInfo) async throws {
        let url = URL(string: "\(environment.baseURL)/inApps/v1/transactions/consumption/\(transactionId)")!

        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(bundleId, forHTTPHeaderField: "X-Apple-Bundle-ID")
        
        // Add JWT authentication
        let jwtToken = try generateJWT()
        request.setValue("Bearer \(jwtToken)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONEncoder().encode(consumptionInfo)

        let (_, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
    }
}

// MARK: - Data Models

struct SubscriptionStatusResponse: Codable {
    let data: SubscriptionStatusData
}

struct SubscriptionStatusesResponse: Codable {
    let data: [SubscriptionStatusResponse]
}

struct SubscriptionStatusData: Codable {
    let subscriptionGroupIdentifier: String
    let lastTransactions: [LastTransactionItem]
    let environment: String
}

struct LastTransactionItem: Codable {
    let originalTransactionId: String
    let status: Int
    let signedTransactionInfo: String
    let signedRenewalInfo: String?
}

struct ConsumptionInfo: Codable {
    let customerConsented: Bool
    let deliveryStatus: Int
    let lifetimeDollarsRefunded: Int
    let lifetimeDollarsPurchased: Int
    let platform: Int
    let playTime: Int?
    let sampleContentProvided: Bool
}

enum AppStoreEnvironment {
    case sandbox
    case production

    var baseURL: String {
        switch self {
        case .sandbox:
            return "https://api.storekit-sandbox.itunes.apple.com"
        case .production:
            return "https://api.storekit.itunes.apple.com"
        }
    }
}

enum APIError: Error {
    case invalidResponse
    case networkError
    case decodingError
}
