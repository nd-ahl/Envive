import SwiftUI

// MARK: - Conversion Rate Display View

struct ConversionRateView: View {
    @ObservedObject var rewardManager: ScreenTimeRewardManager
    let xpAmount: Int

    var body: some View {
        let preview = rewardManager.previewConversion(xpAmount: xpAmount)
        let status = rewardManager.getCredibilityStatus()

        VStack(spacing: 16) {
            // Credibility Score Header
            HStack {
                Text("Credibility Score")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 8) {
                    Circle()
                        .fill(colorForTier(status.tier.color))
                        .frame(width: 10, height: 10)

                    Text("\(status.score)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(colorForTier(status.tier.color))

                    Text("/ 100")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            // Tier Badge
            HStack {
                Image(systemName: tierIcon(for: status.tier.name))
                    .foregroundColor(colorForTier(status.tier.color))

                Text(status.tier.name)
                    .font(.headline)
                    .foregroundColor(colorForTier(status.tier.color))

                Spacer()

                Text("\(String(format: "%.1fx", preview.rate)) multiplier")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(colorForTier(status.tier.color).opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(colorForTier(status.tier.color), lineWidth: 2)
            )
            .padding(.horizontal)

            // Conversion Preview
            VStack(spacing: 12) {
                HStack {
                    Text("XP to Redeem:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(xpAmount) XP")
                        .fontWeight(.semibold)
                }

                Divider()

                HStack {
                    Text("Conversion Rate:")
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(String(format: "%.1fx", preview.rate))")
                        .fontWeight(.semibold)
                        .foregroundColor(colorForTier(status.tier.color))
                }

                if preview.hasBonus {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("Redemption Bonus Active!")
                            .font(.subheadline)
                            .foregroundColor(.yellow)
                        Spacer()
                    }

                    if let expiry = status.redemptionBonusExpiry {
                        HStack {
                            Text("Expires:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(expiry, style: .relative)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider()

                HStack {
                    Text("Screen Time Earned:")
                        .fontWeight(.semibold)
                    Spacer()
                    Text("\(preview.minutes) minutes")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)

            // Streak Info
            if status.consecutiveApprovedTasks > 0 {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)

                    Text("\(status.consecutiveApprovedTasks) task streak")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Spacer()

                    let tasksUntilBonus = 10 - (status.consecutiveApprovedTasks % 10)
                    if tasksUntilBonus > 0 {
                        Text("\(tasksUntilBonus) more for +5 bonus")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
            }

            // Recovery Path
            if let recoveryPath = status.recoveryPath {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.blue)

                    Text(recoveryPath)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)

                    Spacer()
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue.opacity(0.1))
                )
                .padding(.horizontal)
            }

            // Tier Description
            Text(status.tier.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }

    private func colorForTier(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "red":
            return .red
        default:
            return .gray
        }
    }

    private func tierIcon(for tierName: String) -> String {
        switch tierName {
        case "Excellent":
            return "star.fill"
        case "Good":
            return "checkmark.circle.fill"
        case "Fair":
            return "circle.fill"
        case "Poor":
            return "exclamationmark.triangle.fill"
        case "Very Poor":
            return "xmark.circle.fill"
        default:
            return "circle.fill"
        }
    }
}

// MARK: - Compact Credibility Badge

struct CredibilityBadge: View {
    let score: Int
    let tier: CredibilityTier
    let compact: Bool

    init(score: Int, tier: CredibilityTier, compact: Bool = false) {
        self.score = score
        self.tier = tier
        self.compact = compact
    }

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(colorForTier(tier.color))
                .frame(width: compact ? 8 : 10, height: compact ? 8 : 10)

            if !compact {
                Text("\(score)")
                    .font(compact ? .caption : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(colorForTier(tier.color))
            }

            Text(compact ? "\(score)" : tier.name)
                .font(compact ? .caption : .subheadline)
                .foregroundColor(compact ? colorForTier(tier.color) : .primary)
        }
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 6)
        .background(
            RoundedRectangle(cornerRadius: compact ? 8 : 10)
                .fill(colorForTier(tier.color).opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 8 : 10)
                .stroke(colorForTier(tier.color).opacity(0.5), lineWidth: 1)
        )
    }

    private func colorForTier(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "green":
            return .green
        case "yellow":
            return .yellow
        case "red":
            return .red
        default:
            return .gray
        }
    }
}

// MARK: - XP Redemption Sheet

struct XPRedemptionSheet: View {
    @ObservedObject var rewardManager: ScreenTimeRewardManager
    @Binding var isPresented: Bool
    @State private var xpToRedeem: String = ""

    let availableXP: Int

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // XP Input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("XP to Redeem")
                            .font(.headline)

                        HStack {
                            TextField("Enter XP amount", text: $xpToRedeem)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())

                            Text("/ \(availableXP)")
                                .foregroundColor(.secondary)
                        }

                        // Quick amount buttons
                        HStack(spacing: 12) {
                            quickAmountButton(100)
                            quickAmountButton(500)
                            quickAmountButton(1000)
                            quickAmountButton(availableXP, label: "All")
                        }
                    }
                    .padding()

                    // Show conversion preview if valid amount
                    if let xpAmount = Int(xpToRedeem), xpAmount > 0, xpAmount <= availableXP {
                        ConversionRateView(rewardManager: rewardManager, xpAmount: xpAmount)

                        // Redeem Button
                        Button(action: {
                            let _ = rewardManager.redeemXPForScreenTime(xpAmount: xpAmount)
                            isPresented = false
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Redeem \(xpAmount) XP")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .padding(.horizontal)
                    } else if !xpToRedeem.isEmpty {
                        Text("Please enter a valid amount (1-\(availableXP))")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding()
                    }

                    Spacer()
                }
            }
            .navigationTitle("Redeem XP")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }

    private func quickAmountButton(_ amount: Int, label: String? = nil) -> some View {
        Button(action: {
            xpToRedeem = "\(min(amount, availableXP))"
        }) {
            Text(label ?? "\(amount)")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
    }
}

// MARK: - Preview

struct ConversionRateView_Previews: PreviewProvider {
    static var previews: some View {
        let manager = ScreenTimeRewardManager()
        return VStack {
            ConversionRateView(rewardManager: manager, xpAmount: 1000)
        }
        .padding()
    }
}