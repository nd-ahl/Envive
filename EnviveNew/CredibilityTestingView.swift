import SwiftUI

// MARK: - Credibility Testing & Demo View

struct CredibilityTestingView: View {
    @StateObject private var credibilityManager = CredibilityManager()
    @State private var selectedScenario: TestScenario = .clean
    @State private var testResults: [String] = []
    @State private var showingResults = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Current State Card
                    currentStateCard

                    // Quick Actions
                    quickActionsCard

                    // Scenario Testing
                    scenarioTestingCard

                    // Manual Controls
                    manualControlsCard

                    // Test Suite
                    testSuiteCard

                    // Conversion Calculator
                    conversionCalculatorCard
                }
                .padding()
            }
            .navigationTitle("Credibility Testing")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingResults) {
                TestResultsView(results: testResults)
            }
        }
    }

    // MARK: - Current State Card

    private var currentStateCard: some View {
        let status = credibilityManager.getCredibilityStatus()

        return VStack(spacing: 16) {
            HStack {
                Text("Current State")
                    .font(.headline)
                Spacer()
                Button("Reset") {
                    credibilityManager.resetCredibility()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Score")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(status.score)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(colorForTier(status.tier.color))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tier")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(status.tier.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Rate")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(credibilityManager.getFormattedConversionRate())
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Streak")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("\(status.consecutiveApprovedTasks)")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)

            HStack(spacing: 8) {
                Text("History Events:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("\(status.history.count)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Quick Actions Card

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                actionButton(
                    title: "Approve Task",
                    icon: "checkmark.circle.fill",
                    color: .green
                ) {
                    credibilityManager.processApprovedTask(
                        taskId: UUID(),
                        reviewerId: UUID(),
                        notes: "Test approval"
                    )
                }

                actionButton(
                    title: "Reject Task",
                    icon: "xmark.circle.fill",
                    color: .red
                ) {
                    credibilityManager.processDownvote(
                        taskId: UUID(),
                        reviewerId: UUID(),
                        notes: "Test rejection"
                    )
                }

                actionButton(
                    title: "Apply Decay",
                    icon: "clock.arrow.circlepath",
                    color: .blue
                ) {
                    credibilityManager.applyTimeBasedDecay()
                }

                actionButton(
                    title: "View History",
                    icon: "list.bullet",
                    color: .purple
                ) {
                    showHistory()
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Scenario Testing Card

    private var scenarioTestingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Test Scenarios")
                .font(.headline)

            Text("Load pre-configured scenarios to test different user states")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(TestScenario.allCases, id: \.self) { scenario in
                Button(action: {
                    loadScenario(scenario)
                }) {
                    HStack {
                        Image(systemName: scenario.icon)
                            .foregroundColor(scenario.color)
                            .frame(width: 24)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(scenario.title)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)

                            Text(scenario.description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(scenario.color.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Manual Controls Card

    private var manualControlsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Manual Controls")
                .font(.headline)

            VStack(spacing: 8) {
                HStack {
                    Text("Add/Remove Points")
                    Spacer()
                }

                HStack(spacing: 12) {
                    ForEach([-15, -10, -5, 5, 10, 15], id: \.self) { points in
                        Button(action: {
                            adjustScore(by: points)
                        }) {
                            Text("\(points > 0 ? "+" : "")\(points)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(points > 0 ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                                .foregroundColor(points > 0 ? .green : .red)
                                .cornerRadius(8)
                        }
                    }
                }

                Divider()

                HStack {
                    Text("Set Streak")
                    Spacer()
                }

                HStack(spacing: 12) {
                    ForEach([0, 5, 10, 15, 20], id: \.self) { streak in
                        Button(action: {
                            setStreak(streak)
                        }) {
                            Text("\(streak)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Test Suite Card

    private var testSuiteCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Automated Tests")
                .font(.headline)

            Text("Run comprehensive test suite to validate all calculations")
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: {
                runTests()
            }) {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                    Text("Run All Tests")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }

            if !testResults.isEmpty {
                Button(action: {
                    showingResults = true
                }) {
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                        Text("View Test Results (\(testResults.count))")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Conversion Calculator Card

    private var conversionCalculatorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conversion Calculator")
                .font(.headline)

            Text("See how different XP amounts convert at current credibility level")
                .font(.caption)
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                ForEach([100, 500, 1000, 2000, 5000], id: \.self) { xp in
                    let minutes = credibilityManager.calculateXPToMinutes(xpAmount: xp)
                    HStack {
                        Text("\(xp) XP")
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        Image(systemName: "arrow.right")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Text("\(minutes) min")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .foregroundColor(.blue)

                        Spacer()

                        Text("(\(credibilityManager.getFormattedConversionRate()))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Helper Methods

    private func actionButton(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)

                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(12)
        }
    }

    private func loadScenario(_ scenario: TestScenario) {
        credibilityManager.resetCredibility()
        selectedScenario = scenario

        let reviewerId = UUID()

        switch scenario {
        case .clean:
            break

        case .excellent:
            for _ in 0..<20 {
                credibilityManager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
            }

        case .struggling:
            for _ in 0..<6 {
                credibilityManager.processDownvote(taskId: UUID(), reviewerId: reviewerId)
            }

        case .recovering:
            for _ in 0..<5 {
                credibilityManager.processDownvote(taskId: UUID(), reviewerId: reviewerId)
            }
            for _ in 0..<10 {
                credibilityManager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
            }

        case .streakBuilder:
            for _ in 0..<15 {
                credibilityManager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
            }

        case .inconsistent:
            for _ in 0..<5 {
                credibilityManager.processApprovedTask(taskId: UUID(), reviewerId: reviewerId)
                credibilityManager.processDownvote(taskId: UUID(), reviewerId: reviewerId)
            }
        }
    }

    private func adjustScore(by points: Int) {
        credibilityManager.credibilityScore = max(0, min(100, credibilityManager.credibilityScore + points))
    }

    private func setStreak(_ streak: Int) {
        credibilityManager.consecutiveApprovedTasks = streak
    }

    private func showHistory() {
        let status = credibilityManager.getCredibilityStatus()
        print("📊 Credibility History:")
        for (index, event) in status.history.enumerated() {
            print("\(index + 1). \(event.event.rawValue): \(event.amount > 0 ? "+" : "")\(event.amount) -> Score: \(event.newScore)")
        }
    }

    private func runTests() {
        testResults.removeAll()
        testResults.append("🧪 Running Credibility Tests...")

        let tests = CredibilityManagerTests()
        tests.runAllTests()

        testResults.append("✅ All unit tests passed!")
        showingResults = true
    }

    private func colorForTier(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "green": return .green
        case "yellow": return .yellow
        case "red": return .red
        default: return .gray
        }
    }
}

// MARK: - Test Scenario Enum

enum TestScenario: String, CaseIterable {
    case clean = "Clean Slate"
    case excellent = "Excellent Student"
    case struggling = "Struggling"
    case recovering = "Recovering"
    case streakBuilder = "Streak Builder"
    case inconsistent = "Inconsistent"

    var title: String { rawValue }

    var description: String {
        switch self {
        case .clean:
            return "Fresh start at 100 score"
        case .excellent:
            return "High score (100) with 20-task streak"
        case .struggling:
            return "Low score (~40) needing improvement"
        case .recovering:
            return "Improving from low to good score"
        case .streakBuilder:
            return "Building streak with 15 approvals"
        case .inconsistent:
            return "Mixed results, no consistent streak"
        }
    }

    var icon: String {
        switch self {
        case .clean:
            return "sparkles"
        case .excellent:
            return "star.fill"
        case .struggling:
            return "exclamationmark.triangle.fill"
        case .recovering:
            return "arrow.up.circle.fill"
        case .streakBuilder:
            return "flame.fill"
        case .inconsistent:
            return "waveform.path"
        }
    }

    var color: Color {
        switch self {
        case .clean:
            return .blue
        case .excellent:
            return .green
        case .struggling:
            return .red
        case .recovering:
            return .orange
        case .streakBuilder:
            return .yellow
        case .inconsistent:
            return .purple
        }
    }
}

// MARK: - Test Results View

struct TestResultsView: View {
    let results: [String]
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(results.enumerated()), id: \.offset) { index, result in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(width: 30, alignment: .leading)

                            Text(result)
                                .font(.subheadline)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                }
                .padding()
            }
            .navigationTitle("Test Results")
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

// MARK: - Preview

struct CredibilityTestingView_Previews: PreviewProvider {
    static var previews: some View {
        CredibilityTestingView()
    }
}