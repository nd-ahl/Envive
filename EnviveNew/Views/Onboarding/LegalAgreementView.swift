//
//  LegalAgreementView.swift
//  EnviveNew
//
//  Single legal agreement screen - shown only once, never again
//

import SwiftUI

struct LegalAgreementView: View {
    let onAccept: () -> Void

    @State private var hasScrolledToBottom = false
    @State private var agreedToTerms = false
    @State private var agreedToPrivacy = false
    @State private var showContent = false

    private var canContinue: Bool {
        hasScrolledToBottom && agreedToTerms && agreedToPrivacy
    }

    var body: some View {
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
                    .padding(.top, 60)
                    .padding(.horizontal, 24)

                // Legal content in scrollable card
                legalContentCard
                    .padding(.horizontal, 24)
                    .padding(.top, 24)

                // Checkboxes
                checkboxSection
                    .padding(.horizontal, 32)
                    .padding(.top, 20)

                // Continue button
                continueButton
                    .padding(.horizontal, 32)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Terms & Privacy")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)

            Text("Please review and accept to continue")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Legal Content Card

    private var legalContentCard: some View {
        VStack(spacing: 0) {
            // Scroll indicator
            if !hasScrolledToBottom {
                HStack {
                    Spacer()
                    Text("Scroll to bottom to continue")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                    Spacer()
                }
                .padding(.bottom, 8)
            }

            // Scrollable content
            ScrollViewWithBottomDetection(hasScrolledToBottom: $hasScrolledToBottom) {
                VStack(alignment: .leading, spacing: 20) {
                    // Privacy Policy
                    privacyPolicySection

                    Divider()
                        .padding(.vertical, 10)

                    // Terms of Service
                    termsOfServiceSection
                }
                .padding(20)
            }
            .frame(maxHeight: 400)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Privacy Policy Section

    private var privacyPolicySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy Policy")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(.label))

            Text("Effective Date: October 21, 2025")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))

            Group {
                sectionHeader("1. Information We Collect")
                bodyText("Envive collects minimal information to provide our service. This includes:\n• Your name and email (for parent accounts)\n• Child names and ages (stored locally on your device)\n• Task completion data\n• Screen time usage data (never leaves your device)")

                sectionHeader("2. How We Use Your Information")
                bodyText("We use your information solely to:\n• Provide and improve the Envive service\n• Enable parent-child task management\n• Track screen time rewards\n• Send important service notifications")

                sectionHeader("3. Data Storage & Security")
                bodyText("• Most data is stored locally on your device using iOS secure storage\n• Server-stored data (account info) is encrypted\n• We never sell or share your data with third parties\n• Screen time data never leaves your device")

                sectionHeader("4. Children's Privacy (COPPA Compliance)")
                bodyText("For children under 13:\n• We require parental consent before account creation\n• We collect only the minimum data needed (name, age)\n• Parents can review and delete child data at any time\n• No advertising or third-party tracking")

                sectionHeader("5. Your Rights")
                bodyText("You have the right to:\n• Access your data\n• Request data deletion\n• Export your data\n• Withdraw consent at any time")

                sectionHeader("6. Contact")
                bodyText("For privacy questions: privacy@envive.app")
            }
        }
    }

    // MARK: - Terms of Service Section

    private var termsOfServiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Terms of Service")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(Color(.label))

            Text("Effective Date: October 21, 2025")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.secondaryLabel))

            Group {
                sectionHeader("1. Acceptance of Terms")
                bodyText("By using Envive, you agree to these Terms of Service. If you do not agree, please do not use the app.")

                sectionHeader("2. Description of Service")
                bodyText("Envive helps families manage tasks and screen time. Parents assign tasks, children complete them to earn screen time.")

                sectionHeader("3. User Responsibilities")
                bodyText("Parents agree to:\n• Provide accurate information\n• Supervise their children's use of the app\n• Set appropriate tasks and screen time limits\n\nChildren agree to:\n• Complete tasks honestly\n• Respect screen time limits set by parents")

                sectionHeader("4. Screen Time Management")
                bodyText("Envive uses Apple's Screen Time API. You acknowledge that:\n• Screen time limits are enforced by iOS\n• Envive cannot guarantee 100% effectiveness\n• Parents remain responsible for monitoring device usage")

                sectionHeader("5. Account Termination")
                bodyText("You may delete your account at any time from Settings. We reserve the right to terminate accounts that violate these terms.")

                sectionHeader("6. Limitation of Liability")
                bodyText("Envive is provided 'as is' without warranties. We are not liable for any damages arising from use of the service.")

                sectionHeader("7. Changes to Terms")
                bodyText("We may update these terms. Continued use after changes constitutes acceptance.")

                sectionHeader("8. Contact")
                bodyText("For questions about these terms: support@envive.app")
            }
        }
    }

    // MARK: - Checkbox Section

    private var checkboxSection: some View {
        VStack(spacing: 16) {
            // Privacy checkbox
            Button(action: {
                agreedToPrivacy.toggle()
                print("📋 Privacy checkbox: \(agreedToPrivacy)")
                print("   Can continue: hasScrolled=\(hasScrolledToBottom), privacy=\(agreedToPrivacy), terms=\(agreedToTerms)")
            }) {
                HStack(spacing: 12) {
                    Image(systemName: agreedToPrivacy ? "checkmark.square.fill" : "square")
                        .font(.system(size: 24))
                        .foregroundColor(agreedToPrivacy ? .green : .white.opacity(0.7))

                    Text("I have read and agree to the Privacy Policy")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
            }

            // Terms checkbox
            Button(action: {
                agreedToTerms.toggle()
                print("📋 Terms checkbox: \(agreedToTerms)")
                print("   Can continue: hasScrolled=\(hasScrolledToBottom), privacy=\(agreedToPrivacy), terms=\(agreedToTerms)")
            }) {
                HStack(spacing: 12) {
                    Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                        .font(.system(size: 24))
                        .foregroundColor(agreedToTerms ? .green : .white.opacity(0.7))

                    Text("I have read and agree to the Terms of Service")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Spacer()
                }
            }
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        VStack(spacing: 12) {
            // Show requirements if not met
            if !canContinue {
                VStack(spacing: 6) {
                    if !hasScrolledToBottom {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.yellow)
                            Text("Please scroll to the bottom of the document above")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    if !agreedToPrivacy || !agreedToTerms {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.square")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.yellow)
                            Text("Check both boxes above to continue")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.15))
                .cornerRadius(12)
            }

            Button(action: {
                // CRITICAL FIX: Only call onAccept() callback
                // The parent (EnviveNewApp) handles calling completeLegalAgreement()
                // This prevents double-calling and navigation glitches
                onAccept()
            }) {
                Text("Continue")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(canContinue ? Color.blue.opacity(0.9) : Color.gray.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(canContinue ? Color.white : Color.white.opacity(0.3))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(canContinue ? 0.2 : 0.05), radius: 12, x: 0, y: 6)
            }
            .disabled(!canContinue)
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(Color(.label))
            .padding(.top, 8)
    }

    private func bodyText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15, weight: .regular))
            .foregroundColor(Color(.secondaryLabel))
            .lineSpacing(2)
            .fixedSize(horizontal: false, vertical: true)
    }
}

// MARK: - Scroll View with Bottom Detection

struct ScrollViewWithBottomDetection<Content: View>: View {
    @Binding var hasScrolledToBottom: Bool
    let content: Content

    init(hasScrolledToBottom: Binding<Bool>, @ViewBuilder content: () -> Content) {
        self._hasScrolledToBottom = hasScrolledToBottom
        self.content = content()
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                content

                // Bottom detector - more visible area to trigger
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ViewOffsetKey.self,
                        value: geometry.frame(in: .named("scroll")).origin.y
                    )
                }
                .frame(height: 50) // Increased from 1 to make it easier to detect
            }
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ViewOffsetKey.self) { value in
            // When bottom element comes into view, mark as scrolled to bottom
            // More forgiving threshold - trigger when bottom is within 200 points of view
            if value < 200 && !hasScrolledToBottom {
                hasScrolledToBottom = true
                print("✅ Scrolled to bottom detected")
            }
        }
    }
}

struct ViewOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview

struct LegalAgreementView_Previews: PreviewProvider {
    static var previews: some View {
        LegalAgreementView(onAccept: {})
    }
}
