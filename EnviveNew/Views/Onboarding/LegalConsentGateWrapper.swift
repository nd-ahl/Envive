//
//  LegalConsentGateWrapper.swift
//  EnviveNew
//
//  Wraps the main app and ensures legal consent before access
//

import SwiftUI
import Combine

struct LegalConsentGateWrapper<Content: View>: View {
    let content: Content

    @StateObject private var viewModel = LegalConsentGateWrapperViewModel()
    @State private var showingLegalConsent = false

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ZStack {
            if viewModel.hasValidConsent {
                content
            } else {
                consentBlockerView
            }
        }
        .onAppear {
            viewModel.checkConsent()
        }
        .fullScreenCover(isPresented: $showingLegalConsent) {
            if let userId = viewModel.currentUserId,
               let userName = viewModel.currentUserName,
               let userAge = viewModel.currentUserAge,
               let isParent = viewModel.isParent {
                LegalConsentView(
                    userId: userId,
                    userName: userName,
                    userAge: userAge,
                    isParent: isParent,
                    onComplete: {
                        showingLegalConsent = false
                        viewModel.checkConsent()
                    }
                )
            }
        }
    }

    private var consentBlockerView: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "hand.raised.fill")
                .font(.system(size: 70))
                .foregroundColor(.orange)

            Text("Legal Consent Required")
                .font(.title)
                .fontWeight(.bold)

            if let reason = viewModel.blockedReason {
                Text(reason)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Button(action: {
                showingLegalConsent = true
            }) {
                Text(viewModel.actionButtonText)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.top, 20)

            Spacer()
        }
        .background(Color(.systemGroupedBackground))
    }
}

// MARK: - Legal Consent Gate Wrapper View Model

@MainActor
class LegalConsentGateWrapperViewModel: ObservableObject {
    private let legalConsentService: LegalConsentService = DependencyContainer.shared.legalConsentService
    private let deviceModeManager = DependencyContainer.shared.deviceModeManager as! LocalDeviceModeManager

    @Published var hasValidConsent = false
    @Published var blockedReason: String?
    @Published var actionButtonText = "Accept Terms"
    @Published var currentUserId: UUID?
    @Published var currentUserName: String?
    @Published var currentUserAge: Int?
    @Published var isParent: Bool?

    func checkConsent() {
        // Get current user info from device mode manager
        guard let profile = deviceModeManager.currentProfile else {
            hasValidConsent = false
            blockedReason = "Please complete onboarding first."
            return
        }

        currentUserId = profile.id
        currentUserName = profile.name
        currentUserAge = profile.age ?? 18  // Default to 18 if age not set
        isParent = profile.mode == .parent

        // Verify legal consent
        let verification = legalConsentService.verifyConsent(for: profile.id)

        hasValidConsent = verification.canAccessApp
        blockedReason = verification.blockedReason

        if verification.needsUpdate {
            actionButtonText = "Review Updated Terms"
        } else if !verification.hasConsent {
            actionButtonText = "Accept Terms & Privacy Policy"
        }
    }
}
