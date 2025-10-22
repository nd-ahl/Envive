import Foundation

// MARK: - Task Repository Protocol

protocol TaskRepository {
    // Task Templates
    func getAllTemplates() -> [TaskTemplate]
    func getTemplatesByCategory(_ category: TaskTemplateCategory) -> [TaskTemplate]
    func searchTemplates(query: String) -> [TaskTemplate]
    func getTemplate(id: UUID) -> TaskTemplate?
    func saveTemplate(_ template: TaskTemplate)

    // Task Assignments
    func getAssignments(forChild childId: UUID) -> [TaskAssignment]
    func getAssignments(forChild childId: UUID, status: TaskAssignmentStatus) -> [TaskAssignment]
    func getPendingReviewTasks() -> [TaskAssignment]  // All children
    func getPendingReviewTasks(forChild childId: UUID) -> [TaskAssignment]
    func getAssignment(id: UUID) -> TaskAssignment?
    func saveAssignment(_ assignment: TaskAssignment)
    func deleteAssignment(id: UUID)

    // Bulk operations
    func getAssignmentsForAllChildren() -> [UUID: [TaskAssignment]]  // [childId: assignments]

    // Test utilities
    func deleteAllAssignments()
}

// MARK: - Task Repository Implementation

class TaskRepositoryImpl: TaskRepository {
    private let storage: StorageService
    private let templatesKey = "task_templates"
    private let assignmentsKey = "task_assignments"

    // In-memory cache
    private var templatesCache: [TaskTemplate]?
    private var assignmentsCache: [TaskAssignment]?

    init(storage: StorageService) {
        self.storage = storage
        // Load default templates on first launch
        ensureDefaultTemplatesExist()
    }

    // MARK: - Task Templates

    func getAllTemplates() -> [TaskTemplate] {
        if let cached = templatesCache {
            return cached
        }

        let templates: [TaskTemplate] = storage.load(forKey: templatesKey) ?? []
        templatesCache = templates
        return templates
    }

    func getTemplatesByCategory(_ category: TaskTemplateCategory) -> [TaskTemplate] {
        return getAllTemplates().filter { $0.category == category }
    }

    func searchTemplates(query: String) -> [TaskTemplate] {
        let lowercasedQuery = query.lowercased()
        return getAllTemplates().filter {
            $0.title.lowercased().contains(lowercasedQuery) ||
            $0.description.lowercased().contains(lowercasedQuery) ||
            $0.tags.contains(where: { $0.lowercased().contains(lowercasedQuery) })
        }
    }

    func getTemplate(id: UUID) -> TaskTemplate? {
        return getAllTemplates().first { $0.id == id }
    }

    func saveTemplate(_ template: TaskTemplate) {
        var templates = getAllTemplates()

        if let index = templates.firstIndex(where: { $0.id == template.id }) {
            templates[index] = template
        } else {
            templates.append(template)
        }

        storage.save(templates, forKey: templatesKey)
        templatesCache = templates
    }

    // MARK: - Task Assignments

    func getAssignments(forChild childId: UUID) -> [TaskAssignment] {
        let allAssignments = getAllAssignments()
        let filteredAssignments = allAssignments.filter { $0.childId == childId }
        print("📦 TaskRepository.getAssignments: Filtering \(allAssignments.count) total assignments for childId: \(childId)")
        print("📦 Found \(filteredAssignments.count) assignments for this child")
        for assignment in filteredAssignments {
            print("   - Task: '\(assignment.title)', childId: \(assignment.childId), status: \(assignment.status)")
        }
        return filteredAssignments.sorted { $0.createdAt > $1.createdAt }  // Newest first
    }

    func getAssignments(forChild childId: UUID, status: TaskAssignmentStatus) -> [TaskAssignment] {
        return getAssignments(forChild: childId).filter { $0.status == status }
    }

    func getPendingReviewTasks() -> [TaskAssignment] {
        return getAllAssignments()
            .filter { $0.status == .pendingReview }
            .sorted { ($0.completedAt ?? Date.distantPast) > ($1.completedAt ?? Date.distantPast) }
    }

    func getPendingReviewTasks(forChild childId: UUID) -> [TaskAssignment] {
        return getPendingReviewTasks().filter { $0.childId == childId }
    }

    func getAssignment(id: UUID) -> TaskAssignment? {
        return getAllAssignments().first { $0.id == id }
    }

    func saveAssignment(_ assignment: TaskAssignment) {
        var assignments = getAllAssignments()

        if let index = assignments.firstIndex(where: { $0.id == assignment.id }) {
            assignments[index] = assignment
        } else {
            assignments.append(assignment)
        }

        storage.save(assignments, forKey: assignmentsKey)
        assignmentsCache = assignments
    }

    func deleteAssignment(id: UUID) {
        var assignments = getAllAssignments()
        assignments.removeAll { $0.id == id }
        storage.save(assignments, forKey: assignmentsKey)
        assignmentsCache = assignments
    }

    func getAssignmentsForAllChildren() -> [UUID: [TaskAssignment]] {
        let allAssignments = getAllAssignments()
        var result: [UUID: [TaskAssignment]] = [:]

        for assignment in allAssignments {
            if result[assignment.childId] == nil {
                result[assignment.childId] = []
            }
            result[assignment.childId]?.append(assignment)
        }

        return result
    }

    // MARK: - Test Utilities

    func deleteAllAssignments() {
        storage.save([] as [TaskAssignment], forKey: assignmentsKey)
        assignmentsCache = []
        print("🗑️ Deleted all task assignments")
    }

    // MARK: - Private Helpers

    private func getAllAssignments() -> [TaskAssignment] {
        if let cached = assignmentsCache {
            return cached
        }

        let assignments: [TaskAssignment] = storage.load(forKey: assignmentsKey) ?? []
        assignmentsCache = assignments
        return assignments
    }

    private func ensureDefaultTemplatesExist() {
        let existing = getAllTemplates()

        // Only seed if no templates exist
        if existing.isEmpty {
            let defaultTemplates = TaskTemplate.defaultTemplates
            for template in defaultTemplates {
                saveTemplate(template)
            }
            print("✅ Seeded \(defaultTemplates.count) default task templates")
        }
    }
}
