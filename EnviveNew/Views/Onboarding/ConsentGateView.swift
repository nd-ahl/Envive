//
//  ConsentGateView.swift
//  EnviveNew
//
//  Gate view that blocks app access until legal consent is obtained
//

import SwiftUI
import Combine

struct ConsentGateView: View {
    let userId: UUID
    let userName: String
    let userAge: Int
    let isParent: Bool

    @StateObject private var viewModel: ConsentGateViewModel
    @State private var showingConsentView = false

    init(userId: UUID, userName: String, userAge: Int, isParent: Bool) {
        self.userId = userId
        self.userName = userName
        self.userAge = userAge
        self.isParent = isParent
        _viewModel = StateObject(wrappedValue: ConsentGateViewModel(
            legalConsentService: DependencyContainer.shared.legalConsentService,
            userId: userId
        ))
    }

    var body: some View {
        Group {
            if viewModel.hasValidConsent {
                // User has consent, show normal app content
                // This should be handled by parent view
                EmptyView()
            } else {
                // Show consent blocker
                consentBlockerView
            }
        }
        .onAppear {
            viewModel.checkConsent()
        }
        .fullScreenCover(isPresented: $showingConsentView) {
            LegalConsentView(
                userId: userId,
                userName: userName,
                userAge: userAge,
                isParent: isParent,
                onComplete: {
                    showingConsentView = false
                    viewModel.checkConsent()
                }
            )
        }
    }

    private var consentBlockerView: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            Image(systemName: "hand.raised.fill")
                .font(.system(size: 70))
                .foregroundColor(.orange)

            // Title
            Text("Consent Required")
                .font(.title)
                .fontWeight(.bold)

            // Message
            if let reason = viewModel.blockedReason {
                Text(reason)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            // Action Button
            Button(action: {
                showingConsentView = true
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

// MARK: - Consent Gate View Model

@MainActor
class ConsentGateViewModel: ObservableObject {
    private let legalConsentService: LegalConsentService
    private let userId: UUID

    @Published var hasValidConsent = false
    @Published var blockedReason: String?
    @Published var actionButtonText = "Review and Accept"

    init(legalConsentService: LegalConsentService, userId: UUID) {
        self.legalConsentService = legalConsentService
        self.userId = userId
    }

    func checkConsent() {
        let verification = legalConsentService.verifyConsent(for: userId)

        hasValidConsent = verification.canAccessApp
        blockedReason = verification.blockedReason

        if verification.needsUpdate {
            actionButtonText = "Review Updated Terms"
        } else if !verification.hasConsent {
            actionButtonText = "Accept Terms"
        }
    }
}
