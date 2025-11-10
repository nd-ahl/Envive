//
//  ParentWelcomeOnboardingView.swift
//  EnviveNew
//
//  Post-account creation welcome screen for parents
//

import SwiftUI

struct ParentWelcomeOnboardingView: View {
    let parentName: String
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var showContent = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.4, green: 0.5, blue: 0.95),
                        Color(red: 0.55, green: 0.35, blue: 0.85)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: max(40, geometry.safeAreaInsets.top + 20))

                        // Header
                        headerSection

                        // How it works section
                        howItWorksSection
                            .padding(.horizontal, 24)

                        Spacer()

                        // Action buttons
                        actionButtons
                            .padding(.horizontal, 24)
                            .padding(.bottom, max(30, geometry.safeAreaInsets.bottom + 20))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Celebration icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )

                Image(systemName: "star.fill")
                    .font(.system(size: 44, weight: .medium))
                    .foregroundColor(.yellow)
            }
            .scaleEffect(showContent ? 1.0 : 0.3)
            .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Welcome to Your Family's New Adventure!")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)

                Text("Hi \(parentName)!")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))
            }
            .scaleEffect(showContent ? 1.0 : 0.85)
            .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - How It Works Section

    private var howItWorksSection: some View {
        VStack(spacing: 20) {
            Text("You've just unlocked a powerful tool that transforms chores into screen time rewards while teaching your kids accountability.")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 10)

            VStack(spacing: 16) {
                featureCard(
                    icon: "list.bullet.clipboard.fill",
                    title: "You assign tasks",
                    delay: 0.1
                )

                featureCard(
                    icon: "arrow.right.circle.fill",
                    title: "Kids complete them",
                    delay: 0.2
                )

                featureCard(
                    icon: "star.circle.fill",
                    title: "They earn XP",
                    delay: 0.3
                )
            }

            infoBox(
                text: "XP converts to screen time minutes. A credibility score ensures quality work (more on this later!)",
                delay: 0.4
            )
        }
    }

    private func featureCard(icon: String, title: String, delay: Double) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28, weight: .semibold))
                .foregroundColor(.white)
                .frame(width: 44)

            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .tracking(0.2)

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(delay), value: showContent)
    }

    private func infoBox(text: String, delay: Double) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white.opacity(0.9))
            .multilineTextAlignment(.center)
            .lineSpacing(3)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.15))
            )
            .scaleEffect(showContent ? 1.0 : 0.9)
            .opacity(showContent ? 1.0 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(delay), value: showContent)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Continue button
            Button(action: onContinue) {
                HStack(spacing: 12) {
                    Text("Continue")
                        .font(.system(size: 19, weight: .semibold, design: .rounded))
                        .tracking(0.3)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.95))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
                )
            }

            // Skip button
            Button(action: onSkip) {
                Text("Skip Setup - I'll Do This Later")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .underline()
            }
            .padding(.top, 8)
        }
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: showContent)
    }
}

// MARK: - Preview

struct ParentWelcomeOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        ParentWelcomeOnboardingView(
            parentName: "Sarah",
            onContinue: {},
            onSkip: {}
        )
    }
}
