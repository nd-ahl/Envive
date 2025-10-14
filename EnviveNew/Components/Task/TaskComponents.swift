import SwiftUI

// MARK: - Task Card Component

/// Reusable task card for displaying task information
struct TaskCard<Content: View>: View {
    let title: String
    let subtitle: String?
    let icon: String?
    let xpReward: Int?
    let content: Content?

    init(
        title: String,
        subtitle: String? = nil,
        icon: String? = nil,
        xpReward: Int? = nil,
        @ViewBuilder content: () -> Content? = { nil }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.xpReward = xpReward
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.blue)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.semibold)

                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                if let xp = xpReward {
                    XPBadge(amount: xp)
                }
            }

            if let content = content {
                content
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Task Status Badge

/// Badge displaying task verification status
struct TaskStatusBadge: View {
    let status: TaskStatus
    let showIcon: Bool

    init(status: TaskStatus, showIcon: Bool = true) {
        self.status = status
        self.showIcon = showIcon
    }

    var body: some View {
        HStack(spacing: 6) {
            if showIcon {
                Image(systemName: status.icon)
                    .font(.caption)
            }

            Text(status.displayName)
                .font(.caption)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.2))
        .foregroundColor(status.color)
        .cornerRadius(12)
    }
}

// MARK: - Category Icon Helper

/// Returns appropriate icon for task category
enum TaskCategoryIcons {
    static func icon(for category: String) -> String {
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

// MARK: - Task Filter Tabs

/// Horizontal scrollable tabs for filtering tasks
struct TaskFilterTabs: View {
    @Binding var selectedFilter: TaskStatus
    let taskCounts: [TaskStatus: Int]
    let onFilterChange: (TaskStatus) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(TaskStatus.allCases, id: \.self) { status in
                    let count = taskCounts[status] ?? 0

                    Button(action: {
                        selectedFilter = status
                        onFilterChange(status)
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
}

// MARK: - Task Actions

/// Action buttons for task verification
struct TaskActions: View {
    let onApprove: () -> Void
    let onReject: () -> Void
    let isDisabled: Bool

    init(onApprove: @escaping () -> Void, onReject: @escaping () -> Void, isDisabled: Bool = false) {
        self.onApprove = onApprove
        self.onReject = onReject
        self.isDisabled = isDisabled
    }

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onApprove) {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Approve")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isDisabled ? Color.gray : Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isDisabled)

            Button(action: onReject) {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                    Text("Reject")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isDisabled ? Color.gray : Color.red)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(isDisabled)
        }
    }
}

// MARK: - Task Photo Indicator

/// Shows photo attachment indicator
struct TaskPhotoIndicator: View {
    let hasPhoto: Bool
    let onViewPhoto: () -> Void

    var body: some View {
        if hasPhoto {
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(.blue)
                Text("Photo attached")
                    .font(.caption)
                    .foregroundColor(.blue)
                Spacer()
                Button("View") {
                    onViewPhoto()
                }
                .font(.caption)
            }
        }
    }
}

// MARK: - Task Notes Section

/// Displays notes with label
struct TaskNotesSection: View {
    let label: String
    let notes: String
    let backgroundColor: Color
    let labelColor: Color

    init(label: String, notes: String, backgroundColor: Color = Color(.systemGray6), labelColor: Color = .primary) {
        self.label = label
        self.notes = notes
        self.backgroundColor = backgroundColor
        self.labelColor = labelColor
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(labelColor)
            Text(notes)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(8)
                .background(backgroundColor)
                .cornerRadius(6)
        }
    }
}

// MARK: - Task Impact Banner

/// Shows impact of rejecting a task
struct TaskImpactBanner: View {
    let showStreak: Bool
    let showCredibility: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Impact:")
                .font(.headline)

            if showCredibility {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundColor(.red)
                    Text("-10 to -15 credibility points")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            if showStreak {
                HStack(spacing: 8) {
                    Image(systemName: "flame")
                        .foregroundColor(.orange)
                    Text("Resets task streak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Text("Child can appeal within 24 hours")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 4)
        }
        .padding()
        .background(Color.red.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Task Status Enum

/// Task verification status
enum TaskStatus: String, CaseIterable {
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

// MARK: - Previews

struct TaskComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                TaskCard(
                    title: "Morning Run",
                    subtitle: "3 miles • 30 min ago",
                    icon: "figure.run",
                    xpReward: 150
                ) {
                    Text("Additional content here")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack {
                    TaskStatusBadge(status: .pending)
                    TaskStatusBadge(status: .approved)
                    TaskStatusBadge(status: .rejected)
                    TaskStatusBadge(status: .appealed)
                }

                TaskFilterTabs(
                    selectedFilter: .constant(.pending),
                    taskCounts: [.pending: 5, .approved: 12, .rejected: 2],
                    onFilterChange: { _ in }
                )

                TaskActions(
                    onApprove: {},
                    onReject: {}
                )

                TaskPhotoIndicator(hasPhoto: true, onViewPhoto: {})

                TaskNotesSection(
                    label: "Review Notes:",
                    notes: "Great work! Keep it up."
                )

                TaskImpactBanner(showStreak: true, showCredibility: true)
            }
            .padding()
        }
    }
}
