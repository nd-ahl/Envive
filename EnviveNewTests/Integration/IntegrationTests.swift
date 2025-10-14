import XCTest
@testable import EnviveNew

final class IntegrationTests: XCTestCase {

    // MARK: - Credibility Service Integration

    func testCredibilityServiceFullWorkflow() {
        let mockStorage = MockStorage()
        let service = CredibilityServiceImpl(
            storage: mockStorage,
            calculator: CredibilityCalculator(),
            tierProvider: CredibilityTierProvider()
        )

        // Initial state
        XCTAssertEqual(service.credibilityScore, 100)

        // Process downvote
        let taskId1 = UUID()
        let reviewerId = UUID()
        service.processDownvote(taskId: taskId1, reviewerId: reviewerId, notes: "Incomplete")
        XCTAssertEqual(service.credibilityScore, 90)

        // Undo the downvote
        service.undoDownvote(taskId: taskId1, reviewerId: reviewerId)
        XCTAssertEqual(service.credibilityScore, 100)

        // Build up a streak
        for _ in 0..<10 {
            service.processApprovedTask(taskId: UUID(), reviewerId: reviewerId, notes: nil)
        }

        XCTAssertEqual(service.consecutiveApprovedTasks, 10)
        let streakBonuses = service.credibilityHistory.filter { $0.event == .streakBonus }
        XCTAssertEqual(streakBonuses.count, 1)
    }

    func testCredibilityPersistenceAcrossInstances() {
        let mockStorage = MockStorage()

        // First instance
        let service1 = CredibilityServiceImpl(
            storage: mockStorage,
            calculator: CredibilityCalculator(),
            tierProvider: CredibilityTierProvider()
        )

        service1.processApprovedTask(taskId: UUID(), reviewerId: UUID(), notes: "Test")
        service1.processApprovedTask(taskId: UUID(), reviewerId: UUID(), notes: "Test")
        service1.processDownvote(taskId: UUID(), reviewerId: UUID(), notes: "Test")

        let score1 = service1.credibilityScore
        let history1Count = service1.credibilityHistory.count
        let consecutive1 = service1.consecutiveApprovedTasks

        // Second instance with same storage
        let service2 = CredibilityServiceImpl(
            storage: mockStorage,
            calculator: CredibilityCalculator(),
            tierProvider: CredibilityTierProvider()
        )

        XCTAssertEqual(service2.credibilityScore, score1)
        XCTAssertEqual(service2.credibilityHistory.count, history1Count)
        XCTAssertEqual(service2.consecutiveApprovedTasks, consecutive1)
    }

    // MARK: - Repository Integration

    func testRepositoryWithStorageService() {
        let mockStorage = MockStorage()
        let credRepo = CredibilityRepository(storage: mockStorage)
        let rewardRepo = RewardRepositoryImpl(storage: mockStorage)

        // Save credibility data
        credRepo.saveScore(85)
        credRepo.saveConsecutiveTasks(5)

        // Save reward data
        rewardRepo.saveEarnedMinutes(45)

        // Verify all data persisted correctly
        XCTAssertEqual(credRepo.loadScore(), 85)
        XCTAssertEqual(credRepo.loadConsecutiveTasks(), 5)
        XCTAssertEqual(rewardRepo.loadEarnedMinutes(), 45)
    }

    // MARK: - App Selection Service Integration

    func testAppSelectionServiceWithRepository() {
        let mockStorage = MockStorage()
        let repo = AppSelectionRepositoryImpl(storage: mockStorage)
        let service = AppSelectionService(repository: repo)

        // Initially should have no selected apps
        XCTAssertFalse(service.hasSelectedApps)
        XCTAssertEqual(service.selectedCount, 0)

        // Save selection
        service.saveSelection()

        // Load selection
        service.loadSelection()

        XCTAssertFalse(service.hasSelectedApps)
    }

    // MARK: - Dependency Container Integration

    func testDependencyContainerServicesWork() {
        let container = DependencyContainer.shared

        // Verify all services can be accessed
        XCTAssertNotNil(container.storage)
        XCTAssertNotNil(container.credibilityService)
        XCTAssertNotNil(container.appSelectionRepository)
        XCTAssertNotNil(container.rewardRepository)
        XCTAssertNotNil(container.appSelectionService)
        XCTAssertNotNil(container.notificationService)
        XCTAssertNotNil(container.locationService)
        XCTAssertNotNil(container.cameraService)
    }

    func testTestContainerCreation() {
        let mockStorage = MockStorage()
        let container = DependencyContainer.makeTestContainer(storage: mockStorage)

        // Verify test container uses mock storage
        XCTAssertNotNil(container.storage)

        // Test that mock storage works
        mockStorage.saveInt(42, forKey: "test")
        XCTAssertEqual(mockStorage.loadInt(forKey: "test", defaultValue: 0), 42)
    }

    // MARK: - End-to-End Workflow

    func testEndToEndCredibilityWorkflow() {
        // Simulate a complete user workflow
        let mockStorage = MockStorage()
        let service = CredibilityServiceImpl(
            storage: mockStorage,
            calculator: CredibilityCalculator(),
            tierProvider: CredibilityTierProvider()
        )

        let reviewerId = UUID()

        // Day 1: Complete 5 tasks
        for _ in 0..<5 {
            service.processApprovedTask(taskId: UUID(), reviewerId: reviewerId, notes: nil)
        }
        XCTAssertEqual(service.consecutiveApprovedTasks, 5)

        // Day 2: Get one downvote
        service.processDownvote(taskId: UUID(), reviewerId: reviewerId, notes: "Incomplete")
        XCTAssertEqual(service.consecutiveApprovedTasks, 0)
        XCTAssertLessThan(service.credibilityScore, 100)

        // Day 3-5: Complete 10 more tasks (trigger streak bonus)
        for _ in 0..<10 {
            service.processApprovedTask(taskId: UUID(), reviewerId: reviewerId, notes: nil)
        }
        XCTAssertEqual(service.consecutiveApprovedTasks, 10)

        // Verify streak bonus was awarded
        let streakBonuses = service.credibilityHistory.filter { $0.event == .streakBonus }
        XCTAssertGreaterThanOrEqual(streakBonuses.count, 1)

        // Verify XP conversion works
        let minutes = service.calculateXPToMinutes(xpAmount: 100)
        XCTAssertGreaterThan(minutes, 0)
    }
}
