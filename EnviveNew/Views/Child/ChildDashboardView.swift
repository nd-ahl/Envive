import SwiftUI
import Combine

// MARK: - Task Timer Manager (Persistent Storage)

class TaskTimerManager {
    static let shared = TaskTimerManager()

    private let userDefaults = UserDefaults.standard
    private let startTimesKey = "taskStartTimes"
    private let pausedTimesKey = "taskPausedTimes"
    private let pauseStartTimesKey = "taskPauseStartTimes"

    private init() {}

    // Save start time for a task
    func setStartTime(_ date: Date, for taskId: UUID) {
        var startTimes = getStartTimes()
        startTimes[taskId.uuidString] = date.timeIntervalSince1970
        saveStartTimes(startTimes)

        // Reset paused time for new task
        var pausedTimes = getPausedTimes()
        pausedTimes[taskId.uuidString] = 0
        savePausedTimes(pausedTimes)

        print("⏱️ Saved start time for task \(taskId): \(date)")
    }

    // Get start time for a task
    func getStartTime(for taskId: UUID) -> Date? {
        let startTimes = getStartTimes()
        guard let timestamp = startTimes[taskId.uuidString] else {
            return nil
        }
        return Date(timeIntervalSince1970: timestamp)
    }

    // Remove start time for a task (when completed or cancelled)
    func removeStartTime(for taskId: UUID) {
        var startTimes = getStartTimes()
        startTimes.removeValue(forKey: taskId.uuidString)
        saveStartTimes(startTimes)

        var pausedTimes = getPausedTimes()
        pausedTimes.removeValue(forKey: taskId.uuidString)
        savePausedTimes(pausedTimes)

        var pauseStartTimes = getPauseStartTimes()
        pauseStartTimes.removeValue(forKey: taskId.uuidString)
        savePauseStartTimes(pauseStartTimes)

        print("⏱️ Removed start time for task \(taskId)")
    }

    // Pause timer (e.g., when taking photo)
    func pauseTimer(for taskId: UUID) {
        var pauseStartTimes = getPauseStartTimes()
        pauseStartTimes[taskId.uuidString] = Date().timeIntervalSince1970
        savePauseStartTimes(pauseStartTimes)
        print("⏸️ Timer paused for task \(taskId)")
    }

    // Resume timer (e.g., after taking photo)
    func resumeTimer(for taskId: UUID) {
        guard let pauseStartTime = getPauseStartTime(for: taskId) else {
            print("⚠️ No pause start time found for task \(taskId)")
            return
        }

        let pauseDuration = Date().timeIntervalSince1970 - pauseStartTime

        var pausedTimes = getPausedTimes()
        let currentPausedTime = pausedTimes[taskId.uuidString] ?? 0
        pausedTimes[taskId.uuidString] = currentPausedTime + pauseDuration
        savePausedTimes(pausedTimes)

        // Remove pause start time
        var pauseStartTimes = getPauseStartTimes()
        pauseStartTimes.removeValue(forKey: taskId.uuidString)
        savePauseStartTimes(pauseStartTimes)

        print("▶️ Timer resumed for task \(taskId) (paused for \(Int(pauseDuration))s)")
    }

    // Check if timer is currently paused
    func isPaused(for taskId: UUID) -> Bool {
        return getPauseStartTime(for: taskId) != nil
    }

    // Get elapsed time for a task (excluding paused time)
    func getElapsedTime(for taskId: UUID) -> TimeInterval {
        guard let startTime = getStartTime(for: taskId) else {
            return 0
        }

        let totalTime = Date().timeIntervalSince(startTime)
        let pausedTime = getPausedTime(for: taskId)

        // If currently paused, add the current pause duration
        var currentPauseDuration: TimeInterval = 0
        if let pauseStartTime = getPauseStartTime(for: taskId) {
            currentPauseDuration = Date().timeIntervalSince1970 - pauseStartTime
        }

        return max(0, totalTime - pausedTime - currentPauseDuration)
    }

    // Private helpers
    private func getStartTimes() -> [String: TimeInterval] {
        return userDefaults.dictionary(forKey: startTimesKey) as? [String: TimeInterval] ?? [:]
    }

    private func saveStartTimes(_ times: [String: TimeInterval]) {
        userDefaults.set(times, forKey: startTimesKey)
    }

    private func getPausedTimes() -> [String: TimeInterval] {
        return userDefaults.dictionary(forKey: pausedTimesKey) as? [String: TimeInterval] ?? [:]
    }

    private func savePausedTimes(_ times: [String: TimeInterval]) {
        userDefaults.set(times, forKey: pausedTimesKey)
    }

    private func getPausedTime(for taskId: UUID) -> TimeInterval {
        let pausedTimes = getPausedTimes()
        return pausedTimes[taskId.uuidString] ?? 0
    }

    private func getPauseStartTimes() -> [String: TimeInterval] {
        return userDefaults.dictionary(forKey: pauseStartTimesKey) as? [String: TimeInterval] ?? [:]
    }

    private func savePauseStartTimes(_ times: [String: TimeInterval]) {
        userDefaults.set(times, forKey: pauseStartTimesKey)
    }

    private func getPauseStartTime(for taskId: UUID) -> TimeInterval? {
        let pauseStartTimes = getPauseStartTimes()
        return pauseStartTimes[taskId.uuidString]
    }
}

// MARK: - Child Dashboard View

struct ChildDashboardView: View {
    @StateObject private var viewModel: ChildDashboardViewModel
    @State private var showTaskCreation = false
    @State private var showDeclineNotification = false
    @State private var currentDeclinedTask: TaskAssignment?
    @State private var declineCredibilityLost: Int = 0
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: ChildDashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats Overview Card
                    statsOverviewCard

                    // Browse Tasks Button
                    browseTasksButton

                    // Assigned Tasks Section
                    if !viewModel.assignedTasks.isEmpty {
                        assignedTasksSection
                    }

                    // In Progress Tasks
                    if !viewModel.inProgressTasks.isEmpty {
                        inProgressTasksSection
                    }

                    // Pending Review Tasks
                    if !viewModel.pendingReviewTasks.isEmpty {
                        pendingReviewSection
                    }

                    // Empty State
                    if viewModel.assignedTasks.isEmpty && viewModel.inProgressTasks.isEmpty && viewModel.pendingReviewTasks.isEmpty {
                        emptyStateView
                    }
                }
                .padding()
            }
            .navigationTitle("My Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    NavigationLink(destination: TaskHistoryView(
                        taskService: viewModel.taskService,
                        childId: viewModel.childId,
                        childName: nil
                    )) {
                        Image(systemName: "clock.arrow.circlepath")
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    credibilityBadge
                }
            }
            .onAppear {
                viewModel.loadData()
                checkForDeclines()
            }
            .refreshable {
                viewModel.loadData()
                checkForDeclines()
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Check for declines when app becomes active
                if newPhase == .active {
                    print("🔔 App became active - checking for declines")
                    checkForDeclines()
                }
            }
            .sheet(isPresented: $showTaskCreation) {
                ChildTaskCreationView(
                    childId: viewModel.childId,
                    taskService: viewModel.taskService
                )
            }
            .overlay {
                if showDeclineNotification, let task = currentDeclinedTask {
                    DeclineNotificationView(
                        assignment: task,
                        credibilityLost: declineCredibilityLost,
                        onDismiss: {
                            // Mark as viewed
                            _ = viewModel.taskService.markDeclineAsViewed(assignmentId: task.id)
                            showDeclineNotification = false
                            currentDeclinedTask = nil

                            // Check if there are more declines to show
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                checkForDeclines()
                            }
                        }
                    )
                }
            }
        }
    }

    // MARK: - Decline Checking

    private func checkForDeclines() {
        // Get all child's tasks
        let allTasks = viewModel.taskService.getChildTasks(childId: viewModel.childId, status: nil)

        // Find first unseen decline
        if let declinedTask = allTasks.first(where: { $0.isUnseenDecline }) {
            currentDeclinedTask = declinedTask

            // Calculate credibility lost (usually -10 or -15)
            // We'll use -10 as default, but could enhance this to calculate actual amount
            declineCredibilityLost = -10

            // Show the notification
            showDeclineNotification = true

            print("🚨 Showing decline notification for: \(declinedTask.title)")
        }
    }

    // MARK: - Browse Tasks Button

    private var browseTasksButton: some View {
        Button(action: {
            showTaskCreation = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.title3)
                Text("Browse Task Library")
                    .font(.headline)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .foregroundColor(.white)
            .background(
                LinearGradient(
                    colors: [Color.blue, Color.blue.opacity(0.8)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }

    // MARK: - Stats Overview Card

    private var statsOverviewCard: some View {
        VStack(spacing: 16) {
            // Main stat: Screen Time Balance
            VStack(spacing: 8) {
                Text("Screen Time Balance")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(viewModel.xpBalance)")
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(.blue)
                    Text("min")
                        .font(.title3)
                        .foregroundColor(.blue.opacity(0.7))
                }
            }

            Divider()

            // Secondary stats
            HStack(spacing: 0) {
                StatColumn(
                    label: "Credibility",
                    value: "\(viewModel.credibility)%",
                    color: credibilityColor(for: viewModel.credibility)
                )

                Spacer()

                Divider()
                    .frame(height: 40)

                Spacer()

                StatColumn(
                    label: "Tasks Done",
                    value: "\(viewModel.completedTasksCount)",
                    color: .green
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Credibility Badge

    private var credibilityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
            Text("\(viewModel.credibility)%")
                .font(.subheadline)
                .fontWeight(.bold)
        }
        .foregroundColor(credibilityColor(for: viewModel.credibility))
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(credibilityColor(for: viewModel.credibility).opacity(0.2))
        .cornerRadius(12)
    }

    // MARK: - Assigned Tasks Section

    private var assignedTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Assigned Tasks", systemImage: "checklist")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.assignedTasks.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(8)
            }

            ForEach(viewModel.assignedTasks) { task in
                NavigationLink(destination: ChildTaskDetailView(
                    assignment: task,
                    taskService: viewModel.taskService
                )) {
                    ChildTaskCard(assignment: task, showStatus: true)
                }
            }
        }
    }

    // MARK: - In Progress Section

    private var inProgressTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("In Progress", systemImage: "play.circle.fill")
                    .font(.headline)
                    .foregroundColor(.green)
                Spacer()
                Text("\(viewModel.inProgressTasks.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .cornerRadius(8)
            }

            ForEach(viewModel.inProgressTasks) { task in
                NavigationLink(destination: ChildTaskDetailView(
                    assignment: task,
                    taskService: viewModel.taskService
                )) {
                    ChildTaskCard(assignment: task, showStatus: true)
                }
            }
        }
    }

    // MARK: - Pending Review Section

    private var pendingReviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Waiting for Review", systemImage: "hourglass")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
                Text("\(viewModel.pendingReviewTasks.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange)
                    .cornerRadius(8)
            }

            ForEach(viewModel.pendingReviewTasks) { task in
                ChildTaskCard(assignment: task, showStatus: false)
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)

            Text("No Tasks Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text("Tap \"Browse Task Library\" above to find tasks you can do!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Helpers

    private func credibilityColor(for score: Int) -> Color {
        switch score {
        case 95...100: return .green
        case 80...94: return .blue
        case 60...79: return .yellow
        case 40...59: return .orange
        default: return .red
        }
    }
}

// MARK: - Stat Column Component

private struct StatColumn: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Child Task Card

struct ChildTaskCard: View {
    let assignment: TaskAssignment
    let showStatus: Bool

    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(assignment.category.icon)
                .font(.title2)

            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                Text(assignment.title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Text(assignment.assignedLevel.shortName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)

                    Text("\(assignment.assignedLevel.baseXP) min")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if showStatus {
                        Text(statusDisplayName(assignment.status))
                            .font(.caption)
                            .foregroundColor(statusColor(assignment.status))
                    }
                }

                // Show stopwatch for in-progress tasks
                if assignment.status == .inProgress {
                    HStack(spacing: 4) {
                        Image(systemName: "stopwatch.fill")
                            .font(.caption2)
                            .foregroundColor(.orange)
                        Text(formatElapsedTime(elapsedTime))
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                            .monospacedDigit()
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            // Arrow or Status Icon
            if showStatus {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            } else {
                Image(systemName: "clock.fill")
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(backgroundColor(for: assignment.status))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        .onAppear {
            if assignment.status == .inProgress {
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
    }

    private func statusDisplayName(_ status: TaskAssignmentStatus) -> String {
        switch status {
        case .assigned: return "Assigned"
        case .inProgress: return "In Progress"
        case .pendingReview: return "Pending Review"
        case .approved: return "Approved"
        case .declined: return "Declined"
        case .expired: return "Expired"
        }
    }

    private func statusColor(_ status: TaskAssignmentStatus) -> Color {
        switch status {
        case .assigned: return .blue
        case .inProgress: return .green
        case .pendingReview: return .orange
        case .approved: return .green
        case .declined: return .red
        case .expired: return .gray
        }
    }

    private func backgroundColor(for status: TaskAssignmentStatus) -> Color {
        switch status {
        case .assigned: return Color.blue.opacity(0.05)
        case .inProgress: return Color.green.opacity(0.05)
        case .pendingReview: return Color.orange.opacity(0.05)
        case .approved: return Color.green.opacity(0.1)
        case .declined: return Color.red.opacity(0.05)
        case .expired: return Color.gray.opacity(0.05)
        }
    }

    // MARK: - Timer Functions

    private func startTimer() {
        // Get start time from persistent storage
        if let startTime = TaskTimerManager.shared.getStartTime(for: assignment.id) {
            // Calculate elapsed time
            elapsedTime = Date().timeIntervalSince(startTime)

            // Start timer to update display
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                elapsedTime = Date().timeIntervalSince(startTime)
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Child Dashboard View Model

@MainActor
class ChildDashboardViewModel: ObservableObject {
    @Published var assignedTasks: [TaskAssignment] = []
    @Published var inProgressTasks: [TaskAssignment] = []
    @Published var pendingReviewTasks: [TaskAssignment] = []
    @Published var xpBalance: Int = 0
    @Published var credibility: Int = 100
    @Published var completedTasksCount: Int = 0

    let taskService: TaskService
    let xpService: XPService
    let credibilityService: CredibilityService
    let childId: UUID

    init(
        taskService: TaskService,
        xpService: XPService,
        credibilityService: CredibilityService,
        childId: UUID
    ) {
        self.taskService = taskService
        self.xpService = xpService
        self.credibilityService = credibilityService
        self.childId = childId
    }

    func loadData() {
        print("👶 Child dashboard loading for child ID: \(childId)")

        // Load tasks for this child
        let allTasks = taskService.getChildTasks(childId: childId, status: nil)
        print("👶 Found \(allTasks.count) total tasks for this child")

        assignedTasks = allTasks.filter { $0.status == .assigned }
        inProgressTasks = allTasks.filter { $0.status == .inProgress }
        pendingReviewTasks = allTasks.filter { $0.status == .pendingReview }

        print("👶 Assigned: \(assignedTasks.count), In Progress: \(inProgressTasks.count), Pending Review: \(pendingReviewTasks.count)")

        // Load XP balance and convert to screen time minutes
        let rawXP: Int
        if let balance = xpService.getBalance(userId: childId) {
            rawXP = balance.currentXP
        } else {
            rawXP = 0
        }

        // Load credibility
        credibility = credibilityService.getCredibilityScore(childId: childId)

        // Convert XP to minutes using credibility multiplier
        // This ensures consistency with home screen and session system
        xpBalance = credibilityService.calculateXPToMinutes(xpAmount: rawXP, childId: childId)

        print("👶 XP: \(rawXP) → Minutes: \(xpBalance) (credibility: \(credibility)%)")

        // Count completed tasks
        completedTasksCount = allTasks.filter {
            $0.status == .approved
        }.count
    }
}

// MARK: - Child Task Detail View

struct ChildTaskDetailView: View {
    let assignment: TaskAssignment
    let taskService: TaskService

    @StateObject private var model = EnhancedScreenTimeModel()
    @State private var showingCamera = false
    @State private var photoTaken = false
    @State private var capturedBackPhoto: UIImage?
    @State private var capturedFrontPhoto: UIImage?
    @State private var showMainAsBack = true
    @State private var showingCompleteConfirmation = false
    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header Card
                taskHeaderCard

                // Task Description
                descriptionSection

                // XP Reward Card
                xpRewardCard

                // Status Section
                statusSection

                // Photo Section (if photo taken)
                if photoTaken, let backPhoto = capturedBackPhoto, let frontPhoto = capturedFrontPhoto {
                    photoSection(backPhoto: backPhoto, frontPhoto: frontPhoto)
                }

                // Action Buttons
                actionButtons
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Start timer if task is in progress
            if assignment.status == .inProgress {
                startTimer()
            }
        }
        .onDisappear {
            stopTimer()
        }
        .onChange(of: showingCamera) { isShowing in
            // Pause timer when camera opens, resume when it closes
            if isShowing {
                TaskTimerManager.shared.pauseTimer(for: assignment.id)
                print("⏸️ Timer paused - opening camera")
            } else if assignment.status == .inProgress {
                TaskTimerManager.shared.resumeTimer(for: assignment.id)
                print("▶️ Timer resumed - camera closed")
            }
        }
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView(
                cameraManager: model.cameraManager,
                isPresented: $showingCamera,
                taskTitle: assignment.title,
                taskId: assignment.id,
                onPhotoTaken: { backImage, frontImage in
                    print("📸 Photo captured - Back: \(backImage.size), Front: \(frontImage?.size.debugDescription ?? "none")")

                    // Store both images separately (watermark already applied to back image)
                    capturedBackPhoto = backImage
                    capturedFrontPhoto = frontImage
                    photoTaken = true

                    // Save both photos (back and front separately)
                    _ = model.cameraManager.savePhoto(backImage, taskTitle: assignment.title, taskId: assignment.id, frontImage: frontImage)
                    print("📸 Photos saved for task \(assignment.id) (back and front)")

                    // Camera dismisses automatically via CameraViewController
                }
            )
            .edgesIgnoringSafeArea(.all)
        }
        .alert("Task Completed!", isPresented: $showingCompleteConfirmation) {
            Button("OK") {
                dismiss()
            }
        } message: {
            let timeSpent = formatElapsedTime(elapsedTime)
            Text("Your task has been submitted for review.\n\nTime spent: \(timeSpent)\nYou'll receive \(assignment.assignedLevel.baseXP) minutes once approved!")
        }
    }

    // MARK: - Task Header Card

    private var taskHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(assignment.category.icon)
                    .font(.system(size: 50))

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(assignment.assignedLevel.displayName)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text("Level \(assignment.assignedLevel.rawValue)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text(assignment.title)
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                Label(assignment.category.rawValue, systemImage: "tag.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if let dueDate = assignment.dueDate {
                    Label(formatDueDate(dueDate), systemImage: "clock")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                }
            }

            // Task Creator Info
            Divider()

            HStack(spacing: 8) {
                // Profile photo or initials
                if assignment.isParentAssigned,
                   let assignerId = assignment.assignedBy,
                   let assignerProfile = getAssignerProfile(assignerId) {

                    if let photoFileName = assignerProfile.profilePhotoFileName,
                       let image = ProfilePhotoManager.shared.loadProfilePhoto(fileName: photoFileName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Text(String(assignerProfile.name.prefix(1)).uppercased())
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.blue)
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Assigned by")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text(assignerProfile.name)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                } else {
                    // Self-created task - show child's photo
                    let deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager

                    if let profile = deviceModeManager.currentProfile,
                       let photoFileName = profile.profilePhotoFileName,
                       let image = ProfilePhotoManager.shared.loadProfilePhoto(fileName: photoFileName) {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 32, height: 32)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(Color.green.opacity(0.2))
                            .frame(width: 32, height: 32)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.green)
                            )
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Created by")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("You")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                }

                Spacer()
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Description", systemImage: "doc.text")
                .font(.headline)

            Text(assignment.description)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - XP Reward Card

    private var xpRewardCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text("You'll Earn")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(assignment.assignedLevel.baseXP)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                        Text("minutes")
                            .font(.subheadline)
                            .foregroundColor(.blue.opacity(0.7))
                    }
                }

                Spacer()
            }

            Divider()

            Text("Complete this task to earn screen time!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Status", systemImage: "info.circle")
                .font(.headline)

            HStack {
                Circle()
                    .fill(statusColor(assignment.status))
                    .frame(width: 12, height: 12)

                Text(statusText(assignment.status))
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Spacer()
            }

            // Stopwatch display (only show for in-progress tasks)
            if assignment.status == .inProgress {
                Divider()

                let isPaused = TaskTimerManager.shared.isPaused(for: assignment.id)

                HStack {
                    Image(systemName: isPaused ? "pause.circle.fill" : "stopwatch.fill")
                        .foregroundColor(isPaused ? .gray : .orange)
                    Text(isPaused ? "Time Paused:" : "Time Spent:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatElapsedTime(elapsedTime))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(isPaused ? .gray : .orange)
                        .monospacedDigit()
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background((isPaused ? Color.gray : Color.orange).opacity(0.1))
                .cornerRadius(8)

                if isPaused {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.caption2)
                            .foregroundColor(.blue)
                        Text("Timer paused while taking photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if photoTaken {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Photo proof attached")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Photo Section

    private func photoSection(backPhoto: UIImage, frontPhoto: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Photo Proof", systemImage: "camera.fill")
                .font(.headline)

            // BeReal-style photo display with 4:5 ratio
            GeometryReader { geometry in
                let width = geometry.size.width
                let height = width * 1.25 // 4:5 ratio

                ZStack {
                    // Main photo (tappable to view full screen)
                    Image(uiImage: showMainAsBack ? backPhoto : frontPhoto)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height)
                        .clipped()
                        .cornerRadius(20)

                    // Small overlay photo (tappable to swap)
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: { showMainAsBack.toggle() }) {
                                Image(uiImage: showMainAsBack ? frontPhoto : backPhoto)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 80, height: 106) // 4:5 ratio
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 12) {
            if assignment.status == .assigned {
                // Start task button
                Button(action: handleStartTask) {
                    HStack {
                        Image(systemName: "play.fill")
                        Text("Start Task")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }

            if assignment.status == .inProgress {
                // Take photo button
                Button(action: {
                    showingCamera = true
                }) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Take Photo Proof")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(photoTaken ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                // Complete task button (only if photo taken)
                if photoTaken {
                    Button(action: handleCompleteTask) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Complete Task")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }

            if assignment.status == .pendingReview {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Waiting for parent approval...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
    }

    // MARK: - Actions

    private func handleStartTask() {
        let success = taskService.startTask(assignmentId: assignment.id)
        if success {
            print("✅ Task started successfully")

            // Play haptic and audio feedback
            HapticFeedbackManager.shared.taskStarted()

            // Save start time to persistent storage
            TaskTimerManager.shared.setStartTime(Date(), for: assignment.id)
            // Start the stopwatch
            startTimer()
            // Refresh view by dismissing and reloading
            dismiss()
        }
    }

    private func handleCompleteTask() {
        guard photoTaken, let backPhoto = capturedBackPhoto, let frontPhoto = capturedFrontPhoto else {
            print("❌ Cannot complete task without photos")
            return
        }

        // Stop the timer and calculate final time
        stopTimer()
        let timeSpentMinutes = Int(ceil(elapsedTime / 60.0)) // Round up to nearest minute

        // Photos already saved when captured (back and front separately)
        // Parent will load and display them the same way we do

        // Save photo URL (in production, upload to server)
        let photoURL = "photo_\(assignment.id)_\(Date().timeIntervalSince1970)"

        let success = taskService.completeTask(
            assignmentId: assignment.id,
            photoURL: photoURL,
            notes: nil,
            timeMinutes: timeSpentMinutes
        )

        if success {
            print("✅ Task completed and submitted for review (Time spent: \(timeSpentMinutes) minutes)")

            // Play rewarding haptic and audio feedback
            HapticFeedbackManager.shared.taskCompleted()

            // Remove start time from persistent storage
            TaskTimerManager.shared.removeStartTime(for: assignment.id)
            showingCompleteConfirmation = true
        } else {
            print("❌ Failed to complete task")

            // Play error haptic
            HapticFeedbackManager.shared.error()
        }
    }

    // MARK: - Helpers

    private func statusText(_ status: TaskAssignmentStatus) -> String {
        switch status {
        case .assigned: return "Ready to start"
        case .inProgress: return "In progress - take photo to complete"
        case .pendingReview: return "Submitted for review"
        case .approved: return "Approved"
        case .declined: return "Declined"
        case .expired: return "Expired"
        }
    }

    private func statusColor(_ status: TaskAssignmentStatus) -> Color {
        switch status {
        case .assigned: return .blue
        case .inProgress: return .green
        case .pendingReview: return .orange
        case .approved: return .green
        case .declined: return .red
        case .expired: return .gray
        }
    }

    private func formatDueDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    /// Get the profile of the user who assigned this task
    private func getAssignerProfile(_ assignerId: UUID) -> UserProfile? {
        // Use the device mode manager to get the profile by ID
        let deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager

        // Try to load the actual stored profile
        if let profile = deviceModeManager.getProfile(byId: assignerId) {
            return profile
        }

        // Fallback: Create a default parent profile for display
        return UserProfile(
            id: assignerId,
            name: "Parent",
            mode: .parent
        )
    }

    // MARK: - Timer Management

    private func startTimer() {
        // Get start time from persistent storage (or current time if not set)
        let startTime = TaskTimerManager.shared.getStartTime(for: assignment.id) ?? Date()

        // Calculate current elapsed time
        elapsedTime = Date().timeIntervalSince(startTime)

        // Stop existing timer if any
        stopTimer()

        // Start new timer that updates every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            elapsedTime = TaskTimerManager.shared.getElapsedTime(for: assignment.id)
        }

        print("⏱️ Stopwatch started for task \(assignment.id)")
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
        print("⏱️ Stopwatch stopped at \(formatElapsedTime(elapsedTime))")
    }

    private func formatElapsedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60

        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

// MARK: - Preview

struct ChildDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ChildDashboardView(
            viewModel: ChildDashboardViewModel(
                taskService: DependencyContainer.shared.taskService,
                xpService: DependencyContainer.shared.xpService,
                credibilityService: DependencyContainer.shared.credibilityService,
                childId: UUID()
            )
        )
    }
}
