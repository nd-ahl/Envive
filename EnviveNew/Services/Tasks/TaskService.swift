import Foundation

// MARK: - Task Service Protocol

protocol TaskService {
    // Template operations
    func getAllTemplates() -> [TaskTemplate]
    func saveTemplate(_ template: TaskTemplate)

    // Child operations
    func searchTasks(query: String) -> [TaskTemplate]
    func getTasksByCategory(_ category: TaskTemplateCategory) -> [TaskTemplate]
    func claimTask(template: TaskTemplate, childId: UUID, level: TaskLevel) -> TaskAssignment
    func startTask(assignmentId: UUID) -> Bool
    func completeTask(assignmentId: UUID, photoURL: String, notes: String?, timeMinutes: Int?) -> Bool

    // Parent operations
    func assignTask(template: TaskTemplate, childId: UUID, parentId: UUID, level: TaskLevel, dueDate: Date?) -> TaskAssignment
    func getPendingApprovals() -> [TaskAssignment]
    func getPendingApprovals(forChild childId: UUID) -> [TaskAssignment]
    func approveTask(assignmentId: UUID, parentId: UUID, parentNotes: String?, credibilityScore: Int) -> TaskServiceApprovalResult
    func approveTaskWithEdits(assignmentId: UUID, parentId: UUID, newLevel: TaskLevel, parentNotes: String?, credibilityScore: Int) -> TaskServiceApprovalResult
    func declineTask(assignmentId: UUID, parentId: UUID, reason: String, credibilityScore: Int) -> TaskServiceDeclineResult

    // Queries
    func getChildTasks(childId: UUID, status: TaskAssignmentStatus?) -> [TaskAssignment]
    func getTask(id: UUID) -> TaskAssignment?

    // Notification tracking
    func markDeclineAsViewed(assignmentId: UUID) -> Bool

    // Task management
    func deleteTask(assignmentId: UUID) -> Bool
    func updateTask(assignmentId: UUID, title: String?, level: TaskLevel?, dueDate: Date?) -> Bool

    // Test utilities
    func deleteAllAssignments()
}

// MARK: - Task Service Approval Result

struct TaskServiceApprovalResult {
    let success: Bool
    let xpAwarded: Int
    let newCredibility: Int
    let assignment: TaskAssignment
    let message: String
}

// MARK: - Task Service Decline Result

struct TaskServiceDeclineResult {
    let success: Bool
    let newCredibility: Int
    let assignment: TaskAssignment
    let message: String
}

// MARK: - Task Service Implementation

class TaskServiceImpl: TaskService {
    private let repository: TaskRepository
    private let xpService: XPService
    private let credibilityService: CredibilityService
    private let householdContext = HouseholdContext.shared
    private let notificationService = NotificationServiceImpl()
    private let deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager
    private var badgeService: BadgeService?

    init(repository: TaskRepository, xpService: XPService, credibilityService: CredibilityService) {
        self.repository = repository
        self.xpService = xpService
        self.credibilityService = credibilityService
        // Badge service will be set after initialization to avoid circular dependency
    }

    func setBadgeService(_ badgeService: BadgeService) {
        self.badgeService = badgeService
    }

    // MARK: - Template Operations

    func getAllTemplates() -> [TaskTemplate] {
        return repository.getAllTemplates()
    }

    func saveTemplate(_ template: TaskTemplate) {
        repository.saveTemplate(template)
        print("✅ Saved custom template: \(template.title)")
    }

    // MARK: - Child Operations

    func searchTasks(query: String) -> [TaskTemplate] {
        return repository.searchTemplates(query: query)
    }

    func getTasksByCategory(_ category: TaskTemplateCategory) -> [TaskTemplate] {
        return repository.getTemplatesByCategory(category)
    }

    func claimTask(template: TaskTemplate, childId: UUID, level: TaskLevel) -> TaskAssignment {
        let assignment = TaskAssignment.childClaimed(
            template: template,
            childId: childId,
            level: level
        )
        repository.saveAssignment(assignment)
        return assignment
    }

    func startTask(assignmentId: UUID) -> Bool {
        guard var assignment = repository.getAssignment(id: assignmentId) else {
            return false
        }

        assignment.status = .inProgress
        assignment.startedAt = Date()
        repository.saveAssignment(assignment)
        return true
    }

    func completeTask(assignmentId: UUID, photoURL: String, notes: String?, timeMinutes: Int?) -> Bool {
        guard var assignment = repository.getAssignment(id: assignmentId) else {
            return false
        }

        // IMPORTANT: All tasks require photo proof - reject empty photoURL
        guard !photoURL.isEmpty else {
            print("❌ Task completion rejected: Photo proof is required")
            return false
        }

        assignment.status = .pendingReview
        assignment.completedAt = Date()
        assignment.photoURL = photoURL
        assignment.childNotes = notes
        assignment.completionTimeMinutes = timeMinutes

        repository.saveAssignment(assignment)

        // Process daily streak when task is uploaded
        credibilityService.processTaskUpload(taskId: assignment.id, childId: assignment.childId)

        // Send notification to parent
        if let childProfile = deviceModeManager.getProfile(byId: assignment.childId) {
            let childName = childProfile.name
            notificationService.sendTaskPendingReviewNotification(
                childName: childName,
                taskTitle: assignment.title,
                xpReward: assignment.assignedLevel.baseXP
            )
        }

        return true
    }

    // MARK: - Parent Operations

    func assignTask(template: TaskTemplate, childId: UUID, parentId: UUID, level: TaskLevel, dueDate: Date?) -> TaskAssignment {
        let assignment = TaskAssignment.fromTemplate(
            template,
            childId: childId,
            assignedBy: parentId,
            level: level,
            dueDate: dueDate
        )
        repository.saveAssignment(assignment)

        // Send notification to child
        if let childProfile = deviceModeManager.getProfile(byId: childId) {
            let childName = childProfile.name
            notificationService.sendTaskAssignedNotification(
                childName: childName,
                taskTitle: assignment.title,
                difficulty: level.displayName,
                xpReward: level.baseXP
            )
        }

        return assignment
    }

    func getPendingApprovals() -> [TaskAssignment] {
        let allPendingTasks = repository.getPendingReviewTasks()

        // Filter to only tasks for children in current household
        let householdTasks = householdContext.filterTasksForHousehold(allPendingTasks) { task in
            task.childId
        }

        print("📋 getPendingApprovals: \(allPendingTasks.count) total → \(householdTasks.count) household-scoped")
        return householdTasks
    }

    func getPendingApprovals(forChild childId: UUID) -> [TaskAssignment] {
        // Validate child is in current household
        guard householdContext.isChildInHousehold(childId) else {
            print("⚠️ getPendingApprovals: Child \(childId) not in current household")
            return []
        }

        return repository.getPendingReviewTasks(forChild: childId)
    }

    func approveTask(assignmentId: UUID, parentId: UUID, parentNotes: String?, credibilityScore: Int) -> TaskServiceApprovalResult {
        guard var assignment = repository.getAssignment(id: assignmentId) else {
            return TaskServiceApprovalResult(
                success: false,
                xpAwarded: 0,
                newCredibility: credibilityScore,
                assignment: TaskAssignment(
                    templateId: UUID(),
                    childId: UUID(),
                    title: "",
                    description: "",
                    category: TaskTemplateCategory.other,
                    assignedLevel: TaskLevel.level1
                ),
                message: "Task not found"
            )
        }

        // Calculate XP earned based on credibility
        let xpAwarded = xpService.awardXP(
            userId: assignment.childId,
            timeMinutes: assignment.assignedLevel.baseXP,
            taskId: assignment.id,
            credibilityScore: credibilityScore
        )

        // Increase credibility (+5)
        credibilityService.processApprovedTask(
            taskId: assignment.id,
            childId: assignment.childId,
            reviewerId: parentId,
            notes: parentNotes
        )

        let newCredibility = credibilityService.getCredibilityScore(childId: assignment.childId)

        // Update assignment
        assignment.status = .approved
        assignment.reviewedAt = Date()
        assignment.reviewedBy = parentId
        assignment.parentNotes = parentNotes
        assignment.reviewDecision = .approved
        assignment.xpAwarded = xpAwarded

        repository.saveAssignment(assignment)

        // Play approval sound
        SoundEffectsManager.shared.playTaskApproved(xpAmount: xpAwarded)

        // Check and award badges
        Task {
            try? await badgeService?.checkAndAwardBadges(for: assignment.childId)
        }

        // TODO: Send notification to child

        return TaskServiceApprovalResult(
            success: true,
            xpAwarded: xpAwarded,
            newCredibility: newCredibility,
            assignment: assignment,
            message: "Task approved! +\(xpAwarded) XP earned"
        )
    }

    func approveTaskWithEdits(assignmentId: UUID, parentId: UUID, newLevel: TaskLevel, parentNotes: String?, credibilityScore: Int) -> TaskServiceApprovalResult {
        guard var assignment = repository.getAssignment(id: assignmentId) else {
            return TaskServiceApprovalResult(
                success: false,
                xpAwarded: 0,
                newCredibility: credibilityScore,
                assignment: TaskAssignment(
                    templateId: UUID(),
                    childId: UUID(),
                    title: "",
                    description: "",
                    category: TaskTemplateCategory.other,
                    assignedLevel: TaskLevel.level1
                ),
                message: "Task not found"
            )
        }

        // Store adjusted level
        assignment.adjustedLevel = newLevel

        // Calculate XP based on ADJUSTED level
        let xpAwarded = xpService.awardXP(
            userId: assignment.childId,
            timeMinutes: newLevel.baseXP,
            taskId: assignment.id,
            credibilityScore: credibilityScore
        )

        // Increase credibility (+5)
        credibilityService.processApprovedTask(
            taskId: assignment.id,
            childId: assignment.childId,
            reviewerId: parentId,
            notes: parentNotes
        )

        let newCredibility = credibilityService.getCredibilityScore(childId: assignment.childId)

        // Update assignment
        assignment.status = .approved
        assignment.reviewedAt = Date()
        assignment.reviewedBy = parentId
        assignment.parentNotes = parentNotes
        assignment.reviewDecision = .approvedEdited
        assignment.xpAwarded = xpAwarded

        repository.saveAssignment(assignment)

        // Play approval sound
        SoundEffectsManager.shared.playTaskApproved(xpAmount: xpAwarded)

        // Check and award badges
        Task {
            try? await badgeService?.checkAndAwardBadges(for: assignment.childId)
        }

        // TODO: Send notification to child

        let originalLevel = assignment.assignedLevel.rawValue
        let adjustedLevelValue = newLevel.rawValue

        return TaskServiceApprovalResult(
            success: true,
            xpAwarded: xpAwarded,
            newCredibility: newCredibility,
            assignment: assignment,
            message: "Task approved with changes: Level \(originalLevel) → Level \(adjustedLevelValue) (+\(xpAwarded) XP)"
        )
    }

    func declineTask(assignmentId: UUID, parentId: UUID, reason: String, credibilityScore: Int) -> TaskServiceDeclineResult {
        guard var assignment = repository.getAssignment(id: assignmentId) else {
            return TaskServiceDeclineResult(
                success: false,
                newCredibility: credibilityScore,
                assignment: TaskAssignment(
                    templateId: UUID(),
                    childId: UUID(),
                    title: "",
                    description: "",
                    category: TaskTemplateCategory.other,
                    assignedLevel: TaskLevel.level1
                ),
                message: "Task not found"
            )
        }

        // Decrease credibility (-20)
        credibilityService.processDownvote(
            taskId: assignment.id,
            childId: assignment.childId,
            reviewerId: parentId,
            notes: reason
        )

        let newCredibility = credibilityService.getCredibilityScore(childId: assignment.childId)

        // Update assignment
        assignment.status = .declined
        assignment.reviewedAt = Date()
        assignment.reviewedBy = parentId
        assignment.parentNotes = reason
        assignment.reviewDecision = .declined
        assignment.xpAwarded = 0  // No XP for declined tasks

        repository.saveAssignment(assignment)

        // Play decline sound
        SoundEffectsManager.shared.playTaskDeclined()

        // TODO: Send notification to child

        return TaskServiceDeclineResult(
            success: true,
            newCredibility: newCredibility,
            assignment: assignment,
            message: "Task declined. Credibility reduced by 20."
        )
    }

    // MARK: - Queries

    func getChildTasks(childId: UUID, status: TaskAssignmentStatus?) -> [TaskAssignment] {
        // Validate child is in current household (if household context is set)
        if householdContext.currentHouseholdId != nil {
            guard householdContext.isChildInHousehold(childId) else {
                print("⚠️ getChildTasks: Child \(childId) not in current household")
                return []
            }
        }

        if let status = status {
            return repository.getAssignments(forChild: childId, status: status)
        } else {
            return repository.getAssignments(forChild: childId)
        }
    }

    func getTask(id: UUID) -> TaskAssignment? {
        return repository.getAssignment(id: id)
    }

    // MARK: - Notification Tracking

    func markDeclineAsViewed(assignmentId: UUID) -> Bool {
        guard var assignment = repository.getAssignment(id: assignmentId) else {
            return false
        }

        assignment.declineViewedByChild = true
        repository.saveAssignment(assignment)
        print("✅ Marked decline as viewed for task: \(assignment.title)")
        return true
    }

    // MARK: - Task Management

    func deleteTask(assignmentId: UUID) -> Bool {
        guard let assignment = repository.getAssignment(id: assignmentId) else {
            print("❌ Cannot delete task: assignment not found")
            return false
        }

        repository.deleteAssignment(id: assignmentId)
        print("✅ Deleted task: \(assignment.title) (ID: \(assignmentId))")
        return true
    }

    func updateTask(assignmentId: UUID, title: String?, level: TaskLevel?, dueDate: Date?) -> Bool {
        guard var assignment = repository.getAssignment(id: assignmentId) else {
            print("❌ Cannot update task: assignment not found")
            return false
        }

        // Update fields if provided
        if let newTitle = title {
            assignment.title = newTitle
        }
        if let newLevel = level {
            assignment.assignedLevel = newLevel
        }
        // Handle due date update (can be nil to remove due date)
        assignment.dueDate = dueDate

        repository.saveAssignment(assignment)
        print("✅ Updated task: \(assignment.title)")
        return true
    }

    // MARK: - Test Utilities

    func deleteAllAssignments() {
        if let repo = repository as? TaskRepositoryImpl {
            repo.deleteAllAssignments()
        }
    }
}
