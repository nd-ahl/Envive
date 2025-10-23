//
//  BadgeDetailView.swift
//  EnviveNew
//
//  Detailed view for a specific badge
//

import SwiftUI
import Combine

struct BadgeDetailView: View {
    let badgeType: BadgeType
    let isEarned: Bool
    let earnedDate: Date?
    let progress: BadgeProgress?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Badge Icon (Large)
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tierColor.opacity(0.3), tierColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 150, height: 150)

                    Image(systemName: badgeType.icon)
                        .font(.system(size: 70))
                        .foregroundColor(isEarned ? tierColor : .gray)
                }
                .padding(.top, 20)

                // Badge Name
                Text(badgeType.displayName)
                    .font(.title)
                    .fontWeight(.bold)

                // Tier Badge
                HStack(spacing: 6) {
                    Image(systemName: "medal.fill")
                        .foregroundColor(tierColor)
                    Text(badgeType.tier.displayName)
                        .fontWeight(.semibold)
                        .foregroundColor(tierColor)
                }
                .font(.headline)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(tierColor.opacity(0.15))
                .cornerRadius(12)

                // Status Section
                VStack(spacing: 16) {
                    if isEarned {
                        // Earned status
                        VStack(spacing: 8) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                                Text("Badge Earned!")
                                    .font(.headline)
                                    .foregroundColor(.green)
                            }

                            if let date = earnedDate {
                                Text("Earned on \(date, style: .date)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }

                            // Bonus XP awarded
                            HStack(spacing: 8) {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text("+\(badgeType.bonusXP) XP Bonus Awarded")
                                    .fontWeight(.medium)
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(12)
                    } else {
                        // Locked status with progress
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(.orange)
                                Text("Not Yet Earned")
                                    .font(.headline)
                                    .foregroundColor(.orange)
                            }

                            if let progress = progress {
                                VStack(spacing: 8) {
                                    ProgressView(value: progress.percentage)
                                        .tint(tierColor)

                                    Text("\(progress.current) of \(progress.target)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)

                                    let remaining = progress.target - progress.current
                                    if remaining > 0 {
                                        Text("\(remaining) more to go!")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }

                            // Potential bonus XP
                            HStack(spacing: 8) {
                                Image(systemName: "star")
                                    .foregroundColor(.yellow)
                                Text("Earn +\(badgeType.bonusXP) XP")
                                    .fontWeight(.medium)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)

                // Description Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("About This Badge")
                        .font(.headline)

                    Text(badgeType.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // How to Earn Section
                VStack(alignment: .leading, spacing: 12) {
                    Text(isEarned ? "How You Earned It" : "How to Earn")
                        .font(.headline)

                    Text(howToEarnText)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)

                // Category Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.headline)

                    Text(badgeType.category.displayName)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            .padding(.bottom, 40)
        }
        .navigationTitle("Badge Details")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var tierColor: Color {
        switch badgeType.tier {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .cyan
        }
    }

    private var howToEarnText: String {
        // Provide specific instructions based on badge type
        switch badgeType {
        case .firstAppOpen:
            return isEarned ? "You opened the app for the first time!" : "Simply open the app - you'll earn this automatically!"
        case .profileComplete:
            return isEarned ? "You completed your profile setup." : "Fill in all your profile information including your name and age."
        case .firstTaskComplete:
            return isEarned ? "You completed your first task!" : "Complete any task and get it approved by your parent."
        case .tasksNovice:
            return isEarned ? "You completed 5 tasks!" : "Complete 5 tasks total and get them all approved."
        case .tasksApprentice:
            return isEarned ? "You completed 25 tasks!" : "Complete 25 tasks total and get them all approved."
        case .tasksExpert:
            return isEarned ? "You completed 100 tasks!" : "Complete 100 tasks total and get them all approved."
        case .tasksMaster:
            return isEarned ? "You completed 500 tasks!" : "Complete 500 tasks total and get them all approved."
        case .xpBeginner:
            return isEarned ? "You earned 100 total XP!" : "Earn 100 XP total by completing tasks."
        case .xpIntermediate:
            return isEarned ? "You earned 1,000 total XP!" : "Earn 1,000 XP total by completing tasks."
        case .xpAdvanced:
            return isEarned ? "You earned 10,000 total XP!" : "Earn 10,000 XP total by completing tasks."
        case .xpMaster:
            return isEarned ? "You earned 100,000 total XP!" : "Earn 100,000 XP total by completing tasks."
        case .streak3:
            return isEarned ? "You completed tasks for 3 days in a row!" : "Complete at least one task each day for 3 days in a row."
        case .streak7:
            return isEarned ? "You completed tasks for 7 days in a row!" : "Complete at least one task each day for 7 days in a row."
        case .streak30:
            return isEarned ? "You completed tasks for 30 days in a row!" : "Complete at least one task each day for 30 days in a row."
        case .streak100:
            return isEarned ? "You completed tasks for 100 days in a row!" : "Complete at least one task each day for 100 days in a row."
        case .perfectWeek:
            return isEarned ? "You completed all your assigned tasks for 7 days straight!" : "Complete every assigned task for 7 days without missing any."
        case .earlyBird:
            return isEarned ? "You completed a task before 8 AM!" : "Complete and submit a task before 8:00 AM."
        case .nightOwl:
            return isEarned ? "You completed a task after 10 PM!" : "Complete and submit a task after 10:00 PM."
        case .speedDemon:
            return isEarned ? "You completed a task within 5 minutes of accepting it!" : "Accept a task and complete it within 5 minutes."
        case .overachiever:
            return isEarned ? "You completed 10 tasks in a single day!" : "Complete and submit 10 different tasks in one day."
        case .trustworthy:
            return isEarned ? "You maintained 90+ credibility for a week!" : "Keep your credibility score at 90 or higher for 7 consecutive days."
        case .reliable:
            return isEarned ? "You maintained 95+ credibility for a month!" : "Keep your credibility score at 95 or higher for 30 consecutive days."
        case .exemplary:
            return isEarned ? "You maintained 98+ credibility for 90 days!" : "Keep your credibility score at 98 or higher for 90 consecutive days."
        }
    }
}
