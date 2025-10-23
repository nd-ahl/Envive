import SwiftUI

// MARK: - Parent Password Authentication View

/// View for parent to unlock protected features with password
struct ParentPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var passwordManager = ParentPasswordManager.shared

    let onSuccess: () -> Void

    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isAuthenticating: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    Spacer()

                    // Lock Icon
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .padding(.bottom, 8)

                    // Title
                    Text("Parent Access Required")
                        .font(.title)
                        .fontWeight(.bold)

                    Text("Enter your password to manage app restrictions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Password Field
                    SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 40)
                        .textContentType(.password)
                        .submitLabel(.done)
                        .onSubmit {
                            verifyPassword()
                        }

                    if showError {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(.horizontal, 40)
                    }

                    // Verify Button
                    Button(action: verifyPassword) {
                        HStack {
                            if isAuthenticating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isAuthenticating ? "Verifying..." : "Unlock")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            password.isEmpty ? Color.gray : Color.blue
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(password.isEmpty || isAuthenticating)
                    .padding(.horizontal, 40)

                    // Note: Biometric authentication disabled for security
                    // A child may have their face registered on the device
                    Text("Password required for security")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func verifyPassword() {
        isAuthenticating = true
        showError = false

        // Small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if passwordManager.verifyPassword(password) {
                isAuthenticating = false
                onSuccess()
                dismiss()
            } else {
                isAuthenticating = false
                showError = true
                errorMessage = "Incorrect password. Please try again."
                password = ""

                // Shake animation
                withAnimation(.default) {
                    errorMessage = "Incorrect password. Please try again."
                }
            }
        }
    }
}

// MARK: - Parent Password Setup View

/// View for parent to set up their password for the first time
struct ParentPasswordSetupView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var passwordManager = ParentPasswordManager.shared

    let onSuccess: () -> Void

    @State private var password: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        Spacer(minLength: 40)

                        // Lock Icon
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .padding(.bottom, 8)

                        // Title
                        Text("Set Parent Password")
                            .font(.title)
                            .fontWeight(.bold)

                        Text("Create a password to protect parental controls. This password will be required to change app restrictions.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        // Password Fields
                        VStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Password")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                SecureField("Enter password", text: $password)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.newPassword)
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Confirm Password")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                SecureField("Re-enter password", text: $confirmPassword)
                                    .textFieldStyle(.roundedBorder)
                                    .textContentType(.newPassword)
                            }
                        }
                        .padding(.horizontal, 40)

                        // Password Requirements
                        VStack(alignment: .leading, spacing: 8) {
                            requirementRow(
                                text: "At least 4 characters",
                                isMet: password.count >= 4
                            )
                            requirementRow(
                                text: "Passwords match",
                                isMet: !password.isEmpty && password == confirmPassword
                            )
                        }
                        .padding(.horizontal, 40)

                        if showError {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal, 40)
                        }

                        // Set Password Button
                        Button(action: setPassword) {
                            Text("Set Password")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    isPasswordValid ? Color.blue : Color.gray
                                )
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .disabled(!isPasswordValid)
                        .padding(.horizontal, 40)
                        .padding(.top, 8)

                        Spacer()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private var isPasswordValid: Bool {
        password.count >= 4 && password == confirmPassword
    }

    private func requirementRow(text: String, isMet: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .primary : .secondary)
        }
    }

    private func setPassword() {
        do {
            try passwordManager.setPassword(password)
            passwordManager.isUnlocked = true
            onSuccess()
            dismiss()
        } catch {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Preview

struct ParentPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ParentPasswordView(onSuccess: {})
            ParentPasswordSetupView(onSuccess: {})
        }
    }
}
