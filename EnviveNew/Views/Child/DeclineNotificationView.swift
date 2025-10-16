import SwiftUI

// MARK: - Decline Notification View

/// A full-screen overlay that displays when a child's task is declined
/// Shows the task, reason for decline, and credibility impact
struct DeclineNotificationView: View {
    let assignment: TaskAssignment
    let credibilityLost: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var bounceAnimation = false

    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissWithAnimation()
                }

            // Main content card
            VStack(spacing: 0) {
                // Header with icon
                headerSection

                // Task info
                taskInfoSection

                // Reason section
                reasonSection

                // Impact section
                impactSection

                // Dismiss button
                dismissButton
            }
            .frame(maxWidth: 340)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.3), radius: 15, x: 0, y: 8)
            .scaleEffect(showContent ? 1.0 : 0.8)
            .opacity(showContent ? 1.0 : 0)
            .padding(.horizontal, 20)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showContent = true
            }

            // Bounce animation for attention
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                withAnimation(.interpolatingSpring(stiffness: 300, damping: 10)) {
                    bounceAnimation = true
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 10) {
            // Large X icon with gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                    .scaleEffect(bounceAnimation ? 1.1 : 1.0)

                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.white)
                    .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
            }
            .padding(.top, 24)

            Text("Task Declined")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.red)

            Text("Your parent didn't approve this task")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.bottom, 16)
    }

    // MARK: - Task Info Section

    private var taskInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Text(assignment.category.icon)
                    .font(.title3)

                VStack(alignment: .leading, spacing: 3) {
                    Text(assignment.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    HStack(spacing: 6) {
                        Text(assignment.assignedLevel.shortName)
                            .font(.caption2)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.2))
                            .foregroundColor(.red)
                            .cornerRadius(3)

                        if let completedAt = assignment.completedAt {
                            Text("Submitted \(timeAgo(completedAt))")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(12)
        .background(Color.red.opacity(0.05))
        .cornerRadius(10)
        .padding(.horizontal, 16)
    }

    // MARK: - Reason Section

    private var reasonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "bubble.left.fill")
                    .font(.caption)
                    .foregroundColor(.orange)
                Text("Parent's Feedback")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            if let parentNotes = assignment.parentNotes, !parentNotes.isEmpty {
                Text(parentNotes)
                    .font(.subheadline)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            } else {
                Text("No specific reason provided")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - Impact Section

    private var impactSection: some View {
        VStack(spacing: 10) {
            Text("How This Affects You")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)

            VStack(spacing: 8) {
                // Credibility impact
                ImpactRow(
                    icon: "star.slash.fill",
                    iconColor: .red,
                    title: "Credibility",
                    value: "\(credibilityLost) points",
                    isNegative: true
                )

                // XP impact
                ImpactRow(
                    icon: "clock.fill",
                    iconColor: .gray,
                    title: "Screen Time Earned",
                    value: "0 minutes",
                    isNegative: true
                )

                // What could have earned
                HStack(spacing: 6) {
                    Image(systemName: "info.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.blue)
                    Text("You could have earned \(assignment.assignedLevel.baseXP) minutes")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 2)
            }
            .padding(10)
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Dismiss Button

    private var dismissButton: some View {
        Button(action: dismissWithAnimation) {
            Text("Got It")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .cornerRadius(10)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }

    // MARK: - Helpers

    private func dismissWithAnimation() {
        withAnimation(.easeInOut(duration: 0.2)) {
            showContent = false
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onDismiss()
        }
    }

    private func timeAgo(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        let minutes = Int(interval / 60)

        if minutes < 1 { return "just now" }
        if minutes < 60 { return "\(minutes) min ago" }

        let hours = minutes / 60
        if hours < 24 { return "\(hours) hour\(hours == 1 ? "" : "s") ago" }

        let days = hours / 24
        return "\(days) day\(days == 1 ? "" : "s") ago"
    }
}

// MARK: - Impact Row Component

private struct ImpactRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let isNegative: Bool

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.2))
                    .frame(width: 32, height: 32)

                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(iconColor)
            }

            // Title and value
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)

                HStack(spacing: 3) {
                    if isNegative {
                        Image(systemName: "arrow.down")
                            .font(.caption2)
                            .foregroundColor(.red)
                    }
                    Text(value)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isNegative ? .red : .primary)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Preview

struct DeclineNotificationView_Previews: PreviewProvider {
    static var previews: some View {
        DeclineNotificationView(
            assignment: TaskAssignment(
                templateId: UUID(),
                childId: UUID(),
                title: "Clean Your Room",
                description: "Organize toys, make bed, vacuum floor",
                category: .indoorCleaning,
                assignedLevel: .level2
            ),
            credibilityLost: -10,
            onDismiss: {}
        )
    }
}
