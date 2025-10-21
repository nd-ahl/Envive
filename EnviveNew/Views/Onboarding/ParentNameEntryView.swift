import SwiftUI

// MARK: - Parent Name Entry View

/// Screen for parent to enter/confirm their name
struct ParentNameEntryView: View {
    let onComplete: (String) -> Void
    let onBack: () -> Void

    @StateObject private var authService = AuthenticationService.shared
    @State private var parentName: String = ""
    @State private var showContent = false

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
                VStack(spacing: 40) {
                    // Header
                    headerSection

                    // Name input
                    nameInputSection

                    // Helper text
                    helperText
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
            // Pre-fill with existing name if available
            if let existingName = authService.currentProfile?.fullName, !existingName.isEmpty {
                parentName = existingName
            }

            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            Text("👋")
                .font(.system(size: 70))
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("What's your name?")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text("This helps personalize your family's experience")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
            }
        }
    }

    // MARK: - Name Input Section

    private var nameInputSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Name")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            TextField("", text: $parentName)
                .placeholder(when: parentName.isEmpty) {
                    Text("Enter your name")
                        .foregroundColor(.gray.opacity(0.6))
                }
                .textContentType(.name)
                .autocapitalization(.words)
                .padding(.horizontal, 20)
                .padding(.vertical, 18)
                .background(Color.white)
                .cornerRadius(14)
                .foregroundColor(.black)
                .font(.system(size: 18))
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Helper Text

    private var helperText: some View {
        HStack(spacing: 8) {
            Image(systemName: "person.fill")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))

            Text("This will be shown to your family")
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
        Button(action: {
            guard !parentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
            onComplete(parentName.trimmingCharacters(in: .whitespacesAndNewlines))
        }) {
            HStack(spacing: 10) {
                Text("Continue")
                    .font(.system(size: 18, weight: .bold))
                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 20))
            }
            .foregroundColor(canContinue ? Color.blue.opacity(0.9) : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            .opacity(canContinue ? 1.0 : 0.5)
        }
        .disabled(!canContinue)
        .scaleEffect(showContent ? 1.0 : 0.9)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Computed Properties

    private var canContinue: Bool {
        !parentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

// MARK: - Preview

struct ParentNameEntryView_Previews: PreviewProvider {
    static var previews: some View {
        ParentNameEntryView(onComplete: { _ in }, onBack: {})
    }
}
