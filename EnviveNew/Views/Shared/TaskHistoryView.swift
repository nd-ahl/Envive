import SwiftUI
import Combine

// MARK: - Task History View

struct TaskHistoryView: View {
    @StateObject private var viewModel: TaskHistoryViewModel

    init(taskService: TaskService, childId: UUID?, childName: String?) {
        _viewModel = StateObject(wrappedValue: TaskHistoryViewModel(
            taskService: taskService,
            childId: childId,
            childName: childName
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Summary Stats
                summaryStatsCard

                // Filter Buttons
                filterSection

                // Task List
                if viewModel.filteredTasks.isEmpty {
                    emptyStateView
                } else {
                    tasksSection
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.isParentView ? "Task History" : "My History")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            viewModel.loadData()
        }
        .refreshable {
            viewModel.loadData()
        }
    }

    // MARK: - Summary Stats Card

    private var summaryStatsCard: some View {
        VStack(spacing: 16) {
            Text(viewModel.isParentView ? "All Children" : "Your Stats")
                .font(.headline)
                .foregroundColor(.secondary)

            HStack(spacing: 0) {
                StatColumn(
                    label: "Approved",
                    value: "\(viewModel.approvedCount)",
                    color: .green
                )

                Spacer()

                Divider()
                    .frame(height: 40)

                Spacer()

                StatColumn(
                    label: "Declined",
                    value: "\(viewModel.declinedCount)",
                    color: .red
                )

                Spacer()

                Divider()
                    .frame(height: 40)

                Spacer()

                StatColumn(
                    label: "Total XP",
                    value: "\(viewModel.totalXPEarned)",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Filter Section

    private var filterSection: some View {
        HStack(spacing: 12) {
            FilterButton(
                title: "All",
                count: viewModel.allTasks.count,
                isSelected: viewModel.selectedFilter == .all
            ) {
                viewModel.selectedFilter = .all
            }

            FilterButton(
                title: "Approved",
                count: viewModel.approvedCount,
                isSelected: viewModel.selectedFilter == .approved
            ) {
                viewModel.selectedFilter = .approved
            }

            FilterButton(
                title: "Declined",
                count: viewModel.declinedCount,
                isSelected: viewModel.selectedFilter == .declined
            ) {
                viewModel.selectedFilter = .declined
            }
        }
    }

    // MARK: - Tasks Section

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("History", systemImage: "clock.arrow.circlepath")
                    .font(.headline)
                Spacer()
                Text("\(viewModel.filteredTasks.count) tasks")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(viewModel.filteredTasks) { task in
                NavigationLink(destination: HistoryTaskDetailView(
                    assignment: task,
                    childName: viewModel.isParentView ? viewModel.getChildName(task.childId) : nil
                )) {
                    HistoryTaskCard(
                        assignment: task,
                        childName: viewModel.isParentView ? viewModel.getChildName(task.childId) : nil
                    )
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No History Yet")
                .font(.title2)
                .fontWeight(.bold)

            Text(viewModel.isParentView
                ? "Completed tasks will appear here once you approve or decline them."
                : "Your completed tasks will appear here once they're reviewed.")
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
}

// MARK: - Filter Button

private struct FilterButton: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("\(count)")
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(10)
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

// MARK: - History Task Card

struct HistoryTaskCard: View {
    let assignment: TaskAssignment
    let childName: String?

    var body: some View {
        HStack(spacing: 12) {
            // Icon with status indicator
            ZStack(alignment: .bottomTrailing) {
                Text(assignment.category.icon)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(statusColor(assignment.status).opacity(0.1))
                    .cornerRadius(10)

                Image(systemName: assignment.status == .approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.white)
                    .background(statusColor(assignment.status))
                    .clipShape(Circle())
                    .offset(x: 4, y: 4)
            }

            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                if let childName = childName {
                    Text(childName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

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

                    if let adjustedLevel = assignment.adjustedLevel {
                        Image(systemName: "arrow.right")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(adjustedLevel.shortName)
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }

                    if assignment.status == .approved, let xp = assignment.xpAwarded {
                        HStack(spacing: 2) {
                            Image(systemName: "clock.fill")
                                .font(.caption2)
                            Text("\(xp) min")
                        }
                        .font(.caption)
                        .foregroundColor(.green)
                    }
                }

                if let reviewedAt = assignment.reviewedAt {
                    Text(formatDate(reviewedAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(backgroundColor(for: assignment.status))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
    }

    private func statusColor(_ status: TaskAssignmentStatus) -> Color {
        switch status {
        case .approved: return .green
        case .declined: return .red
        default: return .gray
        }
    }

    private func backgroundColor(for status: TaskAssignmentStatus) -> Color {
        switch status {
        case .approved: return Color.green.opacity(0.05)
        case .declined: return Color.red.opacity(0.05)
        default: return Color(.systemBackground)
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Task History View Model

enum TaskHistoryFilter {
    case all
    case approved
    case declined
}

@MainActor
class TaskHistoryViewModel: ObservableObject {
    @Published var allTasks: [TaskAssignment] = []
    @Published var selectedFilter: TaskHistoryFilter = .all
    @Published var approvedCount: Int = 0
    @Published var declinedCount: Int = 0
    @Published var totalXPEarned: Int = 0

    let taskService: TaskService
    let childId: UUID?
    let childName: String?
    let isParentView: Bool

    // For parent view: store all children names
    private var childrenNames: [UUID: String] = [:]

    init(taskService: TaskService, childId: UUID?, childName: String?) {
        self.taskService = taskService
        self.childId = childId
        self.childName = childName
        self.isParentView = (childId == nil)
    }

    var filteredTasks: [TaskAssignment] {
        switch selectedFilter {
        case .all:
            return allTasks
        case .approved:
            return allTasks.filter { $0.status == .approved }
        case .declined:
            return allTasks.filter { $0.status == .declined }
        }
    }

    func loadData() {
        if let childId = childId {
            // Child view: load only this child's completed tasks
            allTasks = taskService.getChildTasks(childId: childId, status: nil)
                .filter { $0.status == .approved || $0.status == .declined }
                .sorted { ($0.reviewedAt ?? Date.distantPast) > ($1.reviewedAt ?? Date.distantPast) }
        } else {
            // Parent view: load all completed tasks
            allTasks = []

            // Get all pending tasks to find all child IDs
            let allKnownTasks = taskService.getPendingApprovals()
            let childIds = Set(allKnownTasks.map { $0.childId })

            // Load completed tasks for each child
            for childId in childIds {
                let childTasks = taskService.getChildTasks(childId: childId, status: nil)
                    .filter { $0.status == .approved || $0.status == .declined }
                allTasks.append(contentsOf: childTasks)

                // Store child name (in production, fetch from user service)
                childrenNames[childId] = "Test Child"
            }

            allTasks.sort { ($0.reviewedAt ?? Date.distantPast) > ($1.reviewedAt ?? Date.distantPast) }
        }

        // Calculate stats
        approvedCount = allTasks.filter { $0.status == .approved }.count
        declinedCount = allTasks.filter { $0.status == .declined }.count
        totalXPEarned = allTasks.filter { $0.status == .approved }.compactMap { $0.xpAwarded }.reduce(0, +)

        print("📜 Task history loaded: \(allTasks.count) tasks (Approved: \(approvedCount), Declined: \(declinedCount))")
    }

    func getChildName(_ childId: UUID) -> String {
        if let name = childrenNames[childId] {
            return name
        }
        return childName ?? "Child"
    }
}

// MARK: - History Task Detail View

struct HistoryTaskDetailView: View {
    let assignment: TaskAssignment
    let childName: String?

    @StateObject private var model = EnhancedScreenTimeModel()
    @State private var showMainAsBack = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Status Banner
                statusBanner

                // Header Card
                taskHeaderCard

                // Task Description
                descriptionSection

                // Result Card (XP or Reason)
                resultCard

                // Review Details
                reviewDetailsSection

                // Photo Section
                photoSection
            }
            .padding()
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Status Banner

    private var statusBanner: some View {
        HStack {
            Image(systemName: assignment.status == .approved ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.title2)

            VStack(alignment: .leading, spacing: 2) {
                Text(assignment.status == .approved ? "Approved" : "Declined")
                    .font(.headline)
                    .fontWeight(.bold)

                if let reviewedAt = assignment.reviewedAt {
                    Text(formatFullDate(reviewedAt))
                        .font(.caption)
                }
            }

            Spacer()
        }
        .foregroundColor(.white)
        .padding()
        .background(assignment.status == .approved ? Color.green : Color.red)
        .cornerRadius(12)
    }

    // MARK: - Task Header Card

    private var taskHeaderCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(assignment.category.icon)
                    .font(.system(size: 50))

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    if let adjustedLevel = assignment.adjustedLevel {
                        Text(adjustedLevel.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.orange)

                        Text("(Adjusted from \(assignment.assignedLevel.rawValue))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text(assignment.assignedLevel.displayName)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        Text("Level \(assignment.assignedLevel.rawValue)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if let childName = childName {
                Text(childName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(6)
            }

            Text(assignment.title)
                .font(.title2)
                .fontWeight(.bold)

            HStack {
                Label(assignment.category.rawValue, systemImage: "tag.fill")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Result Card

    private var resultCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            if assignment.status == .approved {
                HStack {
                    Image(systemName: "clock.fill")
                        .font(.title)
                        .foregroundColor(.green)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Screen Time Earned")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(assignment.xpAwarded ?? 0)")
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                            Text("minutes")
                                .font(.subheadline)
                                .foregroundColor(.green.opacity(0.7))
                        }
                    }

                    Spacer()
                }
            } else {
                // Declined - show reason
                VStack(alignment: .leading, spacing: 8) {
                    Label("Reason for Decline", systemImage: "exclamationmark.triangle.fill")
                        .font(.headline)
                        .foregroundColor(.red)

                    if let notes = assignment.parentNotes {
                        Text(notes)
                            .font(.body)
                            .foregroundColor(.primary)
                    } else {
                        Text("No reason provided")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [
                    (assignment.status == .approved ? Color.green : Color.red).opacity(0.1),
                    (assignment.status == .approved ? Color.green : Color.red).opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke((assignment.status == .approved ? Color.green : Color.red).opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Review Details Section

    private var reviewDetailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Details", systemImage: "info.circle")
                .font(.headline)

            if let completionTime = assignment.completionTimeMinutes {
                HStack {
                    Text("Time Spent:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(completionTime) minutes")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            if let completedAt = assignment.completedAt {
                HStack {
                    Text("Completed:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatFullDate(completedAt))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            if let reviewedAt = assignment.reviewedAt {
                HStack {
                    Text("Reviewed:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatFullDate(reviewedAt))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }

            if assignment.status == .approved, let notes = assignment.parentNotes {
                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Parent Notes:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(notes)
                        .font(.body)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Photo Proof", systemImage: "camera.fill")
                .font(.headline)

            if let savedPhoto = model.cameraManager.getLatestPhotoForTask(assignment.id),
               let backPhoto = model.cameraManager.loadPhoto(savedPhoto: savedPhoto) {
                let frontPhoto = model.cameraManager.loadFrontPhoto(savedPhoto: savedPhoto) ?? backPhoto

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
            } else {
                Text("No photo available")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Helpers

    private func formatFullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
