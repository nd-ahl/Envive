import SwiftUI

// MARK: - Household Selection View

/// Allows users to choose whether to create a new household or join an existing one
struct HouseholdSelectionView: View {
    let userRole: UserRole
    let onCreateHousehold: () -> Void
    let onJoinHousehold: () -> Void
    let onBack: () -> Void

    @State private var showContent = false
    @State private var selectedOption: HouseholdOption?

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

                    // Options
                    optionsSection
                }
                .padding(.horizontal, 32)

                Spacer()

                // Continue button
                continueButton
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
            // Icon
            Text("🏠")
                .font(.system(size: 70))
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text(userRole == .parent ? "Set Up Your Household" : "Join Your Family")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text(userRole == .parent ? "Create a new household or join an existing one" : "Connect with your family's household")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
            }
        }
    }

    // MARK: - Options Section

    private var optionsSection: some View {
        VStack(spacing: 16) {
            // Create Household Option
            if userRole == .parent {
                HouseholdOptionButton(
                    icon: "plus.circle.fill",
                    title: "Create New Household",
                    subtitle: "Set up a household for your family",
                    isSelected: selectedOption == .create
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedOption = .create
                    }
                }
            }

            // Join Household Option
            HouseholdOptionButton(
                icon: "person.2.fill",
                title: "Join Existing Household",
                subtitle: userRole == .parent ? "You've been invited to a household" : "Your parent will give you a code",
                isSelected: selectedOption == .join
            ) {
                withAnimation(.spring(response: 0.3)) {
                    selectedOption = .join
                }
            }
        }
        .opacity(showContent ? 1.0 : 0)
        .offset(y: showContent ? 0 : 20)
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: handleContinue) {
            HStack(spacing: 10) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "arrow.right")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(selectedOption != nil ? Color.blue.opacity(0.9) : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(12)
            .opacity(selectedOption != nil ? 1.0 : 0.5)
        }
        .disabled(selectedOption == nil)
        .padding(.horizontal, 32)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Actions

    private func handleContinue() {
        guard let option = selectedOption else { return }

        switch option {
        case .create:
            onCreateHousehold()
        case .join:
            onJoinHousehold()
        }
    }
}

// MARK: - Household Option Button Component

private struct HouseholdOptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(.white)
                    .frame(width: 50)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Household Option Enum

private enum HouseholdOption {
    case create
    case join
}

// MARK: - Preview

struct HouseholdSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HouseholdSelectionView(
                userRole: .parent,
                onCreateHousehold: {},
                onJoinHousehold: {},
                onBack: {}
            )
            .previewDisplayName("Parent View")

            HouseholdSelectionView(
                userRole: .child,
                onCreateHousehold: {},
                onJoinHousehold: {},
                onBack: {}
            )
            .previewDisplayName("Child View")
        }
    }
}
