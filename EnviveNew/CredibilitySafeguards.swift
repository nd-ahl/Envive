import SwiftUI
import UserNotifications
import Combine

// MARK: - Credibility Safeguards Manager

class CredibilitySafeguardsManager: ObservableObject {
    @Published var showFirstTimeWarning = false
    @Published var showAppealSheet = false
    @Published var showLowCredibilityAlert = false
    @Published var currentAppealVerification: TaskVerification?

    private let userDefaults = UserDefaults.standard
    private let hasSeenWarningKey = "hasSeenCredibilityWarning"

    init() {
        checkFirstTimeWarning()
    }

    func checkFirstTimeWarning() {
        if !userDefaults.bool(forKey: hasSeenWarningKey) {
            showFirstTimeWarning = true
        }
    }

    func dismissFirstTimeWarning() {
        userDefaults.set(true, forKey: hasSeenWarningKey)
        showFirstTimeWarning = false
    }

    func initiateAppeal(for verification: TaskVerification) {
        guard verification.status == .rejected,
              let deadline = verification.appealDeadline,
              Date() < deadline else {
            return
        }

        currentAppealVerification = verification
        showAppealSheet = true
    }

    func canAppeal(verification: TaskVerification) -> Bool {
        guard verification.status == .rejected,
              let deadline = verification.appealDeadline else {
            return false
        }
        return Date() < deadline
    }

    func timeRemainingForAppeal(verification: TaskVerification) -> String? {
        guard let deadline = verification.appealDeadline else {
            return nil
        }

        let remaining = deadline.timeIntervalSince(Date())
        if remaining <= 0 {
            return nil
        }

        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m remaining"
        } else {
            return "\(minutes)m remaining"
        }
    }

    func checkLowCredibilityThreshold(score: Int) {
        if score < 60 && !showLowCredibilityAlert {
            showLowCredibilityAlert = true
        }
    }
}

// MARK: - First Time Warning Dialog

struct FirstTimeCredibilityWarning: View {
    @Binding var isPresented: Bool
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Background dimmer
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Prevent dismissal by tapping outside
                }

            // Warning Card
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)

                    Text("Understanding Credibility")
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Your credibility score affects how much screen time you earn from XP")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding()

                Divider()

                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        infoSection(
                            icon: "checkmark.circle.fill",
                            color: .green,
                            title: "Build Trust",
                            description: "Complete tasks honestly and earn +2 points per approved task. Every 10 approved tasks gives you a +5 bonus!"
                        )

                        infoSection(
                            icon: "xmark.circle.fill",
                            color: .red,
                            title: "Consequences Matter",
                            description: "If a parent rejects your task, you'll lose 10-15 credibility points and your streak will reset."
                        )

                        infoSection(
                            icon: "chart.line.uptrend.xyaxis",
                            color: .blue,
                            title: "Better Rates",
                            description: "Higher credibility = better XP conversion rates. Excellent (90-100) gives 1.2x multiplier!"
                        )

                        infoSection(
                            icon: "clock.arrow.circlepath",
                            color: .purple,
                            title: "Second Chances",
                            description: "Old downvotes fade over time. After 30 days they count 50% less, and after 60 days they're removed completely."
                        )

                        infoSection(
                            icon: "hand.raised.fill",
                            color: .orange,
                            title: "You Can Appeal",
                            description: "If you disagree with a rejection, you have 24 hours to appeal and explain your side."
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Credibility Tiers:")
                                .font(.headline)
                                .padding(.bottom, 4)

                            tierRow(name: "Excellent", range: "90-100", multiplier: "1.2x", color: .green)
                            tierRow(name: "Good", range: "75-89", multiplier: "1.0x", color: .green)
                            tierRow(name: "Fair", range: "60-74", multiplier: "0.8x", color: .yellow)
                            tierRow(name: "Poor", range: "40-59", multiplier: "0.5x", color: .orange)
                            tierRow(name: "Very Poor", range: "0-39", multiplier: "0.3x", color: .red)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                    .padding()
                }
                .frame(maxHeight: 400)

                Divider()

                // Footer
                VStack(spacing: 12) {
                    Text("Be honest, work hard, and build trust!")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)

                    Button(action: {
                        onDismiss()
                        isPresented = false
                    }) {
                        Text("I Understand")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .frame(maxWidth: 500)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 20)
            .padding(32)
        }
    }

    private func infoSection(icon: String, color: Color, title: String, description: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }

    private func tierRow(name: String, range: String, multiplier: String, color: Color) -> some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)

            Text(name)
                .font(.subheadline)
                .frame(width: 80, alignment: .leading)

            Text(range)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 60, alignment: .leading)

            Spacer()

            Text(multiplier)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
    }
}

// MARK: - Appeal Workflow

struct TaskAppealSheet: View {
    @Environment(\.dismiss) var dismiss
    let verification: TaskVerification
    let onSubmitAppeal: (String) -> Void

    @State private var appealNotes = ""
    @State private var showConfirmation = false

    var timeRemaining: String {
        guard let deadline = verification.appealDeadline else {
            return "Expired"
        }

        let remaining = deadline.timeIntervalSince(Date())
        if remaining <= 0 {
            return "Expired"
        }

        let hours = Int(remaining / 3600)
        let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)

        if hours > 0 {
            return "\(hours)h \(minutes)m left"
        } else {
            return "\(minutes)m left"
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.bubble.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.purple)

                        Text("Appeal Task Rejection")
                            .font(.title2)
                            .fontWeight(.bold)

                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                                .foregroundColor(.orange)
                            Text(timeRemaining)
                                .font(.subheadline)
                                .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.top)

                    // Task Info
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Rejected Task")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(verification.taskTitle)
                                    .font(.headline)
                                Spacer()
                                Text("\(verification.taskXPReward) XP")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                            }

                            if let description = verification.taskDescription {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text("Category: \(verification.taskCategory)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    // Parent's Reason
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Parent's Reason for Rejection")
                            .font(.headline)

                        Text(verification.notes ?? "No reason provided")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }

                    // Appeal Form
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your Appeal (Required)")
                            .font(.headline)

                        Text("Explain why you believe this task should be approved. Be respectful and honest.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $appealNotes)
                            .frame(height: 150)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )

                        Text("\(appealNotes.count)/500 characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }

                    // Important Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Important:")
                            .font(.headline)

                        infoRow(
                            icon: "info.circle.fill",
                            text: "Your parent will review your appeal and make a final decision",
                            color: .blue
                        )

                        infoRow(
                            icon: "exclamationmark.triangle.fill",
                            text: "The final decision cannot be appealed again",
                            color: .orange
                        )

                        infoRow(
                            icon: "hand.thumbsup.fill",
                            text: "If approved, your credibility will be restored",
                            color: .green
                        )
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Submit Button
                    Button(action: {
                        showConfirmation = true
                    }) {
                        Text("Submit Appeal")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(appealNotes.count >= 20 ? Color.purple : Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    .disabled(appealNotes.count < 20)

                    Text("Minimum 20 characters required")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Appeal Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Submit Appeal?", isPresented: $showConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Submit") {
                    onSubmitAppeal(appealNotes)
                    dismiss()
                }
            } message: {
                Text("Your parent will be notified and will review your appeal. This is your final chance to contest this decision.")
            }
        }
    }

    private func infoRow(icon: String, text: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 20)

            Text(text)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Low Credibility Alert

struct LowCredibilityAlert: View {
    @Binding var isPresented: Bool
    let currentScore: Int
    let tier: String
    let conversionRate: Double

    var body: some View {
        VStack(spacing: 20) {
            // Icon
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.orange)

            // Title
            Text("Low Credibility Warning")
                .font(.title2)
                .fontWeight(.bold)

            // Score Display
            VStack(spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(currentScore)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.orange)

                    Text("/ 100")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }

                Text(tier)
                    .font(.headline)
                    .foregroundColor(.orange)
            }

            // Impact
            VStack(alignment: .leading, spacing: 12) {
                Text("How this affects you:")
                    .font(.headline)

                impactRow(
                    icon: "chart.line.downtrend.xyaxis",
                    text: "Your XP conversion rate is only \(String(format: "%.1fx", conversionRate))",
                    color: .red
                )

                impactRow(
                    icon: "hourglass",
                    text: "You're earning less screen time per task",
                    color: .orange
                )

                impactRow(
                    icon: "arrow.up.circle.fill",
                    text: "Complete approved tasks to improve your score",
                    color: .green
                )
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(12)

            // Action Tips
            VStack(alignment: .leading, spacing: 8) {
                Text("Tips to improve:")
                    .font(.headline)

                bulletPoint("Take clear photos showing completed tasks")
                bulletPoint("Follow task instructions carefully")
                bulletPoint("Complete tasks at the correct location")
                bulletPoint("Be honest and thorough in your work")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            // Dismiss Button
            Button(action: {
                isPresented = false
            }) {
                Text("I Understand")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding()
    }

    private func impactRow(icon: String, text: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)

            Text(text)
                .font(.subheadline)
        }
    }

    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.subheadline)
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Downvote Impact Dialog

struct DownvoteImpactDialog: View {
    @Binding var isPresented: Bool
    let taskTitle: String
    let parentNotes: String
    let previousScore: Int
    let newScore: Int
    let pointsLost: Int
    let canAppeal: Bool
    let onAppeal: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Header
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.red)

            Text("Task Rejected")
                .font(.title2)
                .fontWeight(.bold)

            // Task Info
            VStack(spacing: 8) {
                Text(taskTitle)
                    .font(.headline)
                    .multilineTextAlignment(.center)

                Text("Your parent has rejected this task")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            // Parent's Notes
            if !parentNotes.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Reason:")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)

                    Text(parentNotes)
                        .font(.subheadline)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
            }

            // Impact
            VStack(spacing: 12) {
                Text("Impact on Your Credibility")
                    .font(.headline)

                HStack(spacing: 24) {
                    VStack(spacing: 4) {
                        Text("\(previousScore)")
                            .font(.title)
                            .fontWeight(.bold)
                        Text("Before")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Image(systemName: "arrow.right")
                        .foregroundColor(.red)

                    VStack(spacing: 4) {
                        Text("\(newScore)")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                        Text("After")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Text("\(pointsLost) points")
                    .font(.headline)
                    .foregroundColor(.red)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)

            // Additional Impact
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Your task streak has been reset")
                        .font(.subheadline)
                }

                HStack(spacing: 8) {
                    Image(systemName: "chart.line.downtrend.xyaxis")
                        .foregroundColor(.orange)
                    Text("Your XP conversion rate may be affected")
                        .font(.subheadline)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // Actions
            if canAppeal {
                VStack(spacing: 12) {
                    Button(action: {
                        isPresented = false
                        onAppeal()
                    }) {
                        Text("Appeal This Decision")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }

                    Text("You have 24 hours to appeal")
                        .font(.caption)
                        .foregroundColor(.purple)
                }
            }

            Button(action: {
                isPresented = false
            }) {
                Text(canAppeal ? "Dismiss" : "I Understand")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
}

// MARK: - Preview

struct CredibilitySafeguards_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            FirstTimeCredibilityWarning(isPresented: .constant(true), onDismiss: {})
                .previewDisplayName("First Time Warning")

            LowCredibilityAlert(
                isPresented: .constant(true),
                currentScore: 45,
                tier: "Poor",
                conversionRate: 0.5
            )
            .previewDisplayName("Low Credibility Alert")
        }
    }
}