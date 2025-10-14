import SwiftUI

// MARK: - Task Completion Result View

struct TaskCompletionResultView: View {
    let result: TaskApprovalResult
    let onDismiss: () -> Void

    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 24) {
            // Success Icon
            VStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 70))
                    .foregroundColor(.green)
                    .scaleEffect(showConfetti ? 1.0 : 0.5)
                    .animation(.spring(response: 0.6, dampingFraction: 0.7), value: showConfetti)

                Text("Task Approved!")
                    .font(.title)
                    .fontWeight(.bold)

                Text(result.taskTitle)
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)

            // XP Earned Card
            VStack(spacing: 16) {
                HStack {
                    Text("XP Earned")
                        .font(.headline)
                    Spacer()
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(result.earnedXP)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.blue)
                    Text("XP")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }

                // Time spent
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.blue)
                    Text("\(result.timeSpent) minutes of work")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.blue.opacity(0.1))
            )

            // Credibility Impact Card
            VStack(spacing: 16) {
                HStack {
                    Image(systemName: "medal.fill")
                        .foregroundColor(credibilityColor)
                    Text("Credibility Impact")
                        .font(.headline)
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Your Credibility:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(result.credibilityScore) (\(result.credibilityTier))")
                            .fontWeight(.semibold)
                            .foregroundColor(credibilityColor)
                    }

                    HStack {
                        Text("Earning Rate:")
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(result.earningRate)%")
                            .fontWeight(.semibold)
                            .foregroundColor(credibilityColor)
                    }

                    Divider()

                    // Calculation breakdown
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How XP was calculated:")
                            .font(.caption)
                            .fontWeight(.semibold)

                        HStack {
                            Text("Base XP (1 XP/min):")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(result.baseXP) XP")
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        HStack {
                            Text("× Credibility Rate:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(result.earningRate)%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }

                        Divider()

                        HStack {
                            Text("Total Earned:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Spacer()
                            Text("\(result.earnedXP) XP")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)

                    // Tip for improving credibility
                    if result.credibilityScore < 95 {
                        HStack(spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(.yellow)
                            Text("Keep completing tasks honestly to reach 95+ credibility and earn full XP!")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.yellow.opacity(0.1))
                        .cornerRadius(10)
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            Text("Excellent! You're earning full XP.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(12)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(credibilityColor.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                    )
            )

            Spacer()

            // Dismiss Button
            Button(action: onDismiss) {
                Text("Got It!")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .onAppear {
            showConfetti = true
        }
    }

    private var credibilityColor: Color {
        switch result.credibilityScore {
        case 95...100: return .green
        case 80...94:  return .blue
        case 60...79:  return .yellow
        case 40...59:  return .orange
        default:       return .red
        }
    }
}

// MARK: - Preview

struct TaskCompletionResultView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Excellent credibility
            TaskCompletionResultView(
                result: TaskApprovalResult(
                    taskTitle: "Morning Run",
                    timeSpent: 30,
                    baseXP: 30,
                    earnedXP: 30,
                    credibilityScore: 100,
                    credibilityTier: "Excellent",
                    earningRate: 100
                ),
                onDismiss: {}
            )
            .previewDisplayName("Excellent (100%)")

            // Good credibility
            TaskCompletionResultView(
                result: TaskApprovalResult(
                    taskTitle: "Math Homework",
                    timeSpent: 45,
                    baseXP: 45,
                    earnedXP: 41,
                    credibilityScore: 85,
                    credibilityTier: "Good",
                    earningRate: 90
                ),
                onDismiss: {}
            )
            .previewDisplayName("Good (90%)")

            // Fair credibility
            TaskCompletionResultView(
                result: TaskApprovalResult(
                    taskTitle: "Clean Room",
                    timeSpent: 20,
                    baseXP: 20,
                    earnedXP: 15,
                    credibilityScore: 70,
                    credibilityTier: "Fair",
                    earningRate: 75
                ),
                onDismiss: {}
            )
            .previewDisplayName("Fair (75%)")
        }
    }
}
