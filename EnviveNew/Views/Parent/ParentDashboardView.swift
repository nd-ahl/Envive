import SwiftUI
import Combine

// MARK: - Parent Dashboard View

struct ParentDashboardView: View {
    @StateObject private var viewModel: ParentDashboardViewModel
    @ObservedObject var appSelectionStore: AppSelectionStore
    @ObservedObject var notificationManager: NotificationManager

    @State private var showingChildSelector = false
    @State private var showingAssignTask = false
    @State private var selectedChildrenForAssignment: [ChildSummary] = []
    @State private var showingResetConfirmation = false
    @Environment(\.scenePhase) private var scenePhase

    init(viewModel: ParentDashboardViewModel, appSelectionStore: AppSelectionStore, notificationManager: NotificationManager) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.appSelectionStore = appSelectionStore
        self.notificationManager = notificationManager
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingResetConfirmation = true
                    }) {
                        Image(systemName: "trash.circle.fill")
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Reset All Test Data", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    viewModel.resetAllChildData()
                }
            } message: {
                Text("This will delete all tasks, reset all children's XP to 0, and set credibility to 100. This action cannot be undone.")
            }
            .onAppear {
                viewModel.loadData()
            }
            .refreshable {
                viewModel.loadData()
            }
            .sheet(isPresented: $showingChildSelector) {
                ChildSelectorView(children: viewModel.children) { selectedChildren in
                    selectedChildrenForAssignment = selectedChildren
                    // Don't set showingAssignTask here - let onChange handle it
                }
            }
            .onChange(of: showingChildSelector) { oldValue, newValue in
                // When child selector dismisses with selected children, show assign task
                if oldValue == true && newValue == false && !selectedChildrenForAssignment.isEmpty {
                    // Delay to ensure first sheet is fully dismissed
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        showingAssignTask = true
                    }
                }
            }
            .sheet(isPresented: $showingAssignTask, onDismiss: {
                // Clear selection after AssignTask sheet dismisses
                selectedChildrenForAssignment = []
                // Refresh data to show newly assigned tasks
                print("📋 AssignTask sheet dismissed - reloading parent dashboard")
                viewModel.loadData()
            }) {
                if !selectedChildrenForAssignment.isEmpty {
                    AssignTaskView(
                        taskService: viewModel.taskService,
                        parentId: viewModel.parentId,
                        selectedChildren: selectedChildrenForAssignment,
                        notificationManager: notificationManager
                    )
                }
            }
            .onChange(of: scenePhase) { oldPhase, newPhase in
                // Reload data when app becomes active
                if newPhase == .active {
                    print("🔔 App became active - reloading parent dashboard data")
                    viewModel.loadData()
                }
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
                // Assign Task Button
                Button(action: {
                    SoundEffectsManager.shared.play(.buttonTap, withHaptic: .light)
                    showingChildSelector = true
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Assign Task")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }

                // Task History Navigation
                NavigationLink(destination: TaskHistoryView(
                    taskService: viewModel.taskService,
                    childId: nil,
                    childName: nil
                )) {
                    HStack {
                        Image(systemName: "clock.fill")
                            .font(.title3)
                        Text("Task History")
                            .fontWeight(.medium)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .foregroundColor(.purple)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Children Overview

    private var childrenOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Children Overview")
                .font(.headline)

            if viewModel.isLoadingChildren {
                // Loading state
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        ProgressView()
                        Text("Loading children...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                    Spacer()
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
            } else if viewModel.children.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary)

                    Text("No Children Yet")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Add children to your household to start assigning tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            } else {
                // Children list
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
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
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

struct ChildSummary: Identifiable, Equatable {
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
    @Published var isLoadingChildren = false

    let taskService: TaskService
    let credibilityService: CredibilityService
    let xpService: XPService
    let parentId: UUID
    private let householdContext = HouseholdContext.shared
    private let householdService = HouseholdService.shared

    init(taskService: TaskService, credibilityService: CredibilityService, xpService: XPService, parentId: UUID) {
        self.taskService = taskService
        self.credibilityService = credibilityService
        self.xpService = xpService
        self.parentId = parentId
    }

    func loadData() {
        // Load pending approvals (already filtered by TaskService using household context)
        pendingApprovals = taskService.getPendingApprovals()

        // Load children from Supabase asynchronously
        Task {
            await loadChildrenFromSupabase()
        }
    }

    private func loadChildrenFromSupabase() async {
        await MainActor.run {
            isLoadingChildren = true
        }

        do {
            // Fetch children from Supabase for current household
            let childProfiles = try await householdService.getMyChildren()

            print("📋 Parent dashboard loaded \(childProfiles.count) children from Supabase")

            // Create child summaries
            let childSummaries = childProfiles.map { profile in
                let childId = UUID(uuidString: profile.id) ?? UUID()
                return ChildSummary(
                    id: childId,
                    name: profile.fullName ?? "Child",
                    credibility: credibilityService.getCredibilityScore(childId: childId),
                    xpBalance: xpService.getBalance(userId: childId)?.currentXP ?? 0,
                    pendingCount: pendingApprovals.filter { $0.childId == childId }.count
                )
            }

            await MainActor.run {
                self.children = childSummaries
                self.isLoadingChildren = false
            }

            print("📋 Parent dashboard loaded.")
            print("📋 Children: \(children.map { $0.name }.joined(separator: ", "))")
            print("📋 Pending approvals: \(pendingApprovals.count)")

        } catch {
            print("❌ Error loading children from Supabase: \(error.localizedDescription)")
            await MainActor.run {
                self.children = []
                self.isLoadingChildren = false
            }
        }
    }

    func getChildName(_ childId: UUID) -> String {
        return children.first(where: { $0.id == childId })?.name ?? "Child"
    }

    // MARK: - Test Utilities

    func resetAllChildData() {
        print("🗑️ Resetting all child data...")

        // Get all children IDs
        let childIds = children.map { $0.id }

        // Reset data for each child
        for childId in childIds {
            // Reset XP balance
            xpService.resetBalance(userId: childId)
            xpService.deleteAllTransactions(userId: childId)

            // Reset credibility
            credibilityService.resetCredibility(childId: childId)
        }

        // Delete all task assignments
        taskService.deleteAllAssignments()

        // Also clear ScreenTimeRewardManager storage for all children
        for childId in childIds {
            UserDefaults.standard.removeObject(forKey: "earnedScreenTimeMinutes_\(childId.uuidString)")
            UserDefaults.standard.removeObject(forKey: "currentStreak_\(childId.uuidString)")
            UserDefaults.standard.removeObject(forKey: "lastTaskCompletionDate_\(childId.uuidString)")
        }

        print("✅ Reset complete - all tasks deleted, XP set to 0, credibility set to 100")

        // Reload data to reflect changes
        loadData()
    }
}
