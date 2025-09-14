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
    
    func saveShift(_ shift: Shift) async throws {
        try await client
            .from("shifts")
            .insert(shift)
            .execute()
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
}
