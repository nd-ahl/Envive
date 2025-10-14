import XCTest
import FamilyControls
@testable import EnviveNew

final class RepositoryTests: XCTestCase {
    var mockStorage: MockStorage!

    override func setUp() {
        super.setUp()
        mockStorage = MockStorage()
    }

    override func tearDown() {
        mockStorage.clear()
        mockStorage = nil
        super.tearDown()
    }

    // MARK: - CredibilityRepository Tests

    func testCredibilityRepositorySaveAndLoadScore() {
        let repo = CredibilityRepository(storage: mockStorage)
        repo.saveScore(85)
        let loaded = repo.loadScore()
        XCTAssertEqual(loaded, 85)
    }

    func testCredibilityRepositoryLoadScoreDefaultValue() {
        let repo = CredibilityRepository(storage: mockStorage)
        let loaded = repo.loadScore(defaultValue: 100)
        XCTAssertEqual(loaded, 100)
    }

    func testCredibilityRepositorySaveAndLoadHistory() {
        let repo = CredibilityRepository(storage: mockStorage)
        let events = [
            CredibilityHistoryEvent(event: .approvedTask, amount: 2, newScore: 102),
            CredibilityHistoryEvent(event: .downvote, amount: -10, newScore: 92)
        ]

        repo.saveHistory(events)
        let loaded = repo.loadHistory()

        XCTAssertEqual(loaded.count, 2)
        XCTAssertEqual(loaded[0].event, .approvedTask)
        XCTAssertEqual(loaded[1].event, .downvote)
    }

    func testCredibilityRepositorySaveAndLoadConsecutiveTasks() {
        let repo = CredibilityRepository(storage: mockStorage)
        repo.saveConsecutiveTasks(5)
        let loaded = repo.loadConsecutiveTasks()
        XCTAssertEqual(loaded, 5)
    }

    func testCredibilityRepositorySaveAndLoadRedemptionBonus() {
        let repo = CredibilityRepository(storage: mockStorage)
        let expiry = Date().addingTimeInterval(86400 * 7)

        repo.saveRedemptionBonus(active: true, expiry: expiry)
        let loaded = repo.loadRedemptionBonus()

        XCTAssertTrue(loaded.active)
        XCTAssertNotNil(loaded.expiry)
    }

    func testCredibilityRepositoryRedemptionBonusWithoutExpiry() {
        let repo = CredibilityRepository(storage: mockStorage)

        repo.saveRedemptionBonus(active: false, expiry: nil)
        let loaded = repo.loadRedemptionBonus()

        XCTAssertFalse(loaded.active)
        XCTAssertNil(loaded.expiry)
    }

    // MARK: - AppSelectionRepository Tests

    func testAppSelectionRepositorySaveAndLoad() {
        let repo = AppSelectionRepositoryImpl(storage: mockStorage)
        let selection = FamilyActivitySelection()

        repo.saveSelection(selection)
        let loaded = repo.loadSelection()

        XCTAssertNotNil(loaded)
    }

    func testAppSelectionRepositoryClear() {
        let repo = AppSelectionRepositoryImpl(storage: mockStorage)
        let selection = FamilyActivitySelection()

        repo.saveSelection(selection)
        XCTAssertNotNil(repo.loadSelection())

        repo.clearSelection()
        XCTAssertNil(repo.loadSelection())
    }

    // MARK: - RewardRepository Tests

    func testRewardRepositorySaveAndLoadEarnedMinutes() {
        let repo = RewardRepositoryImpl(storage: mockStorage)

        repo.saveEarnedMinutes(45)
        let loaded = repo.loadEarnedMinutes()

        XCTAssertEqual(loaded, 45)
    }

    func testRewardRepositoryLoadEarnedMinutesDefault() {
        let repo = RewardRepositoryImpl(storage: mockStorage)
        let loaded = repo.loadEarnedMinutes()
        XCTAssertEqual(loaded, 0)
    }
}
