//
//  FocusWidget.swift
//  EnviveNewWidgets
//
//  Created by Claude on 9/29/25.
//

import WidgetKit
import SwiftUI

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

        // Use sample data for now to ensure widget loads
        let entry = FocusWidgetEntry(
            date: currentDate,
            minutes: 45,
            streak: 2
        )

        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Focus Widget Views
struct FocusWidgetEntryView: View {
    var entry: FocusWidgetProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        ZStack {
            // Background with gradient and vignette
            backgroundView

            // Content
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
        Link(destination: URL(string: "envivenew://spend")!) {
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
                .background(
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
                )
        }
        .configurationDisplayName("Envive Focus")
        .description("Track your available screen time and current streak. Tap to spend time.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}