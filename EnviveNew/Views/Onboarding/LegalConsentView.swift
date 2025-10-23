//
//  LegalConsentView.swift
//  EnviveNew
//
//  Privacy Policy and Terms of Service acceptance view
//  Includes COPPA compliance for children under 13
//

import SwiftUI
import Combine

// MARK: - Legal Consent View

struct LegalConsentView: View {
    let userId: UUID
    let userName: String
    let userAge: Int
    let isParent: Bool
    let onComplete: () -> Void

    @StateObject private var viewModel: LegalConsentViewModel
    @State private var privacyAccepted = false
    @State private var termsAccepted = false
    @State private var parentalConsentAccepted = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTerms = false
    @State private var showError = false
    @State private var errorMessage = ""

    init(userId: UUID, userName: String, userAge: Int, isParent: Bool, onComplete: @escaping () -> Void) {
        self.userId = userId
        self.userName = userName
        self.userAge = userAge
        self.isParent = isParent
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: LegalConsentViewModel(
            legalConsentService: DependencyContainer.shared.legalConsentService,
            userId: userId,
            userAge: userAge,
            isParent: isParent
        ))
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Age-specific messaging
                    if viewModel.needsParentalConsent {
                        coppaNotice
                    }

                    // Privacy Policy
                    privacyPolicySection

                    // Terms of Service
                    termsOfServiceSection

                    // Parental Consent (for children under 13)
                    if viewModel.needsParentalConsent {
                        parentalConsentSection
                    }

                    // Accept Button
                    acceptButton

                    // Footer
                    footerText
                }
                .padding()
            }
            .navigationTitle("Legal Agreement")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)  // Prevent skipping
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc.text.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text("Welcome, \(userName)!")
                .font(.title2)
                .fontWeight(.bold)

            Text("Before we begin, please review and accept our Privacy Policy and Terms of Service.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical)
    }

    // MARK: - COPPA Notice

    private var coppaNotice: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(.orange)
                Text("Parental Consent Required")
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            Text("Since you're under 13 years old, federal law (COPPA) requires that a parent or guardian review and approve your use of this app. After you read the documents below, a parent will need to give their consent.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Privacy Policy Section

    private var privacyPolicySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Privacy Policy")
                .font(.headline)

            Text("Our Privacy Policy explains how we collect, use, and protect your information.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: {
                showingPrivacyPolicy = true
            }) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Read Privacy Policy")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }

            Toggle(isOn: $privacyAccepted) {
                Text("I have read and accept the Privacy Policy")
                    .font(.subheadline)
            }
            .toggleStyle(CheckboxToggleStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
        .sheet(isPresented: $showingPrivacyPolicy) {
            WebDocumentView(
                url: LegalDocumentVersions.privacyPolicyURL,
                title: "Privacy Policy"
            )
        }
    }

    // MARK: - Terms of Service Section

    private var termsOfServiceSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Terms of Service")
                .font(.headline)

            Text("Our Terms of Service outline the rules and guidelines for using Envive.")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button(action: {
                showingTerms = true
            }) {
                HStack {
                    Image(systemName: "doc.text")
                    Text("Read Terms of Service")
                    Spacer()
                    Image(systemName: "arrow.up.right")
                        .font(.caption)
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .foregroundColor(.blue)
                .cornerRadius(8)
            }

            Toggle(isOn: $termsAccepted) {
                Text("I have read and accept the Terms of Service")
                    .font(.subheadline)
            }
            .toggleStyle(CheckboxToggleStyle())
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
        .sheet(isPresented: $showingTerms) {
            WebDocumentView(
                url: LegalDocumentVersions.termsOfServiceURL,
                title: "Terms of Service"
            )
        }
    }

    // MARK: - Parental Consent Section

    private var parentalConsentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Parental Consent")
                .font(.headline)

            if isParent {
                Text("As a parent or legal guardian, I give permission for \(userName) (age \(userAge)) to use Envive and agree to the collection and use of their information as described in the Privacy Policy.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Toggle(isOn: $parentalConsentAccepted) {
                    Text("I am the parent/guardian and give consent")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                .toggleStyle(CheckboxToggleStyle())
            } else {
                Text("After accepting, a parent or guardian will need to approve your account before you can use the app.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5)
    }

    // MARK: - Accept Button

    private var acceptButton: some View {
        Button(action: handleAccept) {
            Text(acceptButtonText)
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(canAccept ? Color.blue : Color.gray)
                .cornerRadius(12)
        }
        .disabled(!canAccept)
        .padding(.top)
    }

    private var canAccept: Bool {
        let basicAcceptance = privacyAccepted && termsAccepted

        if viewModel.needsParentalConsent && isParent {
            return basicAcceptance && parentalConsentAccepted
        }

        return basicAcceptance
    }

    private var acceptButtonText: String {
        if viewModel.needsParentalConsent && !isParent {
            return "Submit for Parental Approval"
        }
        return "I Accept"
    }

    // MARK: - Footer

    private var footerText: some View {
        VStack(spacing: 8) {
            Text("By accepting, you acknowledge that you have read, understood, and agree to be bound by these terms.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Text("Document Version: Privacy Policy v\(LegalDocumentVersions.currentPrivacyPolicyVersion), Terms v\(LegalDocumentVersions.currentTermsOfServiceVersion)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }

    // MARK: - Actions

    private func handleAccept() {
        do {
            try viewModel.recordConsent(
                privacyAccepted: privacyAccepted,
                termsAccepted: termsAccepted,
                parentalConsentGiven: isParent ? parentalConsentAccepted : false
            )

            // Show success message for children under 13 who need parental approval
            if viewModel.needsParentalConsent && !isParent {
                errorMessage = "Your request has been submitted! A parent or guardian will need to approve your account before you can continue."
                showError = true

                // Delay completion to show message
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    onComplete()
                }
            } else {
                onComplete()
            }
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

// MARK: - Legal Consent View Model

@MainActor
class LegalConsentViewModel: ObservableObject {
    private let legalConsentService: LegalConsentService
    private let userId: UUID
    private let userAge: Int
    private let isParent: Bool

    @Published var needsParentalConsent: Bool

    init(legalConsentService: LegalConsentService, userId: UUID, userAge: Int, isParent: Bool) {
        self.legalConsentService = legalConsentService
        self.userId = userId
        self.userAge = userAge
        self.isParent = isParent
        self.needsParentalConsent = legalConsentService.needsParentalConsent(age: userAge)
    }

    func recordConsent(privacyAccepted: Bool, termsAccepted: Bool, parentalConsentGiven: Bool) throws {
        guard privacyAccepted && termsAccepted else {
            throw LegalConsentError.consentAlreadyExists  // Reusing error, should create new one
        }

        let userType: UserConsentType
        if isParent {
            userType = .parent
        } else if userAge >= 13 {
            userType = .childOver13
        } else {
            userType = .childUnder13
        }

        let consent = LegalConsent(
            userId: userId,
            userType: userType,
            privacyPolicyVersion: LegalDocumentVersions.currentPrivacyPolicyVersion,
            termsOfServiceVersion: LegalDocumentVersions.currentTermsOfServiceVersion,
            acceptedAt: Date(),
            ipAddress: nil,  // Could capture this for compliance
            parentalConsentRequired: needsParentalConsent,
            parentalConsentGiven: parentalConsentGiven,
            parentUserId: nil
        )

        try legalConsentService.recordConsent(consent)
    }
}

// MARK: - Checkbox Toggle Style

struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(action: {
            configuration.isOn.toggle()
        }) {
            HStack(spacing: 12) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(configuration.isOn ? .blue : .gray)

                configuration.label
                    .foregroundColor(.primary)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Web Document View

struct WebDocumentView: View {
    let url: String
    let title: String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Loading \(title)...")
                        .foregroundColor(.secondary)

                    Text("Please visit: \(url)")
                        .font(.caption)
                        .foregroundColor(.blue)

                    Link("Open in Browser", destination: URL(string: url)!)
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}
