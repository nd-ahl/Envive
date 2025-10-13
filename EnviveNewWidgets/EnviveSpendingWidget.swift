//
//  EnviveSpendingWidget.swift
//  EnviveNewWidgets
//
//  Created by Claude on 9/30/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared UserDefaults
private let sharedDefaults = UserDefaults(suiteName: "group.com.neal.envivenew.screentime")!

// MARK: - Session State
enum SessionState: String {
    case idle           // Initial state - show balance and spend button
    case selecting      // Show time options
    case active         // Countdown timer running
}

// MARK: - App Intents
struct StartSpendingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Spending"

    func perform() async throws -> some IntentResult {
        // Show time selection options
        sharedDefaults.set(SessionState.selecting.rawValue, forKey: "EnviveSessionState")
        sharedDefaults.synchronize()
        WidgetCenter.shared.reloadTimelines(ofKind: "EnviveSpendingWidget")
        return .result()
    }
}

struct SelectTimeIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Time"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Minutes")
    var minutes: Int

    func perform() async throws -> some IntentResult {
        print("🟢 ENVIVE WIDGET: Starting \(minutes) minute session")

        // Start an active session with countdown
        let sessionStart = Date()
        sharedDefaults.set(SessionState.active.rawValue, forKey: "EnviveSessionState")
        sharedDefaults.set(sessionStart.timeIntervalSince1970, forKey: "EnviveSessionStartTime")
        sharedDefaults.set(minutes, forKey: "EnviveSessionDuration")

        // Store pending request for app to pick up
        sharedDefaults.set(minutes, forKey: "PendingScreenTimeMinutes")
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: "PendingScreenTimeTimestamp")
        sharedDefaults.synchronize()

        print("🔵 ENVIVE WIDGET: App will open and handle shield removal")

        WidgetCenter.shared.reloadTimelines(ofKind: "EnviveSpendingWidget")
        return .result()
    }
}

struct EndSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "End Session"
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        print("🛑 ENVIVE WIDGET: User requested to end session")

        // Signal to app that session should end
        sharedDefaults.set(true, forKey: "EndSessionRequested")
        sharedDefaults.synchronize()

        // Reset widget state
        sharedDefaults.set(SessionState.idle.rawValue, forKey: "EnviveSessionState")
        sharedDefaults.removeObject(forKey: "EnviveSessionStartTime")
        sharedDefaults.removeObject(forKey: "EnviveSessionDuration")
        sharedDefaults.synchronize()

        WidgetCenter.shared.reloadTimelines(ofKind: "EnviveSpendingWidget")

        print("🔵 ENVIVE WIDGET: App will open to end session and reapply shields")

        return .result()
    }
}

// MARK: - Widget Entry
struct EnviveSpendingEntry: TimelineEntry {
    let date: Date
    let sessionState: SessionState
    let availableMinutes: Int
    let sessionStartTime: Date?
    let sessionDuration: Int?

    var remainingSeconds: Int? {
        guard let startTime = sessionStartTime,
              let duration = sessionDuration else {
            return nil
        }

        let elapsed = Date().timeIntervalSince(startTime)
        let total = TimeInterval(duration * 60)
        let remaining = max(0, total - elapsed)
        return Int(remaining)
    }

    static var initial: EnviveSpendingEntry {
        EnviveSpendingEntry(
            date: Date(),
            sessionState: .idle,
            availableMinutes: 180, // Default 3 hours
            sessionStartTime: nil,
            sessionDuration: nil
        )
    }
}

// MARK: - Provider
struct EnviveSpendingProvider: TimelineProvider {
    func placeholder(in context: Context) -> EnviveSpendingEntry {
        .initial
    }

    func getSnapshot(in context: Context, completion: @escaping (EnviveSpendingEntry) -> ()) {
        completion(.initial)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<EnviveSpendingEntry>) -> ()) {
        let currentDate = Date()

        // Load state from shared UserDefaults
        let stateRaw = sharedDefaults.string(forKey: "EnviveSessionState") ?? SessionState.idle.rawValue
        let sessionState = SessionState(rawValue: stateRaw) ?? .idle

        // Initialize available minutes if not set (default 3 hours = 180 minutes)
        var availableMinutes = sharedDefaults.integer(forKey: "EnviveAvailableMinutes")
        if availableMinutes == 0 {
            availableMinutes = 180
            sharedDefaults.set(availableMinutes, forKey: "EnviveAvailableMinutes")
            sharedDefaults.synchronize()
        }

        // Load session data if active
        var sessionStartTime: Date?
        var sessionDuration: Int?

        if sessionState == .active {
            if let startTimeInterval = sharedDefaults.object(forKey: "EnviveSessionStartTime") as? TimeInterval {
                sessionStartTime = Date(timeIntervalSince1970: startTimeInterval)
            }
            sessionDuration = sharedDefaults.integer(forKey: "EnviveSessionDuration")

            // Check if session has ended
            if let startTime = sessionStartTime, let duration = sessionDuration {
                let elapsed = currentDate.timeIntervalSince(startTime)
                if elapsed >= TimeInterval(duration * 60) {
                    print("⏰ ENVIVE WIDGET: Session time expired - signaling app to end session")

                    // Session ended - update widget state and signal app
                    sharedDefaults.set(true, forKey: "EndSessionRequested")
                    sharedDefaults.set(SessionState.idle.rawValue, forKey: "EnviveSessionState")
                    sharedDefaults.removeObject(forKey: "EnviveSessionStartTime")
                    sharedDefaults.removeObject(forKey: "EnviveSessionDuration")
                    sharedDefaults.synchronize()

                    print("🔵 ENVIVE WIDGET: App will handle session end and shield reapplication")

                    // Create idle entry - app will handle balance deduction
                    let entry = EnviveSpendingEntry(
                        date: currentDate,
                        sessionState: .idle,
                        availableMinutes: availableMinutes,
                        sessionStartTime: nil,
                        sessionDuration: nil
                    )
                    let timeline = Timeline(entries: [entry], policy: .never)
                    completion(timeline)
                    return
                }
            }
        }

        let entry = EnviveSpendingEntry(
            date: currentDate,
            sessionState: sessionState,
            availableMinutes: availableMinutes,
            sessionStartTime: sessionStartTime,
            sessionDuration: sessionDuration
        )

        // Set refresh policy based on state
        let policy: TimelineReloadPolicy
        if sessionState == .active {
            // Refresh every 30 seconds during active session
            let nextUpdate = currentDate.addingTimeInterval(30)
            policy = .after(nextUpdate)
        } else {
            // No auto-refresh when idle or selecting
            policy = .never
        }

        let timeline = Timeline(entries: [entry], policy: policy)
        completion(timeline)
    }
}

// MARK: - Widget View
struct EnviveSpendingWidgetView: View {
    var entry: EnviveSpendingProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            backgroundGradient

            VStack(spacing: family == .systemSmall ? 12 : 16) {
                switch entry.sessionState {
                case .idle:
                    idleStateView
                case .selecting:
                    selectingStateView
                case .active:
                    activeStateView
                }
            }
            .padding(family == .systemSmall ? 16 : 20)
        }
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                .envivePink,
                .envivePurple,
                .enviveBlue,
                .enviveTeal
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Idle State (Show balance and Spend button)
    private var idleStateView: some View {
        VStack(spacing: family == .systemSmall ? 12 : 16) {
            Spacer()

            // Available time display
            VStack(spacing: 8) {
                Text("\(entry.availableMinutes)")
                    .font(.system(size: family == .systemSmall ? 48 : 64, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("minutes available")
                    .font(family == .systemSmall ? .caption : .subheadline)
                    .foregroundColor(.white.opacity(0.9))
            }

            Spacer()

            // Spend Time button
            Button(intent: StartSpendingIntent()) {
                HStack {
                    Spacer()
                    Text("Spend Time")
                        .font(family == .systemSmall ? .subheadline : .headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.vertical, family == .systemSmall ? 12 : 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.white)
                        .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
                )
                .foregroundColor(.envivePurple)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Selecting State (Show time options)
    private var selectingStateView: some View {
        VStack(spacing: family == .systemSmall ? 10 : 12) {
            Text("How long?")
                .font(family == .systemSmall ? .headline : .title3)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            VStack(spacing: family == .systemSmall ? 8 : 10) {
                timeButton(minutes: 15)
                timeButton(minutes: 30)
                timeButton(minutes: 45)
            }

            Spacer()
        }
    }

    private func timeButton(minutes: Int) -> some View {
        let intent = SelectTimeIntent()
        intent.minutes = minutes
        return Button(intent: intent) {
            HStack {
                Spacer()
                Text("\(minutes) minutes")
                    .font(family == .systemSmall ? .subheadline : .headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(.vertical, family == .systemSmall ? 10 : 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(.white.opacity(0.95))
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
            .foregroundColor(.enviveBlue)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Active State (Show countdown timer)
    private var activeStateView: some View {
        VStack(spacing: family == .systemSmall ? 12 : 16) {
            Spacer()

            // Countdown timer
            if let remainingSeconds = entry.remainingSeconds {
                VStack(spacing: 8) {
                    Text(formatTime(seconds: remainingSeconds))
                        .font(.system(size: family == .systemSmall ? 48 : 64, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .monospacedDigit()

                    Text("remaining")
                        .font(family == .systemSmall ? .caption : .subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }

                // Progress indicator
                if let duration = entry.sessionDuration {
                    let totalSeconds = duration * 60
                    let progress = Double(totalSeconds - remainingSeconds) / Double(totalSeconds)

                    ProgressView(value: progress)
                        .progressViewStyle(LinearProgressViewStyle(tint: .white))
                        .frame(height: 8)
                        .padding(.horizontal, family == .systemSmall ? 16 : 24)
                }
            }

            Spacer()

            // End session button
            Button(intent: EndSessionIntent()) {
                HStack {
                    Spacer()
                    Text("End Session")
                        .font(family == .systemSmall ? .caption : .subheadline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                .padding(.vertical, family == .systemSmall ? 10 : 12)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.white.opacity(0.3))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(.white.opacity(0.5), lineWidth: 1)
                        )
                )
                .foregroundColor(.white)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Helper
    private func formatTime(seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%d:%02d", mins, secs)
    }
}

// MARK: - Widget Configuration
struct EnviveSpendingWidget: Widget {
    let kind: String = "EnviveSpendingWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: EnviveSpendingProvider()) { entry in
            EnviveSpendingWidgetView(entry: entry)
        }
        .configurationDisplayName("Envive Spending")
        .description("Spend your available time directly from your home screen. Track sessions with live countdown.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Previews
#Preview(as: .systemSmall) {
    EnviveSpendingWidget()
} timeline: {
    // Idle state
    EnviveSpendingEntry(
        date: Date(),
        sessionState: .idle,
        availableMinutes: 180,
        sessionStartTime: nil,
        sessionDuration: nil
    )

    // Selecting state
    EnviveSpendingEntry(
        date: Date(),
        sessionState: .selecting,
        availableMinutes: 180,
        sessionStartTime: nil,
        sessionDuration: nil
    )

    // Active state with 10 minutes remaining
    EnviveSpendingEntry(
        date: Date(),
        sessionState: .active,
        availableMinutes: 180,
        sessionStartTime: Date().addingTimeInterval(-20 * 60), // Started 20 mins ago
        sessionDuration: 30 // 30 minute session
    )
}
