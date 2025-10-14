import SwiftUI
import Combine

// MARK: - Task Review View (Parent Approval Interface)

struct TaskReviewView: View {
    @StateObject private var viewModel: TaskReviewViewModel
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
                if let photoURL = viewModel.assignment.photoURL {
                    photoEvidenceSection(photoURL: photoURL)
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

    private func photoEvidenceSection(photoURL: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Photo Evidence", systemImage: "camera.fill")
                .font(.headline)

            // TODO: Load actual image from photoURL
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 200)
                .cornerRadius(8)
                .overlay(
                    Text("📸 Photo")
                        .foregroundColor(.secondary)
                )

            Text("Tap to view full size")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
        VStack(alignment: .leading, spacing: 12) {
            Label("Child's Stats", systemImage: "person.fill")
                .font(.headline)

            HStack {
                StatRow(label: "Current Credibility", value: "\(viewModel.currentCredibility)%")
                Spacer()
                StatRow(label: "Recent Approvals", value: "\(viewModel.consecutiveApprovals)")
            }

            HStack {
                StatRow(label: "Recent Declines", value: "\(viewModel.recentDeclines)")
                Spacer()
                StatRow(label: "Earning Rate", value: "\(viewModel.currentCredibility)%")
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - XP Calculation

    private var xpCalculationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("XP Calculation", systemImage: "number.circle.fill")
                .font(.headline)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Base XP:")
                    Spacer()
                    Text("\(viewModel.assignment.assignedLevel.baseXP) XP")
                        .fontWeight(.medium)
                }

                HStack {
                    Text("× Credibility:")
                    Spacer()
                    Text("\(viewModel.currentCredibility)%")
                        .fontWeight(.medium)
                }

                Divider()

                HStack {
                    Text("Child will earn:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(viewModel.calculatedXP) XP")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color.green.opacity(0.1))
            .cornerRadius(8)

            HStack {
                Text("Credibility change:")
                Spacer()
                Text("\(viewModel.currentCredibility)% → \(viewModel.newCredibilityAfterApproval)%")
                    .foregroundColor(.green)
                    .fontWeight(.medium)
            }
            .font(.subheadline)
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
                    Text("⚠️ Credibility -20")
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
                Section {
                    Text("This will:")
                        .font(.subheadline)
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Give 0 XP to child", systemImage: "xmark.circle")
                        Label("Reduce credibility by 20 points", systemImage: "arrow.down.circle")
                            .foregroundColor(.red)
                        Label("Reset consecutive approval streak", systemImage: "flame.slash")
                    }
                    .padding(.vertical, 4)
                }

                Section("Credibility Impact") {
                    HStack {
                        Text("Current:")
                        Spacer()
                        Text("\(viewModel.currentCredibility)%")
                            .fontWeight(.medium)
                    }
                    HStack {
                        Text("After decline:")
                        Spacer()
                        Text("\(viewModel.newCredibilityAfterDecline)%")
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
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

                Section("Recovery Path") {
                    Text("Child will need \(viewModel.tasksToRecover) approved tasks to regain 20 credibility points")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
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
