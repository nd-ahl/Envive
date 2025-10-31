//
//  EmailVerificationView.swift
//  EnviveNew
//
//  Email verification instructions screen shown after sign-up
//

import SwiftUI

struct EmailVerificationView: View {
    let email: String
    let onComplete: () -> Void

    @State private var showContent = false
    @State private var isResending = false
    @State private var showResendSuccess = false
    @Environment(\.dismiss) var dismiss

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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    Spacer()
                        .frame(height: 80)

                    // Icon and title
                    headerSection
                        .padding(.bottom, 40)

                    // Instructions
                    instructionsSection
                        .padding(.bottom, 40)

                    // Action buttons
                    actionsSection
                        .padding(.bottom, 50)
                }
                .padding(.horizontal, 32)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.75).delay(0.1)) {
                showContent = true
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EmailConfirmed"))) { _ in
            // Email was confirmed via deep link - automatically dismiss this view
            print("📧 Email confirmed via deep link - auto-dismissing verification screen")
            dismiss()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 24) {
            // Email icon with animation
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
                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(showContent ? 1.0 : 0.3)
            .opacity(showContent ? 1.0 : 0)

            // Title
            VStack(spacing: 16) {
                Text("Check Your Email")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)
                    .multilineTextAlignment(.center)

                Text("We sent a confirmation link to:")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .multilineTextAlignment(.center)

                Text(email)
                    .font(.system(size: 16, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.2))
                    )
            }
            .scaleEffect(showContent ? 1.0 : 0.85)
            .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        VStack(spacing: 20) {
            instructionStep(
                number: "1",
                title: "Open Your Email",
                description: "Check your inbox (and spam folder) for an email from Envive",
                delay: 0.1
            )

            instructionStep(
                number: "2",
                title: "Click the Link",
                description: "Click the confirmation link in the email to verify your account",
                delay: 0.2
            )

            instructionStep(
                number: "3",
                title: "You're All Set!",
                description: "Once confirmed, you'll be automatically signed in and can continue",
                delay: 0.3
            )
        }
    }

    private func instructionStep(number: String, title: String, description: String, delay: Double) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Step number
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 40, height: 40)

                Text(number)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.2)

                Text(description)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.75).delay(delay), value: showContent)
    }

    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(spacing: 16) {
            // Resend confirmation button
            Button(action: resendConfirmationEmail) {
                HStack {
                    if isResending {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue.opacity(0.9)))
                    } else {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Resend Confirmation Email")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .tracking(0.3)
                    }
                }
                .foregroundColor(.blue.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
            }
            .disabled(isResending)
            .opacity(showContent ? 1.0 : 0)
            .scaleEffect(showContent ? 1.0 : 0.9)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.4), value: showContent)

            // Success message
            if showResendSuccess {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Email sent! Check your inbox.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.2))
                )
                .transition(.scale.combined(with: .opacity))
            }

            // Continue to sign in
            Button(action: onComplete) {
                HStack(spacing: 10) {
                    Text("I've Confirmed My Email")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .tracking(0.2)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white.opacity(0.2))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .opacity(showContent ? 1.0 : 0)
            .animation(.spring(response: 0.6, dampingFraction: 0.7).delay(0.5), value: showContent)
        }
    }

    // MARK: - Actions

    private func resendConfirmationEmail() {
        isResending = true
        showResendSuccess = false

        Task {
            do {
                // Resend confirmation email via Supabase
                try await AuthenticationService.shared.resendConfirmationEmail(email: email)

                await MainActor.run {
                    isResending = false
                    withAnimation {
                        showResendSuccess = true
                    }

                    // Hide success message after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        withAnimation {
                            showResendSuccess = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isResending = false
                    print("❌ Failed to resend confirmation email: \(error)")
                }
            }
        }
    }
}

// MARK: - Preview

struct EmailVerificationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            EmailVerificationView(
                email: "user@example.com",
                onComplete: {}
            )
            .preferredColorScheme(.light)

            EmailVerificationView(
                email: "user@example.com",
                onComplete: {}
            )
            .preferredColorScheme(.dark)
        }
    }
}
