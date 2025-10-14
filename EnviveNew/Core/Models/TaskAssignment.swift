import Foundation

// MARK: - Task Assignment

/// Represents a specific task assigned to or claimed by a child
struct TaskAssignment: Identifiable, Codable {
    let id: UUID
    let templateId: UUID  // Reference to TaskTemplate
    let childId: UUID
    let assignedBy: UUID?  // Parent who assigned (nil if child claimed)

    // Task details (copied from template, can be edited by parent)
    var title: String
    var description: String
    var category: TaskTemplateCategory
    var assignedLevel: TaskLevel

    // Status tracking
    var status: TaskAssignmentStatus
    var createdAt: Date
    var startedAt: Date?
    var completedAt: Date?
    var reviewedAt: Date?

    // Completion evidence
    var photoURL: String?  // Path to photo evidence
    var childNotes: String?
    var completionTimeMinutes: Int?  // Actual time taken

    // Review info
    var reviewedBy: UUID?  // Parent who reviewed
    var parentNotes: String?
    var reviewDecision: TaskReviewDecision?
    var adjustedLevel: TaskLevel?  // If parent edited level
    var xpAwarded: Int?  // Final XP given to child

    // Due date (optional)
    var dueDate: Date?

    init(
        id: UUID = UUID(),
        templateId: UUID,
        childId: UUID,
        assignedBy: UUID? = nil,
        title: String,
        description: String,
        category: TaskTemplateCategory,
        assignedLevel: TaskLevel,
        status: TaskAssignmentStatus = .assigned,
        createdAt: Date = Date(),
        dueDate: Date? = nil
    ) {
        self.id = id
        self.templateId = templateId
        self.childId = childId
        self.assignedBy = assignedBy
        self.title = title
        self.description = description
        self.category = category
        self.assignedLevel = assignedLevel
        self.status = status
        self.createdAt = createdAt
        self.dueDate = dueDate
    }
}

// MARK: - Task Assignment Status

enum TaskAssignmentStatus: String, Codable {
    case assigned        // Parent assigned or child claimed, not started
    case inProgress      // Child marked as started
    case pendingReview   // Child marked complete, waiting parent approval
    case approved        // Parent approved
    case declined        // Parent declined
    case expired         // Past due date without completion
}

// MARK: - Task Review Decision

enum TaskReviewDecision: String, Codable {
    case approved        // Approved as-is
    case approvedEdited  // Approved with changes (level, notes, etc)
    case declined        // Rejected
}

// MARK: - Helper Extensions

extension TaskAssignment {
    /// Is this task assigned by parent or claimed by child?
    var isParentAssigned: Bool {
        return assignedBy != nil
    }

    /// Is this task waiting for parent review?
    var needsReview: Bool {
        return status == .pendingReview
    }

    /// Calculate XP that will be awarded based on level and credibility
    func calculateEarnedXP(credibilityScore: Int) -> Int {
        let level = adjustedLevel ?? assignedLevel
        return level.calculateEarnedXP(credibilityScore: credibilityScore)
    }

    /// Get display status text
    var statusDisplayText: String {
        switch status {
        case .assigned: return "To Do"
        case .inProgress: return "In Progress"
        case .pendingReview: return "Pending Approval"
        case .approved: return "Approved"
        case .declined: return "Declined"
        case .expired: return "Expired"
        }
    }

    /// Get status icon
    var statusIcon: String {
        switch status {
        case .assigned: return "⚪"
        case .inProgress: return "🔵"
        case .pendingReview: return "🟡"
        case .approved: return "✅"
        case .declined: return "❌"
        case .expired: return "⏰"
        }
    }

    /// Is task overdue?
    var isOverdue: Bool {
        guard let dueDate = dueDate else { return false }
        return Date() > dueDate && (status == .assigned || status == .inProgress)
    }

    /// Time since completion (for pending review)
    var timeSinceCompletion: String? {
        guard let completedAt = completedAt else { return nil }
        let interval = Date().timeIntervalSince(completedAt)
        let minutes = Int(interval / 60)

        if minutes < 1 { return "Just now" }
        if minutes < 60 { return "\(minutes) min ago" }

        let hours = minutes / 60
        if hours < 24 { return "\(hours) hour\(hours == 1 ? "" : "s") ago" }

        let days = hours / 24
        return "\(days) day\(days == 1 ? "" : "s") ago"
    }
}

// MARK: - Factory Methods

extension TaskAssignment {
    /// Create assignment from template (parent assigns to child)
    static func fromTemplate(
        _ template: TaskTemplate,
        childId: UUID,
        assignedBy: UUID,
        level: TaskLevel,
        dueDate: Date? = nil
    ) -> TaskAssignment {
        return TaskAssignment(
            templateId: template.id,
            childId: childId,
            assignedBy: assignedBy,
            title: template.title,
            description: template.description,
            category: template.category,
            assignedLevel: level,
            status: .assigned,
            dueDate: dueDate
        )
    }

    /// Create assignment when child claims task
    static func childClaimed(
        template: TaskTemplate,
        childId: UUID,
        level: TaskLevel
    ) -> TaskAssignment {
        return TaskAssignment(
            templateId: template.id,
            childId: childId,
            assignedBy: nil,  // Child claimed, not parent assigned
            title: template.title,
            description: template.description,
            category: template.category,
            assignedLevel: level,
            status: .assigned
        )
    }
}
