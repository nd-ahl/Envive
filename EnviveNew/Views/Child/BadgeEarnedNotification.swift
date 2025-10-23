//
//  BadgeEarnedNotification.swift
//  EnviveNew
//
//  Pop-up notification shown when a badge is earned
//

import SwiftUI
import Combine

// MARK: - Badge Earned Notification View

struct BadgeEarnedNotification: View {
    let badge: EarnedBadge
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    @State private var rotation: Double = -180

    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissNotification()
                }

            // Notification card
            VStack(spacing: 20) {
                // Badge icon with animation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [tierColor.opacity(0.3), tierColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)

                    Image(systemName: badge.badgeType.icon)
                        .font(.system(size: 50))
                        .foregroundColor(tierColor)
                        .rotationEffect(.degrees(rotation))
                }
                .scaleEffect(scale)

                // Congratulations text
                VStack(spacing: 8) {
                    Text("🎉 Badge Earned! 🎉")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text(badge.badgeType.displayName)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(tierColor)

                    Text(badge.badgeType.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Bonus XP
                    HStack(spacing: 8) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        Text("+\(badge.bonusXPAwarded) XP Bonus")
                            .font(.headline)
                            .foregroundColor(.yellow)
                    }
                    .padding(.top, 8)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.yellow.opacity(0.15))
                    .cornerRadius(20)
                }

                // Tier badge
                HStack(spacing: 4) {
                    Image(systemName: "medal.fill")
                        .foregroundColor(tierColor)
                    Text(badge.badgeType.tier.displayName)
                        .fontWeight(.semibold)
                        .foregroundColor(tierColor)
                }
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(tierColor.opacity(0.15))
                .cornerRadius(12)

                // Close button
                Button(action: {
                    dismissNotification()
                }) {
                    Text("Awesome!")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(tierColor)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .padding(24)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: tierColor.opacity(0.3), radius: 20)
            .padding(.horizontal, 40)
            .opacity(opacity)
        }
        .onAppear {
            presentNotification()
        }
    }

    private var tierColor: Color {
        switch badge.badgeType.tier {
        case .bronze: return .brown
        case .silver: return .gray
        case .gold: return .yellow
        case .platinum: return .cyan
        }
    }

    private func presentNotification() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
        }

        withAnimation(.easeOut(duration: 0.8)) {
            rotation = 0
        }

        // Play sound effect
        SoundEffectsManager.shared.playBadgeEarned()
    }

    private func dismissNotification() {
        withAnimation(.easeOut(duration: 0.2)) {
            opacity = 0
            scale = 0.9
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            isPresented = false
        }
    }
}

// MARK: - Badge Notification Manager

@MainActor
class BadgeNotificationManager: ObservableObject {
    static let shared = BadgeNotificationManager()

    @Published var pendingBadges: [EarnedBadge] = []
    @Published var currentBadge: EarnedBadge?
    @Published var showingNotification: Bool = false

    private init() {}

    func showBadge(_ badge: EarnedBadge) {
        // Add to queue
        pendingBadges.append(badge)

        // Show immediately if not already showing
        if !showingNotification {
            showNextBadge()
        }
    }

    func showBadges(_ badges: [EarnedBadge]) {
        for badge in badges {
            showBadge(badge)
        }
    }

    private func showNextBadge() {
        guard !pendingBadges.isEmpty else {
            return
        }

        currentBadge = pendingBadges.removeFirst()
        showingNotification = true
    }

    func dismissCurrent() {
        showingNotification = false
        currentBadge = nil

        // Show next badge after short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showNextBadge()
        }
    }
}

// MARK: - Badge Notification Overlay Modifier

struct BadgeNotificationOverlay: ViewModifier {
    @ObservedObject var manager = BadgeNotificationManager.shared

    func body(content: Content) -> some View {
        ZStack {
            content

            if manager.showingNotification, let badge = manager.currentBadge {
                BadgeEarnedNotification(
                    badge: badge,
                    isPresented: Binding(
                        get: { manager.showingNotification },
                        set: { if !$0 { manager.dismissCurrent() } }
                    )
                )
                .transition(.opacity)
                .zIndex(999)
            }
        }
    }
}

extension View {
    func badgeNotifications() -> some View {
        self.modifier(BadgeNotificationOverlay())
    }
}
