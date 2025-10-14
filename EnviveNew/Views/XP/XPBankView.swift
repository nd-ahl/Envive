import SwiftUI

// MARK: - XP Bank View

struct XPBankView: View {
    @StateObject private var viewModel: XPBankViewModel

    init(viewModel: XPBankViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Balance Card
                balanceCard

                // Credibility Info
                credibilityCard

                // Redemption Section
                redemptionSection

                // Recent Activity
                recentActivitySection
            }
            .padding()
        }
        .navigationTitle("XP Bank")
        .alert("Success", isPresented: $viewModel.showRedemptionSuccess) {
            Button("OK") {
                viewModel.dismissRedemptionMessage()
            }
        } message: {
            if let message = viewModel.redemptionMessage {
                Text(message)
            }
        }
        .alert("Error", isPresented: $viewModel.showRedemptionError) {
            Button("OK") {
                viewModel.dismissRedemptionMessage()
            }
        } message: {
            if let message = viewModel.redemptionMessage {
                Text(message)
            }
        }
        .onAppear {
            viewModel.loadData()
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "dollarsign.circle.fill")
                    .font(.title)
                    .foregroundColor(.green)
                Text("Your Balance")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Text(viewModel.balanceDisplay)
                    .font(.system(size: 48, weight: .bold))
                Spacer()
            }

            if let warning = viewModel.softCapWarning {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.orange)
                    Text(warning)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Credibility Card

    private var credibilityCard: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "medal.fill")
                    .font(.title3)
                    .foregroundColor(credibilityColor)
                Text("Credibility: \(viewModel.credibilityDisplay)")
                    .font(.headline)
                Spacer()
            }

            HStack {
                Text(viewModel.earningRateDisplay)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }

            if viewModel.credibilityScore < 95 {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Keep completing tasks honestly to reach 95+ credibility and earn full XP!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Redemption Section

    private var redemptionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Redeem XP for Screen Time")
                    .font(.headline)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack {
                    Text("How much time do you want?")
                        .font(.subheadline)
                    Spacer()
                }

                Slider(
                    value: Binding(
                        get: { Double(viewModel.redemptionAmount) },
                        set: { viewModel.redemptionAmount = Int($0) }
                    ),
                    in: 0...Double(viewModel.currentBalance),
                    step: 5
                )

                HStack {
                    Text("\(viewModel.redemptionMinutes) minutes")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Cost: \(viewModel.redemptionAmount) XP")
                            .font(.subheadline)
                        Text("Remaining: \(viewModel.remainingAfterRedemption) XP")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }

                Button(action: {
                    viewModel.redeemXP()
                }) {
                    HStack {
                        if viewModel.isRedeeming {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Redeem \(viewModel.redemptionAmount) XP")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canRedeem ? Color.blue : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .disabled(!viewModel.canRedeem || viewModel.isRedeeming)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                Spacer()
            }

            if viewModel.recentTransactions.isEmpty {
                Text("No transactions yet")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
            } else {
                ForEach(viewModel.recentTransactions) { transaction in
                    transactionRow(transaction)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    // MARK: - Transaction Row

    private func transactionRow(_ transaction: XPTransaction) -> some View {
        HStack {
            Image(systemName: transaction.type == .earned ? "arrow.down.circle.fill" : "arrow.up.circle.fill")
                .foregroundColor(transaction.type == .earned ? .green : .blue)

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.type == .earned ? "Earned" : "Redeemed")
                    .font(.subheadline)
                    .fontWeight(.medium)

                if let credibility = transaction.credibilityAtTime {
                    Text("\(transaction.amount) XP (\(credibility)% rate)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(transaction.amount) XP")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Text(transaction.timestamp.formatted(date: .abbreviated, time: .shortened))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private var credibilityColor: Color {
        switch viewModel.credibilityScore {
        case 95...100: return .green
        case 80...94:  return .blue
        case 60...79:  return .yellow
        case 40...59:  return .orange
        default:       return .red
        }
    }
}

// MARK: - Preview

struct XPBankView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            XPBankView(
                viewModel: XPBankViewModel(
                    userId: UUID(),
                    xpService: MockXPService(),
                    credibilityService: MockCredibilityService()
                )
            )
        }
    }
}

// MARK: - Mock Services for Preview

private class MockXPService: XPService {
    func calculateXP(timeMinutes: Int, credibilityScore: Int) -> Int { 30 }
    func credibilityMultiplier(score: Int) -> Double { 1.0 }
    func credibilityTierName(score: Int) -> String { "Excellent" }
    func earningRatePercentage(score: Int) -> Int { 100 }
    func redeemXP(amount: Int, userId: UUID, credibilityScore: Int) -> Result<RedemptionResult, RedemptionError> {
        .success(RedemptionResult(success: true, minutesGranted: 30, xpSpent: 30, newBalance: 70, message: "Success"))
    }
    func getBalance(userId: UUID) -> XPBalance? {
        XPBalance(userId: userId, currentXP: 100)
    }
    func getRecentTransactions(userId: UUID, limit: Int) -> [XPTransaction] { [] }
    func getDailyStats(userId: UUID) -> DailyXPStats {
        DailyXPStats(earnedToday: 50, redeemedToday: 30, currentBalance: 100, credibilityScore: 95, earningRate: 1.0)
    }
    func awardXP(userId: UUID, timeMinutes: Int, taskId: UUID, credibilityScore: Int) -> Int { 30 }
    func grantXPDirect(userId: UUID, amount: Int, reason: String) -> Bool { true }
}

private class MockCredibilityService: CredibilityService {
    var credibilityScore: Int { 95 }
    var credibilityHistory: [CredibilityHistoryEvent] { [] }
    var consecutiveApprovedTasks: Int { 5 }
    var hasRedemptionBonus: Bool { false }
    var redemptionBonusExpiry: Date? { nil }
    func processDownvote(taskId: UUID, reviewerId: UUID, notes: String?) {}
    func undoDownvote(taskId: UUID, reviewerId: UUID) {}
    func processApprovedTask(taskId: UUID, reviewerId: UUID, notes: String?) {}
    func calculateXPToMinutes(xpAmount: Int) -> Int { xpAmount }
    func getConversionRate() -> Double { 1.0 }
    func getCurrentTier() -> CredibilityTier {
        CredibilityTier(
            name: "Excellent",
            range: 95...100,
            multiplier: 1.0,
            color: "green",
            description: "Excellent standing"
        )
    }
    func getCredibilityStatus() -> CredibilityStatus {
        CredibilityStatus(
            score: 95,
            tier: getCurrentTier(),
            consecutiveApprovedTasks: 5,
            hasRedemptionBonus: false,
            redemptionBonusExpiry: nil,
            history: [],
            conversionRate: 1.0,
            recoveryPath: nil
        )
    }
    func applyTimeBasedDecay() {}
}
