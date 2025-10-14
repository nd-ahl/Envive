import SwiftUI

// MARK: - Card Container

/// Reusable card container with consistent styling
struct CardContainer<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

// MARK: - Info Card

/// Card with gray background for grouping information
struct InfoCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
    }
}

// MARK: - Status Badge

/// Generic status badge with color and icon
struct StatusBadge: View {
    let title: String
    let icon: String
    let color: Color
    let count: Int?

    init(title: String, icon: String, color: Color, count: Int? = nil) {
        self.title = title
        self.icon = icon
        self.color = color
        self.count = count
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)

            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            if let count = count, count > 0 {
                Text("\(count)")
                    .font(.caption)
                    .fontWeight(.bold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(color.opacity(0.3))
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(color)
        .foregroundColor(.white)
        .cornerRadius(20)
    }
}

// MARK: - Category Badge

/// Small badge for categorizing items
struct CategoryBadge: View {
    let title: String
    let icon: String?
    let backgroundColor: Color

    init(title: String, icon: String? = nil, backgroundColor: Color = Color(.systemGray6)) {
        self.title = title
        self.icon = icon
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.caption)
            }
            Text(title)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .cornerRadius(6)
    }
}

// MARK: - Detail Row

/// Row displaying label and value with icon
struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    let iconColor: Color

    init(label: String, value: String, icon: String, iconColor: Color = .blue) {
        self.label = label
        self.value = value
        self.icon = icon
        self.iconColor = iconColor
    }

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24)

            Text(label)
                .foregroundColor(.secondary)

            Spacer()

            Text(value)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Action Button

/// Primary action button with icon and color
struct PrimaryActionButton: View {
    let title: String
    let icon: String?
    let color: Color
    let isDisabled: Bool
    let action: () -> Void

    init(
        title: String,
        icon: String? = nil,
        color: Color = .blue,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.color = color
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isDisabled ? Color.gray : color)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(isDisabled)
    }
}

// MARK: - Quick Action Button

/// Compact action button with icon and label
struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
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
}

// MARK: - Quick Amount Button

/// Small button for selecting predefined amounts
struct QuickAmountButton: View {
    let amount: Int
    let label: String?
    let action: () -> Void

    init(amount: Int, label: String? = nil, action: @escaping () -> Void) {
        self.amount = amount
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(label ?? "\(amount)")
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.2))
                .foregroundColor(.blue)
                .cornerRadius(8)
        }
    }
}

// MARK: - Empty State View

/// Generic empty state with icon and message
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let iconColor: Color

    init(icon: String, title: String, message: String, iconColor: Color = .gray) {
        self.icon = icon
        self.title = title
        self.message = message
        self.iconColor = iconColor
    }

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(iconColor.opacity(0.5))

            Text(title)
                .font(.title2)
                .fontWeight(.semibold)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Loading View

/// Simple loading indicator with message
struct LoadingView: View {
    let message: String

    init(message: String = "Loading...") {
        self.message = message
    }

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Section Header

/// Styled section header with optional action
struct SectionHeader: View {
    let title: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(title: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(actionTitle, action: action)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
            }
        }
    }
}

// MARK: - Info Banner

/// Information banner with icon and message
struct InfoBanner: View {
    let message: String
    let icon: String
    let backgroundColor: Color

    init(message: String, icon: String, backgroundColor: Color = .blue) {
        self.message = message
        self.icon = icon
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(backgroundColor)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)

            Spacer()
        }
        .padding()
        .background(backgroundColor.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - XP Badge

/// Displays XP amount with styling
struct XPBadge: View {
    let amount: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("\(amount)")
                .font(.headline)
                .fontWeight(.bold)
            Text("XP")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Time Badge

/// Displays time amount with styling
struct TimeBadge: View {
    let minutes: Int

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "clock.fill")
                .font(.caption)
            Text("\(minutes) min")
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.green.opacity(0.1))
        .foregroundColor(.green)
        .cornerRadius(8)
    }
}

// MARK: - Divider with Label

/// Horizontal divider with centered label
struct LabeledDivider: View {
    let label: String

    var body: some View {
        HStack {
            VStack { Divider() }
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
            VStack { Divider() }
        }
    }
}

// MARK: - Previews

struct CommonComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 24) {
                CardContainer {
                    Text("Card Container")
                }

                InfoCard {
                    Text("Info Card")
                }

                StatusBadge(title: "Pending", icon: "clock.fill", color: .orange, count: 5)

                CategoryBadge(title: "Exercise", icon: "figure.run")

                DetailRow(label: "Name", value: "John Doe", icon: "person.fill")

                PrimaryActionButton(title: "Approve", icon: "checkmark.circle.fill", color: .green) {
                    print("Approved")
                }

                HStack {
                    QuickActionButton(title: "Run", icon: "play.fill", color: .blue) {}
                    QuickActionButton(title: "Pause", icon: "pause.fill", color: .orange) {}
                }

                HStack {
                    QuickAmountButton(amount: 100) {}
                    QuickAmountButton(amount: 500) {}
                    QuickAmountButton(amount: 1000, label: "Max") {}
                }

                EmptyStateView(
                    icon: "tray",
                    title: "No Items",
                    message: "There are no items to display",
                    iconColor: .blue
                )
                .frame(height: 200)

                InfoBanner(message: "Complete 3 more tasks for a bonus!", icon: "star.fill")

                HStack {
                    XPBadge(amount: 150)
                    TimeBadge(minutes: 30)
                }

                LabeledDivider(label: "OR")

                SectionHeader(title: "Recent Activity", actionTitle: "See All") {
                    print("See all tapped")
                }
            }
            .padding()
        }
    }
}
