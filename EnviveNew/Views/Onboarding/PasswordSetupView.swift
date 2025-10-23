//
//  PasswordSetupView.swift
//  EnviveNew
//
//  First-time password setup for new users
//

import SwiftUI
import Supabase
import Auth

struct PasswordSetupView: View {
    let userEmail: String
    let onComplete: () -> Void

    @StateObject private var authService = AuthenticationService.shared
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showPassword = false
    @State private var showConfirmPassword = false

    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.4, green: 0.5, blue: 0.95),
                    Color(red: 0.55, green: 0.35, blue: 0.85)
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
                    VStack(spacing: 16) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.white)

                        Text("Create Your Password")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Set up a secure password to protect your account and manage app restrictions")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    .padding(.bottom, 20)

                    // Form
                    VStack(spacing: 20) {
                        // Password field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("New Password")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))

                            HStack {
                                if showPassword {
                                    TextField("Enter password", text: $password)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                } else {
                                    SecureField("Enter password", text: $password)
                                        .textContentType(.newPassword)
                                }

                                Button(action: {
                                    showPassword.toggle()
                                }) {
                                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }

                        // Confirm password field
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Confirm Password")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))

                            HStack {
                                if showConfirmPassword {
                                    TextField("Confirm password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                        .autocapitalization(.none)
                                } else {
                                    SecureField("Confirm password", text: $confirmPassword)
                                        .textContentType(.newPassword)
                                }

                                Button(action: {
                                    showConfirmPassword.toggle()
                                }) {
                                    Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                        .foregroundColor(.white.opacity(0.7))
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.2))
                            .cornerRadius(12)
                        }

                        // Password requirements
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password Requirements:")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))

                            RequirementRow(text: "At least 6 characters", met: password.count >= 6)
                            RequirementRow(text: "Passwords match", met: !password.isEmpty && password == confirmPassword)
                        }
                        .padding()
                        .background(Color.white.opacity(0.15))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 28)

                    // Error message
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.white.opacity(0.9))
                            .cornerRadius(10)
                            .padding(.horizontal, 28)
                    }

                    Spacer()

                    // Continue button
                    Button(action: handleSetPassword) {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.45, green: 0.5, blue: 0.95)))
                            } else {
                                Text("Set Password")
                                    .font(.system(size: 19, weight: .semibold, design: .rounded))
                            }
                        }
                        .foregroundColor(Color(red: 0.45, green: 0.5, blue: 0.95))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                        )
                    }
                    .disabled(!isFormValid || isLoading)
                    .opacity(isFormValid ? 1.0 : 0.6)
                    .padding(.horizontal, 28)
                    .padding(.bottom, 40)
                }
            }
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        password.count >= 6 && password == confirmPassword
    }

    // MARK: - Actions

    private func handleSetPassword() {
        errorMessage = nil
        isLoading = true

        Task {
            do {
                // Update user password in Supabase
                let supabase = SupabaseService.shared.client
                try await supabase.auth.update(user: .init(password: password))

                print("✅ Password set successfully for user: \(userEmail)")

                // Mark that password has been set
                UserDefaults.standard.set(true, forKey: "hasSetPassword_\(userEmail)")

                await MainActor.run {
                    isLoading = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to set password: \(error.localizedDescription)"
                    print("❌ Password setup failed: \(error)")
                }
            }
        }
    }
}

// MARK: - Requirement Row

struct RequirementRow: View {
    let text: String
    let met: Bool

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .foregroundColor(met ? .green : .white.opacity(0.5))
                .font(.system(size: 14))

            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.white.opacity(0.85))

            Spacer()
        }
    }
}

// MARK: - Preview

struct PasswordSetupView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordSetupView(userEmail: "user@example.com", onComplete: {})
    }
}
