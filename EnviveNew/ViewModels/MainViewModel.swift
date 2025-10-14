import SwiftUI
import Combine

/// Main ViewModel that coordinates services and manages app-level state
final class MainViewModel: ObservableObject {
    // Services from DependencyContainer
    let credibilityService: CredibilityService
    let storageService: StorageService
    let appSelectionService: AppSelectionService
    let notificationService: NotificationServiceImpl
    let cameraService: CameraServiceImpl

    // Legacy managers (to be migrated)
    @Published var screenTimeModel: EnhancedScreenTimeModel

    init(dependencies: DependencyContainer = .shared) {
        self.credibilityService = dependencies.credibilityService
        self.storageService = dependencies.storage
        self.appSelectionService = dependencies.appSelectionService
        self.notificationService = dependencies.notificationService
        self.cameraService = dependencies.cameraService

        // Initialize legacy model (will be refactored later)
        self.screenTimeModel = EnhancedScreenTimeModel()
    }

    // Convenience accessors for common operations
    var currentUser: User {
        screenTimeModel.currentUser
    }

    var xpBalance: Int {
        screenTimeModel.xpBalance
    }

    var minutesEarned: Int {
        screenTimeModel.minutesEarned
    }

    var isSessionActive: Bool {
        screenTimeModel.isSessionActive
    }
}
