import SwiftUI

// MARK: - Credibility Badge Component

/// Displays a compact or full credibility score badge with tier styling
struct CredibilityBadgeComponent: View {
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
                .fill(tierColor)
                .frame(width: compact ? 8 : 10, height: compact ? 8 : 10)

            if !compact {
                Text("\(score)")
                    .font(compact ? .caption : .subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(tierColor)
            }

            Text(compact ? "\(score)" : tier.name)
                .font(compact ? .caption : .subheadline)
                .foregroundColor(compact ? tierColor : .primary)
        }
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 6)
        .background(
            RoundedRectangle(cornerRadius: compact ? 8 : 10)
                .fill(tierColor.opacity(0.15))
        )
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 8 : 10)
                .stroke(tierColor.opacity(0.5), lineWidth: 1)
        )
    }

    private var tierColor: Color {
        CredibilityColors.color(for: tier.color)
    }
}

// MARK: - Credibility Score Header

/// Large credibility score display with tier indicator
struct CredibilityScoreHeader: View {
    let score: Int
    let tier: CredibilityTier

    var body: some View {
        HStack {
            Text("Credibility Score")
                .font(.headline)
                .foregroundColor(.secondary)

            Spacer()

            HStack(spacing: 8) {
                Circle()
                    .fill(tierColor)
                    .frame(width: 10, height: 10)

                Text("\(score)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(tierColor)

                Text("/ 100")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
    }

    private var tierColor: Color {
        CredibilityColors.color(for: tier.color)
    }
}

// MARK: - Tier Badge Component

/// Displays tier information with icon and multiplier
struct TierBadgeComponent: View {
    let tier: CredibilityTier
    let multiplier: Double
    let showMultiplier: Bool

    init(tier: CredibilityTier, multiplier: Double, showMultiplier: Bool = true) {
        self.tier = tier
        self.multiplier = multiplier
        self.showMultiplier = showMultiplier
    }

    var body: some View {
        HStack {
            Image(systemName: tierIcon)
                .foregroundColor(tierColor)

            Text(tier.name)
                .font(.headline)
                .foregroundColor(tierColor)

            Spacer()

            if showMultiplier {
                Text("\(String(format: "%.1fx", multiplier)) multiplier")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(tierColor.opacity(0.1))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(tierColor, lineWidth: 2)
        )
    }

    private var tierColor: Color {
        CredibilityColors.color(for: tier.color)
    }

    private var tierIcon: String {
        CredibilityIcons.icon(for: tier.name)
    }
}

// MARK: - Streak Indicator

/// Displays current streak with progress to next bonus
struct StreakIndicator: View {
    let consecutiveTasks: Int
    let showProgress: Bool

    init(consecutiveTasks: Int, showProgress: Bool = true) {
        self.consecutiveTasks = consecutiveTasks
        self.showProgress = showProgress
    }

    var body: some View {
        if consecutiveTasks > 0 {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundColor(.orange)

                Text("\(consecutiveTasks) task streak")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                if showProgress {
                    let tasksUntilBonus = 10 - (consecutiveTasks % 10)
                    if tasksUntilBonus > 0 {
                        Text("\(tasksUntilBonus) more for +5 bonus")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
        }
    }
}

// MARK: - Recovery Path Banner

/// Displays recovery path information for users with reduced credibility
struct RecoveryPathBanner: View {
    let recoveryPath: String

    var body: some View {
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
    }
}

// MARK: - Redemption Bonus Banner

/// Shows active redemption bonus with expiry
struct RedemptionBonusBanner: View {
    let isActive: Bool
    let expiry: Date?

    var body: some View {
        if isActive {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Redemption Bonus Active!")
                        .font(.subheadline)
                        .foregroundColor(.yellow)
                    Spacer()
                }

                if let expiryDate = expiry {
                    HStack {
                        Text("Expires:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(expiryDate, style: .relative)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

// MARK: - Conversion Preview Card

/// Shows XP to minutes conversion with credibility multiplier
struct ConversionPreviewCard: View {
    let xpAmount: Int
    let rate: Double
    let minutes: Int
    let hasBonus: Bool

    var body: some View {
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
                Text("\(String(format: "%.1fx", rate))")
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
            }

            if hasBonus {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Redemption Bonus Applied!")
                        .font(.subheadline)
                        .foregroundColor(.yellow)
                    Spacer()
                }
            }

            Divider()

            HStack {
                Text("Screen Time Earned:")
                    .fontWeight(.semibold)
                Spacer()
                Text("\(minutes) minutes")
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
    }
}

// MARK: - Credibility Status Summary

/// Complete credibility status overview
struct CredibilityStatusSummary: View {
    let status: CredibilityStatus

    var body: some View {
        VStack(spacing: 16) {
            CredibilityScoreHeader(score: status.score, tier: status.tier)

            TierBadgeComponent(tier: status.tier, multiplier: status.conversionRate)
                .padding(.horizontal)

            HStack(spacing: 24) {
                StatItem(label: "Score", value: "\(status.score)", color: CredibilityColors.color(for: status.tier.color))
                StatItem(label: "Tier", value: status.tier.name, color: .primary)
                StatItem(label: "Rate", value: String(format: "%.1fx", status.conversionRate), color: .blue)
                StatItem(label: "Streak", value: "\(status.dailyStreak) days", color: .orange)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal)

            if status.dailyStreak > 0 {
                StreakIndicator(consecutiveTasks: status.dailyStreak)
                    .padding(.horizontal)
            }

            if status.hasRedemptionBonus {
                RedemptionBonusBanner(isActive: true, expiry: status.redemptionBonusExpiry)
                    .padding(.horizontal)
            }

            if let recoveryPath = status.recoveryPath {
                RecoveryPathBanner(recoveryPath: recoveryPath)
                    .padding(.horizontal)
            }

            Text(status.tier.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding(.vertical)
    }
}

// MARK: - Supporting Views

private struct StatItem: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Credibility Utilities

/// Color mapping for credibility tiers
enum CredibilityColors {
    static func color(for tierString: String) -> Color {
        switch tierString.lowercased() {
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

/// Icon mapping for credibility tiers
enum CredibilityIcons {
    static func icon(for tierName: String) -> String {
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

// MARK: - Previews

struct CredibilityComponents_Previews: PreviewProvider {
    static var previews: some View {
        let sampleTier = CredibilityTier(
            name: "Excellent",
            range: 90...100,
            multiplier: 1.2,
            color: "green",
            description: "Outstanding performance!"
        )

        let sampleStatus = CredibilityStatus(
            score: 95,
            tier: sampleTier,
            consecutiveApprovedTasks: 15,
            dailyStreak: 12,
            hasRedemptionBonus: true,
            redemptionBonusExpiry: Date().addingTimeInterval(86400 * 3),
            history: [],
            conversionRate: 1.2,
            recoveryPath: nil
        )

        ScrollView {
            VStack(spacing: 24) {
                CredibilityBadgeComponent(score: 95, tier: sampleTier)
                CredibilityBadgeComponent(score: 95, tier: sampleTier, compact: true)
                TierBadgeComponent(tier: sampleTier, multiplier: 1.2)
                StreakIndicator(consecutiveTasks: 7)
                ConversionPreviewCard(xpAmount: 1000, rate: 1.2, minutes: 120, hasBonus: true)
                CredibilityStatusSummary(status: sampleStatus)
            }
            .padding()
        }
    }
}
