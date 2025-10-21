import SwiftUI

// MARK: - Onboarding Question View

/// Asks users personalization questions to tailor their experience
struct OnboardingQuestionView: View {
    let onComplete: () -> Void
    let onBack: () -> Void

    @State private var currentQuestion = 0
    @State private var showContent = false
    @State private var selectedRole: UserRole?
    @State private var averageScreenTime: ScreenTimeAmount?
    @State private var biggestChallenge: ScreenTimeChallenge?
    @State private var numberOfChildren: Int = 1

    private let totalQuestions = 3

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
                // Progress bar
                progressBar

                Spacer()

                // Question content
                Group {
                    switch currentQuestion {
                    case 0:
                        questionOne
                    case 1:
                        questionTwo
                    case 2:
                        questionThree
                    default:
                        EmptyView()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()

                // Navigation buttons
                navigationButtons
            }
            .padding(.horizontal, 28)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                showContent = true
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                ForEach(0..<totalQuestions, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentQuestion ? Color.white : Color.white.opacity(0.3))
                        .frame(height: 4)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 20)

            HStack {
                Text("Question \(currentQuestion + 1) of \(totalQuestions)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
            }
        }
    }

    // MARK: - Question 1: Role Selection

    private var questionOne: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("👋")
                    .font(.system(size: 60))
                    .opacity(showContent ? 1.0 : 0)
                    .scaleEffect(showContent ? 1.0 : 0.5)

                Text("First things first...")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)

                Text("Are you a parent or a child?")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .opacity(showContent ? 1.0 : 0)
            }

            VStack(spacing: 16) {
                OptionButton(
                    icon: "👨‍👩‍👧‍👦",
                    title: "Parent",
                    subtitle: "I manage my family's screen time",
                    isSelected: selectedRole == .parent
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedRole = .parent
                    }
                }

                OptionButton(
                    icon: "🧒",
                    title: "Child",
                    subtitle: "I earn screen time by doing tasks",
                    isSelected: selectedRole == .child
                ) {
                    withAnimation(.spring(response: 0.3)) {
                        selectedRole = .child
                    }
                }
            }
        }
    }

    // MARK: - Question 2: Screen Time Amount

    private var questionTwo: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text(selectedRole == .parent ? "📱" : "⏰")
                    .font(.system(size: 60))

                Text(selectedRole == .parent ? "How much screen time?" : "How much time do you get?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(selectedRole == .parent ? "On average, how much daily screen time do your kids get?" : "How many hours of screen time do you usually get per day?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(ScreenTimeAmount.allCases, id: \.self) { amount in
                    CompactOptionButton(
                        title: amount.displayText,
                        isSelected: averageScreenTime == amount
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            averageScreenTime = amount
                        }
                    }
                }
            }
        }
    }

    // MARK: - Question 3: Biggest Challenge

    private var questionThree: some View {
        VStack(spacing: 32) {
            VStack(spacing: 12) {
                Text("💭")
                    .font(.system(size: 60))

                Text("What's the struggle?")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                Text(selectedRole == .parent ? "What's your biggest screen time challenge?" : "What's hardest for you about screen time limits?")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                ForEach(ScreenTimeChallenge.allCases(for: selectedRole ?? .parent), id: \.self) { challenge in
                    CompactOptionButton(
                        title: challenge.displayText,
                        isSelected: biggestChallenge == challenge
                    ) {
                        withAnimation(.spring(response: 0.3)) {
                            biggestChallenge = challenge
                        }
                    }
                }
            }
        }
    }

    // MARK: - Navigation Buttons

    private var navigationButtons: some View {
        VStack(spacing: 12) {
            // Continue/Finish button
            Button(action: handleContinue) {
                HStack(spacing: 10) {
                    Text(currentQuestion == totalQuestions - 1 ? "Get Started" : "Continue")
                        .font(.system(size: 17, weight: .semibold))
                    Image(systemName: currentQuestion == totalQuestions - 1 ? "checkmark" : "arrow.right")
                        .font(.system(size: 16, weight: .semibold))
                }
                .foregroundColor(canContinue ? Color.blue.opacity(0.9) : Color.gray)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(12)
                .opacity(canContinue ? 1.0 : 0.5)
            }
            .disabled(!canContinue)

            // Back button
            Button(action: {
                if currentQuestion > 0 {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        currentQuestion -= 1
                    }
                } else {
                    onBack()
                }
            }) {
                Text("Back")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.vertical, 10)
            }
        }
        .padding(.bottom, 30)
    }

    // MARK: - Computed Properties

    private var canContinue: Bool {
        switch currentQuestion {
        case 0:
            return selectedRole != nil
        case 1:
            return averageScreenTime != nil
        case 2:
            return biggestChallenge != nil
        default:
            return false
        }
    }

    // MARK: - Actions

    private func handleContinue() {
        if currentQuestion < totalQuestions - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentQuestion += 1
            }
        } else {
            // Save responses
            saveUserResponses()
            onComplete()
        }
    }

    private func saveUserResponses() {
        // Save to UserDefaults or backend
        if let role = selectedRole {
            UserDefaults.standard.set(role.rawValue, forKey: "userRole")
        }
        if let screenTime = averageScreenTime {
            UserDefaults.standard.set(screenTime.rawValue, forKey: "averageScreenTime")
        }
        if let challenge = biggestChallenge {
            UserDefaults.standard.set(challenge.rawValue, forKey: "biggestChallenge")
        }
        print("✅ User responses saved: Role=\(selectedRole?.rawValue ?? ""), ScreenTime=\(averageScreenTime?.rawValue ?? ""), Challenge=\(biggestChallenge?.rawValue ?? "")")
    }
}

// MARK: - Option Button Component

private struct OptionButton: View {
    let icon: String
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Text(icon)
                    .font(.system(size: 40))

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                }
            }
            .padding(20)
            .background(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Compact Option Button

private struct CompactOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(isSelected ? Color.white.opacity(0.25) : Color.white.opacity(0.1))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.white.opacity(0.5) : Color.clear, lineWidth: 1.5)
            )
        }
    }
}

// MARK: - Data Models

enum UserRole: String {
    case parent = "parent"
    case child = "child"
}

enum ScreenTimeAmount: String, CaseIterable {
    case lessThanOne = "less_than_1"
    case oneToTwo = "1_to_2"
    case twoToFour = "2_to_4"
    case fourPlus = "4_plus"

    var displayText: String {
        switch self {
        case .lessThanOne: return "Less than 1 hour"
        case .oneToTwo: return "1-2 hours"
        case .twoToFour: return "2-4 hours"
        case .fourPlus: return "4+ hours"
        }
    }
}

enum ScreenTimeChallenge: String {
    // Parent challenges
    case tooMuchTime = "too_much_time"
    case constantBattles = "constant_battles"
    case lackMotivation = "lack_motivation"
    case noStructure = "no_structure"

    // Child challenges
    case notEnoughTime = "not_enough_time"
    case unfairRules = "unfair_rules"
    case wantMoreFreedom = "want_more_freedom"
    case hardToEarn = "hard_to_earn"

    var displayText: String {
        switch self {
        // Parent
        case .tooMuchTime: return "Kids want too much screen time"
        case .constantBattles: return "Constant battles about limits"
        case .lackMotivation: return "Kids lack motivation to help out"
        case .noStructure: return "No clear reward system"
        // Child
        case .notEnoughTime: return "I don't get enough time"
        case .unfairRules: return "The rules feel unfair"
        case .wantMoreFreedom: return "I want more freedom"
        case .hardToEarn: return "It's too hard to earn more time"
        }
    }

    static func allCases(for role: UserRole) -> [ScreenTimeChallenge] {
        switch role {
        case .parent:
            return [.tooMuchTime, .constantBattles, .lackMotivation, .noStructure]
        case .child:
            return [.notEnoughTime, .unfairRules, .wantMoreFreedom, .hardToEarn]
        }
    }
}

// MARK: - Preview

struct OnboardingQuestionView_Previews: PreviewProvider {
    static var previews: some View {
        OnboardingQuestionView(onComplete: {}, onBack: {})
    }
}
