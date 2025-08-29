import Foundation
import Supabase

class SupabaseManager {
    static let shared = SupabaseManager()
    
    let client = SupabaseClient(
        supabaseURL: URL(string: "https://ztzpjsbfzcccvbacgskc.supabase.co")!,
        supabaseKey: "sb_publishable_6lBH6DSnvQ9hTY_3k5Gsfg_RdGVc95c"
    )
    
    private init() {}
}
