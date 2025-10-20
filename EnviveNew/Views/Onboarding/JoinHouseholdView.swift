import SwiftUI

// MARK: - Join Household View

/// Allows users to join an existing household using an invite code
struct JoinHouseholdView: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var householdService = HouseholdService.shared
    @State private var showContent = false
    @State private var inviteCode = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var isCodeFieldFocused: Bool

    private let codeLength = 6

    var body: some View {
        ZStack {
            // Gradient background (consistent theme)
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

                    // Code input section
                    codeInputSection

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

                    // Join button
                    joinButton
                }
                .padding(.horizontal, 32)

                Spacer()

                // Footer
                footerSection
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            // Auto-focus the code field
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isCodeFieldFocused = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            // Icon
            Text("🔐")
                .font(.system(size: 70))
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Enter Invite Code")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text("Ask your family member for the 6-digit code")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
            }
        }
    }

    // MARK: - Code Input Section

    private var codeInputSection: some View {
        VStack(spacing: 16) {
            // Code input boxes
            HStack(spacing: 12) {
                ForEach(0..<codeLength, id: \.self) { index in
                    CodeDigitBox(
                        digit: getDigit(at: index),
                        isFilled: index < inviteCode.count,
                        isActive: index == inviteCode.count
                    )
                }
            }

            // Hidden text field for input
            TextField("", text: $inviteCode)
                .keyboardType(.numberPad)
                .focused($isCodeFieldFocused)
                .opacity(0)
                .frame(width: 1, height: 1)
                .onChange(of: inviteCode) { oldValue, newValue in
                    handleCodeChange(newValue)
                }

            // Tap to focus hint
            if inviteCode.isEmpty {
                Text("Tap above to enter code")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .opacity(showContent ? 1.0 : 0)
        .offset(y: showContent ? 0 : 20)
        .onTapGesture {
            isCodeFieldFocused = true
        }
    }

    // MARK: - Join Button

    private var joinButton: some View {
        Button(action: handleJoinHousehold) {
            HStack(spacing: 10) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.blue.opacity(0.9)))
                } else {
                    Text("Join Household")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .foregroundColor(canJoin ? Color.blue.opacity(0.9) : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(12)
            .opacity(canJoin ? 1.0 : 0.5)
        }
        .disabled(!canJoin || isLoading)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Footer Section

    private var footerSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))

                Text("Don't have a code? Ask your parent to invite you from their app")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .multilineTextAlignment(.center)
            .padding(.horizontal, 20)

            Button(action: {
                // TODO: Show how to get invite code
            }) {
                Text("How do I get an invite code?")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .underline()
            }
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Computed Properties

    private var canJoin: Bool {
        inviteCode.count == codeLength
    }

    // MARK: - Helper Functions

    private func getDigit(at index: Int) -> String {
        guard index < inviteCode.count else { return "" }
        let digitIndex = inviteCode.index(inviteCode.startIndex, offsetBy: index)
        return String(inviteCode[digitIndex])
    }

    private func handleCodeChange(_ newValue: String) {
        // Only allow digits
        let filtered = newValue.filter { $0.isNumber }

        // Limit to code length
        if filtered.count <= codeLength {
            inviteCode = filtered
            errorMessage = nil

            // Auto-submit when code is complete
            if filtered.count == codeLength {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    handleJoinHousehold()
                }
            }
        } else {
            inviteCode = String(filtered.prefix(codeLength))
        }
    }

    // MARK: - Actions

    private func handleJoinHousehold() {
        guard canJoin else { return }

        isCodeFieldFocused = false
        isLoading = true
        errorMessage = nil

        Task {
            do {
                // First verify the code exists
                let isValid = try await householdService.verifyInviteCode(inviteCode)

                guard isValid else {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Invalid invite code. Please check and try again."
                    }
                    return
                }

                // Get current user ID
                guard let userId = await authService.currentProfile?.id else {
                    await MainActor.run {
                        isLoading = false
                        errorMessage = "Please sign in first to join a household."
                    }
                    return
                }

                // Get user role
                let roleString = UserDefaults.standard.string(forKey: "userRole") ?? "child"

                // Join the household
                let household = try await householdService.joinHousehold(
                    inviteCode: inviteCode,
                    userId: userId,
                    role: roleString
                )

                print("✅ Joined household: \(household.name)")
                print("Household ID: \(household.id)")

                // Save household info for backward compatibility
                UserDefaults.standard.set(inviteCode, forKey: "householdCode")
                UserDefaults.standard.set(household.id, forKey: "householdId")
                UserDefaults.standard.set(true, forKey: "isInHousehold")

                await MainActor.run {
                    isLoading = false
                    onComplete()
                }
            } catch {
                print("❌ Failed to join household: \(error.localizedDescription)")
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to join household. Please try again."
                }
            }
        }
    }
}

// MARK: - Code Digit Box Component

private struct CodeDigitBox: View {
    let digit: String
    let isFilled: Bool
    let isActive: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(isFilled ? 0.25 : 0.1))
                .frame(width: 50, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? Color.white : Color.clear, lineWidth: 2)
                )

            Text(digit)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
        }
        .animation(.spring(response: 0.3), value: isFilled)
        .animation(.spring(response: 0.3), value: isActive)
    }
}

// MARK: - Preview

struct JoinHouseholdView_Previews: PreviewProvider {
    static var previews: some View {
        JoinHouseholdView(
            onComplete: {},
            onBack: {}
        )
    }
}
