//
//  BadgesView.swift
//  EnviveNew
//
//  Badge display and progress view for child profile
//

import SwiftUI
import Combine

// MARK: - Badges View

struct BadgesView: View {
    let childId: UUID
    @StateObject private var viewModel: BadgesViewModel

    init(childId: UUID) {
        self.childId = childId
        _viewModel = StateObject(wrappedValue: BadgesViewModel(
            childId: childId,
            badgeService: DependencyContainer.shared.badgeService
        ))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Badge Summary
                badgeSummarySection

                // Earned Badges
                if !viewModel.earnedBadges.isEmpty {
                    earnedBadgesSection
                }

                // In Progress Badges
                if !viewModel.inProgressBadges.isEmpty {
                    inProgressSection
                }

                // Locked Badges
                if !viewModel.lockedBadges.isEmpty {
                    lockedBadgesSection
                }
            }
            .padding()
        }
        .navigationTitle("Badges")
        .onAppear {
            viewModel.loadBadges()
        }
    }

    // MARK: - Badge Summary Section

    private var badgeSummarySection: some View {
        VStack(spacing: 12) {
            Text("Your Achievements")
                .font(.title2)
                .fontWeight(.bold)

            HStack(spacing: 20) {
                BadgeTierCount(tier: .platinum, count: viewModel.tierCounts[.platinum] ?? 0)
                BadgeTierCount(tier: .gold, count: viewModel.tierCounts[.gold] ?? 0)
                BadgeTierCount(tier: .silver, count: viewModel.tierCounts[.silver] ?? 0)
                BadgeTierCount(tier: .bronze, count: viewModel.tierCounts[.bronze] ?? 0)
            }

            Text("\(viewModel.earnedBadges.count) of \(BadgeType.allCases.count) badges earned")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    // MARK: - Earned Badges Section

    private var earnedBadgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Earned Badges")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.earnedBadges) { earnedBadge in
                    NavigationLink(destination: BadgeDetailView(
                        badgeType: earnedBadge.badgeType,
                        isEarned: true,
                        earnedDate: earnedBadge.earnedAt,
                        progress: nil
                    )) {
                        BadgeCard(
                            badgeType: earnedBadge.badgeType,
                            isEarned: true,
                            earnedDate: earnedBadge.earnedAt
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - In Progress Section

    private var inProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("In Progress")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.inProgressBadges, id: \.badgeType) { progress in
                    NavigationLink(destination: BadgeDetailView(
                        badgeType: progress.badgeType,
                        isEarned: false,
                        earnedDate: nil,
                        progress: progress
                    )) {
                        BadgeCard(
                            badgeType: progress.badgeType,
                            isEarned: false,
                            progress: progress
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Locked Badges Section

    private var lockedBadgesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Locked Badges")
                .font(.headline)
                .padding(.horizontal)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.lockedBadges, id: \.badgeType) { progress in
                    NavigationLink(destination: BadgeDetailView(
                        badgeType: progress.badgeType,
                        isEarned: false,
                        earnedDate: nil,
                        progress: progress
                    )) {
                        BadgeCard(
                            badgeType: progress.badgeType,
                            isEarned: false,
                            progress: progress
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Badge Tier Count

struct BadgeTierCount: View {
    let tier: BadgeTier
    let count: Int

    var body: some View {
        VStack(spacing: 4) {
            ZStack {
                Circle()
                    .fill(tierColor.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: "medal.fill")
                    .font(.title3)
                    .foregroundColor(tierColor)
            }

            Text("\(count)")
                .font(.headline)
                .fontWeight(.bold)

            Text(tier.displayName)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    private var tierColor: Color {
        switch tier {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .cyan
        }
    }
}

// MARK: - Badge Card

struct BadgeCard: View {
    let badgeType: BadgeType
    let isEarned: Bool
    var earnedDate: Date? = nil
    var progress: BadgeProgress? = nil

    var body: some View {
        VStack(spacing: 8) {
            // Badge Icon
            ZStack {
                Circle()
                    .fill(badgeColor.opacity(isEarned ? 0.2 : 0.05))
                    .frame(width: 60, height: 60)

                Image(systemName: badgeType.icon)
                    .font(.title2)
                    .foregroundColor(isEarned ? badgeColor : .gray)
            }

            // Badge Name
            Text(badgeType.displayName)
                .font(.caption)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 32)

            // Progress or Bonus XP
            if let progress = progress, !isEarned {
                VStack(spacing: 4) {
                    ProgressView(value: progress.percentage)
                        .tint(badgeColor)

                    Text("\(progress.current)/\(progress.target)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            } else if isEarned {
                Text("+\(badgeType.bonusXP) XP")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.green)
            }
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(isEarned ? 0.1 : 0.03), radius: 3)
        .opacity(isEarned ? 1.0 : 0.6)
    }

    private var badgeColor: Color {
        switch badgeType.tier {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .cyan
        }
    }
}

// MARK: - Badges View Model

class BadgesViewModel: ObservableObject {
    @Published var earnedBadges: [EarnedBadge] = []
    @Published var inProgressBadges: [BadgeProgress] = []
    @Published var lockedBadges: [BadgeProgress] = []
    @Published var tierCounts: [BadgeTier: Int] = [:]

    private let childId: UUID
    private let badgeService: BadgeService

    init(childId: UUID, badgeService: BadgeService) {
        self.childId = childId
        self.badgeService = badgeService
    }

    func loadBadges() {
        // Get earned badges
        earnedBadges = badgeService.getEarnedBadges(for: childId)

        // Get tier counts
        tierCounts = badgeService.getBadgeCountByTier(for: childId)

        // Calculate progress for all badges
        var inProgress: [BadgeProgress] = []
        var locked: [BadgeProgress] = []

        for badgeType in BadgeType.allCases {
            // Skip already earned badges
            if earnedBadges.contains(where: { $0.badgeType == badgeType }) {
                continue
            }

            if let progress = badgeService.getBadgeProgress(badgeType, for: childId) {
                if progress.percentage > 0 {
                    inProgress.append(progress)
                } else {
                    locked.append(progress)
                }
            }
        }

        // Sort by progress percentage
        inProgressBadges = inProgress.sorted { $0.percentage > $1.percentage }
        lockedBadges = locked.sorted { $0.badgeType.tier < $1.badgeType.tier }
    }
}
