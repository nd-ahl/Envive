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
            VStack(spacing: 20) {
                Text("🔒")
                    .font(.system(size: 70))
                    .scaleEffect(showContent ? 1.0 : 0.5)
                    .opacity(showContent ? 1.0 : 0)

                VStack(spacing: 12) {
                    Text("Forgot Password?")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(showContent ? 1.0 : 0)

                    Text("Enter your email and we'll send you a link to reset your password")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .opacity(showContent ? 1.0 : 0)
                }
            }

            // Email input
            VStack(spacing: 20) {
                TextField("", text: $email)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                    .padding()
                    .background(Color(UIColor.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .placeholder(when: email.isEmpty) {
                        Text("Email")
                            .foregroundColor(Color(UIColor.placeholderText))
                            .padding(.leading, 16)
                    }
                    .opacity(showContent ? 1.0 : 0)

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                }

                // Send Reset Link button
                Button(action: handlePasswordReset) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        } else {
                            Text("Send Reset Link")
                                .font(.system(size: 18, weight: .bold))
                        }
                    }
                    .foregroundColor(.blue.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
                }
                .disabled(isLoading || email.isEmpty)
                .opacity(email.isEmpty ? 0.5 : 1.0)
                .scaleEffect(showContent ? 1.0 : 0.9)
                .opacity(showContent ? 1.0 : 0)
            }
            .padding(.horizontal, 32)
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 30) {
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.green)
            }
            .scaleEffect(showContent ? 1.0 : 0.5)

            VStack(spacing: 16) {
                Text("Check Your Email")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text("We've sent a password reset link to:\n\(email)")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Text("Click the link in the email to reset your password")
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                    .padding(.top, 8)
            }

            // Done button
            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.blue.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            }
            .padding(.horizontal, 32)
            .padding(.top, 20)
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
