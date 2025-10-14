import Foundation
import Combine

// MARK: - Starter Bonus Service Protocol

protocol StarterBonusService {
    /// Check if user has received their starter bonus
    func hasReceivedStarterBonus(userId: UUID) -> Bool

    /// Grant starter bonus to new user (30 XP = 30 minutes)
    func grantStarterBonus(userId: UUID) -> Result<StarterBonusResult, StarterBonusError>

    /// Get information about the starter bonus
    func getStarterBonusInfo() -> StarterBonusInfo
}

// MARK: - Starter Bonus Models

struct StarterBonusResult {
    let userId: UUID
    let amountGranted: Int
    let message: String
    let timestamp: Date
}

struct StarterBonusInfo {
    let amount: Int
    let description: String
    let icon: String

    static let `default` = StarterBonusInfo(
        amount: 30,
        description: "Welcome bonus: 30 minutes of screen time to get you started!",
        icon: "star.fill"
    )
}

enum StarterBonusError: Error, LocalizedError {
    case alreadyReceived
    case balanceNotFound
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .alreadyReceived:
            return "Starter bonus has already been received"
        case .balanceNotFound:
            return "Could not find user balance"
        case .saveFailed:
            return "Failed to save starter bonus"
        }
    }
}

// MARK: - Starter Bonus Service Implementation

class StarterBonusServiceImpl: StarterBonusService {
    private let xpRepository: XPRepository
    private let storage: StorageService
    private let starterAmount: Int = 30

    // Storage key for tracking who has received the bonus
    private let receivedBonusesKey = "starter_bonuses_received"

    init(xpRepository: XPRepository, storage: StorageService) {
        self.xpRepository = xpRepository
        self.storage = storage
    }

    func hasReceivedStarterBonus(userId: UUID) -> Bool {
        guard let receivedBonuses: [String: Bool] = storage.load(forKey: receivedBonusesKey) else {
            return false
        }
        return receivedBonuses[userId.uuidString] ?? false
    }

    func grantStarterBonus(userId: UUID) -> Result<StarterBonusResult, StarterBonusError> {
        // Check if already received
        if hasReceivedStarterBonus(userId: userId) {
            return .failure(.alreadyReceived)
        }

        // Get or create balance
        var balance = xpRepository.getBalance(userId: userId) ?? XPBalance(userId: userId)

        // Grant the starter bonus
        balance.currentXP += starterAmount
        balance.lifetimeEarned += starterAmount

        // Save the updated balance
        xpRepository.saveBalance(balance)

        // Record that this user has received the bonus
        var receivedBonuses: [String: Bool] = storage.load(forKey: receivedBonusesKey) ?? [:]
        receivedBonuses[userId.uuidString] = true
        storage.save(receivedBonuses, forKey: receivedBonusesKey)

        // Verify the bonus was recorded
        guard hasReceivedStarterBonus(userId: userId) else {
            return .failure(.saveFailed)
        }

        let result = StarterBonusResult(
            userId: userId,
            amountGranted: starterAmount,
            message: "Welcome! You've received \(starterAmount) minutes of screen time to get started.",
            timestamp: Date()
        )

        return .success(result)
    }

    func getStarterBonusInfo() -> StarterBonusInfo {
        return .default
    }
}

// MARK: - Starter Bonus Welcome View

import SwiftUI

struct StarterBonusWelcomeView: View {
    let userId: UUID
    let onComplete: () -> Void

    @StateObject private var viewModel: StarterBonusViewModel
    @State private var showConfetti = false

    init(userId: UUID, onComplete: @escaping () -> Void) {
        self.userId = userId
        self.onComplete = onComplete
        _viewModel = StateObject(wrappedValue: StarterBonusViewModel(userId: userId))
    }

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Welcome Icon
            VStack(spacing: 16) {
                Image(systemName: "star.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.yellow)
                    .scaleEffect(showConfetti ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showConfetti)

                Text("Welcome to Envive!")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)

            // Bonus Card
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Starter Bonus")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("30")
                            .font(.system(size: 72, weight: .bold))
                            .foregroundColor(.blue)
                        Text("minutes")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }

                    Text("of screen time")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Divider()
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Complete tasks to earn more time")
                            .font(.subheadline)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Build credibility for better rewards")
                            .font(.subheadline)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Redeem XP anytime for screen time")
                            .font(.subheadline)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.blue.opacity(0.1))
                    .shadow(color: .blue.opacity(0.2), radius: 20, x: 0, y: 10)
            )

            Spacer()

            // Claim Button
            Button(action: {
                viewModel.claimStarterBonus()
            }) {
                HStack {
                    if viewModel.isClaiming {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Image(systemName: "gift.fill")
                        Text("Claim Your Bonus")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(16)
            }
            .disabled(viewModel.isClaiming)
            .padding(.horizontal)
        }
        .padding()
        .onAppear {
            showConfetti = true
        }
        .alert("Welcome Bonus Claimed!", isPresented: $viewModel.showSuccess) {
            Button("Get Started") {
                onComplete()
            }
        } message: {
            if let message = viewModel.successMessage {
                Text(message)
            }
        }
        .alert("Error", isPresented: $viewModel.showError) {
            Button("OK") {
                viewModel.dismissError()
            }
        } message: {
            if let error = viewModel.errorMessage {
                Text(error)
            }
        }
    }
}

// MARK: - Starter Bonus View Model

class StarterBonusViewModel: ObservableObject {
    @Published var isClaiming = false
    @Published var showSuccess = false
    @Published var showError = false
    @Published var successMessage: String?
    @Published var errorMessage: String?

    private let userId: UUID
    private let starterBonusService: StarterBonusService

    init(
        userId: UUID,
        starterBonusService: StarterBonusService? = nil
    ) {
        self.userId = userId
        self.starterBonusService = starterBonusService ??
            DependencyContainer.shared.starterBonusService
    }

    func claimStarterBonus() {
        isClaiming = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }

            let result = self.starterBonusService.grantStarterBonus(userId: self.userId)

            switch result {
            case .success(let bonusResult):
                self.successMessage = bonusResult.message
                self.showSuccess = true
            case .failure(let error):
                self.errorMessage = error.localizedDescription
                self.showError = true
            }

            self.isClaiming = false
        }
    }

    func dismissError() {
        showError = false
        errorMessage = nil
    }
}

// MARK: - Preview

struct StarterBonusWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        StarterBonusWelcomeView(userId: UUID()) {
            print("Bonus claimed!")
        }
    }
}
