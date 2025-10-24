import SwiftUI
import Charts
import Combine

// MARK: - Parent Children Management View

struct ParentChildrenManagementView: View {
    @StateObject private var viewModel: ChildrenManagementViewModel
    @State private var selectedChild: ChildInfo?

    init() {
        _viewModel = StateObject(wrappedValue: ChildrenManagementViewModel(
            taskService: DependencyContainer.shared.taskService,
            xpService: DependencyContainer.shared.xpService,
            credibilityService: DependencyContainer.shared.credibilityService,
            deviceModeManager: DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager
        ))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if viewModel.children.isEmpty {
                        emptyStateView
                    } else {
                        // Child Selector Cards
                        childSelectorSection

                        // Selected child details
                        if let child = selectedChild {
                            ChildDetailView(child: child, viewModel: viewModel)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Children")
            .onAppear {
                viewModel.loadChildren()
                if selectedChild == nil, let firstChild = viewModel.children.first {
                    selectedChild = firstChild
                }
            }
            .refreshable {
                viewModel.loadChildren()
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 60))
                .foregroundColor(.gray)

            Text("No Children Added")
                .font(.title2)
                .fontWeight(.bold)

            Text("Add children to your household to see their activity and manage their screen time")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }

    // MARK: - Child Selector

    private var childSelectorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Select Child")
                .font(.headline)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(viewModel.children) { child in
                        ChildSelectorCard(
                            child: child,
                            isSelected: selectedChild?.id == child.id,
                            onTap: {
                                withAnimation {
                                    selectedChild = child
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Child Selector Card

struct ChildSelectorCard: View {
    let child: ChildInfo
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Profile photo or initials
                if let photoFileName = child.profilePhotoFileName,
                   let image = ProfilePhotoManager.shared.loadProfilePhoto(fileName: photoFileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 3)
                        )
                } else {
                    Circle()
                        .fill(isSelected ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Text(String(child.name.prefix(1)).uppercased())
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundColor(isSelected ? .blue : .gray)
                        )
                        .overlay(
                            Circle()
                                .stroke(isSelected ? Color.blue : Color.gray.opacity(0.3), lineWidth: 3)
                        )
                }

                Text(child.name)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 2)
            )
        }
    }
}

// MARK: - Child Detail View

struct ChildDetailView: View {
    let child: ChildInfo
    @ObservedObject var viewModel: ChildrenManagementViewModel
    @State private var selectedTimeRange: TimeRange = .week

    var body: some View {
        VStack(spacing: 20) {
            // Statistics Overview
            statisticsOverviewSection

            // Current Tasks (To-Do List)
            currentTasksSection

            // Screen Time Chart
            screenTimeChartSection

            // Activity Summary
            activitySummarySection

            // Recent Activity Log
            activityLogSection
        }
    }

    // MARK: - Current Tasks Section

    private var currentTasksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Current Tasks")
                    .font(.headline)
                Spacer()
                let currentTasks = viewModel.getCurrentTasks(for: child.id)
                Text("\(currentTasks.count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue)
                    .cornerRadius(8)
            }

            if viewModel.getCurrentTasks(for: child.id).isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.green)
                        Text("No active tasks")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.getCurrentTasks(for: child.id).prefix(5)) { task in
                        CurrentTaskRow(task: task)

                        if task.id != viewModel.getCurrentTasks(for: child.id).prefix(5).last?.id {
                            Divider()
                        }
                    }
                }

                if viewModel.getCurrentTasks(for: child.id).count > 5 {
                    NavigationLink(destination: AllCurrentTasksView(
                        childName: child.name,
                        tasks: viewModel.getCurrentTasks(for: child.id)
                    )) {
                        Text("View All Tasks (\(viewModel.getCurrentTasks(for: child.id).count))")
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 8)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Statistics Overview

    private var statisticsOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)

            HStack(spacing: 12) {
                ChildStatCard(
                    title: "Credibility",
                    value: "\(viewModel.getCredibility(for: child.id))%",
                    icon: "star.fill",
                    color: credibilityColor(for: viewModel.getCredibility(for: child.id))
                )

                ChildStatCard(
                    title: "Screen Time",
                    value: "\(viewModel.getTotalScreenTime(for: child.id)) min",
                    icon: "clock.fill",
                    color: .blue
                )
            }

            HStack(spacing: 12) {
                ChildStatCard(
                    title: "Tasks Complete",
                    value: "\(viewModel.getCompletedTasksCount(for: child.id))",
                    icon: "checkmark.circle.fill",
                    color: .green
                )

                ChildStatCard(
                    title: "Tasks Pending",
                    value: "\(viewModel.getPendingTasksCount(for: child.id))",
                    icon: "clock.badge.exclamationmark.fill",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Screen Time Chart

    private var screenTimeChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Screen Time Earned")
                        .font(.headline)
                    Text("Minutes earned from approved tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Picker("Time Range", selection: $selectedTimeRange) {
                    Text("Week").tag(TimeRange.week)
                    Text("Month").tag(TimeRange.month)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(viewModel.getScreenTimeData(for: child.id, range: selectedTimeRange)) { dataPoint in
                        BarMark(
                            x: .value("Date", dataPoint.date, unit: .day),
                            y: .value("Minutes", dataPoint.minutes)
                        )
                        .foregroundStyle(Color.blue.gradient)
                        .annotation(position: .top) {
                            if dataPoint.minutes > 0 {
                                Text("\(dataPoint.minutes)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let minutes = value.as(Int.self) {
                                Text("\(minutes) min")
                                    .font(.caption)
                            }
                        }
                    }
                }
            } else {
                // Fallback for iOS 15
                SimplifiedBarChart(data: viewModel.getScreenTimeData(for: child.id, range: selectedTimeRange))
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Activity Summary

    private var activitySummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Summary")
                .font(.headline)

            VStack(spacing: 8) {
                ActivitySummaryRow(
                    icon: "checkmark.circle.fill",
                    title: "Tasks Approved",
                    value: "\(viewModel.getApprovedTasksCount(for: child.id, days: 7))",
                    subtitle: "Last 7 days",
                    color: .green
                )

                Divider()

                ActivitySummaryRow(
                    icon: "xmark.circle.fill",
                    title: "Tasks Declined",
                    value: "\(viewModel.getDeclinedTasksCount(for: child.id, days: 7))",
                    subtitle: "Last 7 days",
                    color: .red
                )

                Divider()

                ActivitySummaryRow(
                    icon: "clock.arrow.circlepath",
                    title: "Average Completion Time",
                    value: "\(viewModel.getAverageCompletionTime(for: child.id)) min",
                    subtitle: "Per task",
                    color: .blue
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Activity Log

    private var activityLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)

            if viewModel.getActivityLog(for: child.id).isEmpty {
                Text("No recent activity")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.getActivityLog(for: child.id).prefix(10)) { log in
                        ActivityLogRow(log: log)

                        if log.id != viewModel.getActivityLog(for: child.id).prefix(10).last?.id {
                            Divider()
                        }
                    }
                }
            }

            if viewModel.getActivityLog(for: child.id).count > 10 {
                NavigationLink(destination: FullActivityLogView(
                    childName: child.name,
                    logs: viewModel.getActivityLog(for: child.id)
                )) {
                    Text("View All Activity")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

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

// MARK: - Child Stat Card

struct ChildStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Activity Summary Row

struct ActivitySummaryRow: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Current Task Row

struct CurrentTaskRow: View {
    let task: TaskAssignment
    @State private var showingTaskOptions = false

    var body: some View {
        Button(action: {
            showingTaskOptions = true
        }) {
            HStack(spacing: 12) {
                // Status indicator
                Circle()
                    .fill(statusColor)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)

                    HStack(spacing: 8) {
                        // Status badge
                        Text(statusText)
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(statusColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(statusColor.opacity(0.15))
                            .cornerRadius(6)

                        // Level
                        Text(task.assignedLevel.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        // Due date if exists
                        if let dueDate = task.dueDate {
                            Text("•")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Due \(formatDueDate(dueDate))")
                                .font(.caption2)
                                .foregroundColor(task.isOverdue ? .red : .secondary)
                        }
                    }
                }

                Spacer()

                // Navigate to task details
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingTaskOptions) {
            ParentTaskOptionsView(task: task)
        }
    }

    private var statusColor: Color {
        switch task.status {
        case .assigned: return .blue
        case .inProgress: return .green
        case .pendingReview: return .orange
        default: return .gray
        }
    }

    private var statusText: String {
        switch task.status {
        case .assigned: return "To Do"
        case .inProgress: return "In Progress"
        case .pendingReview: return "Pending Review"
        default: return task.status.rawValue
        }
    }

    private func formatDueDate(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "today"
        } else if calendar.isDateInTomorrow(date) {
            return "tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return formatter.string(from: date)
        }
    }
}

// MARK: - Activity Log Row

struct ActivityLogRow: View {
    let log: ActivityLog

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: log.icon)
                .font(.body)
                .foregroundColor(log.color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 2) {
                Text(log.title)
                    .font(.subheadline)
                    .foregroundColor(.primary)

                if let subtitle = log.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(log.timeAgo)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Full Activity Log View

struct FullActivityLogView: View {
    let childName: String
    let logs: [ActivityLog]

    var body: some View {
        List {
            ForEach(logs) { log in
                ActivityLogRow(log: log)
            }
        }
        .navigationTitle("\(childName)'s Activity")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - All Current Tasks View

struct AllCurrentTasksView: View {
    let childName: String
    let tasks: [TaskAssignment]

    var body: some View {
        List {
            ForEach(tasks) { task in
                CurrentTaskRow(task: task)
            }
        }
        .navigationTitle("\(childName)'s Tasks")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Simplified Bar Chart (iOS 15 fallback)

struct SimplifiedBarChart: View {
    let data: [ScreenTimeDataPoint]

    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.map { $0.minutes }.max() ?? 1

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(data) { point in
                    VStack(spacing: 4) {
                        Spacer()

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue.gradient)
                            .frame(height: CGFloat(point.minutes) / CGFloat(maxValue) * geometry.size.height * 0.8)

                        Text(dateFormatter.string(from: point.date))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 8)
        }
    }

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
}

// MARK: - Supporting Models

struct ChildInfo: Identifiable {
    let id: UUID
    let name: String
    let profilePhotoFileName: String?
}

struct ScreenTimeDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let minutes: Int
}

struct ActivityLog: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let timestamp: Date
    let type: ActivityType

    var icon: String {
        switch type {
        case .taskCompleted: return "checkmark.circle.fill"
        case .taskApproved: return "hand.thumbsup.fill"
        case .taskDeclined: return "hand.thumbsdown.fill"
        case .taskStarted: return "play.circle.fill"
        case .credibilityChanged: return "star.fill"
        case .screenTimeEarned: return "clock.badge.checkmark.fill"
        case .screenTimeUsed: return "hourglass"
        }
    }

    var color: Color {
        switch type {
        case .taskCompleted, .taskApproved, .screenTimeEarned: return .green
        case .taskDeclined: return .red
        case .taskStarted: return .blue
        case .credibilityChanged: return .orange
        case .screenTimeUsed: return .purple
        }
    }

    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
}

enum ActivityType {
    case taskCompleted
    case taskApproved
    case taskDeclined
    case taskStarted
    case credibilityChanged
    case screenTimeEarned
    case screenTimeUsed
}

enum TimeRange {
    case week
    case month
}

// MARK: - View Model

@MainActor
class ChildrenManagementViewModel: ObservableObject {
    @Published var children: [ChildInfo] = []

    private let taskService: TaskService
    private let xpService: XPService
    private let credibilityService: CredibilityService
    private let deviceModeManager: LocalDeviceModeManager
    private let householdContext = HouseholdContext.shared
    private let householdService = HouseholdService.shared

    init(taskService: TaskService, xpService: XPService, credibilityService: CredibilityService, deviceModeManager: LocalDeviceModeManager) {
        self.taskService = taskService
        self.xpService = xpService
        self.credibilityService = credibilityService
        self.deviceModeManager = deviceModeManager
    }

    func loadChildren() {
        // Load children from Supabase database (source of truth)
        Task {
            do {
                let childProfiles = try await householdService.getMyChildren()

                print("📊 Loading children for management view: \(childProfiles.count) from database")

                // Convert Profile objects to ChildInfo format, fetching local profile photo data
                let loadedChildren = childProfiles.map { profile in
                    let childId = UUID(uuidString: profile.id) ?? UUID()

                    // Try to get the local UserProfile to access profilePhotoFileName
                    let localProfile = deviceModeManager.getProfile(byId: childId)

                    return ChildInfo(
                        id: childId,
                        name: profile.fullName ?? "Child",
                        profilePhotoFileName: localProfile?.profilePhotoFileName
                    )
                }

                await MainActor.run {
                    children = loadedChildren
                    print("✅ Children management view loaded \(loadedChildren.count) children")
                }
            } catch {
                print("❌ Error loading children for management view: \(error.localizedDescription)")
                await MainActor.run {
                    children = []
                }
            }
        }
    }

    // MARK: - Statistics Methods

    func getCredibility(for childId: UUID) -> Int {
        return credibilityService.getCredibilityScore(childId: childId)
    }

    func getTotalScreenTime(for childId: UUID) -> Int {
        // Get raw XP balance
        let rawXP = xpService.getBalance(userId: childId)?.currentXP ?? 0

        // Convert to screen time minutes using credibility multiplier
        let credibility = credibilityService.getCredibilityScore(childId: childId)
        let minutes = credibilityService.calculateXPToMinutes(xpAmount: rawXP, childId: childId)

        print("📊 Child \(childId) - Raw XP: \(rawXP), Credibility: \(credibility)%, Minutes: \(minutes)")
        return minutes
    }

    func getCompletedTasksCount(for childId: UUID) -> Int {
        let tasks = taskService.getChildTasks(childId: childId, status: .approved)
        return tasks.count
    }

    func getPendingTasksCount(for childId: UUID) -> Int {
        // Only count tasks that are pending review (submitted for parent approval)
        // NOT tasks that are just assigned or in progress
        let pendingReview = taskService.getChildTasks(childId: childId, status: .pendingReview)

        print("📊 Pending review tasks for child \(childId): \(pendingReview.count)")

        return pendingReview.count
    }

    func getCurrentTasks(for childId: UUID) -> [TaskAssignment] {
        // Get tasks that are actively being worked on (not completed or declined)
        let assigned = taskService.getChildTasks(childId: childId, status: .assigned)
        let inProgress = taskService.getChildTasks(childId: childId, status: .inProgress)
        let pendingReview = taskService.getChildTasks(childId: childId, status: .pendingReview)

        // Combine and sort by due date
        let allCurrentTasks = assigned + inProgress + pendingReview
        return allCurrentTasks.sorted { task1, task2 in
            guard let date1 = task1.dueDate, let date2 = task2.dueDate else {
                return task1.dueDate != nil // Tasks with due dates come first
            }
            return date1 < date2
        }
    }

    func getApprovedTasksCount(for childId: UUID, days: Int) -> Int {
        let tasks = taskService.getChildTasks(childId: childId, status: .approved)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return tasks.filter { $0.completedAt ?? Date.distantPast > cutoffDate }.count
    }

    func getDeclinedTasksCount(for childId: UUID, days: Int) -> Int {
        let tasks = taskService.getChildTasks(childId: childId, status: .declined)
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return tasks.filter { $0.completedAt ?? Date.distantPast > cutoffDate }.count
    }

    func getAverageCompletionTime(for childId: UUID) -> Int {
        let tasks = taskService.getChildTasks(childId: childId, status: .approved)
        let tasksWithTime = tasks.filter { ($0.completionTimeMinutes ?? 0) > 0 }

        guard !tasksWithTime.isEmpty else { return 0 }

        let total = tasksWithTime.reduce(0) { $0 + ($1.completionTimeMinutes ?? 0) }
        return total / tasksWithTime.count
    }

    // MARK: - Screen Time Data

    func getScreenTimeData(for childId: UUID, range: TimeRange) -> [ScreenTimeDataPoint] {
        let days = range == .week ? 7 : 30
        var dataPoints: [ScreenTimeDataPoint] = []

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Get all tasks approved on this day (when parent approved, not when child completed)
            let allApprovedTasks = taskService.getChildTasks(childId: childId, status: .approved)
            let tasksApprovedOnDay = allApprovedTasks.filter { task in
                guard let reviewedAt = task.reviewedAt else { return false }
                return calendar.isDate(reviewedAt, inSameDayAs: date)
            }

            // Calculate total minutes earned (using actual XP awarded with credibility multiplier)
            let minutesEarned = tasksApprovedOnDay.reduce(0) { total, task in
                total + (task.xpAwarded ?? task.assignedLevel.baseXP)
            }

            dataPoints.append(ScreenTimeDataPoint(date: date, minutes: minutesEarned))

            if minutesEarned > 0 {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                print("📊 \(formatter.string(from: date)): \(tasksApprovedOnDay.count) tasks approved, \(minutesEarned) minutes earned")
            }
        }

        return dataPoints.reversed()
    }

    // MARK: - Activity Log

    func getActivityLog(for childId: UUID) -> [ActivityLog] {
        var logs: [ActivityLog] = []

        // Get all tasks for this child
        let allTasks = taskService.getChildTasks(childId: childId, status: nil)

        // Create logs from tasks
        for task in allTasks {
            // Task started
            if let startedAt = task.startedAt {
                logs.append(ActivityLog(
                    title: "Started task: \(task.title)",
                    subtitle: task.assignedLevel.displayName,
                    timestamp: startedAt,
                    type: .taskStarted
                ))
            }

            // Task completed
            if let completedAt = task.completedAt {
                logs.append(ActivityLog(
                    title: "Completed task: \(task.title)",
                    subtitle: "Earned \(task.assignedLevel.baseXP) minutes",
                    timestamp: completedAt,
                    type: .taskCompleted
                ))
            }

            // Task approved
            if task.status == .approved, let approvedAt = task.reviewedAt {
                logs.append(ActivityLog(
                    title: "Task approved: \(task.title)",
                    subtitle: "+\(task.assignedLevel.baseXP) screen time",
                    timestamp: approvedAt,
                    type: .taskApproved
                ))
            }

            // Task declined
            if task.status == .declined, let declinedAt = task.reviewedAt {
                logs.append(ActivityLog(
                    title: "Task declined: \(task.title)",
                    subtitle: task.parentNotes,
                    timestamp: declinedAt,
                    type: .taskDeclined
                ))
            }
        }

        // Sort by most recent first
        return logs.sorted { $0.timestamp > $1.timestamp }
    }
}

// MARK: - Parent Task Options View

struct ParentTaskOptionsView: View {
    let task: TaskAssignment
    @Environment(\.dismiss) private var dismiss
    private let taskService = DependencyContainer.shared.taskService

    @State private var showingEditSheet = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    // Task Info
                    VStack(alignment: .leading, spacing: 8) {
                        Text(task.title)
                            .font(.headline)

                        HStack {
                            Text(task.assignedLevel.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            if let dueDate = task.dueDate {
                                Text("•")
                                    .foregroundColor(.secondary)
                                Text("Due \(formatDate(dueDate))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    Button(action: {
                        showingEditSheet = true
                    }) {
                        Label("Edit Task", systemImage: "pencil")
                    }

                    Button(role: .destructive, action: {
                        showingDeleteConfirmation = true
                    }) {
                        Label("Delete Task", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Task Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingEditSheet) {
                ParentTaskEditView(task: task) {
                    dismiss()
                }
            }
            .alert("Delete Task", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    deleteTask()
                }
            } message: {
                Text("Are you sure you want to delete '\(task.title)'? This action cannot be undone.")
            }
        }
    }

    private func deleteTask() {
        let success = taskService.deleteTask(assignmentId: task.id)
        if success {
            HapticFeedbackManager.shared.success()
            dismiss()
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Parent Task Edit View

struct ParentTaskEditView: View {
    let task: TaskAssignment
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    private let taskService = DependencyContainer.shared.taskService

    @State private var editedTitle: String
    @State private var editedLevel: TaskLevel
    @State private var editedDueDate: Date?
    @State private var hasDueDate: Bool

    init(task: TaskAssignment, onComplete: @escaping () -> Void) {
        self.task = task
        self.onComplete = onComplete
        _editedTitle = State(initialValue: task.title)
        _editedLevel = State(initialValue: task.assignedLevel)
        _editedDueDate = State(initialValue: task.dueDate)
        _hasDueDate = State(initialValue: task.dueDate != nil)
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task Title", text: $editedTitle)

                    Picker("Difficulty", selection: $editedLevel) {
                        ForEach([TaskLevel.level1, .level2, .level3, .level4, .level5], id: \.self) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                }

                Section("Due Date") {
                    Toggle("Set Due Date", isOn: $hasDueDate)

                    if hasDueDate {
                        DatePicker("Due Date", selection: Binding(
                            get: { editedDueDate ?? Date() },
                            set: { editedDueDate = $0 }
                        ), displayedComponents: [.date])
                    }
                }
            }
            .navigationTitle("Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveChanges()
                    }
                    .disabled(editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func saveChanges() {
        let finalDueDate = hasDueDate ? editedDueDate : nil
        let success = taskService.updateTask(
            assignmentId: task.id,
            title: editedTitle,
            level: editedLevel,
            dueDate: finalDueDate
        )

        if success {
            HapticFeedbackManager.shared.success()
            dismiss()
            onComplete()
        }
    }
}
