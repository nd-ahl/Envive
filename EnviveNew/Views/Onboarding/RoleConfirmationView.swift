import SwiftUI

// MARK: - Role Confirmation View

/// Confirms the user's device role selection to prevent accidental misconfiguration
struct RoleConfirmationView: View {
    let userRole: UserRole
    let onConfirm: () -> Void
    let onGoBack: () -> Void

    @State private var showContent = false

    var body: some View {
        ZStack {
            // Gradient background (consistent theme)
            LinearGradient(
                colors: [
                    Color.orange.opacity(0.6),
                    Color.red.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Content
                VStack(spacing: 32) {
                    // Warning icon
                    warningSection

                    // Role information
                    roleInfoSection

                    // What this means
                    capabilitiesSection

                    // Important notice
                    noticeSection
                }
                .padding(.horizontal, 32)

                Spacer()

                // Buttons
                buttonSection
                    .padding(.bottom, 50)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }

    // MARK: - Warning Section

    private var warningSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.yellow)
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            Text("Important: Confirm Your Device Role")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Role Info Section

    private var roleInfoSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: userRole == .parent ? "person.2.fill" : "person.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)

                Text("Setting Up as \(userRole == .parent ? "Parent" : "Child") Device")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.2))
            .cornerRadius(16)
            .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Capabilities Section

    private var capabilitiesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(userRole == .parent ? "This device will be able to:" : "This device will:")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            if userRole == .parent {
                CapabilityRow(
                    icon: "checkmark.circle.fill",
                    text: "Manage and assign tasks to children",
                    color: .green
                )

                CapabilityRow(
                    icon: "checkmark.circle.fill",
                    text: "Approve or decline completed tasks",
                    color: .green
                )

                CapabilityRow(
                    icon: "checkmark.circle.fill",
                    text: "Set screen time limits and rewards",
                    color: .green
                )

                CapabilityRow(
                    icon: "checkmark.circle.fill",
                    text: "View progress and activity reports",
                    color: .green
                )
            } else {
                CapabilityRow(
                    icon: "star.fill",
                    text: "View and complete assigned tasks",
                    color: .yellow
                )

                CapabilityRow(
                    icon: "star.fill",
                    text: "Earn screen time by finishing chores",
                    color: .yellow
                )

                CapabilityRow(
                    icon: "star.fill",
                    text: "Track your progress and rewards",
                    color: .yellow
                )

                CapabilityRow(
                    icon: "xmark.circle.fill",
                    text: "Cannot access parent controls",
                    color: .red
                )
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.15))
        .cornerRadius(16)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Notice Section

    private var noticeSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.white)

                Text(userRole == .parent ? "Your child's device needs separate setup" : "Your parent will set up their device separately")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            if userRole == .parent {
                Text("Each family member uses their own device with their assigned role")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Button Section

    private var buttonSection: some View {
        VStack(spacing: 16) {
            // Confirm button
            Button(action: {
                onConfirm()
            }) {
                HStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                    Text("Confirm - I'm a \(userRole == .parent ? "Parent" : "Child")")
                        .font(.system(size: 18, weight: .bold))
                }
                .foregroundColor(Color.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            }

            // Go back button
            Button(action: {
                onGoBack()
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 16))
                    Text("Go Back - I Made a Mistake")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.vertical, 12)
            }
        }
        .padding(.horizontal, 32)
        .opacity(showContent ? 1.0 : 0)
    }
}

// MARK: - Capability Row Component

private struct CapabilityRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)

            Spacer()
        }
    }
}

// MARK: - Preview

struct RoleConfirmationView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            RoleConfirmationView(
                userRole: .parent,
                onConfirm: {},
                onGoBack: {}
            )

            RoleConfirmationView(
                userRole: .child,
                onConfirm: {},
                onGoBack: {}
            )
        }
    }
}
