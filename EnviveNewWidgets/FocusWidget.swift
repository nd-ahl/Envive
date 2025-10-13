//
//  FocusWidget.swift
//  EnviveNewWidgets
//
//  Created by Claude on 9/29/25.
//

import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Shared UserDefaults
private let sharedDefaults = UserDefaults(suiteName: "group.com.neal.envivenew.screentime")!

// MARK: - App Intents
struct StartFocusSpendingIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Spending"

    func perform() async throws -> some IntentResult {
        // Toggle the widget state to show time options
        sharedDefaults.set(true, forKey: "FocusWidgetShowTimeOptions")
        WidgetCenter.shared.reloadTimelines(ofKind: "FocusWidget")
        return .result()
    }
}

struct SelectFocusTimeIntent: AppIntent {
    static var title: LocalizedStringResource = "Select Time"
    static var openAppWhenRun: Bool = true

    @Parameter(title: "Minutes")
    var minutes: Int

    func perform() async throws -> some IntentResult {
        print("🔵 WIDGET: SelectFocusTimeIntent called with \(minutes) minutes")

        // Store pending session request for app to pick up using shared container
        sharedDefaults.set(minutes, forKey: "PendingScreenTimeMinutes")
        sharedDefaults.set(Date().timeIntervalSince1970, forKey: "PendingScreenTimeTimestamp")
        sharedDefaults.synchronize()

        // Reset widget state to hide time options
        sharedDefaults.set(false, forKey: "FocusWidgetShowTimeOptions")
        WidgetCenter.shared.reloadTimelines(ofKind: "FocusWidget")

        print("🔵 WIDGET: Stored \(minutes) minutes - app will open and handle shield removal")

        return .result()
    }
}

// MARK: - Focus Widget Provider
struct FocusWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> FocusWidgetEntry {
        FocusWidgetEntry.sample
    }

    func getSnapshot(in context: Context, completion: @escaping (FocusWidgetEntry) -> ()) {
        let entry = FocusWidgetEntry.sample
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<FocusWidgetEntry>) -> ()) {
        let currentDate = Date()

        // Check if we should show time options using shared container
        let showTimeOptions = sharedDefaults.bool(forKey: "FocusWidgetShowTimeOptions")

        // Use sample data for now to ensure widget loads
        let entry = FocusWidgetEntry(
            date: currentDate,
            minutes: 45,
            streak: 2,
            showTimeOptions: showTimeOptions
        )

        // Update policy: never auto-refresh (only when widget is reloaded manually)
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// MARK: - Focus Widget Views
struct FocusWidgetEntryView: View {
    var entry: FocusWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if entry.showTimeOptions {
            // Only show time options - nothing else
            VStack(spacing: family == .systemSmall ? 8 : 12) {
                timeOptionsView
            }
            .padding(family == .systemSmall ? 12 : 16)
        } else {
            // Normal state with all elements
            VStack(spacing: family == .systemSmall ? 8 : 12) {
                // Top badges row
                topMetricsRow

                // Center logo with halo
                centerSection

                // Title
                titleText

                // CTA Button
                spendTimeButton
            }
            .padding(family == .systemSmall ? 12 : 16)
        }
    }

    // MARK: - Background
    private var backgroundView: some View {
        ZStack {
            // Primary gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.lavender,
                    Color.lavender.opacity(0.85)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            // Vignette overlay
            RadialGradient(
                gradient: Gradient(colors: [
                    Color.clear,
                    Color.deepPlum.opacity(0.65)
                ]),
                center: .center,
                startRadius: 20,
                endRadius: 120
            )
        }
    }

    // MARK: - Content Sections
    private var topMetricsRow: some View {
        HStack {
            // Minutes badge with hourglass
            metricBadge(
                text: "\(entry.minutes)m",
                systemImage: "hourglass",
                accessibilityLabel: "You have \(entry.minutes) minutes available"
            )

            Spacer()

            // Streak badge with flame
            metricBadge(
                text: "🔥 \(entry.streak)",
                systemImage: nil,
                accessibilityLabel: "Streak \(entry.streak) days"
            )
        }
    }

    private var centerSection: some View {
        ZStack {
            // Mint halo behind logo
            Circle()
                .fill(Color.mintAccent.opacity(0.18))
                .frame(
                    width: family == .systemSmall ? 50 : 60,
                    height: family == .systemSmall ? 50 : 60
                )

            // Tree logo - using system icon
            Image(systemName: "tree.fill")
                .font(.system(size: family == .systemSmall ? 28 : 36, weight: .medium))
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.green, Color.green.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .widgetAccentable()
        }
    }

    private var titleText: some View {
        Text("Lock In")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .widgetAccentable()
    }

    private var spendTimeButton: some View {
        Button(intent: StartFocusSpendingIntent()) {
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                .frame(height: family == .systemSmall ? 32 : 36)
                .overlay(
                    Text("Spend Time")
                        .font(family == .systemSmall ? .caption : .subheadline)
                        .fontWeight(.medium)
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.mintAccent,
                                    Color.white.opacity(0.85)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private var timeOptionsView: some View {
        VStack(spacing: family == .systemSmall ? 8 : 12) {
            Spacer()
            timeButton(minutes: 15)
            timeButton(minutes: 30)
            timeButton(minutes: 45)
            Spacer()
        }
    }

    private func timeButton(minutes: Int) -> some View {
        let intent = SelectFocusTimeIntent()
        intent.minutes = minutes
        return Button(intent: intent) {
            HStack {
                Spacer()
                Text("\(minutes) minutes")
                    .font(family == .systemSmall ? .caption : .subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .padding(.vertical, family == .systemSmall ? 6 : 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
            )
            .foregroundStyle(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.mintAccent,
                        Color.white.opacity(0.85)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Views
    private func metricBadge(text: String, systemImage: String?, accessibilityLabel: String) -> some View {
        HStack(spacing: 4) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }

            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.25))
                .overlay(
                    Capsule()
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - Widget Configuration
struct FocusWidget: Widget {
    let kind: String = "FocusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusWidgetProvider()) { entry in
            FocusWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    ZStack {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.lavender,
                                Color.lavender.opacity(0.85)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )

                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color.clear,
                                Color.deepPlum.opacity(0.65)
                            ]),
                            center: .center,
                            startRadius: 20,
                            endRadius: 120
                        )
                    }
                }
        }
        .configurationDisplayName("Envive Focus")
        .description("Track your available screen time and current streak. Tap to spend time.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}