import SwiftUI
import PhotosUI
import Combine

// MARK: - Task Verification Models

struct TaskApprovalResult {
    let taskTitle: String
    let timeSpent: Int
    let baseXP: Int
    let earnedXP: Int
    let credibilityScore: Int
    let credibilityTier: String
    let earningRate: Int
}

struct TaskVerification: Identifiable, Codable {
    let id: UUID
    let taskId: UUID
    let userId: UUID // Child
    let reviewerId: UUID? // Parent
    var status: VerificationStatus
    var notes: String?
    var appealNotes: String?
    var appealDeadline: Date?
    let createdAt: Date
    var updatedAt: Date
    var reviewedAt: Date?

    // Task details for display
    let taskTitle: String
    let taskDescription: String?
    let taskCategory: String
    let taskXPReward: Int
    let taskTimeMinutes: Int  // Time spent on task
    let photoURL: String?
    let locationName: String?
    let completedAt: Date
    let childName: String

    init(
        id: UUID = UUID(),
        taskId: UUID,
        userId: UUID,
        reviewerId: UUID? = nil,
        status: VerificationStatus = .pending,
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
        taskTimeMinutes: Int,
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
        self.taskTimeMinutes = taskTimeMinutes
        self.photoURL = photoURL
        self.locationName = locationName
        self.completedAt = completedAt
        self.childName = childName
    }
}

enum VerificationStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case approved = "approved"
    case rejected = "rejected"
    case appealed = "appealed"

    var displayName: String {
        switch self {
        case .pending: return "Pending"
        case .approved: return "Approved"
        case .rejected: return "Rejected"
        case .appealed: return "Appealed"
        }
    }

    var color: Color {
        switch self {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .appealed: return .purple
        }
    }

    var icon: String {
        switch self {
        case .pending: return "clock.fill"
        case .approved: return "checkmark.circle.fill"
        case .rejected: return "xmark.circle.fill"
        case .appealed: return "exclamationmark.bubble.fill"
        }
    }
}

// MARK: - Task Verification Manager

class TaskVerificationManager: ObservableObject {
    @Published var verifications: [TaskVerification] = []
    @Published var selectedChild: UUID?
    @Published var lastApprovedTaskResult: TaskApprovalResult?

    private let credibilityManager = CredibilityManager()
    private let xpService: XPService
    private let credibilityService: CredibilityService

    init(
        xpService: XPService? = nil,
        credibilityService: CredibilityService? = nil
    ) {
        // Use injected services or fall back to container
        self.xpService = xpService ?? DependencyContainer.shared.xpService
        self.credibilityService = credibilityService ?? DependencyContainer.shared.credibilityService
        loadMockData()
    }

    func approveTask(_ verification: TaskVerification, notes: String? = nil) {
        if let index = verifications.firstIndex(where: { $0.id == verification.id }) {
            verifications[index].status = .approved
            verifications[index].notes = notes
            verifications[index].reviewedAt = Date()
            verifications[index].updatedAt = Date()

            // Get current credibility score
            let currentCredibility = credibilityService.getCredibilityScore(childId: verification.userId)

            // Update credibility
            credibilityManager.processApprovedTask(
                taskId: verification.taskId,
                reviewerId: verification.reviewerId ?? UUID(),
                notes: notes
            )

            // Award XP based on time spent and credibility
            let earnedXP = xpService.awardXP(
                userId: verification.userId,
                timeMinutes: verification.taskTimeMinutes,
                taskId: verification.taskId,
                credibilityScore: currentCredibility
            )

            // Store result for UI feedback
            lastApprovedTaskResult = TaskApprovalResult(
                taskTitle: verification.taskTitle,
                timeSpent: verification.taskTimeMinutes,
                baseXP: verification.taskTimeMinutes,
                earnedXP: earnedXP,
                credibilityScore: currentCredibility,
                credibilityTier: xpService.credibilityTierName(score: currentCredibility),
                earningRate: xpService.earningRatePercentage(score: currentCredibility)
            )

            // Play satisfying approval sound with XP amount
            SoundEffectsManager.shared.playTaskApproved(xpAmount: earnedXP)

            print("✅ Approved task: \(verification.taskTitle) - Earned \(earnedXP) XP")
        }
    }

    func rejectTask(_ verification: TaskVerification, notes: String) {
        if let index = verifications.firstIndex(where: { $0.id == verification.id }) {
            verifications[index].status = .rejected
            verifications[index].notes = notes
            verifications[index].reviewedAt = Date()
            verifications[index].updatedAt = Date()
            verifications[index].appealDeadline = Calendar.current.date(byAdding: .hour, value: 24, to: Date())

            // Update credibility
            credibilityManager.processDownvote(
                taskId: verification.taskId,
                reviewerId: verification.reviewerId ?? UUID(),
                notes: notes
            )

            // Play decline sound
            SoundEffectsManager.shared.playTaskDeclined()

            print("❌ Rejected task: \(verification.taskTitle)")
        }
    }

    func bulkApprove(_ verifications: [TaskVerification]) {
        for verification in verifications {
            approveTask(verification, notes: "Bulk approved")
        }
    }

    func getPendingVerifications(forChild childId: UUID? = nil) -> [TaskVerification] {
        let pending = verifications.filter { $0.status == .pending }
        if let childId = childId {
            return pending.filter { $0.userId == childId }
        }
        return pending
    }

    func getAppealedVerifications(forChild childId: UUID? = nil) -> [TaskVerification] {
        let appealed = verifications.filter { $0.status == .appealed }
        if let childId = childId {
            return appealed.filter { $0.userId == childId }
        }
        return appealed
    }

    private func loadMockData() {
        // Mock data for testing
        verifications = [
            TaskVerification(
                taskId: UUID(),
                userId: UUID(),
                status: .pending,
                taskTitle: "Morning Run",
                taskDescription: "3 mile run around the neighborhood",
                taskCategory: "Exercise",
                taskXPReward: 150,
                taskTimeMinutes: 30,
                locationName: "Neighborhood Park",
                completedAt: Date().addingTimeInterval(-3600),
                childName: "Alex"
            ),
            TaskVerification(
                taskId: UUID(),
                userId: UUID(),
                status: .pending,
                taskTitle: "Math Homework",
                taskDescription: "Complete Chapter 5 exercises",
                taskCategory: "Study",
                taskXPReward: 100,
                taskTimeMinutes: 45,
                completedAt: Date().addingTimeInterval(-7200),
                childName: "Alex"
            ),
            TaskVerification(
                taskId: UUID(),
                userId: UUID(),
                status: .appealed,
                notes: "Photo doesn't show completed work",
                appealNotes: "I accidentally submitted wrong photo. Here's the correct one.",
                taskTitle: "Clean Room",
                taskDescription: "Organize and vacuum bedroom",
                taskCategory: "Chores",
                taskXPReward: 80,
                taskTimeMinutes: 20,
                completedAt: Date().addingTimeInterval(-86400),
                childName: "Jordan"
            )
        ]
    }
}

// MARK: - Task Verification View

struct TaskVerificationView: View {
    @StateObject private var verificationManager = TaskVerificationManager()
    @State private var selectedFilter: VerificationStatus = .pending
    @State private var showingBulkApprove = false
    @State private var selectedTasks: Set<UUID> = []
    @State private var showingApprovalResult = false

    var filteredVerifications: [TaskVerification] {
        verifications.filter { $0.status == selectedFilter }
    }

    var verifications: [TaskVerification] {
        if let childId = verificationManager.selectedChild {
            return verificationManager.verifications.filter { $0.userId == childId }
        }
        return verificationManager.verifications
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Filter Tabs
                filterTabs

                // Content
                if filteredVerifications.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredVerifications) { verification in
                                TaskVerificationCard(
                                    verification: verification,
                                    isSelected: selectedTasks.contains(verification.id),
                                    onToggleSelection: {
                                        if selectedTasks.contains(verification.id) {
                                            selectedTasks.remove(verification.id)
                                        } else {
                                            selectedTasks.insert(verification.id)
                                        }
                                    },
                                    onApprove: { notes in
                                        verificationManager.approveTask(verification, notes: notes)
                                        showingApprovalResult = true
                                    },
                                    onReject: { notes in
                                        verificationManager.rejectTask(verification, notes: notes)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Task Verification")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if selectedFilter == .pending && !filteredVerifications.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            Button(action: {
                                showingBulkApprove = true
                            }) {
                                Label("Approve All", systemImage: "checkmark.circle")
                            }

                            Button(action: {
                                // Select all
                                selectedTasks = Set(filteredVerifications.map { $0.id })
                            }) {
                                Label("Select All", systemImage: "checkmark.square")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .alert("Bulk Approve", isPresented: $showingBulkApprove) {
                Button("Cancel", role: .cancel) { }
                Button("Approve All") {
                    verificationManager.bulkApprove(filteredVerifications)
                }
            } message: {
                Text("Approve all \(filteredVerifications.count) pending tasks?")
            }
            .sheet(isPresented: $showingApprovalResult) {
                if let result = verificationManager.lastApprovedTaskResult {
                    TaskCompletionResultView(result: result) {
                        showingApprovalResult = false
                        verificationManager.lastApprovedTaskResult = nil
                    }
                }
            }
        }
    }

    private var filterTabs: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(VerificationStatus.allCases, id: \.self) { status in
                    let count = verifications.filter { $0.status == status }.count

                    Button(action: {
                        selectedFilter = status
                        selectedTasks.removeAll()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: status.icon)
                                .font(.caption)

                            Text(status.displayName)
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            if count > 0 {
                                Text("\(count)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(selectedFilter == status ? Color.white.opacity(0.3) : status.color.opacity(0.3))
                                    .cornerRadius(8)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedFilter == status ? status.color : Color(.systemGray6))
                        .foregroundColor(selectedFilter == status ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
            .padding()
        }
        .background(Color(.systemBackground))
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: selectedFilter.icon)
                .font(.system(size: 60))
                .foregroundColor(selectedFilter.color.opacity(0.5))

            Text("No \(selectedFilter.displayName) Tasks")
                .font(.title2)
                .fontWeight(.semibold)

            Text(emptyStateMessage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateMessage: String {
        switch selectedFilter {
        case .pending:
            return "Great! No tasks waiting for review."
        case .approved:
            return "No approved tasks yet."
        case .rejected:
            return "No rejected tasks."
        case .appealed:
            return "No tasks under appeal."
        }
    }
}

// MARK: - Task Verification Card

struct TaskVerificationCard: View {
    let verification: TaskVerification
    let isSelected: Bool
    let onToggleSelection: () -> Void
    let onApprove: (String?) -> Void
    let onReject: (String) -> Void

    @State private var showingDetail = false
    @State private var showingRejectSheet = false
    @State private var rejectNotes = ""
    @State private var approveNotes = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                if verification.status == .pending {
                    Button(action: onToggleSelection) {
                        Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                            .foregroundColor(isSelected ? .blue : .secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(verification.taskTitle)
                        .font(.headline)
                        .fontWeight(.semibold)

                    HStack(spacing: 8) {
                        Text(verification.childName)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text(verification.completedAt, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 4) {
                    Text("\(verification.taskXPReward)")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }

            // Category badge
            HStack {
                Image(systemName: categoryIcon(verification.taskCategory))
                    .font(.caption)
                Text(verification.taskCategory)
                    .font(.caption)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color(.systemGray6))
            .cornerRadius(6)

            // Description
            if let description = verification.taskDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            // Location
            if let location = verification.locationName {
                HStack(spacing: 4) {
                    Image(systemName: "location.fill")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Text(location)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Photo preview
            if verification.photoURL != nil {
                HStack {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.blue)
                    Text("Photo attached")
                        .font(.caption)
                        .foregroundColor(.blue)
                    Spacer()
                    Button("View") {
                        showingDetail = true
                    }
                    .font(.caption)
                }
            }

            // Notes (for reviewed tasks)
            if let notes = verification.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Review Notes:")
                        .font(.caption)
                        .fontWeight(.semibold)
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }
            }

            // Appeal notes
            if let appealNotes = verification.appealNotes, !appealNotes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Appeal:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.purple)
                    Text(appealNotes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(8)
                        .background(Color.purple.opacity(0.1))
                        .cornerRadius(6)
                }
            }

            // Actions
            if verification.status == .pending || verification.status == .appealed {
                HStack(spacing: 12) {
                    Button(action: {
                        onApprove(approveNotes.isEmpty ? nil : approveNotes)
                    }) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Approve")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }

                    Button(action: {
                        showingRejectSheet = true
                    }) {
                        HStack {
                            Image(systemName: "xmark.circle.fill")
                            Text("Reject")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        .sheet(isPresented: $showingRejectSheet) {
            RejectTaskSheet(
                taskTitle: verification.taskTitle,
                notes: $rejectNotes,
                onReject: {
                    onReject(rejectNotes)
                    showingRejectSheet = false
                    rejectNotes = ""
                }
            )
        }
        .sheet(isPresented: $showingDetail) {
            TaskVerificationDetailView(verification: verification)
        }
    }

    private func categoryIcon(_ category: String) -> String {
        switch category.lowercased() {
        case "exercise":
            return "figure.run"
        case "chores":
            return "house.fill"
        case "study":
            return "book.fill"
        case "social":
            return "person.2.fill"
        case "creative":
            return "paintbrush.fill"
        case "outdoor":
            return "tree.fill"
        case "health":
            return "heart.fill"
        default:
            return "star.fill"
        }
    }
}

// MARK: - Reject Task Sheet

struct RejectTaskSheet: View {
    let taskTitle: String
    @Binding var notes: String
    let onReject: () -> Void
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.red)

                    Text("Reject Task")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(taskTitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason (Required)")
                        .font(.headline)

                    TextEditor(text: $notes)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)

                    Text("Please explain why this task is being rejected. The child will see this message.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Impact:")
                        .font(.headline)

                    HStack(spacing: 8) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.red)
                        Text("-10 to -15 credibility points")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "flame")
                            .foregroundColor(.orange)
                        Text("Resets task streak")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text("Child can appeal within 24 hours")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .padding(.top, 4)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)

                Spacer()

                Button(action: onReject) {
                    Text("Confirm Rejection")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(notes.isEmpty ? Color.gray : Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .disabled(notes.isEmpty)
            }
            .padding()
            .navigationTitle("Reject Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Task Verification Detail View

struct TaskVerificationDetailView: View {
    let verification: TaskVerification
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Task Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(verification.taskTitle)
                            .font(.title2)
                            .fontWeight(.bold)

                        if let description = verification.taskDescription {
                            Text(description)
                                .foregroundColor(.secondary)
                        }
                    }

                    // Photo (placeholder)
                    if verification.photoURL != nil {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 300)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 60))
                                    .foregroundColor(.gray)
                            )
                    }

                    // Details
                    VStack(spacing: 12) {
                        detailRow(label: "Child", value: verification.childName, icon: "person.fill")
                        detailRow(label: "Category", value: verification.taskCategory, icon: "tag.fill")
                        detailRow(label: "XP Reward", value: "\(verification.taskXPReward)", icon: "star.fill")
                        detailRow(label: "Completed", value: verification.completedAt.formatted(), icon: "clock.fill")

                        if let location = verification.locationName {
                            detailRow(label: "Location", value: location, icon: "location.fill")
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Task Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func detailRow(label: String, value: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            Text(label)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Previews

struct TaskVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        TaskVerificationView()
    }
}