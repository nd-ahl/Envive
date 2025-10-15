import SwiftUI

// MARK: - Child Selection Mode

enum ChildSelectionMode {
    case single
    case multiple
}

// MARK: - Child Selector View

/// Modal for selecting one or more children to assign tasks to
struct ChildSelectorView: View {
    let children: [ChildSummary]
    let onConfirm: ([ChildSummary]) -> Void
    let selectionMode: ChildSelectionMode

    @Environment(\.dismiss) private var dismiss
    @State private var selectedChildren: Set<UUID> = []

    init(children: [ChildSummary], selectionMode: ChildSelectionMode = .multiple, onConfirm: @escaping ([ChildSummary]) -> Void) {
        self.children = children
        self.selectionMode = selectionMode
        self.onConfirm = onConfirm
    }

    var selectedChildrenList: [ChildSummary] {
        children.filter { selectedChildren.contains($0.id) }
    }

    var canConfirm: Bool {
        !selectedChildren.isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    // Selection Instructions
                    instructionsSection

                    // Children List
                    childrenListSection

                    // Selection Summary
                    if !selectedChildren.isEmpty {
                        selectionSummarySection
                    }
                }
                .padding()
            }
            .navigationTitle("Select Children")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Confirm") {
                        onConfirm(selectedChildrenList)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canConfirm)
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 50))
                .foregroundColor(.blue)

            Text(selectionMode == .single ? "Who should do this?" : "Who should do this task?")
                .font(.title3)
                .fontWeight(.bold)

            Text(selectionMode == .single ? "Select one child" : "Select one or more children to assign a task")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Instructions Section

    private var instructionsSection: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title3)
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 4) {
                Text(selectionMode == .single ? "Single Selection" : "Multi-Select Enabled")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(selectionMode == .single ? "Tap a child to select them." : "Tap children to select or deselect. The same task will be assigned to all selected children.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }

    // MARK: - Children List Section

    private var childrenListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Available Children")
                .font(.headline)
                .padding(.horizontal, 4)

            if children.isEmpty {
                emptyStateView
            } else {
                ForEach(children) { child in
                    ChildSelectionCard(
                        child: child,
                        isSelected: selectedChildren.contains(child.id),
                        onToggle: {
                            toggleSelection(for: child.id)
                        }
                    )
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 50))
                .foregroundColor(.secondary)

            Text("No Children Available")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Add children to your family to assign tasks")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Selection Summary Section

    private var selectionSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected (\(selectedChildren.count))")
                    .font(.headline)

                Spacer()

                Button("Clear All") {
                    selectedChildren.removeAll()
                }
                .font(.caption)
                .foregroundColor(.red)
            }

            VStack(spacing: 8) {
                ForEach(selectedChildrenList) { child in
                    HStack {
                        Text(child.name)
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Spacer()

                        Button(action: {
                            selectedChildren.remove(child.id)
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Actions

    private func toggleSelection(for childId: UUID) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if selectionMode == .single {
                // Single select: replace selection
                if selectedChildren.contains(childId) {
                    selectedChildren.remove(childId)
                } else {
                    selectedChildren.removeAll()
                    selectedChildren.insert(childId)
                }
            } else {
                // Multi-select: toggle selection
                if selectedChildren.contains(childId) {
                    selectedChildren.remove(childId)
                } else {
                    selectedChildren.insert(childId)
                }
            }
        }
    }
}

// MARK: - Child Selection Card

struct ChildSelectionCard: View {
    let child: ChildSummary
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 16) {
            // Selection Indicator
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title2)
                .foregroundColor(isSelected ? .blue : .secondary)

            // Child Info
            VStack(alignment: .leading, spacing: 4) {
                Text(child.name)
                    .font(.headline)
                    .foregroundColor(.primary)

                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.caption)
                        Text("\(child.credibility)%")
                            .font(.caption)
                    }
                    .foregroundColor(credibilityColor(for: child.credibility))

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.caption)
                        Text("\(child.xpBalance) XP")
                            .font(.caption)
                    }
                    .foregroundColor(.orange)

                    if child.pendingCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "clock.fill")
                                .font(.caption)
                            Text("\(child.pendingCount) pending")
                                .font(.caption)
                        }
                        .foregroundColor(.yellow)
                    }
                }
            }

            Spacer()

            // Arrow indicator
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .opacity(isSelected ? 1 : 0.3)
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
    }

    private func credibilityColor(for score: Int) -> Color {
        switch score {
        case 95...100: return .green
        case 80...94: return .blue
        case 60...79: return .yellow
        case 40...59: return .orange
        default: return .red
        }
    }
}

// MARK: - Preview

struct ChildSelectorView_Previews: PreviewProvider {
    static var previews: some View {
        ChildSelectorView(
            children: [
                ChildSummary(
                    id: UUID(),
                    name: "Sarah",
                    credibility: 95,
                    xpBalance: 45,
                    pendingCount: 2
                ),
                ChildSummary(
                    id: UUID(),
                    name: "Tanner",
                    credibility: 88,
                    xpBalance: 120,
                    pendingCount: 0
                ),
                ChildSummary(
                    id: UUID(),
                    name: "Emma",
                    credibility: 92,
                    xpBalance: 75,
                    pendingCount: 1
                )
            ],
            onConfirm: { _ in }
        )
    }
}
