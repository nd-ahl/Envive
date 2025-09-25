import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity
import Combine

class ScreenTimeManager: ObservableObject {
    private let authorizationCenter = AuthorizationCenter.shared
    @Published var authorizationStatus: AuthorizationStatus = .notDetermined
    @Published var isAuthorized: Bool = false

    init() {
        updateAuthorizationStatus()
    }

    func updateAuthorizationStatus() {
        authorizationStatus = authorizationCenter.authorizationStatus
        isAuthorized = authorizationStatus == .approved
    }

    func requestAuthorization() async throws {
        print("🔐 Requesting Screen Time authorization for individual management...")
        print("🔐 Current status before request: \(authorizationStatus)")

        do {
            try await authorizationCenter.requestAuthorization(for: .individual)
            await MainActor.run {
                updateAuthorizationStatus()
                print("🔐 Authorization request completed. New status: \(self.authorizationStatus)")
            }
        } catch {
            print("❌ Screen Time authorization failed with error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            throw error
        }
    }

    func revokeAuthorization() {
        authorizationCenter.revokeAuthorization { [weak self] result in
            DispatchQueue.main.async {
                self?.updateAuthorizationStatus()
            }
        }
    }
}