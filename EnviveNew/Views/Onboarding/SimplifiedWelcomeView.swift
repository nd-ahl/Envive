//
//  SimplifiedWelcomeView.swift
//  EnviveNew
//
//  Simplified welcome screen with inline privacy agreement
//

import SwiftUI

struct SimplifiedWelcomeView: View {
    let onParentContinue: () -> Void
    let onChildContinue: () -> Void

    @State private var showContent = false
    @State private var privacyAccepted = false
    @State private var hasScrolledToBottom = false
    @State private var showingPrivacyDetails = false

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

            ScrollView {
                VStack(spacing: 32) {
                    Spacer()
                        .frame(height: 20)

                    // Logo and tagline
                    logoSection

                    // What it does (simple 3 benefits)
                    benefitsSection

                    // Privacy agreement (inline, simple)
                    privacySection

                    // Action buttons
                    actionButtons

                    Spacer()
                        .frame(height: 40)
                }
                .padding(.horizontal, 24)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)

                Image(systemName: "house.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1.0 : 0.5)
            .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Envive")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)

                Text("Turn Chores into Screen Time")
                    .font(.system(size: 18, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .tracking(0.3)
            }
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: 16) {
            benefitCard(
                icon: "checkmark.circle.fill",
                title: "For Parents",
                description: "Set up chores, approve tasks, manage screen time"
            )

            benefitCard(
                icon: "gamecontroller.fill",
                title: "For Kids",
                description: "Complete tasks, earn screen time, have fun"
            )

            benefitCard(
                icon: "heart.fill",
                title: "For Families",
                description: "Less arguing, more responsibility, better habits"
            )
        }
        .opacity(showContent ? 1.0 : 0)
    }

    private func benefitCard(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 52, height: 52)

                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.2)

                Text(description)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.12))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }

    // MARK: - Privacy Section

    private var privacySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("Your Privacy & Security")
                    .font(.system(size: 19, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.2)
            }

            VStack(alignment: .leading, spacing: 14) {
                privacyPoint(icon: "lock.fill", text: "Your data stays on your device")
                privacyPoint(icon: "hand.raised.fill", text: "We don't sell your information")
                privacyPoint(icon: "checkmark.seal.fill", text: "COPPA compliant for kids under 13")
                privacyPoint(icon: "arrow.up.forward.app.fill", text: "Secure Apple authentication")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.1))
            )

            // Simple agreement checkbox
            Button(action: {
                privacyAccepted.toggle()
            }) {
                HStack(spacing: 14) {
                    Image(systemName: privacyAccepted ? "checkmark.square.fill" : "square")
                        .font(.system(size: 26, weight: .medium))
                        .foregroundColor(privacyAccepted ? .green : .white.opacity(0.7))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("I agree to the Privacy Policy and Terms of Service")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)

                        Button(action: {
                            showingPrivacyDetails = true
                        }) {
                            Text("Read full policy →")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .underline()
                        }
                    }

                    Spacer()
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.15))
            )

            Text("Version 1.0 • Last updated December 2024")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.55))
        }
        .sheet(isPresented: $showingPrivacyDetails) {
            PrivacyPolicyDetailView()
        }
    }

    private func privacyPoint(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .frame(width: 22)

            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Parent button
            Button(action: {
                if privacyAccepted {
                    recordConsent(isParent: true)
                    onParentContinue()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 19, weight: .semibold))
                    Text("I'm a Parent")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .tracking(0.3)
                }
                .foregroundColor(privacyAccepted ? Color.blue.opacity(0.9) : Color.gray.opacity(0.6))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(privacyAccepted ? 0.2 : 0.08), radius: 12, x: 0, y: 6)
            }
            .disabled(!privacyAccepted)
            .opacity(privacyAccepted ? 1.0 : 0.6)

            // Child button
            Button(action: {
                if privacyAccepted {
                    recordConsent(isParent: false)
                    onChildContinue()
                }
            }) {
                HStack(spacing: 12) {
                    Image(systemName: "person.fill")
                        .font(.system(size: 19, weight: .semibold))
                    Text("I'm a Kid")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .tracking(0.3)
                }
                .foregroundColor(privacyAccepted ? .white : .white.opacity(0.4))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(privacyAccepted ? Color.white.opacity(0.25) : Color.white.opacity(0.08))
                )
            }
            .disabled(!privacyAccepted)
            .opacity(privacyAccepted ? 1.0 : 0.6)

            if !privacyAccepted {
                Text("Please accept the privacy policy to continue")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.top, 6)
            }
        }
    }

    // MARK: - Helper

    private func recordConsent(isParent: Bool) {
        // Save user role
        UserDefaults.standard.set(isParent ? "parent" : "child", forKey: "userRole")

        // Record consent in UserDefaults for now (will integrate with LegalConsentService)
        let consent = [
            "accepted": true,
            "timestamp": Date().timeIntervalSince1970,
            "version": "1.0",
            "isParent": isParent
        ] as [String : Any]
        UserDefaults.standard.set(consent, forKey: "privacyConsent")
    }
}

// MARK: - Privacy Policy Detail View

struct PrivacyPolicyDetailView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Group {
                        sectionHeader("Privacy Policy")
                        sectionText("Last Updated: December 2024")

                        sectionHeader("1. Information We Collect")
                        sectionText("Envive collects minimal information needed to provide our service:")
                        bulletPoint("Account information (email, name)")
                        bulletPoint("Task completion data")
                        bulletPoint("Screen time usage (stored locally on device)")
                        bulletPoint("Age information for COPPA compliance")

                        sectionHeader("2. How We Use Your Information")
                        sectionText("We use your information to:")
                        bulletPoint("Provide and improve our service")
                        bulletPoint("Manage task assignments and rewards")
                        bulletPoint("Enable family account features")
                        bulletPoint("Comply with legal obligations (COPPA)")

                        sectionHeader("3. Data Storage & Security")
                        bulletPoint("Screen time data stays on your device")
                        bulletPoint("Account data encrypted in transit")
                        bulletPoint("We use industry-standard security measures")
                        bulletPoint("We never sell your personal information")

                        sectionHeader("4. Children's Privacy (COPPA)")
                        sectionText("We comply with the Children's Online Privacy Protection Act:")
                        bulletPoint("Children under 13 require parental consent")
                        bulletPoint("We collect minimal information from children")
                        bulletPoint("Parents can review and delete child data")
                        bulletPoint("Parents control child account settings")

                        sectionHeader("5. Your Rights")
                        sectionText("You have the right to:")
                        bulletPoint("Access your personal information")
                        bulletPoint("Delete your account and data")
                        bulletPoint("Opt out of communications")
                        bulletPoint("Update your information")
                    }

                    Group {
                        sectionHeader("Terms of Service")

                        sectionHeader("1. Acceptance of Terms")
                        sectionText("By using Envive, you agree to these terms and our Privacy Policy.")

                        sectionHeader("2. Service Description")
                        sectionText("Envive is a family task management and screen time reward app. Parents set tasks, children complete them, and screen time is earned as a reward.")

                        sectionHeader("3. User Responsibilities")
                        bulletPoint("Provide accurate information")
                        bulletPoint("Keep account credentials secure")
                        bulletPoint("Use the service appropriately")
                        bulletPoint("Parents supervise children's use")

                        sectionHeader("4. Limitations")
                        sectionText("Envive is provided 'as is' without warranties. We are not liable for any damages arising from use of the service.")

                        sectionHeader("5. Contact Us")
                        sectionText("Questions about privacy or terms?")
                        sectionText("Email: privacy@envive.app")
                    }
                }
                .padding(20)
            }
            .navigationTitle("Privacy & Terms")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 18, weight: .bold))
            .padding(.top, 8)
    }

    private func sectionText(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 15))
            .foregroundColor(.secondary)
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: 15))
            Text(text)
                .font(.system(size: 15))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
