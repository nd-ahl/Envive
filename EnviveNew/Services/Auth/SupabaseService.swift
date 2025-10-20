import Foundation
import Supabase

/// Singleton service that manages the Supabase client connection
class SupabaseService {
    static let shared = SupabaseService()

    let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: URL(string: SupabaseConfig.url)!,
            supabaseKey: SupabaseConfig.anonKey
        )
    }

    /// Get the current authenticated user
    var currentUser: Supabase.User? {
        get async {
            try? await client.auth.session.user
        }
    }

    /// Get the current user ID
    var currentUserId: String? {
        get async {
            try? await client.auth.session.user.id.uuidString
        }
    }
}
