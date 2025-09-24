import Foundation
import Supabase

class SupabaseManager: ObservableObject {
    static let shared = SupabaseManager()
    
    let client: SupabaseClient = {
        let config = ConfigManager.shared

        #if DEBUG
        print("🚀 Initializing SupabaseManager...")
        #endif
        config.printConfigurationStatus()

        // Validate configuration before creating client
        guard config.validateConfiguration() else {
            fatalError("❌ Invalid Supabase configuration! Check your Info.plist values.")
        }

        guard let url = URL(string: config.supabaseURL) else {
            fatalError("❌ Invalid Supabase URL format")
        }

        let client = SupabaseClient(
            supabaseURL: url,
            supabaseKey: config.supabaseAnonKey
        )

        #if DEBUG
        print("✅ SupabaseClient initialized successfully")
        #endif
        return client
    }()
    
    init() {}
    
    // MARK: - Authentication Helpers
    
    func clearAuthSession() async {
        do {
            try await client.auth.signOut()
        } catch {
            print("Error clearing auth session: \(error)")
        }
    }
    
    // MARK: - Employer Methods
    
    func fetchEmployers() async throws -> [Employer] {
        let response: [Employer] = try await client
            .from("employers")
            .select()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Shift Methods
    
    func saveShift(_ shift: Shift) async throws -> Shift {
        let response: Shift = try await client
            .from("shifts")
            .insert(shift)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    func updateShift(_ shift: Shift) async throws {
        guard let shiftId = shift.id else {
            throw NSError(domain: "SupabaseManager", code: 0, userInfo: [NSLocalizedDescriptionKey: "Shift ID is required for update"])
        }
        
        try await client
            .from("shifts")
            .update(shift)
            .eq("id", value: shiftId)
            .execute()
    }
    
    func fetchShifts() async throws -> [Shift] {
        let response: [Shift] = try await client
            .from("shifts")
            .select()
            .execute()
            .value
        
        return response
    }
    
    // MARK: - Shift Income Methods
    
    func saveShiftIncome(_ shiftIncome: ShiftIncomeData) async throws {
        try await client
            .from("shift_income")
            .insert(shiftIncome)
            .execute()
    }
    
    func fetchShiftIncome() async throws -> [ShiftIncomeData] {
        let response: [ShiftIncomeData] = try await client
            .from("shift_income")
            .select()
            .execute()
            .value
        
        return response
    }
    
    func fetchShiftIncomeForDate(_ date: Date) async throws -> [ShiftIncomeData] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        let response: [ShiftIncomeData] = try await client
            .from("shift_income")
            .select()
            .eq("shift_date", value: dateString)
            .execute()
            .value
        
        return response
    }

    // MARK: - Alert Methods

    func createAlert(
        alertType: String,
        title: String,
        message: String,
        action: String? = nil,
        data: [String: Any]? = nil
    ) async throws -> UUID {
        let userId = try await client.auth.session.user.id

        struct AlertInsert: Codable {
            let user_id: String
            let alert_type: String
            let title: String
            let message: String
            let action: String?
            let data: String?
        }

        // Convert data to JSON string if provided
        var jsonString: String? = nil
        if let data = data, let jsonData = try? JSONSerialization.data(withJSONObject: data) {
            jsonString = String(data: jsonData, encoding: .utf8)
        }

        let alertInsert = AlertInsert(
            user_id: userId.uuidString,
            alert_type: alertType,
            title: title,
            message: message,
            action: action,
            data: jsonString
        )

        let response: DatabaseAlert = try await client
            .from("alerts")
            .insert(alertInsert)
            .select()
            .single()
            .execute()
            .value

        print("✅ Created alert in database: \(response.id)")
        return response.id
    }

    func fetchUnreadAlerts() async throws -> [DatabaseAlert] {
        let userId = try await client.auth.session.user.id

        // Since we delete read alerts, all existing alerts are unread
        let response: [DatabaseAlert] = try await client
            .from("alerts")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .execute()
            .value

        return response
    }

    func fetchAllAlerts(limit: Int = 50) async throws -> [DatabaseAlert] {
        let userId = try await client.auth.session.user.id

        let response: [DatabaseAlert] = try await client
            .from("alerts")
            .select()
            .eq("user_id", value: userId)
            .order("created_at", ascending: false)
            .limit(limit)
            .execute()
            .value

        return response
    }


    func deleteAlert(_ alertId: UUID) async throws {
        try await client
            .from("alerts")
            .delete()
            .eq("id", value: alertId)
            .execute()

        print("✅ Deleted alert: \(alertId)")
    }
}

// Date extension for ISO string formatting
extension Date {
    func toISOString() -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.string(from: self)
    }
}
