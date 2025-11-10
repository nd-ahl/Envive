//
//  InviteCodeOnboardingView.swift
//  EnviveNew
//
//  Display invite code with instructions for child setup
//

import SwiftUI

struct InviteCodeOnboardingView: View {
    let inviteCode: String
    let onContinue: () -> Void
    let onSkip: () -> Void

    @State private var showContent = false
    @State private var showCopiedMessage = false

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

                ScrollView {
                    VStack(spacing: 28) {
                        Spacer()
                            .frame(height: max(40, geometry.safeAreaInsets.top + 20))

                        // Header
                        headerSection

                        // Invite code display
                        inviteCodeDisplay
                            .padding(.horizontal, 24)

                        // Instructions
                        instructionsSection
                            .padding(.horizontal, 24)

                        // Why this matters
                        whyItMattersSection
                            .padding(.horizontal, 24)

                        // Example
                        exampleSection
                            .padding(.horizontal, 24)

                        // Pro tip
                        proTipSection
                            .padding(.horizontal, 24)

                        Spacer()

                        // Action buttons
                        actionButtons
                            .padding(.horizontal, 24)
                            .padding(.bottom, max(30, geometry.safeAreaInsets.bottom + 20))
                    }
                }

                // Copied message overlay
                if showCopiedMessage {
                    VStack {
                        Spacer()
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Code copied to clipboard!")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(radius: 10)
                        .padding(.bottom, 100)
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
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
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 90, height: 90)

                Image(systemName: "qrcode")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1.0 : 0.3)
            .opacity(showContent ? 1.0 : 0)

            Text("Your Family Invite Code")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .scaleEffect(showContent ? 1.0 : 0.85)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Invite Code Display

    private var inviteCodeDisplay: some View {
        VStack(spacing: 16) {
            Text("This is how your kids join your household from their devices!")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Text("Your invite code is:")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))

                // Code display
                Text(formatInviteCode(inviteCode))
                    .font(.system(size: 48, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                    .tracking(8)
                    .padding(.vertical, 20)
                    .padding(.horizontal, 30)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(0.25))
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.4), lineWidth: 2)
                            )
                    )

                // Copy button
                Button(action: copyCode) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc.fill")
                            .font(.system(size: 16))
                        Text("Copy Code")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                    )
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.opacity(0.3))
                    .shadow(color: Color.black.opacity(0.15), radius: 15, x: 0, y: 8)
            )
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("How it works:")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            VStack(alignment: .leading, spacing: 12) {
                instructionStep(number: 1, text: "Open Envive on your child's device (phone, tablet, etc.)")
                instructionStep(number: 2, text: "Select \"I'm a Kid\" during setup")
                instructionStep(number: 3, text: "Enter this 6-digit code")
                instructionStep(number: 4, text: "Your child selects their profile")
                instructionStep(number: 5, text: "Their device links to your family—done!")
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    private func instructionStep(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.blue)
            }

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .fixedSize(horizontal: false, vertical: true)

            Spacer()
        }
    }

    // MARK: - Why It Matters Section

    private var whyItMattersSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why this matters:")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Your child doesn't need their own email or password. They just use this code once to join, then their device remembers them forever.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(3)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.purple.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.purple.opacity(0.4), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    // MARK: - Example Section

    private var exampleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)

                Text("Real-life example:")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text("\"I gave the code to my daughter verbally. She entered it on her iPad, picked her name from the list, and boom—she was in. No complicated login steps!\"")
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
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    // MARK: - Pro Tip Section

    private var proTipSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "star.fill")
                .font(.system(size: 20))
                .foregroundColor(.yellow)

            VStack(alignment: .leading, spacing: 4) {
                Text("Pro tip:")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)

                Text("You can find this code anytime in Settings > Family > Invite Code")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(2)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
        )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Continue button
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
        }
    }

    // MARK: - Helper Functions

    private func formatInviteCode(_ code: String) -> String {
        // Insert space in the middle for readability (e.g., "123 456")
        guard code.count == 6 else { return code }
        let index = code.index(code.startIndex, offsetBy: 3)
        return "\(code[..<index]) \(code[index...])"
    }

    private func copyCode() {
        UIPasteboard.general.string = inviteCode
        withAnimation {
            showCopiedMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
        }
    }
}

// MARK: - Preview

struct InviteCodeOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        InviteCodeOnboardingView(
            inviteCode: "123456",
            onContinue: {},
            onSkip: {}
        )
    }
}
