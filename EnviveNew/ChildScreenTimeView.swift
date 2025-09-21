import SwiftUI

struct ChildScreenTimeView: View {
    @StateObject private var rewardManager = ScreenTimeRewardManager()
    @StateObject private var scheduler = ActivityScheduler()

    @State private var showingSessionOptions = false
    @State private var selectedDuration = 30

    let sessionOptions = [15, 30, 45, 60, 90, 120]

    var body: some View {
        VStack(spacing: 20) {
            screenTimeStatusCard

            if rewardManager.isScreenTimeActive {
                activeSessionCard
            } else {
                earnedTimeCard
            }
        }
        .sheet(isPresented: $showingSessionOptions) {
            sessionSelectionSheet
        }
    }

    private var screenTimeStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "hourglass")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Screen Time")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                if rewardManager.isScreenTimeActive {
                    Text("ACTIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .cornerRadius(8)
                }
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading) {
                    Text("Earned Time")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(rewardManager.formattedEarnedTime())
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                }

                Spacer()

                if rewardManager.isScreenTimeActive {
                    VStack(alignment: .trailing) {
                        Text("Session Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(rewardManager.formattedActiveTime())
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private var activeSessionCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "play.circle.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                Text("Session Active")
                    .font(.headline)
                    .fontWeight(.semibold)

                Spacer()

                Button("End Session") {
                    rewardManager.endScreenTimeSession()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Time Remaining")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(scheduler.remainingMinutes) minutes")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }

                ProgressView(value: Double(scheduler.remainingMinutes), total: Double(rewardManager.activeSessionMinutes))
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .scaleEffect(y: 2)
            }

            Text("Apps are currently unlocked. Use your time wisely!")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }

    private var earnedTimeCard: some View {
        VStack(spacing: 16) {
            if rewardManager.hasEarnedTime {
                VStack(spacing: 12) {
                    Text("Ready to start a session?")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("You have \(rewardManager.formattedEarnedTime()) of earned screen time available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Button("Start Session") {
                        showingSessionOptions = true
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(!rewardManager.canStartSession)
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "hourglass.badge.plus")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)

                    Text("No Screen Time Available")
                        .font(.headline)
                        .fontWeight(.semibold)

                    Text("Complete tasks to earn screen time! Each task rewards you with minutes you can use to unlock apps.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    NavigationLink("View Tasks") {
                        // This would navigate to the tasks view
                        Text("Tasks View")
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding()
        .background(rewardManager.hasEarnedTime ? Color.blue.opacity(0.1) : Color.orange.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke((rewardManager.hasEarnedTime ? Color.blue : Color.orange).opacity(0.3), lineWidth: 1)
        )
    }

    private var sessionSelectionSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Start Screen Time Session")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text("Available time: \(rewardManager.formattedEarnedTime())")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top)

                VStack(alignment: .leading, spacing: 12) {
                    Text("Select Duration")
                        .font(.headline)

                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(sessionOptions.filter { $0 <= rewardManager.earnedMinutes }, id: \.self) { duration in
                            sessionOptionButton(duration: duration)
                        }
                    }
                }

                Spacer()

                VStack(spacing: 12) {
                    Button("Start \(selectedDuration) Minute Session") {
                        if rewardManager.startScreenTimeSession(durationMinutes: selectedDuration) {
                            showingSessionOptions = false
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .frame(maxWidth: .infinity)
                    .disabled(selectedDuration > rewardManager.earnedMinutes)

                    Text("This will unlock your restricted apps for \(selectedDuration) minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .navigationTitle("Session Options")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        showingSessionOptions = false
                    }
                }
            }
        }
    }

    private func sessionOptionButton(duration: Int) -> some View {
        Button(action: {
            selectedDuration = duration
        }) {
            VStack(spacing: 4) {
                Text("\(duration)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("min")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selectedDuration == duration ? Color.blue : Color(.systemGray6))
            .foregroundColor(selectedDuration == duration ? .white : .primary)
            .cornerRadius(12)
        }
    }
}

// Compact version for home page integration
struct ScreenTimeStatusBanner: View {
    @StateObject private var rewardManager = ScreenTimeRewardManager()

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: rewardManager.isScreenTimeActive ? "play.circle.fill" : "hourglass")
                .font(.title2)
                .foregroundColor(rewardManager.isScreenTimeActive ? .green : .blue)

            VStack(alignment: .leading, spacing: 2) {
                Text(rewardManager.isScreenTimeActive ? "Session Active" : "Screen Time")
                    .font(.headline)
                    .fontWeight(.semibold)

                if rewardManager.isScreenTimeActive {
                    Text("\(rewardManager.formattedActiveTime()) remaining")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("\(rewardManager.formattedEarnedTime()) earned")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if rewardManager.isScreenTimeActive {
                Text("🔓")
                    .font(.title2)
            } else if rewardManager.hasEarnedTime {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("🔒")
                    .font(.title2)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct ChildScreenTimeView_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            ChildScreenTimeView()

            Divider()

            ScreenTimeStatusBanner()
        }
        .padding()
    }
}