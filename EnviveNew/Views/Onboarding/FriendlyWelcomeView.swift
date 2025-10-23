//
//  FriendlyWelcomeView.swift
//  EnviveNew
//
//  Modern, professional welcome screen with polished design
//

import SwiftUI

struct FriendlyWelcomeView: View {
    let onContinue: () -> Void

    @State private var showContent = false
    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        ZStack {
            // Modern gradient background with subtle sophistication
            LinearGradient(
                colors: gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Top spacing
                    Spacer()
                        .frame(height: 80)

                    // Logo and title
                    logoSection
                        .padding(.bottom, 60)

                    // Benefits cards
                    benefitsSection
                        .padding(.bottom, 40)

                    // Continue button
                    continueButton
                        .padding(.bottom, 50)
                }
                .padding(.horizontal, 28)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Gradient Colors

    private var gradientColors: [Color] {
        [
            Color(red: 0.4, green: 0.5, blue: 0.95),  // Refined blue
            Color(red: 0.55, green: 0.35, blue: 0.85)  // Elegant purple
        ]
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: 28) {
            // App icon with modern styling
            ZStack {
                // Outer glow
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 140, height: 140)
                    .blur(radius: 20)

                // Main circle
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 110, height: 110)
                    .overlay(
                        Circle()
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )

                // Icon
                Image(systemName: "house.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1.0 : 0.3)
            .opacity(showContent ? 1.0 : 0)

            // Title and tagline
            VStack(spacing: 16) {
                Text("Envive")
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)

                Text("Helping Families Build Better Habits")
                    .font(.system(size: 19, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 20)
            }
            .scaleEffect(showContent ? 1.0 : 0.85)
            .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: 20) {
            benefitCard(
                icon: "checkmark.seal.fill",
                title: "Parents Assign Tasks",
                subtitle: "Set up chores and responsibilities with ease",
                delay: 0.1
            )

            benefitCard(
                icon: "sparkles",
                title: "Kids Earn Screen Time",
                subtitle: "Complete tasks to unlock device time",
                delay: 0.2
            )

            benefitCard(
                icon: "chart.line.uptrend.xyaxis",
                title: "Everyone Benefits",
                subtitle: "Build responsibility without the battles",
                delay: 0.3
            )
        }
    }

    private func benefitCard(icon: String, title: String, subtitle: String, delay: Double) -> some View {
        HStack(spacing: 20) {
            // Icon container
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 56, height: 56)

                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.2)

                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(delay), value: showContent)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: onContinue) {
            HStack(spacing: 12) {
                Text("Get Started")
                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                    .tracking(0.3)

                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.95))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: 10)
            )
        }
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: showContent)
    }
}

// MARK: - Preview

struct FriendlyWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FriendlyWelcomeView(onContinue: {})
                .preferredColorScheme(.light)

            FriendlyWelcomeView(onContinue: {})
                .preferredColorScheme(.dark)
        }
    }
}
