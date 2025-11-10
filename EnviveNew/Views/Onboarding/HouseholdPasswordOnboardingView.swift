//
//  HouseholdPasswordOnboardingView.swift
//  EnviveNew
//
//  Household password setup with explanations
//

import SwiftUI

struct HouseholdPasswordOnboardingView: View {
    let onComplete: (String) -> Void
    let onSkip: () -> Void

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showContent = false
    @State private var showPassword = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        GeometryReader { geometry in
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

                ScrollView {
                    VStack(spacing: 28) {
                        Spacer()
                            .frame(height: max(40, geometry.safeAreaInsets.top + 20))

                        // Header
                        headerSection

                        // Explanation sections
                        explanationSection
                            .padding(.horizontal, 24)

                        // Password input
                        passwordInputSection
                            .padding(.horizontal, 24)

                        Spacer()

                        // Action buttons
                        actionButtons
                            .padding(.horizontal, 24)
                            .padding(.bottom, max(30, geometry.safeAreaInsets.bottom + 20))
                    }
                }
            }
        }
        .alert("Password Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 90, height: 90)

                Image(systemName: "lock.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1.0 : 0.3)
            .opacity(showContent ? 1.0 : 0)

            Text("Create Your Household Password")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text("Protect your parent features")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .scaleEffect(showContent ? 1.0 : 0.85)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Explanation Section

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionCard(
                title: "What is it?",
                description: "A 4-6 digit code that protects your parent features when kids use their devices. It's like a digital lock for grown-up controls."
            )

            sectionCard(
                title: "You'll use it to:",
                items: [
                    "Approve or decline tasks",
                    "Change family settings",
                    "Grant emergency screen time",
                    "Access parent dashboard on any device"
                ]
            )

            whyUsefulCard()

            exampleCard()

            infoBox(
                text: "Your password will sync across all family devices automatically.",
                icon: "arrow.triangle.2.circlepath"
            )
        }
    }

    private func sectionCard(title: String, items: [String]? = nil, description: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if let items = items {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green.opacity(0.9))

                            Text(item)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if let description = description {
                Text(description)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(3)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    private func whyUsefulCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why it's useful:")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Imagine your child wants to approve their own task on their tablet. This password prevents that! Only you can unlock parent features.")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(3)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.blue.opacity(0.25))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    private func exampleCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "face.smiling.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)

                Text("Real-life example:")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text("\"My son tried to give himself 100 XP by accessing my review screen. Good thing I had a password set up—he couldn't get in!\"")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .italic()
                .lineSpacing(3)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    private func infoBox(text: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.white)

            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.15))
        )
    }

    // MARK: - Password Input Section

    private var passwordInputSection: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Password (4-6 digits)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                HStack {
                    if showPassword {
                        TextField("Enter password", text: $password)
                            .keyboardType(.numberPad)
                            .textFieldStyle(CustomWhiteTextFieldStyle())
                    } else {
                        SecureField("Enter password", text: $password)
                            .keyboardType(.numberPad)
                            .textFieldStyle(CustomWhiteTextFieldStyle())
                    }

                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                            .foregroundColor(.gray)
                    }
                    .padding(.trailing, 8)
                }
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Confirm Password")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                if showPassword {
                    TextField("Confirm password", text: $confirmPassword)
                        .keyboardType(.numberPad)
                        .textFieldStyle(CustomWhiteTextFieldStyle())
                } else {
                    SecureField("Confirm password", text: $confirmPassword)
                        .keyboardType(.numberPad)
                        .textFieldStyle(CustomWhiteTextFieldStyle())
                }
            }
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Create Password button
            Button(action: handleCreatePassword) {
                Text("Create Password")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(isFormValid ? Color.blue.opacity(0.9) : .gray.opacity(0.5))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(isFormValid ? 0.15 : 0.05), radius: 10, x: 0, y: 4)
            }
            .disabled(!isFormValid)
            .opacity(isFormValid ? 1.0 : 0.6)

            // Skip button
            Button(action: onSkip) {
                Text("Skip - I'll Set This Up Later")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .underline()
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Validation

    private var isFormValid: Bool {
        let passwordLength = password.count
        return passwordLength >= 4 && passwordLength <= 6 &&
               password == confirmPassword &&
               password.allSatisfy { $0.isNumber }
    }

    private func handleCreatePassword() {
        guard password == confirmPassword else {
            errorMessage = "Passwords don't match"
            showError = true
            return
        }

        guard password.count >= 4 && password.count <= 6 else {
            errorMessage = "Password must be 4-6 digits"
            showError = true
            return
        }

        guard password.allSatisfy({ $0.isNumber }) else {
            errorMessage = "Password must contain only numbers"
            showError = true
            return
        }

        onComplete(password)
    }
}

// MARK: - Custom Text Field Style

struct CustomWhiteTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.black)
            .accentColor(.blue)
    }
}

// MARK: - Preview

struct HouseholdPasswordOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        HouseholdPasswordOnboardingView(
            onComplete: { _ in },
            onSkip: {}
        )
    }
}
