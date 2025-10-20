import SwiftUI
import Charts
import Combine

// MARK: - XP Analytics Data Models

struct XPAnalyticsData {
    let userId: UUID
    let currentBalance: Int
    let lifetimeEarned: Int
    let lifetimeSpent: Int
    let earnedToday: Int
    let redeemedToday: Int
    let credibilityScore: Int
    let earningRate: Double
    let recentTransactions: [XPTransaction]
    let weeklyHistory: [XPHistoryPoint]
}

struct XPHistoryPoint: Identifiable {
    let id = UUID()
    let date: Date
    let earned: Int
    let redeemed: Int
    let balance: Int
}

// MARK: - XP Analytics Manager

class XPAnalyticsManager: ObservableObject {
    @Published var analyticsData: XPAnalyticsData?

    private let xpService: XPService
    private let credibilityService: CredibilityService

    init(xpService: XPService? = nil, credibilityService: CredibilityService? = nil) {
        self.xpService = xpService ?? DependencyContainer.shared.xpService
        self.credibilityService = credibilityService ?? DependencyContainer.shared.credibilityService
    }

    func loadAnalytics(for userId: UUID) {
        // Get current balance
        guard let balance = xpService.getBalance(userId: userId) else {
            return
        }

        // Get daily stats
        let dailyStats = xpService.getDailyStats(userId: userId)

        // Get recent transactions
        let transactions = xpService.getRecentTransactions(userId: userId, limit: 10)

        // Generate weekly history (mock for now - would come from repository in production)
        let weeklyHistory = generateWeeklyHistory(userId: userId)

        analyticsData = XPAnalyticsData(
            userId: userId,
            currentBalance: balance.currentXP,
            lifetimeEarned: balance.lifetimeEarned,
            lifetimeSpent: balance.lifetimeSpent,
            earnedToday: dailyStats.earnedToday,
            redeemedToday: dailyStats.redeemedToday,
            credibilityScore: credibilityService.getCredibilityScore(childId: userId),
            earningRate: dailyStats.earningRate,
            recentTransactions: transactions,
            weeklyHistory: weeklyHistory
        )
    }

    private func generateWeeklyHistory(userId: UUID) -> [XPHistoryPoint] {
        var history: [XPHistoryPoint] = []
        let calendar = Calendar.current
        let today = Date()

        var runningBalance = analyticsData?.currentBalance ?? 100

        for day in (0..<7).reversed() {
            if let date = calendar.date(byAdding: .day, value: -day, to: today) {
                let earned = Int.random(in: 0...60)
                let redeemed = Int.random(in: 0...40)
                runningBalance += (earned - redeemed)

                history.append(XPHistoryPoint(
                    date: date,
                    earned: earned,
                    redeemed: redeemed,
                    balance: max(0, runningBalance)
                ))
            }
        }

        return history
    }
}

// MARK: - XP Analytics View

struct XPAnalyticsView: View {
    let childId: UUID
    @StateObject private var manager = XPAnalyticsManager()
    @State private var selectedMetric: XPMetric = .balance

    var body: some View {
        VStack(spacing: 20) {
            if let data = manager.analyticsData {
                // XP Balance Overview
                xpBalanceCard(data: data)

                // Today's Activity
                todayActivityCard(data: data)

                // Weekly Trend Chart
                weeklyTrendCard(data: data)

                // Lifetime Stats
                lifetimeStatsCard(data: data)

                // Earning Efficiency
                earningEfficiencyCard(data: data)
            } else {
                ProgressView("Loading XP Analytics...")
            }
        }
        .onAppear {
            manager.loadAnalytics(for: childId)
        }
    }

    // MARK: - XP Balance Card

    private func xpBalanceCard(data: XPAnalyticsData) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Current XP Balance")
                    .font(.headline)
                Spacer()
            }

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(data.currentBalance)")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundColor(.blue)

                Text("XP")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Available Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(data.currentBalance) minutes")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Earning Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(Int(data.earningRate * 100))%")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(earningRateColor(data.earningRate))
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Soft cap warning if applicable
            if data.currentBalance >= XPBalance.softCap {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.orange)
                    Text("Above 1000 XP: Earning at 50% rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(12)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Today's Activity Card

    private func todayActivityCard(data: XPAnalyticsData) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Today's Activity")
                    .font(.headline)
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 16) {
                // Earned Today
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.green)
                        Text("Earned")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("\(data.earnedToday)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.green)

                    Text("XP")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)

                // Redeemed Today
                VStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.blue)
                        Text("Redeemed")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Text("\(data.redeemedToday)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)

                    Text("XP")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }

            // Net change
            let netChange = data.earnedToday - data.redeemedToday
            HStack(spacing: 8) {
                Image(systemName: netChange >= 0 ? "plus.circle.fill" : "minus.circle.fill")
                    .foregroundColor(netChange >= 0 ? .green : .red)
                Text("Net change: \(netChange >= 0 ? "+" : "")\(netChange) XP")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Weekly Trend Card

    private func weeklyTrendCard(data: XPAnalyticsData) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("7-Day Trend")
                    .font(.headline)

                Spacer()

                Picker("Metric", selection: $selectedMetric) {
                    ForEach(XPMetric.allCases, id: \.self) { metric in
                        Text(metric.displayName).tag(metric)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            if #available(iOS 16.0, *) {
                XPTrendChart(data: data.weeklyHistory, metric: selectedMetric)
                    .frame(height: 180)
            } else {
                Text("Chart requires iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 180)
            }

            // Weekly summary
            let weeklyEarned = data.weeklyHistory.reduce(0) { $0 + $1.earned }
            let weeklyRedeemed = data.weeklyHistory.reduce(0) { $0 + $1.redeemed }

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(weeklyEarned) XP")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }

                Divider()
                    .frame(height: 30)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Redeemed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(weeklyRedeemed) XP")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                }

                Spacer()
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Lifetime Stats Card

    private func lifetimeStatsCard(data: XPAnalyticsData) -> some View {
        VStack(spacing: 16) {
            HStack {
                Text("Lifetime Statistics")
                    .font(.headline)
                Spacer()
            }

            HStack(spacing: 16) {
                // Total Earned
                VStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.title2)
                        .foregroundColor(.yellow)

                    Text("\(data.lifetimeEarned)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Total Earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(12)

                // Total Spent
                VStack(spacing: 8) {
                    Image(systemName: "clock.fill")
                        .font(.title2)
                        .foregroundColor(.purple)

                    Text("\(data.lifetimeSpent)")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Total Spent")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
            }

            // Savings rate
            let savingsRate = data.lifetimeEarned > 0 ?
                Double(data.currentBalance) / Double(data.lifetimeEarned) * 100 : 0

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Current Savings Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(savingsRate))%")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                ProgressView(value: savingsRate, total: 100)
                    .tint(savingsRateColor(savingsRate))
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Earning Efficiency Card

    private func earningEfficiencyCard(data: XPAnalyticsData) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .foregroundColor(.blue)
                Text("Earning Efficiency")
                    .font(.headline)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Credibility Score")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(data.credibilityScore)")
                        .fontWeight(.semibold)
                        .foregroundColor(credibilityColor(data.credibilityScore))
                }

                HStack {
                    Text("Current Earning Rate")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(Int(data.earningRate * 100))%")
                        .fontWeight(.semibold)
                        .foregroundColor(earningRateColor(data.earningRate))
                }

                Divider()

                // Earning potential
                let potentialXP = 60 // 1 hour of tasks
                let actualXP = Int(Double(potentialXP) * data.earningRate)

                VStack(alignment: .leading, spacing: 8) {
                    Text("For 1 hour (60 min) of tasks:")
                        .font(.caption)
                        .fontWeight(.semibold)

                    HStack {
                        Text("Current rate earns:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(actualXP) XP")
                            .font(.caption)
                            .fontWeight(.medium)
                    }

                    if data.earningRate < 1.0 {
                        HStack {
                            Text("At 100% would earn:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(potentialXP) XP (+\(potentialXP - actualXP))")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.orange)
                        }

                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("Reach 95+ credibility to earn full XP!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(8)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Text("Earning at maximum rate!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helper Methods

    private func credibilityColor(_ score: Int) -> Color {
        switch score {
        case 95...100: return .green
        case 80...94:  return .blue
        case 60...79:  return .yellow
        case 40...59:  return .orange
        default:       return .red
        }
    }

    private func earningRateColor(_ rate: Double) -> Color {
        switch rate {
        case 0.95...1.0: return .green
        case 0.75...0.94: return .blue
        case 0.5...0.74: return .yellow
        default: return .orange
        }
    }

    private func savingsRateColor(_ rate: Double) -> Color {
        switch rate {
        case 30...100: return .green
        case 15...29: return .yellow
        default: return .orange
        }
    }
}

// MARK: - XP Metric Enum

enum XPMetric: CaseIterable {
    case balance, earned, redeemed

    var displayName: String {
        switch self {
        case .balance: return "Balance"
        case .earned: return "Earned"
        case .redeemed: return "Redeemed"
        }
    }
}

// MARK: - XP Trend Chart

@available(iOS 16.0, *)
struct XPTrendChart: View {
    let data: [XPHistoryPoint]
    let metric: XPMetric

    var body: some View {
        Chart(data) { point in
            switch metric {
            case .balance:
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(.blue)
                .interpolationMethod(.catmullRom)

                AreaMark(
                    x: .value("Date", point.date),
                    y: .value("Balance", point.balance)
                )
                .foregroundStyle(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.3), Color.blue.opacity(0.05)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

            case .earned:
                BarMark(
                    x: .value("Date", point.date),
                    y: .value("Earned", point.earned)
                )
                .foregroundStyle(.green)

            case .redeemed:
                BarMark(
                    x: .value("Date", point.date),
                    y: .value("Redeemed", point.redeemed)
                )
                .foregroundStyle(.blue)
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) {
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
            }
        }
    }
}

// MARK: - Preview

struct XPAnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            XPAnalyticsView(childId: UUID())
                .padding()
        }
    }
}
