//
//  PasswordResetConfirmationView.swift
//  EnviveNew
//
//  Password reset confirmation screen shown after clicking reset link
//

import SwiftUI
import Supabase
import Auth

struct PasswordResetConfirmationView: View {
    let onComplete: () -> Void

    @StateObject private var authService = AuthenticationService.shared
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false
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

            ScrollView {
                VStack(spacing: 30) {
                    Spacer()
                        .frame(height: 60)

                    // Header
                    VStack(spacing: 18) {
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

                        VStack(spacing: 12) {
                            Text("Reset Your Password")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .tracking(0.5)

                            Text("Enter your new password below")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        .opacity(showContent ? 1.0 : 0)
                    }
                    .padding(.bottom, 20)

                    // Form
                    VStack(spacing: 20) {
                        // Password field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("New Password")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))

                            HStack(spacing: 12) {
                                if showPassword {
                                    TextField("Enter new password", text: $password)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        .foregroundColor(.primary)
                                } else {
                                    SecureField("Enter new password", text: $password)
                                        .textContentType(.newPassword)
                                        .foregroundColor(.primary)
                                }

                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                            )
                        }

                        // Confirm password field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Confirm New Password")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))

                            HStack(spacing: 12) {
                                if showConfirmPassword {
                                    TextField("Confirm new password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                        .foregroundColor(.primary)
                                } else {
                                    SecureField("Confirm new password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .foregroundColor(.primary)
                                }

                                Button(action: {
                                    showConfirmPassword.toggle()
                                }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.gray)
                                        .font(.system(size: 16))
                                }
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(UIColor.systemBackground))
                                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                            )
                        }

                        // Password requirements
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Password Requirements:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))

                            RequirementRow(text: "At least 6 characters", met: password.count >= 6)
                            RequirementRow(text: "Passwords match", met: !password.isEmpty && password == confirmPassword)
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.15))
                        )
                    }
                    .padding(.horizontal, 28)
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
                        .padding(.horizontal, 28)
                    }

                    Spacer()
                        .frame(height: 20)

                    // Reset Password button
                    Button(action: handleResetPassword) {
                        HStack(spacing: 12) {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            } else {
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Reset Password")
                                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                                    .tracking(0.3)
                            }
                        }
                        .foregroundColor(isFormValid ? .blue.opacity(0.9) : .gray.opacity(0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                        .background(Color.white)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(isFormValid ? 0.2 : 0.08), radius: 12, x: 0, y: 6)
                    }
                    .disabled(!isFormValid || isLoading)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 28)
                    .scaleEffect(showContent ? 1.0 : 0.9)
                    .opacity(showContent ? 1.0 : 0)

                    Spacer()
                        .frame(height: 40)
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        password.count >= 6 && password == confirmPassword
    }

    // MARK: - Actions

    private func handleResetPassword() {
        guard isFormValid else { return }

        errorMessage = nil
        isLoading = true

        Task {
            do {
                // Update password using Supabase Auth
                let supabase = SupabaseService.shared.client
                try await supabase.auth.update(user: .init(password: password))

                print("✅ Password reset successfully")

                await MainActor.run {
                    isLoading = false
                    // Show success and complete
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to reset password. Please try again."
                    print("❌ Password reset failed: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Preview

struct PasswordResetConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordResetConfirmationView(onComplete: {})
    }
}
