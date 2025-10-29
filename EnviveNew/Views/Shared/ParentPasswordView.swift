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
        Task {
            do {
                try await passwordManager.setPassword(password)
                await MainActor.run {
                    passwordManager.isUnlocked = true
                    onSuccess()
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Change Password View

/// View for parents to change the app restriction password
/// This password is synced across all household devices
struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var passwordManager = ParentPasswordManager.shared

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    @State private var isChanging: Bool = false

    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    // Lock Icon
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text("App Restriction Password")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Change the password used to manage app restrictions on all household devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .listRowBackground(Color.clear)

            if passwordManager.isPasswordSet {
                Section {
                    SecureField("Current Password", text: $currentPassword)
                        .textContentType(.password)
                } header: {
                    Text("Current Password")
                }
            }

            Section {
                SecureField("New Password", text: $newPassword)
                    .textContentType(.newPassword)

                SecureField("Confirm New Password", text: $confirmPassword)
                    .textContentType(.newPassword)
            } header: {
                Text("New Password")
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    requirementRow(
                        text: "At least 4 characters",
                        isMet: newPassword.count >= 4
                    )
                    requirementRow(
                        text: "Passwords match",
                        isMet: !newPassword.isEmpty && newPassword == confirmPassword
                    )
                }
                .padding(.top, 8)
            }

            if showError {
                Section {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.subheadline)
                }
            }

            if showSuccess {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Password updated and synced to all devices")
                            .foregroundColor(.green)
                            .font(.subheadline)
                    }
                }
            }

            Section {
                Button(action: changePassword) {
                    HStack {
                        if isChanging {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(isChanging ? "Updating..." : (passwordManager.isPasswordSet ? "Change Password" : "Set Password"))
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .disabled(!isFormValid || isChanging)
            }
        }
        .navigationTitle("Password Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        let passwordsValid = newPassword.count >= 4 && newPassword == confirmPassword

        if passwordManager.isPasswordSet {
            return !currentPassword.isEmpty && passwordsValid
        } else {
            return passwordsValid
        }
    }

    private func requirementRow(text: String, isMet: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isMet ? .green : .gray)
                .font(.caption)
            Text(text)
                .font(.caption)
                .foregroundColor(isMet ? .primary : .secondary)
        }
    }

    private func changePassword() {
        showError = false
        showSuccess = false
        isChanging = true

        Task {
            do {
                // Verify current password if one is set
                if passwordManager.isPasswordSet {
                    guard passwordManager.verifyPassword(currentPassword) else {
                        await MainActor.run {
                            showError = true
                            errorMessage = "Current password is incorrect"
                            isChanging = false
                            currentPassword = ""
                        }
                        return
                    }
                }

                // Set new password (will sync to Supabase)
                try await passwordManager.setPassword(newPassword)

                await MainActor.run {
                    showSuccess = true
                    isChanging = false
                    currentPassword = ""
                    newPassword = ""
                    confirmPassword = ""

                    // Dismiss after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                    isChanging = false
                }
            }
        }
    }
}

// MARK: - Preview

struct ParentPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ParentPasswordView(onSuccess: {})
            ParentPasswordSetupView(onSuccess: {})
            NavigationView {
                ChangePasswordView()
            }
        }
    }
}
