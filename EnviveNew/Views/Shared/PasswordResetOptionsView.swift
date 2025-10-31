//
//  PasswordResetOptionsView.swift
//  EnviveNew
//
//  Password reset options - choose between biometric or email verification
//

import SwiftUI

struct PasswordResetOptionsView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var biometricService = BiometricAuthenticationService.shared
    @StateObject private var authService = AuthenticationService.shared

    @State private var showBiometricReset = false
    @State private var showEmailReset = false

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

                        Text("Reset Password")
                            .font(.title2)
                            .fontWeight(.bold)

                        Text("Choose how you'd like to reset your app restriction password")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .listRowBackground(Color.clear)

                Section {
                    // Biometric Reset Option
                    if biometricService.isBiometricsAvailable {
                        Button(action: {
                            showBiometricReset = true
                        }) {
                            HStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.1))
                                        .frame(width: 50, height: 50)

                                    Image(systemName: biometricService.biometricType.icon)
                                        .font(.title2)
                                        .foregroundColor(.blue)
                                }

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Use \(biometricService.biometricType.displayName)")
                                        .font(.headline)
                                        .foregroundColor(.primary)

                                    Text("Quick and secure - verify with your face or fingerprint")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }

                    // Email Reset Option
                    Button(action: {
                        showEmailReset = true
                    }) {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 50, height: 50)

                                Image(systemName: "envelope.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use Email Verification")
                                    .font(.headline)
                                    .foregroundColor(.primary)

                                if let email = authService.currentProfile?.email {
                                    Text("Send code to \(email)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                } else {
                                    Text("Receive a verification code via email")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("Reset Methods")
                } footer: {
                    if !biometricService.isBiometricsAvailable {
                        Text("Note: Biometric authentication is not available on this device. Email verification is recommended.")
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            Text("About Password Reset")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("• Your app restriction password is synced across all household devices")
                            Text("• After resetting, all family members will need to use the new password")
                            Text("• The reset process requires identity verification for security")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Choose Reset Method")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showBiometricReset) {
                BiometricPasswordResetView()
            }
            .sheet(isPresented: $showEmailReset) {
                PasswordResetRequestView()
            }
            .onDisappear {
                // Clear grace period when leaving reset options view
                BiometricAuthenticationService.shared.clearGracePeriod()
            }
        }
    }
}

// MARK: - Preview

struct PasswordResetOptionsView_Previews: PreviewProvider {
    static var previews: some View {
        PasswordResetOptionsView()
    }
}
