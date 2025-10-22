import SwiftUI
import AuthenticationServices

// MARK: - Parent Authentication View

/// Secure authentication screen for parent role access
/// Requires email + password or Apple ID verification before allowing parent role selection
struct ParentAuthenticationView: View {
    let inviteCode: String
    let onAuthenticated: (Profile) -> Void
    let onBack: () -> Void

    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var householdService = HouseholdService.shared
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showContent = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
    }

    var body: some View {
        ZStack {
            // Gradient background
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
                // Back button
                HStack {
                    Button(action: onBack) {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                                .font(.system(size: 17, weight: .medium))
                        }
                        .foregroundColor(.white)
                    }
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    Spacer()
                }

                Spacer()

                // Content
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Auth form
                    authFormSection

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

                    // Sign in button
                    signInButton

                    // Divider
                    HStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                        Text("OR")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.vertical, -10)
                    .opacity(showContent ? 1.0 : 0)

                    // Apple Sign In button
                    SignInWithAppleButton(
                        onRequest: { request in
                            request.requestedScopes = [.fullName, .email]
                        },
                        onCompletion: handleAppleSignIn
                    )
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 55)
                    .cornerRadius(14)
                    .opacity(showContent ? 1.0 : 0)
                }
                .padding(.horizontal, 32)

                Spacer()

                // Security notice
                securityNotice
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            // Auto-focus email field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                focusedField = .email
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Lock icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1.0 : 0.5)
            .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Parent Verification")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text("Enter your account credentials to access parent controls")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
            }
        }
    }

    // MARK: - Auth Form Section

    private var authFormSection: some View {
        VStack(spacing: 16) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                ZStack(alignment: .leading) {
                    if email.isEmpty {
                        Text("parent@example.com")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    TextField("", text: $email)
                        .textFieldStyle(.plain)
                }
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .focused($focusedField, equals: .email)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .onSubmit {
                        focusedField = .password
                    }
            }

            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                ZStack(alignment: .leading) {
                    if password.isEmpty {
                        Text("Enter your password")
                            .foregroundColor(.white.opacity(0.5))
                    }
                    SecureField("", text: $password)
                        .textFieldStyle(.plain)
                }
                    .textContentType(.password)
                    .focused($focusedField, equals: .password)
                    .padding()
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(12)
                    .foregroundColor(.white)
                    .onSubmit {
                        handleSignIn()
                    }
            }
        }
        .opacity(showContent ? 1.0 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    // MARK: - Sign In Button

    private var signInButton: some View {
        Button(action: handleSignIn) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.blue.opacity(0.9)))
                } else {
                    Text("Verify & Continue")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                }
            }
            .foregroundColor(canSignIn ? Color.blue.opacity(0.9) : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            .opacity(canSignIn ? 1.0 : 0.5)
        }
        .disabled(!canSignIn || isLoading)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Security Notice

    private var securityNotice: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.8))

                Text("Secure Parent Authentication")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
            }

            Text("Your credentials are encrypted and verified against your household account. Children cannot access parent roles without valid parent credentials.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Computed Properties

    private var canSignIn: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.isEmpty
    }

    // MARK: - Actions

    private func handleSignIn() {
        guard canSignIn else { return }

        focusedField = nil
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // Sign in with email and password
                let profile = try await authService.signIn(
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password
                )

                // SECURITY CHECK 1: Verify user is a parent
                guard profile.role == "parent" else {
                    // Sign out WITHOUT clearing onboarding data
                    try? await authService.signOutWithoutClearingOnboarding()
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "This account is not a parent account. Parents must use the email address they signed up with."
                    }
                    return
                }

                // SECURITY CHECK 2: Verify user belongs to this household
                guard let userHouseholdId = profile.householdId else {
                    // Sign out WITHOUT clearing onboarding data
                    try? await authService.signOutWithoutClearingOnboarding()
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "This account is not associated with any household. Please contact support."
                    }
                    return
                }

                // Get household by invite code
                let household = try await householdService.getHouseholdByInviteCode(inviteCode)

                // SECURITY CHECK 3: Verify household ID matches
                guard userHouseholdId == household.id else {
                    // Sign out WITHOUT clearing onboarding data
                    try? await authService.signOutWithoutClearingOnboarding()
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "This account belongs to a different household (code: \(household.inviteCode)). Please enter the correct email for household \(inviteCode)."
                    }
                    return
                }

                // ✅ All security checks passed
                print("✅ Parent authentication successful")
                print("  - Email: \(profile.email ?? "unknown")")
                print("  - Name: \(profile.fullName ?? "unknown")")
                print("  - Household: \(household.name)")
                print("  - Role: \(profile.role)")

                await MainActor.run {
                    isLoading = false
                    onAuthenticated(profile)
                }

            } catch {
                print("❌ Authentication failed: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Invalid email or password. Please try again."
                }
            }
        }
    }

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            isLoading = true
            errorMessage = nil

            Task {
                do {
                    // Sign in with Apple
                    let profile = try await authService.signInWithApple(authorization: authorization)

                    // SECURITY CHECK 1: Verify user is a parent
                    guard profile.role == "parent" else {
                        // Sign out WITHOUT clearing onboarding data
                        try? await authService.signOutWithoutClearingOnboarding()
                        await MainActor.run {
                            isLoading = false
                            errorMessage = "This account is not a parent account. Parents must use the Apple ID they signed up with."
                        }
                        return
                    }

                    // SECURITY CHECK 2: Verify user belongs to this household
                    guard let userHouseholdId = profile.householdId else {
                        // Sign out WITHOUT clearing onboarding data
                        try? await authService.signOutWithoutClearingOnboarding()
                        await MainActor.run {
                            isLoading = false
                            errorMessage = "This account is not associated with any household. Please contact support."
                        }
                        return
                    }

                    // Get household by invite code
                    let household = try await householdService.getHouseholdByInviteCode(inviteCode)

                    // SECURITY CHECK 3: Verify household ID matches
                    guard userHouseholdId == household.id else {
                        // Sign out WITHOUT clearing onboarding data
                        try? await authService.signOutWithoutClearingOnboarding()
                        await MainActor.run {
                            isLoading = false
                            errorMessage = "This account belongs to a different household (code: \(household.inviteCode)). Please use the correct Apple ID for household \(inviteCode)."
                        }
                        return
                    }

                    // ✅ All security checks passed
                    print("✅ Parent authentication via Apple successful")
                    print("  - Email: \(profile.email ?? "unknown")")
                    print("  - Name: \(profile.fullName ?? "unknown")")
                    print("  - Household: \(household.name)")
                    print("  - Role: \(profile.role)")

                    await MainActor.run {
                        isLoading = false
                        onAuthenticated(profile)
                    }

                } catch {
                    print("❌ Apple authentication failed: \(error.localizedDescription)")
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Apple sign in failed. Please try again."
                    }
                }
            }

        case .failure(let error):
            errorMessage = "Apple sign in cancelled"
            print("❌ Apple sign in error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

struct ParentAuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        ParentAuthenticationView(
            inviteCode: "123456",
            onAuthenticated: { _ in },
            onBack: {}
        )
    }
}
