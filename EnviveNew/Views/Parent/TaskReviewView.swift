import SwiftUI
import Combine

// MARK: - Task Review View (Parent Approval Interface)

struct TaskReviewView: View {
    @StateObject private var viewModel: TaskReviewViewModel
    @StateObject private var model = EnhancedScreenTimeModel()
    @State private var showMainAsBack = true
    @Environment(\.dismiss) var dismiss

    init(assignment: TaskAssignment, viewModel: TaskReviewViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Task Header
                taskHeaderSection

                // Photo Evidence
                photoEvidenceSection

                // Time Tracking
                if let timeSpent = viewModel.assignment.completionTimeMinutes, timeSpent > 0 {
                    timeTrackingSection(minutes: timeSpent)
                }

                // Child Notes
                if let notes = viewModel.assignment.childNotes, !notes.isEmpty {
                    childNotesSection(notes: notes)
                }

                // Child Stats
                childStatsSection

                // XP Calculation Preview
                xpCalculationSection

                // Decision Buttons
                decisionButtonsSection
            }
            .padding()
        }
        .navigationTitle("Review Task")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Task Approved", isPresented: $viewModel.showApprovalSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(viewModel.resultMessage)
        }
        .alert("Task Declined", isPresented: $viewModel.showDeclineSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text(viewModel.resultMessage)
        }
        .sheet(isPresented: $viewModel.showEditSheet) {
            EditTaskSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showDeclineSheet) {
            DeclineTaskSheet(viewModel: viewModel)
        }
    }

    // MARK: - Task Header

    private var taskHeaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(viewModel.assignment.category.icon)
                    .font(.title)
                Text(viewModel.assignment.title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }

            Text(viewModel.assignment.category.rawValue)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                Label(viewModel.assignment.assignedLevel.displayName, systemImage: "star.fill")
                    .foregroundColor(.orange)
                Spacer()
                if let time = viewModel.assignment.timeSinceCompletion {
                    Text("Completed \(time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(viewModel.assignment.description)
                .font(.body)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Photo Evidence

    private var photoEvidenceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Photo Evidence", systemImage: "camera.fill")
                .font(.headline)

            // Load photos for this task - try to get both back and front if available
            if let savedPhoto = model.cameraManager.getLatestPhotoForTask(viewModel.assignment.id),
               let backImage = model.cameraManager.loadPhoto(savedPhoto: savedPhoto) {

                // Check if we have front image too (for interactive display like Social tab)
                let frontImage = model.cameraManager.loadFrontPhoto(savedPhoto: savedPhoto) ?? backImage

                // BeReal-style photo display with 4:5 ratio (matching Social tab EXACTLY)
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = width * 1.25 // 4:5 ratio

                    ZStack {
                        // Main photo (tappable to swap, just like Social tab)
                        Image(uiImage: showMainAsBack ? backImage : frontImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: width, height: height)
                            .clipped()
                            .cornerRadius(20)

                        // Small overlay photo in top-right (tappable to swap)
                        VStack {
                            HStack {
                                Spacer()
                                Button(action: { showMainAsBack.toggle() }) {
                                    Image(uiImage: showMainAsBack ? frontImage : backImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 80, height: 106) // 4:5 ratio for small image
                                        .clipped()
                                        .cornerRadius(12)
                                        .shadow(color: .black.opacity(0.25), radius: 3, x: 0, y: 2)
                                }
                                .padding(.trailing, 15)
                                .padding(.top, 15)
                            }
                            Spacer()
                        }
                    }
                }
                .aspectRatio(4/5, contentMode: .fit)

                Text("✅ Photo proof submitted by child")
                    .font(.caption)
                    .foregroundColor(.green)
            } else {
                // No photo found - show placeholder
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 200)
                    .cornerRadius(8)
                    .overlay(
                        VStack {
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No photo submitted")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Time Tracking

    private func timeTrackingSection(minutes: Int) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Time Spent on Task", systemImage: "stopwatch.fill")
                .font(.headline)

            VStack(spacing: 12) {
                // Main time display
                HStack {
                    Spacer()
                    VStack(spacing: 4) {
                        Text(formatTimeSpent(minutes))
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                            .monospacedDigit()
                        Text("Time Worked")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)

                Divider()

                // Guidance text
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                        Text("Consider adjusting the task level based on time spent:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("•")
                            Text("Quick tasks (< 10 min) → Easy")
                        }
                        HStack {
                            Text("•")
                            Text("Medium tasks (10-30 min) → Medium")
                        }
                        HStack {
                            Text("•")
                            Text("Long tasks (> 30 min) → Hard")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 22)
                }
                .padding()
                .background(Color.blue.opacity(0.05))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func formatTimeSpent(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 {
            if mins > 0 {
                return "\(hours)h \(mins)m"
            } else {
                return "\(hours)h"
            }
        } else {
            return "\(mins) min"
        }
    }

    // MARK: - Child Notes

    private func childNotesSection(notes: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Child's Notes", systemImage: "note.text")
                .font(.headline)

            Text(notes)
                .font(.body)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Child Stats

    private var childStatsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label("Trust Level", systemImage: "star.fill")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(viewModel.trustLevel.starRating)
                        .font(.title)
                    Text(viewModel.trustLevel.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(viewModel.trustLevel.swiftUIColor)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Recent History")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.consecutiveApprovals) approved")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(viewModel.trustLevel.swiftUIColor.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Reward Preview

    private var xpCalculationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Reward", systemImage: "gift.fill")
                .font(.headline)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Child will earn:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.calculatedXP) XP")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Trust impact:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(viewModel.trustImpactDisplay)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Decision Buttons

    private var decisionButtonsSection: some View {
        VStack(spacing: 12) {
            // Approve Button
            Button(action: {
                viewModel.approveTask()
            }) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("APPROVE")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("+\(viewModel.calculatedXP) XP")
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.isProcessing)

            // Edit & Approve Button
            Button(action: {
                viewModel.showEditSheet = true
            }) {
                HStack {
                    Image(systemName: "pencil.circle.fill")
                    Text("EDIT & APPROVE")
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.isProcessing)

            // Decline Button
            Button(action: {
                viewModel.showDeclineSheet = true
            }) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("DECLINE")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("⚠️ Lowers Trust")
                        .font(.caption)
                        .fontWeight(.bold)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(viewModel.isProcessing)
        }
    }
}

// MARK: - Stat Row Component

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
    }
}

// MARK: - Edit Task Sheet

struct EditTaskSheet: View {
    @ObservedObject var viewModel: TaskReviewViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Title", text: $viewModel.editedTitle)
                    TextField("Description", text: $viewModel.editedDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Level") {
                    Picker("Task Level", selection: $viewModel.editedLevel) {
                        ForEach(TaskLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("New XP Reward:")
                        Spacer()
                        Text("\(viewModel.editedLevel.baseXP) XP")
                            .fontWeight(.bold)
                    }

                    HStack {
                        Text("Child will earn:")
                        Spacer()
                        Text("\(viewModel.editedXPCalculation) XP")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }
                }

                Section("Parent Notes") {
                    TextField("Notes for child (optional)", text: $viewModel.editedParentNotes, axis: .vertical)
                        .lineLimit(2...4)
                    Text("This message will be shown to the child")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save & Approve") {
                        viewModel.approveTaskWithEdits()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Decline Task Sheet

struct DeclineTaskSheet: View {
    @ObservedObject var viewModel: TaskReviewViewModel
    @Environment(\.dismiss) var dismiss

    let quickReasons = [
        "Task not completed",
        "Done poorly/incomplete",
        "Photo doesn't show work",
        "Inflated level"
    ]

    var body: some View {
        NavigationView {
            Form {
                Section("Declining Will") {
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Give child 0 XP", systemImage: "xmark.circle")
                            .foregroundColor(.red)

                        Label {
                            Text("Lower trust rating (\(viewModel.declineTrustImpactDisplay))")
                        } icon: {
                            Image(systemName: "arrow.down.circle")
                        }
                        .foregroundColor(.orange)

                        Label {
                            Text("Child needs \(viewModel.tasksToRecover) approved tasks to rebuild trust")
                        } icon: {
                            Image(systemName: "arrow.uturn.up")
                        }
                        .foregroundColor(.blue)
                    }
                    .padding(.vertical, 4)
                }

                Section("Reason (Required)") {
                    ForEach(quickReasons, id: \.self) { reason in
                        Button(action: {
                            viewModel.declineReason = reason
                        }) {
                            HStack {
                                Text(reason)
                                    .foregroundColor(.primary)
                                Spacer()
                                if viewModel.declineReason == reason {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }

                    TextField("Or write custom reason", text: $viewModel.declineReason, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Decline Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm Decline") {
                        viewModel.declineTask()
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                    .disabled(viewModel.declineReason.isEmpty)
                }
            }
        }
    }
}

// MARK: - Task Review View Model

@MainActor
class TaskReviewViewModel: ObservableObject {
    @Published var assignment: TaskAssignment
    @Published var currentCredibility: Int
    @Published var consecutiveApprovals: Int
    @Published var recentDeclines: Int

    @Published var isProcessing = false
    @Published var showApprovalSuccess = false
    @Published var showDeclineSuccess = false
    @Published var resultMessage = ""

    @Published var showEditSheet = false
    @Published var showDeclineSheet = false

    // Edit state
    @Published var editedTitle: String
    @Published var editedDescription: String
    @Published var editedLevel: TaskLevel
    @Published var editedParentNotes = ""

    // Decline state
    @Published var declineReason = ""

    private let taskService: TaskService
    private let credibilityService: CredibilityService
    private let parentId: UUID

    init(
        assignment: TaskAssignment,
        taskService: TaskService,
        credibilityService: CredibilityService,
        parentId: UUID
    ) {
        self.assignment = assignment
        self.taskService = taskService
        self.credibilityService = credibilityService
        self.parentId = parentId

        self.currentCredibility = credibilityService.credibilityScore
        self.consecutiveApprovals = credibilityService.consecutiveApprovedTasks
        self.recentDeclines = 0 // TODO: Calculate from history

        // Initialize edit state
        self.editedTitle = assignment.title
        self.editedDescription = assignment.description
        self.editedLevel = assignment.assignedLevel
    }

    // MARK: - Trust Level Helpers

    var trustLevel: CredibilityTier {
        return credibilityService.getCurrentTier()
    }

    var trustImpactDisplay: String {
        let newTier = getTierForScore(newCredibilityAfterApproval)
        if newTier.name != trustLevel.name {
            return "\(trustLevel.starRating) → \(newTier.starRating)"
        } else {
            return "Stays \(trustLevel.name)"
        }
    }

    var declineTrustImpactDisplay: String {
        let newTier = getTierForScore(newCredibilityAfterDecline)
        if newTier.name != trustLevel.name {
            return "\(trustLevel.starRating) \(trustLevel.name) → \(newTier.starRating) \(newTier.name)"
        } else {
            return "Stays \(trustLevel.name)"
        }
    }

    private func getTierForScore(_ score: Int) -> CredibilityTier {
        let tiers = [
            CredibilityTier(name: "Excellent", range: 90...100, multiplier: 1.2, color: "green", description: ""),
            CredibilityTier(name: "Good", range: 75...89, multiplier: 1.0, color: "green", description: ""),
            CredibilityTier(name: "Fair", range: 60...74, multiplier: 0.8, color: "yellow", description: ""),
            CredibilityTier(name: "Poor", range: 40...59, multiplier: 0.5, color: "red", description: ""),
            CredibilityTier(name: "Very Poor", range: 0...39, multiplier: 0.3, color: "red", description: "")
        ]
        return tiers.first { $0.range.contains(score) } ?? tiers.last!
    }

    var calculatedXP: Int {
        assignment.assignedLevel.calculateEarnedXP(credibilityScore: currentCredibility)
    }

    var editedXPCalculation: Int {
        editedLevel.calculateEarnedXP(credibilityScore: currentCredibility)
    }

    var newCredibilityAfterApproval: Int {
        min(100, currentCredibility + 5)
    }

    var newCredibilityAfterDecline: Int {
        max(0, currentCredibility - 20)
    }

    var tasksToRecover: Int {
        return 4 // 20 points / 5 points per task = 4 tasks
    }

    func approveTask() {
        isProcessing = true

        let result = taskService.approveTask(
            assignmentId: assignment.id,
            parentId: parentId,
            parentNotes: nil,
            credibilityScore: currentCredibility
        )

        isProcessing = false

        if result.success {
            resultMessage = result.message
            showApprovalSuccess = true
            // TODO: Send notification to child
        }
    }

    func approveTaskWithEdits() {
        isProcessing = true

        let result = taskService.approveTaskWithEdits(
            assignmentId: assignment.id,
            parentId: parentId,
            newLevel: editedLevel,
            parentNotes: editedParentNotes.isEmpty ? nil : editedParentNotes,
            credibilityScore: currentCredibility
        )

        isProcessing = false

        if result.success {
            resultMessage = result.message
            showApprovalSuccess = true
            // TODO: Send notification to child
        }
    }

    func declineTask() {
        guard !declineReason.isEmpty else { return }

        isProcessing = true

        let result = taskService.declineTask(
            assignmentId: assignment.id,
            parentId: parentId,
            reason: declineReason,
            credibilityScore: currentCredibility
        )

        isProcessing = false

        if result.success {
            resultMessage = result.message
            showDeclineSuccess = true
            // TODO: Send notification to child
        }
    }
}
