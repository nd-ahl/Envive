import SwiftUI

// MARK: - Child Invite Code Entry View

/// Screen where child enters the household invite code
struct ChildInviteCodeEntryView: View {
    let onCodeEntered: (String) -> Void
    let onBack: () -> Void

    @StateObject private var householdService = HouseholdService.shared
    @State private var inviteCode: String = ""
    @State private var showContent = false
    @State private var isVerifying = false
    @State private var errorMessage: String?

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
                VStack(spacing: 40) {
                    // Header
                    headerSection

                    // Code input
                    codeInputSection

                    // Helper text
                    helperText

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
                }
                .padding(.horizontal, 32)

                Spacer()

                // Continue button
                continueButton
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            Text("🏠")
                .font(.system(size: 70))
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Join Your Family")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text("Enter the code your parent gave you")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
            }
        }
    }

    // MARK: - Code Input Section

    private var codeInputSection: some View {
        VStack(spacing: 12) {
            Text("Invite Code")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            TextField("", text: $inviteCode)
                .placeholder(when: inviteCode.isEmpty) {
                    Text("Enter 6-digit code")
                        .foregroundColor(.gray.opacity(0.6))
                }
                .keyboardType(.numberPad)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(Color.white)
                .cornerRadius(14)
                .foregroundColor(.black)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .tracking(8)
                .onChange(of: inviteCode) { newValue in
                    // Limit to 6 digits
                    if newValue.count > 6 {
                        inviteCode = String(newValue.prefix(6))
                    }
                    // Clear error when typing
                    errorMessage = nil
                }
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Helper Text

    private var helperText: some View {
        HStack(spacing: 8) {
            Image(systemName: "questionmark.circle.fill")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text("Ask your parent for the household code")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: handleContinue) {
            HStack(spacing: 10) {
                if isVerifying {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.blue.opacity(0.9)))
                } else {
                    Text("Continue")
                        .font(.system(size: 18, weight: .bold))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                }
            }
            .foregroundColor(canContinue ? Color.blue.opacity(0.9) : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            .opacity(canContinue ? 1.0 : 0.5)
        }
        .disabled(!canContinue || isVerifying)
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Computed Properties

    private var canContinue: Bool {
        inviteCode.count == 6
    }

    // MARK: - Actions

    private func handleContinue() {
        guard canContinue else { return }

        isVerifying = true
        errorMessage = nil

        Task {
            do {
                // Verify the invite code exists
                let isValid = try await householdService.verifyInviteCode(inviteCode)

                await MainActor.run {
                    isVerifying = false

                    if isValid {
                        onCodeEntered(inviteCode)
                    } else {
                        errorMessage = "Invalid code. Please check and try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isVerifying = false
                    errorMessage = "Could not verify code. Please try again."
                }
            }
        }
    }
}

// MARK: - Preview

struct ChildInviteCodeEntryView_Previews: PreviewProvider {
    static var previews: some View {
        ChildInviteCodeEntryView(
            onCodeEntered: { _ in },
            onBack: {}
        )
    }
}
