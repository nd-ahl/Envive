import SwiftUI
import Combine

// MARK: - Parent Dashboard View

struct ParentDashboardView: View {
    @StateObject private var viewModel: ParentDashboardViewModel

    init(viewModel: ParentDashboardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Pending Approvals Section
                    if !viewModel.pendingApprovals.isEmpty {
                        pendingApprovalsSection
                    } else {
                        emptyStateView
                    }

                    // Quick Actions
                    quickActionsSection

                    // Children Overview
                    childrenOverviewSection
                }
                .padding()
            }
            .navigationTitle("Parent Dashboard")
            .onAppear {
                viewModel.loadData()
            }
            .refreshable {
                viewModel.loadData()
            }
        }
    }

    // MARK: - Pending Approvals

    private var pendingApprovalsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Needs Your Attention", systemImage: "exclamationmark.circle.fill")
                    .font(.headline)
                    .foregroundColor(.orange)
                Spacer()
                Text("\(viewModel.pendingApprovals.count)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .cornerRadius(12)
            }

            ForEach(viewModel.pendingApprovals) { assignment in
                NavigationLink(destination: TaskReviewView(
                    assignment: assignment,
                    viewModel: TaskReviewViewModel(
                        assignment: assignment,
                        taskService: viewModel.taskService,
                        credibilityService: viewModel.credibilityService,
                        parentId: viewModel.parentId
                    )
                )) {
                    PendingTaskCard(assignment: assignment, childName: viewModel.getChildName(assignment.childId))
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.green)

            Text("All Caught Up!")
                .font(.title2)
                .fontWeight(.bold)

            Text("No tasks pending approval")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Quick Actions

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            HStack(spacing: 12) {
                NavigationLink(destination: Text("Assign Task View")) {
                    QuickActionButton(
                        title: "Assign Task",
                        icon: "plus.circle.fill",
                        color: .blue,
                        action: {}
                    )
                }

                NavigationLink(destination: Text("Emergency Grant View")) {
                    QuickActionButton(
                        title: "Emergency Grant",
                        icon: "bolt.circle.fill",
                        color: .orange,
                        action: {}
                    )
                }
            }
        }
    }

    // MARK: - Children Overview

    private var childrenOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Children Overview")
                .font(.headline)

            ForEach(viewModel.children, id: \.id) { child in
                ChildOverviewCard(
                    childName: child.name,
                    credibility: child.credibility,
                    xpBalance: child.xpBalance,
                    pendingCount: child.pendingCount
                )
            }
        }
    }
}

// MARK: - Pending Task Card

struct PendingTaskCard: View {
    let assignment: TaskAssignment
    let childName: String

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(assignment.category.icon)
                .font(.title2)

            // Task Info
            VStack(alignment: .leading, spacing: 4) {
                Text("\(childName): \(assignment.title)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)

                HStack {
                    Text(assignment.assignedLevel.shortName)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.2))
                        .foregroundColor(.orange)
                        .cornerRadius(4)

                    if let time = assignment.timeSinceCompletion {
                        Text(time)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Arrow
            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.yellow.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Child Overview Card

struct ChildOverviewCard: View {
    let childName: String
    let credibility: Int
    let xpBalance: Int
    let pendingCount: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(childName)
                    .font(.headline)
                Spacer()
                if pendingCount > 0 {
                    Text("\(pendingCount)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red)
                        .cornerRadius(8)
                }
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading) {
                    Text("Credibility")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(credibility)%")
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(credibilityColor(for: credibility))
                }

                VStack(alignment: .leading) {
                    Text("XP Balance")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(xpBalance) XP")
                        .font(.body)
                        .fontWeight(.semibold)
                }

                Spacer()

                Button(action: {
                    // Navigate to child detail
                }) {
                    Text("View Details")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(6)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
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

// MARK: - Parent Dashboard View Model

struct ChildSummary {
    let id: UUID
    let name: String
    let credibility: Int
    let xpBalance: Int
    let pendingCount: Int
}

@MainActor
class ParentDashboardViewModel: ObservableObject {
    @Published var pendingApprovals: [TaskAssignment] = []
    @Published var children: [ChildSummary] = []

    let taskService: TaskService
    let credibilityService: CredibilityService
    let parentId: UUID

    init(taskService: TaskService, credibilityService: CredibilityService, parentId: UUID) {
        self.taskService = taskService
        self.credibilityService = credibilityService
        self.parentId = parentId
    }

    func loadData() {
        // Load pending approvals
        pendingApprovals = taskService.getPendingApprovals()

        // TODO: Load actual children data
        // For now, mock data
        children = [
            ChildSummary(
                id: UUID(),
                name: "Sarah",
                credibility: 95,
                xpBalance: 45,
                pendingCount: pendingApprovals.filter { $0.childId == UUID() }.count
            )
        ]
    }

    func getChildName(_ childId: UUID) -> String {
        // TODO: Look up actual child name
        return children.first(where: { $0.id == childId })?.name ?? "Child"
    }
}
