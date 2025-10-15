import Foundation

final class DependencyContainer {
    static let shared = DependencyContainer()

    // MARK: - Services

    lazy var storage: StorageService = {
        UserDefaultsStorage()
    }()

    lazy var credibilityService: CredibilityService = {
        CredibilityServiceImpl(
            storage: storage,
            calculator: CredibilityCalculator(),
            tierProvider: CredibilityTierProvider()
        )
    }()

    // MARK: - Repositories

    lazy var appSelectionRepository: AppSelectionRepository = {
        AppSelectionRepositoryImpl(storage: storage)
    }()

    lazy var rewardRepository: RewardRepository = {
        RewardRepositoryImpl(storage: storage)
    }()

    lazy var themeRepository: ThemeRepository = {
        ThemeRepository(storage: storage)
    }()

    lazy var xpRepository: XPRepository = {
        XPRepositoryImpl(storage: storage)
    }()

    lazy var taskRepository: TaskRepository = {
        TaskRepositoryImpl(storage: storage)
    }()

    // MARK: - App Services

    lazy var appSelectionService: AppSelectionService = {
        AppSelectionService(repository: appSelectionRepository)
    }()

    lazy var notificationService: NotificationServiceImpl = {
        NotificationServiceImpl()
    }()

    lazy var cameraService: CameraServiceImpl = {
        CameraServiceImpl()
    }()

    lazy var themeService: ThemeService = {
        ThemeServiceImpl(repository: themeRepository)
    }()

    lazy var xpService: XPService = {
        XPServiceImpl(repository: xpRepository, credibilityService: credibilityService)
    }()

    lazy var starterBonusService: StarterBonusService = {
        StarterBonusServiceImpl(xpRepository: xpRepository, storage: storage)
    }()

    lazy var taskService: TaskService = {
        TaskServiceImpl(
            repository: taskRepository,
            xpService: xpService,
            credibilityService: credibilityService
        )
    }()

    // MARK: - Device Mode Management

    lazy var deviceModeManager: DeviceModeManager = {
        LocalDeviceModeManager(storage: storage)
    }()

    // MARK: - View Model Factory

    lazy var viewModelFactory: ViewModelFactory = {
        ViewModelFactory(container: self)
    }()

    // Additional services will be added in later phases
    // lazy var screenTimeService: ScreenTimeService = { ... }()
    // lazy var appRestrictionService: AppRestrictionService = { ... }()
    // lazy var activityScheduler: ActivitySchedulingService = { ... }()
    // lazy var rewardService: RewardService = { ... }()

    // FUTURE: When migrating to Firebase, swap out LocalDeviceModeManager:
    // lazy var deviceModeManager: DeviceModeManager = {
    //     FirebaseDeviceModeManager(auth: firebaseAuth, db: firestore)
    // }()

    private init() {}

    // For testing
    static func makeTestContainer(storage: StorageService) -> DependencyContainer {
        let container = DependencyContainer()
        container.storage = storage
        return container
    }
}
