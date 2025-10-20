import SwiftUI

// MARK: - Payment Plan View

/// Premium subscription payment plan screen with sleek design
struct PaymentPlanView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var showContent = false

    var body: some View {
        ZStack {
            // Dark gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.1),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 0) {
                    // Header
                    headerSection
                        .padding(.top, 60)
                        .padding(.horizontal, 24)

                    // Benefits Timeline
                    benefitsTimeline
                        .padding(.vertical, 40)
                        .padding(.horizontal, 24)

                    // Pricing Options
                    pricingSection
                        .padding(.horizontal, 24)

                    // CTA Button
                    ctaButton
                        .padding(.horizontal, 24)
                        .padding(.top, 32)

                    // No payment due text
                    noPaymentText
                        .padding(.top, 16)
                        .padding(.bottom, 40)
                }
            }

            // Close button
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 32, height: 32)
                            .background(Color.white.opacity(0.2))
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 24)
                    .padding(.top, 16)
                }
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Text("Unlock Envive Family")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("Manage your family's screen time and build healthy habits together")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .opacity(showContent ? 1.0 : 0)
        .offset(y: showContent ? 0 : -20)
    }

    // MARK: - Benefits Timeline

    private var benefitsTimeline: some View {
        VStack(spacing: 0) {
            BenefitTimelineRow(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                title: "Get Started Instantly",
                subtitle: "Set up your family dashboard in minutes",
                isCompleted: true,
                showLine: true
            )

            BenefitTimelineRow(
                icon: "lock.fill",
                iconColor: .white.opacity(0.8),
                title: "Today: Full Family Access",
                subtitle: "Unlimited children accounts, tasks, rewards, and analytics",
                isCompleted: false,
                showLine: true
            )

            BenefitTimelineRow(
                icon: "bell.fill",
                iconColor: .white.opacity(0.8),
                title: "Day 5: See Real Progress",
                subtitle: "Track improvements in productivity and screen time habits",
                isCompleted: false,
                showLine: true
            )

            BenefitTimelineRow(
                icon: "star.fill",
                iconColor: .white.opacity(0.8),
                title: "Day 7: Trial Ends",
                subtitle: "Your subscription starts on day 7. Cancel anytime within 24hrs",
                isCompleted: false,
                showLine: false
            )
        }
        .opacity(showContent ? 1.0 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    // MARK: - Pricing Section

    private var pricingSection: some View {
        VStack(spacing: 16) {
            // Yearly Plan (Recommended)
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedPlan = .yearly
                }
            }) {
                PricingCard(
                    plan: .yearly,
                    isSelected: selectedPlan == .yearly,
                    badge: "60% OFF",
                    title: "Yearly",
                    price: "$49.99",
                    perWeek: "only $0.96/week",
                    trial: "Free for 7 days"
                )
            }

            // Monthly Plan
            Button(action: {
                withAnimation(.spring(response: 0.3)) {
                    selectedPlan = .monthly
                }
            }) {
                PricingCard(
                    plan: .monthly,
                    isSelected: selectedPlan == .monthly,
                    badge: nil,
                    title: "Monthly",
                    price: "$4.99",
                    perWeek: "$4.99/month",
                    trial: "Free for 3 days"
                )
            }
        }
        .opacity(showContent ? 1.0 : 0)
        .scaleEffect(showContent ? 1.0 : 0.95)
    }

    // MARK: - CTA Button

    private var ctaButton: some View {
        Button(action: {
            handleStartTrial()
        }) {
            HStack(spacing: 10) {
                Text("Start Your Free Trial")
                    .font(.system(size: 18, weight: .bold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.48, blue: 1.0),
                        Color(red: 0.0, green: 0.4, blue: 0.9)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Color.blue.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .opacity(showContent ? 1.0 : 0)
        .scaleEffect(showContent ? 1.0 : 0.9)
    }

    // MARK: - No Payment Text

    private var noPaymentText: some View {
        VStack(spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.green)
                Text("No payment due now!")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Text("Children's access is always free")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Actions

    private func handleStartTrial() {
        print("🚀 Starting \(selectedPlan.rawValue) trial")
        // TODO: Implement payment flow
        dismiss()
    }
}

// MARK: - Benefit Timeline Row

private struct BenefitTimelineRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let isCompleted: Bool
    let showLine: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon column with connecting line
            VStack(spacing: 0) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(isCompleted ? 0.15 : 0.1))
                        .frame(width: 48, height: 48)

                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }

                // Connecting line
                if showLine {
                    Rectangle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 2, height: 60)
                }
            }

            // Text content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 6)

            Spacer()
        }
    }
}

// MARK: - Pricing Card

private struct PricingCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let badge: String?
    let title: String
    let price: String
    let perWeek: String
    let trial: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                // Left side - Plan info
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)

                    Text(price)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Right side - Pricing
                VStack(alignment: .trailing, spacing: 4) {
                    Text(perWeek)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.white)

                    Text(trial)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(20)
        }
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(isSelected ? 0.15 : 0.08))

                // Border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        isSelected ? Color.white.opacity(0.4) : Color.white.opacity(0.15),
                        lineWidth: isSelected ? 2 : 1
                    )
            }
        )
        .overlay(
            // Badge overlay
            Group {
                if let badge = badge {
                    VStack {
                        HStack {
                            Spacer()
                            Text(badge)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.orange)
                                .cornerRadius(8)
                                .offset(x: -8, y: -8)
                        }
                        Spacer()
                    }
                }
            }
        )
    }
}

// MARK: - Subscription Plan Enum

enum SubscriptionPlan: String {
    case yearly = "yearly"
    case monthly = "monthly"
}

// MARK: - Preview

struct PaymentPlanView_Previews: PreviewProvider {
    static var previews: some View {
        PaymentPlanView()
            .preferredColorScheme(.dark)
    }
}
