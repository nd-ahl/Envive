import FamilyControls
import Foundation

protocol ScreenTimeService {
    var isAuthorized: Bool { get }
    func requestAuthorization() async throws
    func revokeAuthorization()
}

protocol AppRestrictionService {
    func blockApps(_ selection: FamilyActivitySelection)
    func unblockApps()
    func clearAllSettings()
}

protocol ActivitySchedulingService {
    var isMonitoring: Bool { get }
    func startScreenTimeSession(durationMinutes: Int)
    func stopAllMonitoring()
}
