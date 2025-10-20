import Foundation
import Combine

// MARK: - View Model Factory

/// Factory for creating view models with proper dependency injection
final class ViewModelFactory {
    private let container: DependencyContainer

    init(container: DependencyContainer = .shared) {
        self.container = container
    }

    // MARK: - Credibility View Models

    /// Creates a view model for displaying credibility status
    func makeCredibilityStatusViewModel(childId: UUID) -> CredibilityStatusViewModel {
        CredibilityStatusViewModel(credibilityService: container.credibilityService, childId: childId)
    }

    /// Creates a view model for XP redemption
    func makeXPRedemptionViewModel(availableXP: Int, childId: UUID) -> XPRedemptionViewModel {
        XPRedemptionViewModel(
            availableXP: availableXP,
            credibilityService: container.credibilityService,
            rewardRepository: container.rewardRepository,
            childId: childId
        )
    }

    // MARK: - Task View Models

    /// Creates a view model for task verification
    func makeTaskVerificationViewModel() -> TaskVerificationViewModel {
        TaskVerificationViewModel(
            credibilityService: container.credibilityService
        )
    }

    // MARK: - App Selection View Models

    /// Creates a view model for app selection
    func makeAppSelectionViewModel() -> AppSelectionViewModel {
        AppSelectionViewModel(
            appSelectionService: container.appSelectionService
        )
    }

    // MARK: - Theme View Models

    /// Creates a view model for theme settings
    func makeThemeSettingsViewModel() -> ThemeSettingsViewModel {
        ThemeSettingsViewModel(themeService: container.themeService)
    }

    // MARK: - Helper Methods

    /// Creates a test view model factory with mock dependencies
    static func makeTestFactory(storage: StorageService) -> ViewModelFactory {
        let testContainer = DependencyContainer.makeTestContainer(storage: storage)
        return ViewModelFactory(container: testContainer)
    }
}

// MARK: - Credibility Status View Model

/// View model for displaying credibility status
final class CredibilityStatusViewModel: ObservableObject {
    @Published var status: CredibilityStatus
    @Published var isLoading: Bool = false

    private let credibilityService: CredibilityService
    private let childId: UUID

    init(credibilityService: CredibilityService, childId: UUID) {
        self.credibilityService = credibilityService
        self.childId = childId
        self.status = credibilityService.getCredibilityStatus(childId: childId)
    }

    func refresh() {
        status = credibilityService.getCredibilityStatus(childId: childId)
    }

    func applyDecay() {
        isLoading = true
        credibilityService.applyTimeBasedDecay(childId: childId)
        refresh()
        isLoading = false
    }

    var scoreColor: String {
        status.tier.color
    }

    var formattedRate: String {
        String(format: "%.1fx", status.conversionRate)
    }
}

// MARK: - XP Redemption View Model

/// View model for XP redemption flow
final class XPRedemptionViewModel: ObservableObject {
    @Published var xpToRedeem: String = ""
    @Published var isProcessing: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    let availableXP: Int
    private let credibilityService: CredibilityService
    private let rewardRepository: RewardRepository
    private let childId: UUID

    init(
        availableXP: Int,
        credibilityService: CredibilityService,
        rewardRepository: RewardRepository,
        childId: UUID
    ) {
        self.availableXP = availableXP
        self.credibilityService = credibilityService
        self.rewardRepository = rewardRepository
        self.childId = childId
    }

    var xpAmount: Int? {
        Int(xpToRedeem)
    }

    var isValidAmount: Bool {
        guard let xp = xpAmount else { return false }
        return xp > 0 && xp <= availableXP
    }

    func previewConversion() -> (rate: Double, minutes: Int)? {
        guard let xp = xpAmount, isValidAmount else { return nil }
        let minutes = credibilityService.calculateXPToMinutes(xpAmount: xp, childId: childId)
        let rate = credibilityService.getConversionRate(childId: childId)
        return (rate, minutes)
    }

    func redeemXP() {
        guard let xp = xpAmount, isValidAmount else {
            errorMessage = "Please enter a valid amount"
            return
        }

        isProcessing = true
        errorMessage = nil

        let minutes = credibilityService.calculateXPToMinutes(xpAmount: xp, childId: childId)

        // Update earned minutes
        let currentMinutes = rewardRepository.loadEarnedMinutes()
        rewardRepository.saveEarnedMinutes(currentMinutes + minutes)

        isProcessing = false
        successMessage = "Successfully redeemed \(xp) XP for \(minutes) minutes!"
    }

    func setQuickAmount(_ amount: Int) {
        xpToRedeem = "\(min(amount, availableXP))"
    }
}

// MARK: - Task Verification View Model

/// View model for task verification
final class TaskVerificationViewModel: ObservableObject {
    @Published var verifications: [TaskVerificationItem] = []
    @Published var selectedFilter: TaskVerificationStatus = .pending
    @Published var selectedChild: UUID?
    @Published var isLoading: Bool = false

    private let credibilityService: CredibilityService

    init(credibilityService: CredibilityService) {
        self.credibilityService = credibilityService
        loadMockData()
    }

    var filteredVerifications: [TaskVerificationItem] {
        var filtered = verifications.filter { $0.status == selectedFilter }
        if let childId = selectedChild {
            filtered = filtered.filter { $0.userId == childId }
        }
        return filtered
    }

    func approveTask(_ verification: TaskVerificationItem, notes: String? = nil) {
        if let index = verifications.firstIndex(where: { $0.id == verification.id }) {
            verifications[index].status = .approved
            verifications[index].notes = notes
            verifications[index].reviewedAt = Date()
            verifications[index].updatedAt = Date()

            // Update credibility
            credibilityService.processApprovedTask(
                taskId: verification.taskId,
                childId: verification.userId,
                reviewerId: verification.reviewerId ?? UUID(),
                notes: notes
            )
        }
    }

    func rejectTask(_ verification: TaskVerificationItem, notes: String) {
        if let index = verifications.firstIndex(where: { $0.id == verification.id }) {
            verifications[index].status = .rejected
            verifications[index].notes = notes
            verifications[index].reviewedAt = Date()
            verifications[index].updatedAt = Date()
            verifications[index].appealDeadline = Calendar.current.date(byAdding: .hour, value: 24, to: Date())

            // Update credibility
            credibilityService.processDownvote(
                taskId: verification.taskId,
                childId: verification.userId,
                reviewerId: verification.reviewerId ?? UUID(),
                notes: notes
            )
        }
    }

    func bulkApprove(_ items: [TaskVerificationItem]) {
        for item in items {
            approveTask(item, notes: "Bulk approved")
        }
    }

    private func loadMockData() {
        // Mock data for demonstration
        verifications = [
            TaskVerificationItem(
                id: UUID(),
                taskId: UUID(),
                userId: UUID(),
                status: .pending,
                taskTitle: "Morning Run",
                taskDescription: "3 mile run",
                taskCategory: "Exercise",
                taskXPReward: 150,
                locationName: "Park",
                completedAt: Date().addingTimeInterval(-3600),
                childName: "Alex"
            )
        ]
    }
}

// MARK: - App Selection View Model

/// View model for app selection
final class AppSelectionViewModel: ObservableObject {
    @Published var hasSelectedApps: Bool = false
    @Published var selectedCount: Int = 0
    @Published var isLoading: Bool = false

    private let appSelectionService: AppSelectionService

    init(appSelectionService: AppSelectionService) {
        self.appSelectionService = appSelectionService
        loadSelection()
    }

    func loadSelection() {
        isLoading = true
        appSelectionService.loadSelection()
        hasSelectedApps = appSelectionService.hasSelectedApps
        selectedCount = appSelectionService.selectedCount
        isLoading = false
    }

    func saveSelection() {
        isLoading = true
        appSelectionService.saveSelection()
        hasSelectedApps = appSelectionService.hasSelectedApps
        selectedCount = appSelectionService.selectedCount
        isLoading = false
    }

    func clearSelection() {
        appSelectionService.clearSelection()
        hasSelectedApps = false
        selectedCount = 0
    }
}

// MARK: - Supporting Types

/// Task verification item for view model
struct TaskVerificationItem: Identifiable {
    let id: UUID
    let taskId: UUID
    let userId: UUID
    var reviewerId: UUID?
    var status: TaskVerificationStatus
    var notes: String?
    var appealNotes: String?
    var appealDeadline: Date?
    let createdAt: Date
    var updatedAt: Date
    var reviewedAt: Date?

    let taskTitle: String
    let taskDescription: String?
    let taskCategory: String
    let taskXPReward: Int
    let photoURL: String?
    let locationName: String?
    let completedAt: Date
    let childName: String

    init(
        id: UUID = UUID(),
        taskId: UUID,
        userId: UUID,
        reviewerId: UUID? = nil,
        status: TaskVerificationStatus = .pending,
        notes: String? = nil,
        appealNotes: String? = nil,
        appealDeadline: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        reviewedAt: Date? = nil,
        taskTitle: String,
        taskDescription: String? = nil,
        taskCategory: String,
        taskXPReward: Int,
        photoURL: String? = nil,
        locationName: String? = nil,
        completedAt: Date,
        childName: String
    ) {
        self.id = id
        self.taskId = taskId
        self.userId = userId
        self.reviewerId = reviewerId
        self.status = status
        self.notes = notes
        self.appealNotes = appealNotes
        self.appealDeadline = appealDeadline
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.reviewedAt = reviewedAt
        self.taskTitle = taskTitle
        self.taskDescription = taskDescription
        self.taskCategory = taskCategory
        self.taskXPReward = taskXPReward
        self.photoURL = photoURL
        self.locationName = locationName
        self.completedAt = completedAt
        self.childName = childName
    }
}

/// Task verification status
enum TaskVerificationStatus: String, CaseIterable {
    case pending
    case approved
    case rejected
    case appealed
}
