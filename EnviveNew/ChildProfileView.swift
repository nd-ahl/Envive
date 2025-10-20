import SwiftUI
import Charts

// MARK: - Child Profile View

struct ChildProfileView: View {
    @StateObject private var credibilityManager = CredibilityManager()
    @StateObject private var rewardManager = ScreenTimeRewardManager()
    @StateObject private var themeViewModel = DependencyContainer.shared
        .viewModelFactory.makeThemeSettingsViewModel()
    @State private var showingHistory = false
    @State private var showingXPRedemption = false
    @State private var selectedHistoryFilter: HistoryFilter = .all

    // Mock data
    let userName = "Alex"
    let userAvatar = "person.circle.fill"
    let totalXP = 2450
    let tasksCompleted = 48
    let parentName = "Mom"

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader

                    // Theme Settings
                    ThemePickerView(viewModel: themeViewModel)

                    // Credibility Score Card
                    credibilityScoreCard

                    // Conversion Rate Preview
                    conversionRateCard

                    // Streak & Stats
                    streakStatsCard

                    // Recent Activity
                    recentActivityCard
                }
                .padding()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingHistory) {
                CredibilityHistoryView(credibilityManager: credibilityManager)
            }
            .sheet(isPresented: $showingXPRedemption) {
                XPRedemptionSheet(
                    rewardManager: rewardManager,
                    isPresented: $showingXPRedemption,
                    availableXP: totalXP
                )
            }
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        HStack(spacing: 16) {
            Image(systemName: userAvatar)
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .frame(width: 80, height: 80)
                .background(Color.blue.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(userName)
                    .font(.title2)
                    .fontWeight(.bold)

                HStack(spacing: 4) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                    Text("Managed by \(parentName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                        Text("\(totalXP) XP")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }

                    Text("•")
                        .foregroundColor(.secondary)

                    Text("\(tasksCompleted) tasks")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    // MARK: - Credibility Score Card

    private var credibilityScoreCard: some View {
        let status = credibilityManager.getCredibilityStatus()

        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Credibility Score")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(status.score)")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(colorForTier(status.tier.color))

                        Text("/ 100")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: tierIcon(for: status.tier.name))
                        .font(.system(size: 50))
                        .foregroundColor(colorForTier(status.tier.color))

                    Text(status.tier.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(colorForTier(status.tier.color))
                }
            }

            // Tier Description
            Text(status.tier.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Divider()

            // Recovery Path
            if let recoveryPath = status.recoveryPath {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Path to Next Tier")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)

                        Text(recoveryPath)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }

            // View History Button
            Button(action: {
                showingHistory = true
            }) {
                HStack {
                    Image(systemName: "clock.arrow.circlepath")
                    Text("View History")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .foregroundColor(.blue)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(colorForTier(status.tier.color).opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorForTier(status.tier.color).opacity(0.5), lineWidth: 2)
        )
    }

    // MARK: - Conversion Rate Card

    private var conversionRateCard: some View {
        let status = credibilityManager.getCredibilityStatus()

        return VStack(spacing: 16) {
            HStack {
                Text("XP Conversion Rate")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(String(format: "%.1f", status.conversionRate))
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(colorForTier(status.tier.color))

                        Text("x")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }

                    Text("\(status.tier.name) Tier")
                        .font(.caption)
                        .foregroundColor(colorForTier(status.tier.color))
                }

                Spacer()

                VStack(spacing: 8) {
                    if status.hasRedemptionBonus {
                        VStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.title)
                                .foregroundColor(.yellow)

                            Text("BONUS!")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.yellow)

                            if let expiry = status.redemptionBonusExpiry {
                                Text("Expires: \(expiry, style: .relative)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .background(Color.yellow.opacity(0.2))
                        .cornerRadius(12)
                    } else {
                        VStack(spacing: 4) {
                            Text("Earn bonus at")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("95+ score")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }

            // Conversion Examples
            VStack(spacing: 8) {
                Text("Examples:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach([100, 500, 1000], id: \.self) { xp in
                    let minutes = credibilityManager.calculateXPToMinutes(xpAmount: xp)
                    HStack {
                        Text("\(xp) XP")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(minutes) minutes")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }

            Button(action: {
                showingXPRedemption = true
            }) {
                HStack {
                    Image(systemName: "gift.fill")
                    Text("Redeem XP for Screen Time")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(totalXP == 0)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Streak & Stats Card

    private var streakStatsCard: some View {
        let status = credibilityManager.getCredibilityStatus()
        let nextBonus = status.consecutiveApprovedTasks > 0 ? 10 - (status.consecutiveApprovedTasks % 10) : 10
        let progressValue = Double(status.consecutiveApprovedTasks % 10)

        return VStack(spacing: 16) {
            HStack {
                Text("Your Streak")
                    .font(.headline)
                Spacer()
            }

            // Streak Counter
            HStack(spacing: 16) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(status.consecutiveApprovedTasks)")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.orange)

                    Text("Approved Tasks in a Row")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)

            // Progress to Next Bonus
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("\(nextBonus) more tasks for +5 bonus")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(status.consecutiveApprovedTasks % 10)/10")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: progressValue, total: 10.0)
                    .tint(.orange)
                    .scaleEffect(y: 1.5)

                Text("Every 10 approved tasks gives you a +5 credibility bonus!")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }

            Divider()

            // Mini Stats
            HStack(spacing: 16) {
                miniStat(title: "Best Streak", value: "23", icon: "trophy.fill", color: .yellow)
                miniStat(title: "This Week", value: "12", icon: "checkmark.circle.fill", color: .green)
                miniStat(title: "Pending", value: "2", icon: "clock.fill", color: .orange)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private func miniStat(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    // MARK: - Recent Activity Card

    private var recentActivityCard: some View {
        let recentHistory = credibilityManager.getRecentHistory(days: 7)

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
                Button("View All") {
                    showingHistory = true
                }
                .font(.caption)
            }

            if recentHistory.isEmpty {
                Text("No recent activity")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(recentHistory.prefix(3)) { event in
                    HistoryEventRow(event: event, compact: true)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helper Methods

    private func colorForTier(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        default: return .gray
        }
    }

    private func tierIcon(for tierName: String) -> String {
        switch tierName {
        case "Excellent": return "star.fill"
        case "Good": return "checkmark.circle.fill"
        case "Fair": return "circle.fill"
        case "Poor": return "exclamationmark.triangle.fill"
        case "Very Poor": return "xmark.circle.fill"
        default: return "circle.fill"
        }
    }
}

// MARK: - Credibility History View

enum HistoryFilter: String, CaseIterable {
    case all = "All"
    case downvotes = "Downvotes"
    case approvals = "Approvals"
    case bonuses = "Bonuses"

    var icon: String {
        switch self {
        case .all: return "list.bullet"
        case .downvotes: return "arrow.down.circle"
        case .approvals: return "checkmark.circle"
        case .bonuses: return "star"
        }
    }
}

struct CredibilityHistoryView: View {
    @ObservedObject var credibilityManager: CredibilityManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedFilter: HistoryFilter = .all
    @State private var selectedPeriod: HistoryPeriod = .thirtyDays

    var filteredHistory: [CredibilityHistoryEvent] {
        let history = credibilityManager.getRecentHistory(days: selectedPeriod.days)

        switch selectedFilter {
        case .all:
            return history
        case .downvotes:
            return history.filter { $0.event == .downvote }
        case .approvals:
            return history.filter { $0.event == .approvedTask }
        case .bonuses:
            return history.filter { $0.event == .streakBonus || $0.event == .redemptionBonusActivated }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Summary Card
                summaryCard

                // Filters
                VStack(spacing: 12) {
                    // Period Selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(HistoryPeriod.allCases, id: \.self) { period in
                            Text(period.displayName).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Event Type Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(HistoryFilter.allCases, id: \.self) { filter in
                                filterButton(filter)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGray6))

                // Timeline
                if filteredHistory.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(filteredHistory) { event in
                                HistoryEventRow(event: event)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Credibility History")
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

    private var summaryCard: some View {
        let status = credibilityManager.getCredibilityStatus()

        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current Score")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(status.score)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(colorForTier(status.tier.color))
            }

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Events (\(selectedPeriod.days)d)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(filteredHistory.count)")
                    .font(.title)
                    .fontWeight(.bold)
            }

            Spacer()

            Image(systemName: tierIcon(status.tier.name))
                .font(.system(size: 40))
                .foregroundColor(colorForTier(status.tier.color))
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private func filterButton(_ filter: HistoryFilter) -> some View {
        let isSelected = selectedFilter == filter
        let count = filteredHistory.count

        return Button(action: {
            selectedFilter = filter
        }) {
            HStack(spacing: 6) {
                Image(systemName: filter.icon)
                    .font(.caption)

                Text(filter.rawValue)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemBackground))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("No History")
                .font(.title2)
                .fontWeight(.semibold)

            Text("No events found for the selected filter and period.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func colorForTier(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        default: return .gray
        }
    }

    private func tierIcon(_ tierName: String) -> String {
        switch tierName {
        case "Excellent": return "star.fill"
        case "Good": return "checkmark.circle.fill"
        case "Fair": return "circle.fill"
        case "Poor": return "exclamationmark.triangle.fill"
        case "Very Poor": return "xmark.circle.fill"
        default: return "circle.fill"
        }
    }
}

enum HistoryPeriod: CaseIterable {
    case sevenDays, thirtyDays, sixtyDays, ninetyDays

    var displayName: String {
        switch self {
        case .sevenDays: return "7 Days"
        case .thirtyDays: return "30 Days"
        case .sixtyDays: return "60 Days"
        case .ninetyDays: return "90 Days"
        }
    }

    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .sixtyDays: return 60
        case .ninetyDays: return 90
        }
    }
}

// MARK: - History Event Row

struct HistoryEventRow: View {
    let event: CredibilityHistoryEvent
    var compact: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline dot
            VStack(spacing: 0) {
                Circle()
                    .fill(colorForEvent(event.event))
                    .frame(width: 12, height: 12)

                if !compact {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 2)
                }
            }
            .frame(width: 12)

            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: iconForEvent(event.event))
                        .foregroundColor(colorForEvent(event.event))

                    Text(titleForEvent(event))
                        .font(compact ? .subheadline : .headline)
                        .fontWeight(.semibold)

                    Spacer()

                    Text(event.amount > 0 ? "+\(event.amount)" : "\(event.amount)")
                        .font(compact ? .subheadline : .headline)
                        .fontWeight(.bold)
                        .foregroundColor(event.amount > 0 ? .green : .red)
                }

                if !compact {
                    if let notes = event.notes {
                        Text(notes)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                    }

                    if let streakCount = event.streakCount {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text("\(streakCount) task streak!")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }

                HStack {
                    Text(event.timestamp, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Score: \(event.newScore)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, compact ? 8 : 12)
        .padding(.horizontal, compact ? 0 : 16)
    }

    private func titleForEvent(_ event: CredibilityHistoryEvent) -> String {
        switch event.event {
        case .downvote:
            return "Task Rejected"
        case .downvoteUndone:
            return "Downvote Removed"
        case .approvedTask:
            return "Task Approved"
        case .streakBonus:
            return "Streak Bonus!"
        case .timeDecayRecovery:
            return "Time Decay Recovery"
        case .redemptionBonusActivated:
            return "Redemption Bonus Unlocked!"
        case .redemptionBonusExpired:
            return "Redemption Bonus Expired"
        }
    }

    private func iconForEvent(_ event: CredibilityEventType) -> String {
        switch event {
        case .downvote:
            return "xmark.circle.fill"
        case .downvoteUndone:
            return "arrow.uturn.backward.circle.fill"
        case .approvedTask:
            return "checkmark.circle.fill"
        case .streakBonus:
            return "flame.fill"
        case .timeDecayRecovery:
            return "clock.arrow.circlepath"
        case .redemptionBonusActivated:
            return "star.circle.fill"
        case .redemptionBonusExpired:
            return "star.slash"
        }
    }

    private func colorForEvent(_ event: CredibilityEventType) -> Color {
        switch event {
        case .downvote:
            return .red
        case .downvoteUndone:
            return .blue
        case .approvedTask:
            return .green
        case .streakBonus:
            return .orange
        case .timeDecayRecovery:
            return .blue
        case .redemptionBonusActivated:
            return .yellow
        case .redemptionBonusExpired:
            return .gray
        }
    }
}

// MARK: - Previews

struct ChildProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ChildProfileView()
    }
}