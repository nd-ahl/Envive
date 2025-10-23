import SwiftUI

// MARK: - Forgot Password View

/// Screen for users to reset their password via email
struct ForgotPasswordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var authService = AuthenticationService.shared

    @State private var email = ""
    @State private var isLoading = false
    @State private var showSuccess = false
    @State private var errorMessage: String?
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

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.trailing, 20)
                    .padding(.top, 20)
                }

                Spacer()

                if showSuccess {
                    // Success state
                    successView
                } else {
                    // Input state
                    inputView
                }

                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }

    // MARK: - Input View

    private var inputView: some View {
        VStack(spacing: 40) {
            // Header
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 90, height: 90)
                        .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)

                    Image(systemName: "lock.rotation")
                        .font(.system(size: 44, weight: .medium))
                        .foregroundColor(.white)
                }
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

                VStack(spacing: 14) {
                    Text("Forgot Password?")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .tracking(0.5)
                        .opacity(showContent ? 1.0 : 0)

                    Text("Enter your email and we'll send you a secure link to reset your password")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(2)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(showContent ? 1.0 : 0)
                }
            }

            // Email input
            VStack(spacing: 24) {
                TextField("", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                    )
                    .placeholder(when: email.isEmpty) {
                        Text("Email Address")
                            .foregroundColor(Color(UIColor.placeholderText))
                            .padding(.leading, 18)
                    }
                    .font(.system(size: 16, weight: .regular))
                    .opacity(showContent ? 1.0 : 0)

                // Error message
                if let error = errorMessage {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.95))
                    )
                }

                // Send Reset Link button
                Button(action: handlePasswordReset) {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        } else {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 18, weight: .semibold))
                            Text("Send Reset Link")
                                .font(.system(size: 18, weight: .semibold, design: .rounded))
                                .tracking(0.3)
                        }
                    }
                    .foregroundColor(email.isEmpty ? .gray.opacity(0.5) : .blue.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(email.isEmpty ? 0.08 : 0.2), radius: 12, x: 0, y: 6)
                }
                .disabled(isLoading || email.isEmpty)
                .opacity(email.isEmpty ? 0.6 : 1.0)
                .scaleEffect(showContent ? 1.0 : 0.9)
                .opacity(showContent ? 1.0 : 0)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 36) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)

                Image(systemName: "envelope.badge.fill")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundColor(.white)
                    .symbolRenderingMode(.hierarchical)
            }
            .scaleEffect(showContent ? 1.0 : 0.5)

            VStack(spacing: 18) {
                Text("Check Your Email")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(0.5)

                VStack(spacing: 12) {
                    Text("We've sent a password reset link to:")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(2)

                    Text(email)
                        .font(.system(size: 17, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.white.opacity(0.2))
                        )
                }
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "1.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                        Text("Check your email inbox")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "2.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                        Text("Click the reset link")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    HStack(spacing: 8) {
                        Image(systemName: "3.circle.fill")
                            .foregroundColor(.white.opacity(0.8))
                        Text("Create your new password")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.top, 12)
            }

            // Done button
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .tracking(0.3)
                    .foregroundColor(.blue.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(Color.white)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.2), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, 32)
            .padding(.top, 24)
        }
    }

    // MARK: - Actions

    private func handlePasswordReset() {
        guard !email.isEmpty else { return }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                try await authService.resetPassword(email: email)

                await MainActor.run {
                    isLoading = false
                    withAnimation {
                        showSuccess = true
                    }
                    print("✅ Password reset email sent to: \(email)")
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to send reset email. Please check your email address."
                    print("❌ Password reset failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Preview

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        ForgotPasswordView()
    }
}
