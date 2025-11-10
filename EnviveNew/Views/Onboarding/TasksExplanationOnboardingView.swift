//
//  TasksExplanationOnboardingView.swift
//  EnviveNew
//
//  Comprehensive task system explanation
//

import SwiftUI

struct TasksExplanationOnboardingView: View {
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
                        levelsPage.tag(1)
                        workflowPage.tag(2)
                        decisionGuidePage.tag(3)
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

                Image(systemName: "checklist")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            Text("How Tasks Work")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Swipe to learn more")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
    }

    // MARK: - Page 1: Overview

    private var overviewPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("The Complete Journey")

                workflowStep(
                    number: 1,
                    title: "You Assign a Task",
                    description: "Pick from templates (e.g., \"Clean Bedroom\") or create custom tasks like \"Practice piano for 30 minutes.\""
                )

                workflowStep(
                    number: 2,
                    title: "Child Sees the Task",
                    description: "It appears on their dashboard. They can start it anytime."
                )

                workflowStep(
                    number: 3,
                    title: "Child Completes It",
                    description: "They mark it \"In Progress,\" do the work, then upload a photo as proof with optional notes."
                )

                workflowStep(
                    number: 4,
                    title: "You Review It",
                    description: "See the photo, check their work, and either APPROVE (XP + credibility boost) or DECLINE (no XP + credibility penalty)."
                )

                workflowStep(
                    number: 5,
                    title: "XP Is Awarded",
                    description: "Approved XP goes into their balance. They can redeem it for screen time whenever they want."
                )

                exampleCard(
                    text: "\"I assigned my son a 'Standard' task to take out the trash. He sent me a photo of the empty bins outside. I approved it, he got 50 XP, and used it to unlock 1 hour of Minecraft.\""
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Page 2: Levels

    private var levelsPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("Task Levels")

                Text("Each task has a LEVEL that determines how much XP it's worth:")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .lineSpacing(3)

                levelCard(
                    title: "Quick",
                    duration: "5-10 minutes",
                    xp: "Low XP",
                    color: .green
                )

                levelCard(
                    title: "Standard",
                    duration: "15-30 minutes",
                    xp: "Medium XP",
                    color: .blue
                )

                levelCard(
                    title: "Extended",
                    duration: "30-60 minutes",
                    xp: "High XP",
                    color: .orange
                )

                levelCard(
                    title: "Epic",
                    duration: "1+ hour",
                    xp: "Huge XP",
                    color: .purple
                )

                infoBox(
                    icon: "lightbulb.fill",
                    text: "Match the level to the effort required. A quick bed-making is different from a deep room clean!"
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Page 3: Workflow

    private var workflowPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("Parent Review Process")

                sectionCard(
                    title: "After child submits:",
                    items: [
                        "Check the photo they uploaded",
                        "Read their completion notes",
                        "Verify the work was done",
                        "Make your decision"
                    ]
                )

                approveSection()

                declineSection()

                infoBox(
                    icon: "arrow.triangle.2.circlepath",
                    text: "Pro tip: Declining teaches accountability, but too many declines hurt their credibility score (affects screen time conversion)."
                )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }

    // MARK: - Page 4: Decision Guide

    private var decisionGuidePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                pageTitle("When to Approve vs Decline")

                VStack(alignment: .leading, spacing: 16) {
                    Text("APPROVE when:")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.green)

                    decisionItem(
                        icon: "checkmark.circle.fill",
                        text: "Task is done well (meets expectations)",
                        color: .green
                    )

                    decisionItem(
                        icon: "checkmark.circle.fill",
                        text: "Photo clearly shows completion",
                        color: .green
                    )

                    decisionItem(
                        icon: "checkmark.circle.fill",
                        text: "Child put in honest effort",
                        color: .green
                    )
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.green.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                        )
                )

                VStack(alignment: .leading, spacing: 16) {
                    Text("DECLINE when:")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.red)

                    decisionItem(
                        icon: "xmark.circle.fill",
                        text: "Task is incomplete",
                        color: .red
                    )

                    decisionItem(
                        icon: "xmark.circle.fill",
                        text: "Photo doesn't match the task",
                        color: .red
                    )

                    decisionItem(
                        icon: "xmark.circle.fill",
                        text: "Quality is poor (half-effort)",
                        color: .red
                    )

                    decisionItem(
                        icon: "xmark.circle.fill",
                        text: "Child is trying to game the system",
                        color: .red
                    )
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.15))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.3), lineWidth: 1)
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

    private func workflowStep(number: Int, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 36, height: 36)

                Text("\(number)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue)
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
        )
    }

    private func levelCard(title: String, duration: String, xp: String, color: Color) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(duration)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))

                Text(xp)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(color)
            }

            Spacer()

            Image(systemName: "star.fill")
                .font(.system(size: 30))
                .foregroundColor(color.opacity(0.7))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.4), lineWidth: 1)
                )
        )
    }

    private func sectionCard(title: String, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green.opacity(0.9))

                        Text(item)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.15))
        )
    }

    private func approveSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.green)

                Text("APPROVE")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.green)
            }

            Text("Child gets XP + credibility boost (+2 points)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.green.opacity(0.15))
        )
    }

    private func declineSection() -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.red)

                Text("DECLINE")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.red)
            }

            Text("No XP + credibility penalty (-10 points)")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.red.opacity(0.15))
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

    private func infoBox(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.yellow)

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

    private func decisionItem(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)
        }
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
                Text("Skip - I Got It")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .underline()
            }
            .padding(.top, 8)
        }
    }
}

// MARK: - Preview

struct TasksExplanationOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        TasksExplanationOnboardingView(
            onContinue: {},
            onSkip: {}
        )
    }
}
