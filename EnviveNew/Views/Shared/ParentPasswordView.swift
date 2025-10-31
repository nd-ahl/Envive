import SwiftUI

// MARK: - Parent Password Authentication View

/// View for parent to unlock protected features with biometrics or password
struct ParentPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var passwordManager = ParentPasswordManager.shared
    @StateObject private var biometricService = BiometricAuthenticationService.shared

    let onSuccess: () -> Void

    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var isAuthenticating: Bool = false
    @State private var showPasswordField: Bool = false

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

                    Text(biometricService.isBiometricsAvailable
                         ? "Use \(biometricService.biometricType.displayName) or password to manage app restrictions"
                         : "Enter your password to manage app restrictions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)

                    // Biometric Authentication Button (Primary)
                    if biometricService.isBiometricsAvailable && !showPasswordField {
                        VStack(spacing: 16) {
                            Button(action: authenticateWithBiometrics) {
                                HStack {
                                    if isAuthenticating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: biometricService.biometricType.icon)
                                            .font(.title3)
                                    }
                                    Text(isAuthenticating ? "Authenticating..." : "Unlock with \(biometricService.biometricType.displayName)")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            .disabled(isAuthenticating)
                            .padding(.horizontal, 40)

                            Button("Use Password Instead") {
                                withAnimation {
                                    showPasswordField = true
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                    }

                    // Password Field (Fallback)
                    if showPasswordField || !biometricService.isBiometricsAvailable {
                        VStack(spacing: 16) {
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

                            if biometricService.isBiometricsAvailable {
                                Button("Use \(biometricService.biometricType.displayName) Instead") {
                                    withAnimation {
                                        showPasswordField = false
                                        password = ""
                                        showError = false
                                    }
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                        }
                    }

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
            .onAppear {
                // Automatically trigger biometric authentication if available
                if biometricService.isBiometricsAvailable && !showPasswordField {
                    // Small delay to let the view settle
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        authenticateWithBiometrics()
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func authenticateWithBiometrics() {
        isAuthenticating = true
        showError = false

        Task {
            let result = await biometricService.authenticateParent(
                reason: "Authenticate to manage app restrictions and screen time limits"
            )

            await MainActor.run {
                isAuthenticating = false

                switch result {
                case .success:
                    print("✅ Parent authenticated with biometrics")
                    onSuccess()
                    dismiss()

                case .failure(let error):
                    print("❌ Biometric authentication failed: \(error.localizedDescription)")
                    showError = true
                    errorMessage = error.localizedDescription

                    // If biometrics failed due to lockout or not enrolled, show password field
                    if case .lockout = error, !showPasswordField {
                        withAnimation {
                            showPasswordField = true
                        }
                    } else if case .notEnrolled = error, !showPasswordField {
                        withAnimation {
                            showPasswordField = true
                        }
                    }
                }
            }
        }
    }

    private func verifyPassword() {
        isAuthenticating = true
        showError = false

        // Small delay to show loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if passwordManager.verifyPassword(password) {
                isAuthenticating = false
                print("✅ Parent authenticated with password")
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
/// Parents can authenticate with biometrics instead of typing current password
struct ChangePasswordView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var passwordManager = ParentPasswordManager.shared
    @StateObject private var biometricService = BiometricAuthenticationService.shared

    @State private var currentPassword: String = ""
    @State private var newPassword: String = ""
    @State private var confirmPassword: String = ""
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var showSuccess: Bool = false
    @State private var isChanging: Bool = false
    @State private var biometricAuthVerified: Bool = false
    @State private var showCurrentPasswordField: Bool = false
    @State private var showForgotPassword: Bool = false

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
                    if biometricService.isBiometricsAvailable && !showCurrentPasswordField && !biometricAuthVerified {
                        VStack(spacing: 12) {
                            Button(action: authenticateWithBiometrics) {
                                HStack {
                                    Image(systemName: biometricService.biometricType.icon)
                                        .font(.title3)
                                    Text("Verify Identity with \(biometricService.biometricType.displayName)")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }

                            Button("Use Password Instead") {
                                withAnimation {
                                    showCurrentPasswordField = true
                                }
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                        }
                        .listRowBackground(Color.clear)
                    } else if !biometricAuthVerified {
                        SecureField("Current Password", text: $currentPassword)
                            .textContentType(.password)
                    } else {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Identity Verified")
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                    }
                } header: {
                    Text(biometricAuthVerified ? "Verification Status" : "Current Verification")
                } footer: {
                    if !biometricAuthVerified {
                        VStack(alignment: .leading, spacing: 8) {
                            if biometricService.isBiometricsAvailable && !showCurrentPasswordField {
                                Text("Use \(biometricService.biometricType.displayName) to verify your identity before changing the password")
                            } else if showCurrentPasswordField {
                                Text("Enter your current password to verify your identity")
                            }

                            Button("Forgot Password?") {
                                showForgotPassword = true
                            }
                            .font(.subheadline)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                        }
                    }
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
        .sheet(isPresented: $showForgotPassword) {
            BiometricPasswordResetView()
        }
    }

    // MARK: - Helpers

    private var isFormValid: Bool {
        let passwordsValid = newPassword.count >= 4 && newPassword == confirmPassword

        if passwordManager.isPasswordSet {
            // Either biometric auth verified OR password entered
            return (biometricAuthVerified || !currentPassword.isEmpty) && passwordsValid
        } else {
            return passwordsValid
        }
    }

    private func authenticateWithBiometrics() {
        showError = false

        Task {
            let result = await biometricService.authenticateParent(
                reason: "Verify your identity to change the app restriction password"
            )

            await MainActor.run {
                switch result {
                case .success:
                    print("✅ Parent identity verified with biometrics for password change")
                    biometricAuthVerified = true
                    showError = false

                case .failure(let error):
                    print("❌ Biometric authentication failed: \(error.localizedDescription)")
                    showError = true
                    errorMessage = error.localizedDescription

                    // If biometrics failed, offer password fallback
                    if case .lockout = error, !showCurrentPasswordField {
                        withAnimation {
                            showCurrentPasswordField = true
                        }
                    }
                }
            }
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
                // Verify current identity if password is already set
                if passwordManager.isPasswordSet {
                    // Check if verified with biometrics
                    if biometricAuthVerified {
                        print("✅ Identity already verified with biometrics - proceeding with password change")
                    } else {
                        // Verify with password (without triggering unlock to prevent navigation)
                        guard passwordManager.verifyPasswordOnly(currentPassword) else {
                            await MainActor.run {
                                showError = true
                                errorMessage = "Current password is incorrect"
                                isChanging = false
                                currentPassword = ""
                            }
                            return
                        }
                        print("✅ Identity verified with password - proceeding with password change")
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
                    biometricAuthVerified = false

                    print("✅ Password changed successfully")

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

// MARK: - Biometric Password Reset View

/// View for resetting password using biometric authentication
/// No email required - uses Face ID/Touch ID to verify parent identity
struct BiometricPasswordResetView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var passwordManager = ParentPasswordManager.shared
    @StateObject private var biometricService = BiometricAuthenticationService.shared

    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isResetting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var biometricVerified = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: biometricService.isBiometricsAvailable ? biometricService.biometricType.icon : "key.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Reset Password")
                            .font(.title2)
                            .fontWeight(.bold)

                        if biometricService.isBiometricsAvailable {
                            Text("Use \(biometricService.biometricType.displayName) to verify your identity and reset your password")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        } else {
                            Text("Biometric authentication is required to reset your password")
                                .font(.subheadline)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                if biometricService.isBiometricsAvailable {
                    if !biometricVerified {
                        Section {
                            Button(action: authenticateWithBiometrics) {
                                HStack {
                                    Image(systemName: biometricService.biometricType.icon)
                                        .font(.title3)
                                    Text("Verify Identity with \(biometricService.biometricType.displayName)")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                        } header: {
                            Text("Step 1: Verify Identity")
                        } footer: {
                            Text("Authenticate with \(biometricService.biometricType.displayName) to confirm you are the parent")
                        }
                        .listRowBackground(Color.clear)
                    } else {
                        Section {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Identity Verified")
                                    .foregroundColor(.green)
                                    .fontWeight(.semibold)
                            }
                        } header: {
                            Text("Verification Status")
                        }

                        Section {
                            SecureField("New Password", text: $newPassword)
                                .textContentType(.newPassword)

                            SecureField("Confirm New Password", text: $confirmPassword)
                                .textContentType(.newPassword)
                        } header: {
                            Text("Step 2: Set New Password")
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
                                    Text("Password reset successfully!")
                                        .foregroundColor(.green)
                                        .font(.subheadline)
                                }
                            }
                        }

                        Section {
                            Button(action: resetPassword) {
                                HStack {
                                    if isResetting {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    }
                                    Text(isResetting ? "Resetting..." : "Reset Password")
                                        .fontWeight(.semibold)
                                        .frame(maxWidth: .infinity)
                                }
                            }
                            .disabled(!isFormValid || isResetting)
                        }
                    }
                } else {
                    Section {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Biometric authentication is not available on this device.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("To reset your password, you'll need to:")
                                .font(.subheadline)
                                .fontWeight(.semibold)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("• Set up Face ID or Touch ID in Settings")
                                Text("• Or contact your household administrator")
                            }
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Reset Password")
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

    private var isFormValid: Bool {
        biometricVerified &&
        newPassword.count >= 4 &&
        newPassword == confirmPassword
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

    private func authenticateWithBiometrics() {
        showError = false

        Task {
            let result = await biometricService.authenticateParent(
                reason: "Verify your identity to reset the app restriction password"
            )

            await MainActor.run {
                switch result {
                case .success:
                    print("✅ Parent identity verified with biometrics for password reset")
                    biometricVerified = true
                    showError = false

                case .failure(let error):
                    print("❌ Biometric authentication failed: \(error.localizedDescription)")
                    showError = true
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func resetPassword() {
        showError = false
        showSuccess = false
        isResetting = true

        Task {
            do {
                // Set new password (will sync to Supabase)
                try await passwordManager.setPassword(newPassword)

                await MainActor.run {
                    showSuccess = true
                    isResetting = false
                    newPassword = ""
                    confirmPassword = ""

                    print("✅ Password reset successfully via biometric authentication")

                    // Dismiss after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                    isResetting = false
                }
            }
        }
    }
}

// MARK: - Password Reset Request View (DEPRECATED - Email-based)

/// View for requesting a password reset via email
/// DEPRECATED: Replaced with BiometricPasswordResetView
struct PasswordResetRequestView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var passwordManager = ParentPasswordManager.shared
    @StateObject private var authService = AuthenticationService.shared

    @State private var isRequesting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false
    @State private var sentToEmail = ""
    @State private var showResetCodeEntry = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "envelope.badge.shield.half.filled")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Reset App Restriction Password")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("We'll send a verification code to your email address to confirm your identity")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.blue)
                        Text(authService.currentProfile?.email ?? "No email")
                            .foregroundColor(.primary)
                    }
                } header: {
                    Text("Verification Email")
                } footer: {
                    Text("A 6-digit code will be sent to this email address")
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
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("Code Sent!")
                                    .foregroundColor(.green)
                                    .fontWeight(.semibold)
                            }

                            Text("A verification code has been sent to \(sentToEmail)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)

                            Text("The code will expire in 15 minutes")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Section {
                    Button(action: requestReset) {
                        HStack {
                            if isRequesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isRequesting ? "Sending Code..." : (showSuccess ? "Resend Code" : "Send Verification Code"))
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isRequesting || authService.currentProfile?.email == nil)

                    if showSuccess {
                        Button("Enter Code") {
                            showResetCodeEntry = true
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("Reset Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showResetCodeEntry) {
                PasswordResetCodeEntryView()
            }
        }
    }

    private func requestReset() {
        showError = false
        showSuccess = false
        isRequesting = true

        Task {
            do {
                let email = try await passwordManager.requestPasswordReset()

                await MainActor.run {
                    sentToEmail = email
                    showSuccess = true
                    isRequesting = false
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                    isRequesting = false
                }
            }
        }
    }
}

// MARK: - Password Reset Code Entry View

/// View for entering the reset code and setting new password
struct PasswordResetCodeEntryView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var passwordManager = ParentPasswordManager.shared

    @State private var resetCode = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isResetting = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(spacing: 16) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Enter Reset Code")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Check your email for the 6-digit verification code")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section {
                    TextField("000000", text: $resetCode)
                        .keyboardType(.numberPad)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .multilineTextAlignment(.center)
                        .onChange(of: resetCode) { _, newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                resetCode = String(newValue.prefix(6))
                            }
                        }
                } header: {
                    Text("Verification Code")
                } footer: {
                    Text("Enter the 6-digit code sent to your email")
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
                            Text("Password reset successfully!")
                                .foregroundColor(.green)
                                .font(.subheadline)
                        }
                    }
                }

                Section {
                    Button(action: resetPassword) {
                        HStack {
                            if isResetting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            }
                            Text(isResetting ? "Resetting..." : "Reset Password")
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(!isFormValid || isResetting)
                }
            }
            .navigationTitle("Reset Password")
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

    private var isFormValid: Bool {
        resetCode.count == 6 &&
        newPassword.count >= 4 &&
        newPassword == confirmPassword
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

    private func resetPassword() {
        showError = false
        showSuccess = false
        isResetting = true

        Task {
            do {
                try await passwordManager.resetPasswordWithCode(code: resetCode, newPassword: newPassword)

                await MainActor.run {
                    showSuccess = true
                    isResetting = false

                    // Dismiss after showing success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        dismiss()
                    }
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = error.localizedDescription
                    isResetting = false
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
            PasswordResetRequestView()
            PasswordResetCodeEntryView()
        }
    }
}
