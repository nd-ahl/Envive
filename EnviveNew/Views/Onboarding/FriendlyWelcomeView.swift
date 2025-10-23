//
//  FriendlyWelcomeView.swift
//  EnviveNew
//
//  Friendly welcome screen without legal terms
//

import SwiftUI

struct FriendlyWelcomeView: View {
    let onContinue: () -> Void

    @State private var showContent = false

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

            VStack(spacing: 40) {
                Spacer()

                // Logo and title
                logoSection

                // What it does (3 simple points)
                benefitsSection

                Spacer()

                // Continue button
                continueButton
                    .padding(.bottom, 60)
            }
            .padding(.horizontal, 32)
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
            // App icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "house.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1.0 : 0.5)
            .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Envive")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Helping Families Build Better Habits")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white.opacity(0.95))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: 16) {
            benefitRow(
                icon: "checkmark.circle.fill",
                title: "Parents Assign Tasks",
                subtitle: "Set up chores and approve when they're done"
            )

            benefitRow(
                icon: "star.fill",
                title: "Kids Earn Screen Time",
                subtitle: "Complete tasks to unlock time on their device"
            )

            benefitRow(
                icon: "chart.line.uptrend.xyaxis",
                title: "Everyone Benefits",
                subtitle: "Build responsibility and reduce screen time battles"
            )
        }
        .opacity(showContent ? 1.0 : 0)
    }

    private func benefitRow(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundColor(.white)
                .frame(width: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Get Started")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(Color.blue.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(Color.white)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
        }
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0)
    }
}
