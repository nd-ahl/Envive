//
//  FinalOnboardingSummaryView.swift
//  EnviveNew
//
//  Final summary and next steps for parent onboarding
//

import SwiftUI

struct FinalOnboardingSummaryView: View {
    let childrenAdded: Int
    let inviteCode: String
    let onComplete: () -> Void
    let onSetupApps: () -> Void

    @State private var showContent = false

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

                        // Success header
                        successHeader

                        // What you've set up
                        setupSummary
                            .padding(.horizontal, 24)

                        // Next steps
                        nextStepsSection
                            .padding(.horizontal, 24)

                        // Quick start tips
                        quickStartTips
                            .padding(.horizontal, 24)

                        // Need help
                        helpSection
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

    // MARK: - Success Header

    private var successHeader: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundColor(.green)
            }
            .scaleEffect(showContent ? 1.0 : 0.3)
            .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("You're All Set!")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)

                Text("Your family account is ready to go")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
            }
            .scaleEffect(showContent ? 1.0 : 0.85)
            .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Setup Summary

    private var setupSummary: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Here's what you've set up:")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 12) {
                if childrenAdded > 0 {
                    summaryItem(
                        icon: "checkmark.circle.fill",
                        text: "Added \(childrenAdded) \(childrenAdded == 1 ? "child" : "children") to your household",
                        color: .green
                    )
                }

                summaryItem(
                    icon: "checkmark.circle.fill",
                    text: "Created household password",
                    color: .green
                )

                summaryItem(
                    icon: "checkmark.circle.fill",
                    text: "Received family invite code: \(inviteCode)",
                    color: .green
                )

                summaryItem(
                    icon: "checkmark.circle.fill",
                    text: "Learned how tasks, credibility, and screen time work",
                    color: .green
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
    }

    private func summaryItem(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - Next Steps

    private var nextStepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Next Steps:")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(spacing: 14) {
                nextStepCard(
                    number: 1,
                    title: "Share the invite code with your kids' devices",
                    icon: "qrcode",
                    color: .blue
                )

                nextStepCard(
                    number: 2,
                    title: "Help them join and select their profiles",
                    icon: "person.crop.circle.badge.checkmark",
                    color: .green
                )

                nextStepCard(
                    number: 3,
                    title: "Set up restricted apps (Settings > App Management)",
                    icon: "app.badge.checkmark",
                    color: .orange,
                    action: onSetupApps
                )

                nextStepCard(
                    number: 4,
                    title: "Assign your first task and watch the magic happen!",
                    icon: "sparkles",
                    color: .purple
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
    }

    private func nextStepCard(number: Int, title: String, icon: String, color: Color, action: (() -> Void)? = nil) -> some View {
        Button(action: action ?? {}) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.9))
                        .frame(width: 32, height: 32)

                    Text("\(number)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()

                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(color.opacity(0.8))
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(action != nil ? color.opacity(0.2) : Color.white.opacity(0.1))
            )
        }
        .disabled(action == nil)
    }

    // MARK: - Quick Start Tips

    private var quickStartTips: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.yellow)

                Text("Quick Start Tips")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 12) {
                tipItem(
                    icon: "bolt.fill",
                    text: "Start with simple tasks (make bed, brush teeth) to build momentum",
                    color: .orange
                )

                tipItem(
                    icon: "hand.thumbsup.fill",
                    text: "Approve early tasks generously to build confidence",
                    color: .green
                )

                tipItem(
                    icon: "brain.head.profile",
                    text: "Explain credibility to your kids—it's a learning system, not a punishment",
                    color: .purple
                )

                tipItem(
                    icon: "calendar",
                    text: "Check in daily to review completed tasks",
                    color: .blue
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.yellow.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
    }

    private func tipItem(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - Help Section

    private var helpSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "questionmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(.white.opacity(0.9))

            VStack(alignment: .leading, spacing: 4) {
                Text("Need help?")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text("Tap the \"?\" icon anytime to revisit these guides.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.15))
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Go to Dashboard button
            Button(action: onComplete) {
                HStack(spacing: 12) {
                    Text("Go to Dashboard")
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

            // Setup apps now button
            Button(action: onSetupApps) {
                Text("Set Up Restricted Apps Now")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.white.opacity(0.25))
                    )
            }
        }
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: showContent)
    }
}

// MARK: - Preview

struct FinalOnboardingSummaryView_Previews: PreviewProvider {
    static var previews: some View {
        FinalOnboardingSummaryView(
            childrenAdded: 2,
            inviteCode: "123456",
            onComplete: {},
            onSetupApps: {}
        )
    }
}
