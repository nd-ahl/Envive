//
//  CredibilityExplanationOnboardingView.swift
//  EnviveNew
//
//  Credibility system and accountability explanation
//

import SwiftUI

struct CredibilityExplanationOnboardingView: View {
    let onContinue: () -> Void
    let onSkip: () -> Void

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
                        howItChangesPage.tag(1)
                        impactPage.tag(2)
                        scenariosPage.tag(3)
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

                Image(systemName: "medal.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.yellow)
            }

            Text("The Credibility System")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Teaching Accountability")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Text("Swipe to learn more")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Page 1: Overview

    private var overviewPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("Envive's Secret Sauce")

                Text("This system teaches kids that quality matters, not just quantity.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .lineSpacing(3)

                VStack(alignment: .leading, spacing: 16) {
                    Text("What is Credibility?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    Text("A score from 0-100 that tracks your child's honesty and work quality. Everyone starts at 100 (perfect score).")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(3)
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.15))
                )

                credibilityRangeCard()

                infoBox(
                    icon: "star.fill",
                    text: "Higher credibility = more screen time per XP!",
                    color: .yellow
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Page 2: How It Changes

    private var howItChangesPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("How Credibility Changes")

                changeCard(
                    icon: "arrow.up.circle.fill",
                    title: "Task APPROVED",
                    change: "+2 credibility",
                    description: "Reward for good work (max 100)",
                    color: .green
                )

                changeCard(
                    icon: "arrow.down.circle.fill",
                    title: "Task DECLINED",
                    change: "-10 credibility",
                    description: "Consequence for poor quality",
                    color: .red
                )

                changeCard(
                    icon: "exclamationmark.triangle.fill",
                    title: "2 Declines in 7 Days",
                    change: "-15 credibility",
                    description: "Stacking penalty for repeat issues",
                    color: .orange
                )

                changeCard(
                    icon: "star.circle.fill",
                    title: "10 Approvals in a Row",
                    change: "+5 bonus",
                    description: "Comeback reward for consistency",
                    color: .purple
                )

                infoBox(
                    icon: "clock.fill",
                    text: "Old declines lose 50% weight after 30 days and disappear after 60 days. Kids can always recover!",
                    color: .blue
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Page 3: Impact on Screen Time

    private var impactPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("Why It Matters")

                Text("Credibility changes how much screen time your child gets per XP.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .lineSpacing(3)

                conversionCard(
                    range: "90-100",
                    title: "Excellent",
                    multiplier: "1.2x",
                    example: "1 XP = 1.2 minutes",
                    color: .green
                )

                conversionCard(
                    range: "75-89",
                    title: "Good",
                    multiplier: "1.0x",
                    example: "1 XP = 1.0 minute",
                    color: .blue
                )

                conversionCard(
                    range: "60-74",
                    title: "Fair",
                    multiplier: "0.8x",
                    example: "1 XP = 0.8 minutes",
                    color: .yellow
                )

                conversionCard(
                    range: "40-59",
                    title: "Poor",
                    multiplier: "0.5x",
                    example: "1 XP = 0.5 minutes (half!)",
                    color: .orange
                )

                exampleCard(
                    text: "\"My daughter had 100 credibility. I declined 3 tasks in a row because her room wasn't actually clean. Her score dropped to 70 and suddenly her 100 XP only got her 80 minutes instead of 120. She learned fast—now she does thorough work!\""
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Page 4: Scenarios

    private var scenariosPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("Real Scenarios")

                scenarioCard(
                    title: "The Photo Faker",
                    icon: "camera.fill",
                    scenario: "Emma submits a photo of her made bed, but you notice toys stuffed under it.",
                    action: "DECLINE",
                    result: "Add note: \"Great effort on the bed, but please pick up the toys under it. Try again!\"",
                    lesson: "She learns attention to detail matters.",
                    color: .red
                )

                scenarioCard(
                    title: "The Go-Getter",
                    icon: "star.fill",
                    scenario: "Your son completes 10 chores in a row, all high-quality with clear photo evidence.",
                    action: "APPROVE ALL",
                    result: "He gets the +5 streak bonus + high credibility = max screen time conversion!",
                    lesson: "Hard work pays off.",
                    color: .green
                )

                scenarioCard(
                    title: "The Comeback Kid",
                    icon: "arrow.up.right.circle.fill",
                    scenario: "Your daughter's credibility dropped to 50 after sloppy work. She buckles down and does 15 tasks perfectly.",
                    action: "KEEP APPROVING",
                    result: "Credibility climbs to 95+ → She earns a 1.3x redemption bonus for 7 days!",
                    lesson: "Redemption and improvement are rewarded.",
                    color: .purple
                )

                infoBox(
                    icon: "lightbulb.fill",
                    text: "Use declines sparingly but consistently. They're teaching moments, not punishments.",
                    color: .yellow
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

    private func credibilityRangeCard() -> some View {
        VStack(spacing: 12) {
            Text("Score Ranges:")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(spacing: 8) {
                rangeRow(range: "90-100", label: "Excellent", color: .green)
                rangeRow(range: "75-89", label: "Good", color: .blue)
                rangeRow(range: "60-74", label: "Fair", color: .yellow)
                rangeRow(range: "40-59", label: "Poor", color: .orange)
                rangeRow(range: "0-39", label: "Very Poor", color: .red)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
        )
    }

    private func rangeRow(range: String, label: String, color: Color) -> some View {
        HStack {
            Text(range)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 80, alignment: .leading)

            Circle()
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            Spacer()
        }
    }

    private func changeCard(icon: String, title: String, change: String, description: String, color: Color) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(color)
                .frame(width: 44)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(change)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(color)

                Text(description)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func conversionCard(range: String, title: String, multiplier: String, example: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Circle()
                    .fill(color)
                    .frame(width: 14, height: 14)

                Text("\(title) (\(range))")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text(multiplier)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(0.2))
                    )
            }

            Text(example)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.12))
        )
    }

    private func scenarioCard(title: String, icon: String, scenario: String, action: String, result: String, lesson: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                infoRow(label: "Scenario:", text: scenario)
                infoRow(label: "Action:", text: "→ \(action)", color: color)
                infoRow(label: "Result:", text: result)
                infoRow(label: "Lesson:", text: lesson, color: .green)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private func infoRow(label: String, text: String, color: Color? = nil) -> some View {
        HStack(alignment: .top, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(color ?? .white.opacity(0.85))

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
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
                Text("Skip - I Understand")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .underline()
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Preview

struct CredibilityExplanationOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        CredibilityExplanationOnboardingView(
            onContinue: {},
            onSkip: {}
        )
    }
}
