//
//  ScreenTimeExplanationOnboardingView.swift
//  EnviveNew
//
//  Screen time and XP redemption explanation
//

import SwiftUI

struct ScreenTimeExplanationOnboardingView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void
    let onSetupApps: () -> Void

    @State private var showContent = false
    @State private var currentPage = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.7),
                        Color.purple.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, max(40, geometry.safeAreaInsets.top + 20))
                        .padding(.bottom, 20)

                    // Tabbed content
                    TabView(selection: $currentPage) {
                        overviewPage.tag(0)
                        flowPage.tag(1)
                        controlsPage.tag(2)
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))

                    // Action buttons
                    actionButtons
                        .padding(.horizontal, 24)
                        .padding(.bottom, max(30, geometry.safeAreaInsets.bottom + 20))
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 70, height: 70)

                Image(systemName: "hourglass")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            Text("How Screen Time Works")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Swipe to learn more")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Page 1: Overview

    private var overviewPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("Earning Screen Time")

                Text("Your child earns XP from tasks. Here's how they turn it into screen time.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .lineSpacing(3)

                VStack(spacing: 12) {
                    flowStep(
                        number: 1,
                        text: "Child completes tasks → XP accumulates"
                    )

                    flowStep(
                        number: 2,
                        text: "Child goes to \"Redeem XP\" in their app"
                    )

                    flowStep(
                        number: 3,
                        text: "They see conversion rate (based on credibility)"
                    )

                    flowStep(
                        number: 4,
                        text: "They choose how much XP to redeem"
                    )

                    flowStep(
                        number: 5,
                        text: "XP converts to minutes (e.g., 100 XP → 100 minutes)"
                    )

                    flowStep(
                        number: 6,
                        text: "They tap \"Start Screen Time\""
                    )

                    flowStep(
                        number: 7,
                        text: "Restricted apps unlock for that duration"
                    )

                    flowStep(
                        number: 8,
                        text: "Timer counts down (shown in Dynamic Island)"
                    )

                    flowStep(
                        number: 9,
                        text: "Time expires → Apps lock again"
                    )
                }

                exampleCard(
                    text: "\"I restricted TikTok, Instagram, and Roblox on my daughter's phone. She earned 50 XP from chores, redeemed it for 50 minutes, and used it to play Roblox after homework. When the timer ended, Roblox locked automatically.\""
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Page 2: What Gets Restricted

    private var flowPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("What Gets Restricted?")

                VStack(alignment: .leading, spacing: 12) {
                    Text("You Choose the Apps")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text("You decide which apps require earned screen time. You can restrict games, social media, entertainment, or anything you want!")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(3)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.15))
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Common Choices:")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    appCategory(icon: "gamecontroller.fill", title: "Games", examples: "Roblox, Minecraft, Fortnite", color: .orange)
                    appCategory(icon: "bubble.left.fill", title: "Social Media", examples: "TikTok, Instagram, Snapchat", color: .pink)
                    appCategory(icon: "play.rectangle.fill", title: "Entertainment", examples: "YouTube, Netflix, Twitch", color: .red)
                    appCategory(icon: "music.note", title: "Music", examples: "Spotify, Apple Music", color: .purple)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.2))
                )

                infoBox(
                    icon: "lightbulb.fill",
                    text: "Pro tip: Start with 2-3 high-value apps (games/social) rather than restricting everything. This keeps kids motivated.",
                    color: .yellow
                )

                // Setup apps button
                Button(action: onSetupApps) {
                    HStack {
                        Image(systemName: "app.badge.checkmark.fill")
                            .font(.system(size: 20))
                        Text("Set Up Restricted Apps Now")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.4))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green, lineWidth: 2)
                            )
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Page 3: Parent Controls

    private var controlsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("Parent Controls")

                controlCard(
                    icon: "bolt.fill",
                    title: "Emergency Grant",
                    description: "Give screen time instantly (no XP cost) for urgent situations like long car rides or doctor visits.",
                    color: .orange
                )

                controlCard(
                    icon: "app.badge.fill",
                    title: "App Selection",
                    description: "Add or remove restricted apps anytime. Changes sync instantly to your child's device.",
                    color: .blue
                )

                controlCard(
                    icon: "lock.fill",
                    title: "Household Password",
                    description: "Required for parent overrides and settings changes. Keeps kids from bypassing the system.",
                    color: .purple
                )

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.blue)

                        Text("How It's Different:")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Unlike traditional screen time limits that feel punitive, Envive motivates kids to EARN access by completing real-world tasks. They're working toward something, not being restricted from something.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(4)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Helper Components

    private func pageTitle(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 24, weight: .bold, design: .rounded))
            .foregroundColor(.white)
            .padding(.bottom, 4)
    }

    private func flowStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 28, height: 28)

                Text("\(number)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.blue)
            }

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
        .padding(.vertical, 4)
    }

    private func appCategory(icon: String, title: String, examples: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(examples)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.15))
        )
    }

    private func controlCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(3)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.12))
        )
    }

    private func exampleCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)

                Text("Real-life example:")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .italic()
                .lineSpacing(3)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func infoBox(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(3)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.12))
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button(action: onContinue) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.blue.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            }

            Button(action: onSkip) {
                Text("Skip - I'll Set This Up Later")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .underline()
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Preview

struct ScreenTimeExplanationOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenTimeExplanationOnboardingView(
            onContinue: {},
            onSkip: {},
            onSetupApps: {}
        )
    }
}
