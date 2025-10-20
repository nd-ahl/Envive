import SwiftUI

// MARK: - Benefits View

/// Final onboarding screen showing role-specific benefits and statistics
struct BenefitsView: View {
    let userRole: UserRole
    let onComplete: () -> Void

    @State private var showContent = false
    @State private var animateBenefits = false
    @State private var showPaymentPlan = false

    var body: some View {
        ZStack {
            // Gradient background (consistent theme)
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.6),
                    Color.blue.opacity(0.7)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Content
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Statistics
                    statisticsSection

                    // Benefits
                    benefitsSection

                    // Call to action
                    callToActionSection
                }
                .padding(.horizontal, 32)

                Spacer()

                // High five button
                highFiveButton
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.3)) {
                animateBenefits = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Icon
            Text(userRole == .parent ? "👨‍👩‍👧‍👦" : "🎮")
                .font(.system(size: 70))
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text(userRole == .parent ? "What Envive Does for Your Family" : "What Envive Does for You")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text(userRole == .parent ? "Transform screen time battles into positive habits" : "Earn more screen time by helping out at home")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
            }
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        HStack(spacing: 16) {
            if userRole == .parent {
                StatBox(
                    number: "87%",
                    label: "Less arguing",
                    icon: "checkmark.circle.fill"
                )

                StatBox(
                    number: "2.5x",
                    label: "More chores done",
                    icon: "chart.line.uptrend.xyaxis"
                )
            } else {
                StatBox(
                    number: "+45min",
                    label: "Avg. earned time",
                    icon: "clock.fill"
                )

                StatBox(
                    number: "93%",
                    label: "Kids love it",
                    icon: "star.fill"
                )
            }
        }
        .opacity(animateBenefits ? 1.0 : 0)
        .offset(y: animateBenefits ? 0 : 20)
    }

    // MARK: - Benefits Section

    private var benefitsSection: some View {
        VStack(spacing: 12) {
            if userRole == .parent {
                BenefitRow(
                    icon: "checkmark.shield.fill",
                    text: "Set healthy screen time limits effortlessly"
                )

                BenefitRow(
                    icon: "trophy.fill",
                    text: "Motivate kids with rewards they actually want"
                )

                BenefitRow(
                    icon: "chart.bar.fill",
                    text: "Track progress and build lasting habits"
                )
            } else {
                BenefitRow(
                    icon: "gamecontroller.fill",
                    text: "Earn extra screen time by completing tasks"
                )

                BenefitRow(
                    icon: "star.fill",
                    text: "Level up and unlock special rewards"
                )

                BenefitRow(
                    icon: "heart.fill",
                    text: "Make your parents proud while having fun"
                )
            }
        }
        .opacity(animateBenefits ? 1.0 : 0)
        .offset(y: animateBenefits ? 0 : 20)
    }

    // MARK: - Call to Action Section

    private var callToActionSection: some View {
        Text("Let's do this, high five!")
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(.white.opacity(0.8))
            .opacity(animateBenefits ? 1.0 : 0)
    }

    // MARK: - High Five Button

    private var highFiveButton: some View {
        Button(action: {
            handleLetsDoThis()
        }) {
            HStack(spacing: 10) {
                Text("🙌")
                    .font(.system(size: 22))
                Text("Let's Do This")
                    .font(.system(size: 18, weight: .bold))
            }
            .foregroundColor(Color.blue.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .scaleEffect(animateBenefits ? 1.0 : 0.9)
        .opacity(animateBenefits ? 1.0 : 0)
        .padding(.horizontal, 32)
        .fullScreenCover(isPresented: $showPaymentPlan, onDismiss: {
            // After payment plan is dismissed, complete onboarding
            onComplete()
        }) {
            PaymentPlanView()
        }
    }

    // MARK: - Actions

    private func handleLetsDoThis() {
        if userRole == .parent {
            // Parents see payment plan
            showPaymentPlan = true
        } else {
            // Children get free access - skip payment
            print("👶 Child user - skipping payment, free access granted")
            onComplete()
        }
    }
}

// MARK: - Stat Box Component

private struct StatBox: View {
    let number: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.white)

            Text(number)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
    }
}

// MARK: - Benefit Row Component

private struct BenefitRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.green)
                .frame(width: 28)

            Text(text)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Preview

struct BenefitsView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            BenefitsView(userRole: .parent, onComplete: {})
            BenefitsView(userRole: .child, onComplete: {})
        }
    }
}
