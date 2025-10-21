import SwiftUI

// MARK: - Link Devices View

/// Onboarding screen for linking additional family devices
struct LinkDevicesView: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @StateObject private var householdService = HouseholdService.shared
    @State private var networkSharingEnabled = false
    @State private var showContent = false
    @State private var showCopiedMessage = false
    @State private var inviteCode: String = ""
    @State private var householdName: String = ""

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

                // Header
                headerSection
                    .padding(.top, 20)

                Spacer()

                // Main content
                VStack(spacing: 32) {
                    // Invite code card
                    inviteCodeCard

                    // Network sharing toggle
                    networkSharingSection

                    // Info text
                    infoSection
                }
                .padding(.horizontal, 32)

                Spacer()

                // Action buttons
                actionButtons
                    .padding(.bottom, 50)
            }

            // Copied message overlay
            if showCopiedMessage {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Code copied to clipboard!")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(10)
                    .padding(.bottom, 100)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
            loadHouseholdInfo()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            Text("📱")
                .font(.system(size: 70))
                .scaleEffect(showContent ? 1.0 : 0.5)
                .opacity(showContent ? 1.0 : 0)

            VStack(spacing: 12) {
                Text("Link Additional Devices")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text("Set up Envive on your family's devices")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Invite Code Card

    private var inviteCodeCard: some View {
        VStack(spacing: 20) {
            // Title
            Text("Household Invite Code")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)

            // Code display
            VStack(spacing: 8) {
                Text(inviteCode.isEmpty ? "------" : inviteCode)
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .tracking(8)
                    .kerning(8)

                Text(householdName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            .padding(.vertical, 24)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.15))
            .cornerRadius(16)

            // Action buttons for code
            HStack(spacing: 12) {
                // Copy button
                Button(action: copyInviteCode) {
                    HStack(spacing: 8) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                        Text("Copy Code")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(Color.purple.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(10)
                }

                // Share button
                Button(action: shareInviteCode) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 16))
                        Text("Share")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(Color.blue.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .cornerRadius(10)
                }
            }
        }
        .padding(24)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Network Sharing Section

    private var networkSharingSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Network Sharing")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Text("Allow devices on the same network to discover your household")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                Toggle("", isOn: $networkSharingEnabled)
                    .labelsHidden()
                    .tint(Color.purple)
            }
            .padding(20)
            .background(Color.white.opacity(0.1))
            .cornerRadius(16)
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.8))

                Text("Family members can use this code to join your household on their devices")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(16)
            .background(Color.white.opacity(0.1))
            .cornerRadius(12)
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 16) {
            // Continue button
            Button(action: onComplete) {
                HStack(spacing: 10) {
                    Text("Get Started")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(Color.purple.opacity(0.8))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
            }
            .padding(.horizontal, 32)

            // Skip text
            Button(action: onComplete) {
                Text("I'll set this up later")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .underline()
            }
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Actions

    private func loadHouseholdInfo() {
        if let household = householdService.currentHousehold {
            inviteCode = household.inviteCode
            householdName = household.name
            print("✅ LinkDevicesView: Loaded household from service")
            print("  - Name: \(householdName)")
            print("  - Invite Code: \(inviteCode)")
        } else {
            // Try to load from UserDefaults as fallback
            inviteCode = UserDefaults.standard.string(forKey: "householdCode") ?? ""
            householdName = "My Household"
            print("⚠️ LinkDevicesView: No household in service, using UserDefaults")
            print("  - Invite Code: \(inviteCode)")
        }
    }

    private func copyInviteCode() {
        UIPasteboard.general.string = inviteCode

        withAnimation {
            showCopiedMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showCopiedMessage = false
            }
        }
    }

    private func shareInviteCode() {
        let message = """
        Join my household on Envive!

        Household: \(householdName)
        Invite Code: \(inviteCode)

        Download Envive and enter this code to join.
        """

        let activityVC = UIActivityViewController(
            activityItems: [message],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

// MARK: - Preview

struct LinkDevicesView_Previews: PreviewProvider {
    static var previews: some View {
        LinkDevicesView(onComplete: {}, onBack: {})
    }
}
