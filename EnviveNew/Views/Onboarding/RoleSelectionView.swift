//
//  RoleSelectionView.swift
//  EnviveNew
//
//  Clear role selection screen for parent vs child
//

import SwiftUI

struct RoleSelectionView: View {
    let onParentSelected: () -> Void
    let onChildSelected: () -> Void

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

            VStack(spacing: 40) {
                Spacer()

                // Header
                headerSection

                // Role selection buttons
                roleButtons

                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 20) {
            Text("Who's using this device?")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Choose the role that best describes you")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Role Buttons

    private var roleButtons: some View {
        VStack(spacing: 20) {
            // Parent button
            Button(action: {
                UserDefaults.standard.set("parent", forKey: "userRole")
                onParentSelected()
            }) {
                HStack(spacing: 20) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.blue.opacity(0.9))
                        .frame(width: 70)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("I'm a Parent")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.blue.opacity(0.9))

                        Text("Set up tasks and manage screen time")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.blue.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.blue.opacity(0.6))
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
            }
            .scaleEffect(showContent ? 1.0 : 0.9)
            .opacity(showContent ? 1.0 : 0)

            // Child button
            Button(action: {
                UserDefaults.standard.set("child", forKey: "userRole")
                onChildSelected()
            }) {
                HStack(spacing: 20) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 40))
                        .foregroundColor(.purple.opacity(0.9))
                        .frame(width: 70)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("I'm a Child")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.purple.opacity(0.9))

                        Text("Complete tasks and earn screen time")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.purple.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.purple.opacity(0.6))
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.15), radius: 12, x: 0, y: 6)
            }
            .scaleEffect(showContent ? 1.0 : 0.9)
            .opacity(showContent ? 1.0 : 0)
        }
    }
}

// MARK: - Preview

struct RoleSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        RoleSelectionView(
            onParentSelected: { print("Parent selected") },
            onChildSelected: { print("Child selected") }
        )
    }
}
