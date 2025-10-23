import SwiftUI

// MARK: - Welcome View

/// Initial welcome screen shown to new users
struct WelcomeView: View {
    let onGetStarted: () -> Void
    let onSignIn: () -> Void

    @State private var showContent = false

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
                Spacer()

                // Logo/Icon Section
                logoSection

                Spacer()
                    .frame(height: 40)

                // Welcome Message
                welcomeMessageSection

                Spacer()

                // Action Buttons
                actionButtons

                Spacer()
                    .frame(height: 50)
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }

    // MARK: - Logo Section

    private var logoSection: some View {
        VStack(spacing: 20) {
            // Playful icon
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 100, height: 100)

                Image(systemName: "house.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1.0 : 0.5)
            .opacity(showContent ? 1.0 : 0)

            Text("envive")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .scaleEffect(showContent ? 1.0 : 0.8)
                .opacity(showContent ? 1.0 : 0)
        }
    }

    // MARK: - Welcome Message

    private var welcomeMessageSection: some View {
        VStack(spacing: 16) {
            Text("Chores → Screen Time")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 20)

            Text("Kids do tasks. Parents approve.\nEveryone wins.")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .multilineTextAlignment(.center)
                .lineSpacing(6)
                .opacity(showContent ? 1.0 : 0)
                .offset(y: showContent ? 0 : 20)
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Get Started Button
            Button(action: onGetStarted) {
                HStack(spacing: 10) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold))
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 20))
                }
                .foregroundColor(Color.blue.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(Color.white)
                .cornerRadius(14)
                .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            }
            .scaleEffect(showContent ? 1.0 : 0.9)
            .opacity(showContent ? 1.0 : 0)

            // Already Have Account Button
            Button(action: onSignIn) {
                Text("Already have an account? **Sign In**")
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .padding(.vertical, 10)
            }
            .opacity(showContent ? 1.0 : 0)
        }
    }
}

// MARK: - Preview

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView(
            onGetStarted: {},
            onSignIn: {}
        )
    }
}
