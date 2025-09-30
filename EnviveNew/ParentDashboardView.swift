import SwiftUI
import Charts
import Combine

// MARK: - Child Profile Model

struct ChildProfile: Identifiable {
    let id: UUID
    let name: String
    let avatarIcon: String
    var credibilityScore: Int
    var consecutiveApprovedTasks: Int
    var totalTasksCompleted: Int
    var pendingVerifications: Int

    init(
        id: UUID = UUID(),
        name: String,
        avatarIcon: String = "person.circle.fill",
        credibilityScore: Int = 100,
        consecutiveApprovedTasks: Int = 0,
        totalTasksCompleted: Int = 0,
        pendingVerifications: Int = 0
    ) {
        self.id = id
        self.name = name
        self.avatarIcon = avatarIcon
        self.credibilityScore = credibilityScore
        self.consecutiveApprovedTasks = consecutiveApprovedTasks
        self.totalTasksCompleted = totalTasksCompleted
        self.pendingVerifications = pendingVerifications
    }
}

// MARK: - Credibility Data Point

struct CredibilityDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Int
    let event: String?

    init(date: Date, score: Int, event: String? = nil) {
        self.date = date
        self.score = score
        self.event = event
    }
}

// MARK: - Parent Dashboard Manager

class ParentDashboardManager: ObservableObject {
    @Published var children: [ChildProfile] = []
    @Published var selectedChild: ChildProfile?
    @Published var credibilityHistory: [CredibilityDataPoint] = []

    private let credibilityManager = CredibilityManager()

    init() {
        loadMockData()
        loadCredibilityHistory()
    }

    func selectChild(_ child: ChildProfile) {
        selectedChild = child
        loadCredibilityHistory()
    }

    func getCredibilityTier(score: Int) -> CredibilityTier {
        // Use the CredibilityManager tiers
        let tiers: [CredibilityTier] = [
            CredibilityTier(name: "Excellent", range: 90...100, multiplier: 1.2, color: "green", description: "Outstanding"),
            CredibilityTier(name: "Good", range: 75...89, multiplier: 1.0, color: "green", description: "Good standing"),
            CredibilityTier(name: "Fair", range: 60...74, multiplier: 0.8, color: "yellow", description: "Fair standing"),
            CredibilityTier(name: "Poor", range: 40...59, multiplier: 0.5, color: "red", description: "Poor standing"),
            CredibilityTier(name: "Very Poor", range: 0...39, multiplier: 0.3, color: "red", description: "Very poor standing")
        ]
        return tiers.first { $0.range.contains(score) } ?? tiers.last!
    }

    private func loadMockData() {
        children = [
            ChildProfile(
                name: "Alex",
                credibilityScore: 92,
                consecutiveApprovedTasks: 15,
                totalTasksCompleted: 48,
                pendingVerifications: 2
            ),
            ChildProfile(
                name: "Jordan",
                credibilityScore: 68,
                consecutiveApprovedTasks: 3,
                totalTasksCompleted: 27,
                pendingVerifications: 1
            ),
            ChildProfile(
                name: "Sam",
                credibilityScore: 45,
                consecutiveApprovedTasks: 0,
                totalTasksCompleted: 12,
                pendingVerifications: 3
            )
        ]
        selectedChild = children.first
    }

    private func loadCredibilityHistory() {
        // Generate mock 30-day history
        var history: [CredibilityDataPoint] = []
        let calendar = Calendar.current
        let today = Date()

        guard let child = selectedChild else { return }

        var currentScore = child.credibilityScore
        for day in (0..<30).reversed() {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                // Add some variance
                let variance = Int.random(in: -5...5)
                currentScore = max(0, min(100, currentScore + variance))

                // Add notable events occasionally
                let event: String? = day % 7 == 0 ? (variance > 0 ? "Task approved" : "Task rejected") : nil

                history.append(CredibilityDataPoint(date: date, score: currentScore, event: event))
            }
        }

        credibilityHistory = history
    }

    func getHistoryForPeriod(_ days: Int) -> [CredibilityDataPoint] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return credibilityHistory.filter { $0.date >= cutoffDate }
    }
}

// MARK: - Parent Dashboard View

struct ParentDashboardView: View {
    @StateObject private var dashboardManager = ParentDashboardManager()
    @State private var selectedPeriod: ChartPeriod = .thirtyDays
    @State private var showingTaskVerification = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Children Selector
                    childrenCarousel

                    // Selected Child Details
                    if let child = dashboardManager.selectedChild {
                        VStack(spacing: 20) {
                            // Credibility Overview Card
                            credibilityOverviewCard(for: child)

                            // Pending Verifications Alert
                            if child.pendingVerifications > 0 {
                                pendingVerificationsCard(for: child)
                            }

                            // Credibility Trend Chart
                            credibilityTrendCard

                            // Stats Grid
                            statsGrid(for: child)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Parent Dashboard")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingTaskVerification) {
                TaskVerificationView()
            }
        }
    }

    // MARK: - Children Carousel

    private var childrenCarousel: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(dashboardManager.children) { child in
                    ChildSelectorCard(
                        child: child,
                        isSelected: dashboardManager.selectedChild?.id == child.id,
                        onTap: {
                            dashboardManager.selectChild(child)
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Credibility Overview Card

    private func credibilityOverviewCard(for child: ChildProfile) -> some View {
        let tier = dashboardManager.getCredibilityTier(score: child.credibilityScore)

        return VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Credibility Score")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(child.credibilityScore)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(colorForTier(tier.color))

                        Text("/ 100")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                VStack(spacing: 8) {
                    Image(systemName: tierIcon(for: tier.name))
                        .font(.system(size: 40))
                        .foregroundColor(colorForTier(tier.color))

                    Text(tier.name)
                        .font(.headline)
                        .foregroundColor(colorForTier(tier.color))
                }
            }

            // Conversion Rate
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("XP Conversion Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(String(format: "%.1fx", tier.multiplier))")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(colorForTier(tier.color))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Current Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .foregroundColor(.orange)
                        Text("\(child.consecutiveApprovedTasks)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Progress to next bonus
            if child.consecutiveApprovedTasks > 0 {
                let nextBonus = 10 - (child.consecutiveApprovedTasks % 10)
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(nextBonus) tasks until +5 bonus")
                            .font(.caption)
                            .foregroundColor(.orange)
                        Spacer()
                        Text("\(child.consecutiveApprovedTasks % 10)/10")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    ProgressView(value: Double(child.consecutiveApprovedTasks % 10), total: 10.0)
                        .tint(.orange)
                }
            }
        }
        .padding()
        .background(colorForTier(tier.color).opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(colorForTier(tier.color).opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Pending Verifications Card

    private func pendingVerificationsCard(for child: ChildProfile) -> some View {
        Button(action: {
            showingTaskVerification = true
        }) {
            HStack {
                Image(systemName: "clock.badge.exclamationmark.fill")
                    .font(.title2)
                    .foregroundColor(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(child.pendingVerifications) Tasks Awaiting Review")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text("Tap to review and approve/reject")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Credibility Trend Card

    private var credibilityTrendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Credibility Trend")
                    .font(.headline)

                Spacer()

                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ChartPeriod.allCases, id: \.self) { period in
                        Text(period.displayName).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            if #available(iOS 16.0, *) {
                CredibilityChart(
                    data: dashboardManager.getHistoryForPeriod(selectedPeriod.days),
                    period: selectedPeriod
                )
                .frame(height: 200)
            } else {
                // Fallback for older iOS versions
                Text("Chart requires iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }

            // Trend Insights
            if let trend = calculateTrend() {
                HStack(spacing: 8) {
                    Image(systemName: trend.isPositive ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                        .foregroundColor(trend.isPositive ? .green : .red)

                    Text(trend.message)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Stats Grid

    private func statsGrid(for child: ChildProfile) -> some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 16) {
            statCard(
                title: "Tasks Completed",
                value: "\(child.totalTasksCompleted)",
                icon: "checkmark.circle.fill",
                color: .blue
            )

            statCard(
                title: "Approval Rate",
                value: "\(calculateApprovalRate(child))%",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )

            statCard(
                title: "Current Streak",
                value: "\(child.consecutiveApprovedTasks)",
                icon: "flame.fill",
                color: .orange
            )

            statCard(
                title: "Best Streak",
                value: "23", // Mock data
                icon: "trophy.fill",
                color: .yellow
            )
        }
    }

    private func statCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
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

    private func calculateApprovalRate(_ child: ChildProfile) -> Int {
        guard child.totalTasksCompleted > 0 else { return 0 }
        return Int((Double(child.consecutiveApprovedTasks) / Double(child.totalTasksCompleted)) * 100)
    }

    private func calculateTrend() -> (isPositive: Bool, message: String)? {
        let history = dashboardManager.getHistoryForPeriod(selectedPeriod.days)
        guard history.count >= 2 else { return nil }

        let recentAvg = Double(history.suffix(7).map { $0.score }.reduce(0, +)) / 7.0
        let olderAvg = Double(history.prefix(7).map { $0.score }.reduce(0, +)) / 7.0
        let change = recentAvg - olderAvg

        if abs(change) < 2 {
            return (true, "Stable credibility over the period")
        } else if change > 0 {
            return (true, "Improving by \(String(format: "%.1f", change)) points")
        } else {
            return (false, "Declining by \(String(format: "%.1f", abs(change))) points")
        }
    }
}

// MARK: - Child Selector Card

struct ChildSelectorCard: View {
    let child: ChildProfile
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Image(systemName: child.avatarIcon)
                    .font(.system(size: 40))
                    .foregroundColor(isSelected ? .white : .blue)

                Text(child.name)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)

                Text("\(child.credibilityScore)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)

                if child.pendingVerifications > 0 {
                    Text("\(child.pendingVerifications)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.orange)
                        .cornerRadius(8)
                }
            }
            .frame(width: 100)
            .padding()
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .cornerRadius(16)
        }
    }
}

// MARK: - Credibility Chart

enum ChartPeriod: CaseIterable {
    case sevenDays, thirtyDays, ninetyDays

    var displayName: String {
        switch self {
        case .sevenDays: return "7D"
        case .thirtyDays: return "30D"
        case .ninetyDays: return "90D"
        }
    }

    var days: Int {
        switch self {
        case .sevenDays: return 7
        case .thirtyDays: return 30
        case .ninetyDays: return 90
        }
    }
}

@available(iOS 16.0, *)
struct CredibilityChart: View {
    let data: [CredibilityDataPoint]
    let period: ChartPeriod

    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Date", point.date),
                y: .value("Score", point.score)
            )
            .foregroundStyle(gradientForScore(point.score))
            .interpolationMethod(.catmullRom)

            AreaMark(
                x: .value("Date", point.date),
                y: .value("Score", point.score)
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        gradientForScore(point.score).opacity(0.3),
                        gradientForScore(point.score).opacity(0.05)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .interpolationMethod(.catmullRom)

            if let event = point.event {
                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Score", point.score)
                )
                .foregroundStyle(.orange)
                .annotation(position: .top) {
                    Text(event)
                        .font(.caption2)
                        .padding(4)
                        .background(Color(.systemBackground))
                        .cornerRadius(4)
                }
            }
        }
        .chartYScale(domain: 0...100)
        .chartYAxis {
            AxisMarks(values: [0, 25, 50, 75, 100])
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: period == .sevenDays ? .day : .weekOfYear)) {
                AxisValueLabel(format: .dateTime.month().day())
            }
        }
    }

    private func gradientForScore(_ score: Int) -> Color {
        switch score {
        case 90...100: return .green
        case 75...89: return .blue
        case 60...74: return .yellow
        case 40...59: return .orange
        default: return .red
        }
    }
}

// MARK: - Previews

struct ParentDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        ParentDashboardView()
    }
}