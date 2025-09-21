import SwiftUI
import FamilyControls
import ManagedSettings
import DeviceActivity

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
        try await authorizationCenter.requestAuthorization(for: .individual)
        await MainActor.run {
            updateAuthorizationStatus()
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