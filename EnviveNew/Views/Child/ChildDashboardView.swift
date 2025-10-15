import SwiftUI
import Combine

// MARK: - Child Dashboard View

struct ChildDashboardView: View {
    @StateObject private var viewModel: ChildDashboardViewModel

    init(viewModel: ChildDashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // XP Balance Card
                    xpBalanceCard

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

                    // Browse More Tasks
                    browseTasksSection
                }
                .padding()
            }
            .navigationTitle("My Tasks")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    credibilityBadge
                }
            }
            .onAppear {
                viewModel.loadData()
            }
            .refreshable {
                viewModel.loadData()
            }
        }
    }

    // MARK: - XP Balance Card

    private var xpBalanceCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Screen Time Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(viewModel.xpBalance) minutes")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                Spacer()

                Image(systemName: "clock.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.blue.opacity(0.3))
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total XP Earned")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.totalXP) XP")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Tasks Completed")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.completedTasksCount)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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

    // MARK: - Browse Tasks Section

    private var browseTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Browse More Tasks")
                .font(.headline)

            NavigationLink(destination: Text("Task Browser - Coming Soon")) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.title3)
                    Text("Find tasks to claim")
                        .fontWeight(.semibold)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
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

// MARK: - Child Task Card

struct ChildTaskCard: View {
    let assignment: TaskAssignment
    let showStatus: Bool

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

                    Text("\(assignment.assignedLevel.baseXP) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if showStatus {
                        Text(statusDisplayName(assignment.status))
                            .font(.caption)
                            .foregroundColor(statusColor(assignment.status))
                    }
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
}

// MARK: - Child Dashboard View Model

@MainActor
class ChildDashboardViewModel: ObservableObject {
    @Published var assignedTasks: [TaskAssignment] = []
    @Published var inProgressTasks: [TaskAssignment] = []
    @Published var pendingReviewTasks: [TaskAssignment] = []
    @Published var xpBalance: Int = 0
    @Published var totalXP: Int = 0
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

        // Load XP and credibility
        if let balance = xpService.getBalance(userId: childId) {
            xpBalance = balance.currentXP
            totalXP = balance.lifetimeEarned
        } else {
            xpBalance = 0
            totalXP = 0
        }

        credibility = credibilityService.credibilityScore
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

                    // Save both photos
                    _ = model.cameraManager.savePhoto(backImage, taskTitle: assignment.title, taskId: assignment.id)
                    print("📸 Photos saved for task \(assignment.id)")

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
            Text("Your task has been submitted for review. You'll receive \(assignment.assignedLevel.baseXP) XP once approved!")
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
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)

            Text(assignment.description)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - XP Reward Card

    private var xpRewardCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "star.fill")
                    .font(.title)
                    .foregroundColor(.yellow)

                VStack(alignment: .leading, spacing: 4) {
                    Text("You'll Earn")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(assignment.assignedLevel.baseXP) XP")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                Spacer()

                Image(systemName: "clock.fill")
                    .font(.title)
                    .foregroundColor(.blue)

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Screen Time")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("\(assignment.assignedLevel.baseXP) min")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
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
                colors: [Color.blue.opacity(0.1), Color.yellow.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Status Section

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Status")
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
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Photo Section

    private func photoSection(backPhoto: UIImage, frontPhoto: UIImage) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo Proof")
                .font(.headline)

            // BeReal-style photo display with 4:5 ratio (like Social tab)
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
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
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
            // Refresh view by dismissing and reloading
            dismiss()
        }
    }

    private func handleCompleteTask() {
        guard photoTaken, let backPhoto = capturedBackPhoto, let frontPhoto = capturedFrontPhoto else {
            print("❌ Cannot complete task without photos")
            return
        }

        // Create combined BeReal-style image for submission
        let combinedImage = createBeRealStyleImage(mainImage: backPhoto, overlayImage: frontPhoto)

        // Save the combined image for parent review
        _ = model.cameraManager.savePhoto(combinedImage, taskTitle: assignment.title + " (Combined)", taskId: assignment.id)

        // Save photo URL (in production, upload to server)
        let photoURL = "photo_\(assignment.id)_\(Date().timeIntervalSince1970)"

        let success = taskService.completeTask(
            assignmentId: assignment.id,
            photoURL: photoURL,
            notes: nil,
            timeMinutes: nil
        )

        if success {
            print("✅ Task completed and submitted for review")
            showingCompleteConfirmation = true
        } else {
            print("❌ Failed to complete task")
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

    // MARK: - BeReal-Style Image Combination

    private func createBeRealStyleImage(mainImage: UIImage, overlayImage: UIImage) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: mainImage.size)

        return renderer.image { context in
            // Draw the main image (back camera with watermark)
            mainImage.draw(at: .zero)

            // Calculate overlay size (20% of main image width, maintaining aspect ratio)
            let overlayWidth = mainImage.size.width * 0.2
            let overlayHeight = overlayWidth * (overlayImage.size.height / overlayImage.size.width)
            let overlaySize = CGSize(width: overlayWidth, height: overlayHeight)

            // Position overlay in top-RIGHT corner with padding (matching Social tab)
            let padding: CGFloat = 16
            let overlayRect = CGRect(
                x: mainImage.size.width - overlaySize.width - padding,
                y: padding,
                width: overlaySize.width,
                height: overlaySize.height
            )

            // Draw white border/shadow for overlay
            let borderRect = overlayRect.insetBy(dx: -3, dy: -3)
            context.cgContext.setFillColor(UIColor.white.cgColor)
            let borderPath = UIBezierPath(roundedRect: borderRect, cornerRadius: 12)
            context.cgContext.addPath(borderPath.cgPath)
            context.cgContext.fillPath()

            // Clip to rounded rectangle for overlay
            let clipPath = UIBezierPath(roundedRect: overlayRect, cornerRadius: 10)
            context.cgContext.addPath(clipPath.cgPath)
            context.cgContext.clip()

            // Draw the overlay image (front camera)
            overlayImage.draw(in: overlayRect)
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
