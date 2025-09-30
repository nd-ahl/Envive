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
        // In a real app, you'd fetch this data from UserDefaults, Core Data, or your app group
        let currentDate = Date()
        let entry = FocusWidgetEntry(
            date: currentDate,
            minutesAvailable: 45, // This would come from your ScreenTimeRewardManager
            streak: 2, // This would come from your streak tracking
            logoName: "treeLogo"
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
            backgroundGradient
                .overlay(vignetteOverlay)
                .overlay(innerShadowOverlay)

            // Content
            VStack(spacing: family == .systemSmall ? 8 : 12) {
                // Top badges row
                topBadgesRow

                // Center logo with halo
                centerLogoSection

                // Title
                titleSection

                // CTA Button
                ctaButton
            }
            .padding(family == .systemSmall ? 12 : 16)
        }
        .widgetURL(URL(string: "envivenew://focus"))
    }

    // MARK: - Background Components
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.lavender,
                Color.lavender.opacity(0.85)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var vignetteOverlay: some View {
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

    private var innerShadowOverlay: some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black.opacity(0.1),
                        Color.clear
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                ),
                lineWidth: 1
            )
            .blur(radius: 0.5)
    }

    // MARK: - Content Sections
    private var topBadgesRow: some View {
        HStack {
            // Minutes available badge
            badge("\(entry.minutesAvailable)m", systemImage: "hourglass")
                .accessibilityLabel("You have \(entry.minutesAvailable) minutes available")

            Spacer()

            // Streak badge
            badge("🔥 \(entry.streak)", systemImage: nil)
                .accessibilityLabel("Streak \(entry.streak) days")
        }
    }

    private var centerLogoSection: some View {
        ZStack {
            // Mint halo behind logo
            Circle()
                .fill(Color.mintAccent.opacity(0.18))
                .frame(width: family == .systemSmall ? 50 : 60,
                       height: family == .systemSmall ? 50 : 60)

            // Tree logo
            Image(entry.logoName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: family == .systemSmall ? 32 : 40,
                       height: family == .systemSmall ? 32 : 40)
                .widgetAccentable()
        }
    }

    private var titleSection: some View {
        Text("Lock In")
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .widgetAccentable()
    }

    private var ctaButton: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(.ultraThinMaterial)
            .stroke(Color.white.opacity(0.15), lineWidth: 1)
            .frame(height: family == .systemSmall ? 32 : 36)
            .overlay(
                // Button label with gradient
                Text("Spend Time")
                    .font(family == .systemSmall ? .caption : .subheadline)
                    .fontWeight(.medium)
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

    // MARK: - Helper Views
    private func badge(_ text: String, systemImage: String?) -> some View {
        HStack(spacing: 4) {
            if let systemImage = systemImage {
                Image(systemName: systemImage)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
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
    }
}

// MARK: - Widget Configuration
struct FocusWidget: Widget {
    let kind: String = "FocusWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: FocusWidgetProvider()) { entry in
            if #available(iOS 17.0, *) {
                FocusWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                FocusWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Focus")
        .description("Track your available screen time and streak.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}