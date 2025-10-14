import Foundation

final class CredibilityTierProvider {
    private let tiers: [CredibilityTier] = [
        CredibilityTier(
            name: "Excellent",
            range: 90...100,
            multiplier: 1.2,
            color: "green",
            description: "Outstanding credibility! Maximum conversion rate."
        ),
        CredibilityTier(
            name: "Good",
            range: 75...89,
            multiplier: 1.0,
            color: "green",
            description: "Good standing. Standard conversion rate."
        ),
        CredibilityTier(
            name: "Fair",
            range: 60...74,
            multiplier: 0.8,
            color: "yellow",
            description: "Fair standing. Reduced conversion rate."
        ),
        CredibilityTier(
            name: "Poor",
            range: 40...59,
            multiplier: 0.5,
            color: "red",
            description: "Poor standing. Significantly reduced rate."
        ),
        CredibilityTier(
            name: "Very Poor",
            range: 0...39,
            multiplier: 0.3,
            color: "red",
            description: "Very poor standing. Minimum conversion rate."
        )
    ]

    func getTier(for score: Int) -> CredibilityTier {
        tiers.first { $0.range.contains(score) } ?? tiers.last!
    }

    func allTiers() -> [CredibilityTier] {
        tiers
    }

    func nextTier(above score: Int) -> CredibilityTier? {
        tiers
            .sorted { $0.range.lowerBound > $1.range.lowerBound }
            .first { $0.range.lowerBound > score }
    }
}
