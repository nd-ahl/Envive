import SwiftUI

// MARK: - Assign Task View

/// Parent interface for assigning tasks to children
/// UX Flow: 1) Search/Browse tasks, 2) Select task, 3) Adjust difficulty, 4) Assign
struct AssignTaskView: View {
    let taskService: TaskService
    let parentId: UUID
    let selectedChildren: [ChildSummary]
    let notificationManager: NotificationManager

    @Environment(\.dismiss) private var dismiss

    // Task selection state
    @State private var searchQuery: String = ""
    @State private var selectedCategory: TaskTemplateCategory? = nil
    @State private var selectedTemplate: TaskTemplate? = nil
    @State private var showingCustomTask: Bool = false

    // Task customization (after selection)
    @State private var selectedLevel: TaskLevel = .level3
    @State private var dueDate: Date? = nil
    @State private var hasDueDate: Bool = false

    // Custom task fields
    @State private var customTitle: String = ""
    @State private var customDescription: String = ""
    @State private var customCategory: TaskTemplateCategory = .other

    // UI state
    @State private var showingConfirmation = false
    @State private var assignedTasks: [TaskAssignment] = []
    @State private var showingLevelInfo = false

    // Task templates
    private var allTemplates: [TaskTemplate] {
        TaskTemplate.defaultTemplates
    }

    private var filteredTemplates: [TaskTemplate] {
        var templates = allTemplates

        // Filter by category if selected
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }

        // Filter by search query
        if !searchQuery.isEmpty {
            templates = templates.filter { template in
                template.title.localizedCaseInsensitiveContains(searchQuery) ||
                template.description.localizedCaseInsensitiveContains(searchQuery) ||
                template.tags.contains(where: { $0.localizedCaseInsensitiveContains(searchQuery) })
            }
        }

        return templates
    }

    private var canAssign: Bool {
        if showingCustomTask {
            return !customTitle.isEmpty && !customDescription.isEmpty
        } else {
            return selectedTemplate != nil
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header: Who we're assigning to
                assigningToHeader
                    .padding()
                    .background(Color(.systemGroupedBackground))

                if selectedTemplate == nil && !showingCustomTask {
                    // STEP 1: Task Selection (Search & Browse)
                    taskSelectionView
                } else {
                    // STEP 2: Difficulty Adjustment & Confirmation
                    taskConfirmationView
                }
            }
            .navigationTitle("Assign Task")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                if selectedTemplate != nil || showingCustomTask {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Assign") {
                            assignTask()
                        }
                        .fontWeight(.bold)
                        .disabled(!canAssign)
                    }
                }
            }
            .alert("Task Assigned!", isPresented: $showingConfirmation) {
                Button("Done") {
                    dismiss()
                }
                Button("Assign Another") {
                    resetForm()
                }
            } message: {
                if !assignedTasks.isEmpty {
                    let taskTitle = assignedTasks[0].title
                    if selectedChildren.count == 1 {
                        Text("\(taskTitle) assigned to \(selectedChildren[0].name) for \(selectedLevel.baseXP) XP")
                    } else {
                        Text("\(taskTitle) assigned to \(selectedChildren.count) children for \(selectedLevel.baseXP) XP each")
                    }
                }
            }
            .sheet(isPresented: $showingLevelInfo) {
                LevelInfoView()
            }
        }
    }

    // MARK: - Assigning To Header

    private var assigningToHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: selectedChildren.count == 1 ? "person.circle.fill" : "person.2.fill")
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Assigning to:")
                    .font(.caption)
                    .foregroundColor(.secondary)

                if selectedChildren.count == 1 {
                    Text(selectedChildren[0].name)
                        .font(.headline)
                } else {
                    Text("\(selectedChildren.count) children")
                        .font(.headline)
                }
            }

            Spacer()

            // Step indicator
            if selectedTemplate != nil || showingCustomTask {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.blue)
                }
                .font(.caption)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - STEP 1: Task Selection View

    private var taskSelectionView: some View {
        VStack(spacing: 0) {
            // Search bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search tasks...", text: $searchQuery)
                        .textFieldStyle(.plain)

                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)

                // Category filter chips with Custom Task option
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Custom Task chip - first position, stands out
                        Button(action: {
                            showingCustomTask = true
                            selectedLevel = .level3
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.caption)
                                Text("Custom")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(20)
                        }
                        .buttonStyle(.plain)

                        CategoryChip(
                            title: "All Tasks",
                            icon: "square.grid.2x2",
                            isSelected: selectedCategory == nil,
                            count: allTemplates.count
                        ) {
                            selectedCategory = nil
                        }

                        ForEach(TaskTemplateCategory.allCases) { category in
                            let count = allTemplates.filter { $0.category == category }.count
                            CategoryChip(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category,
                                count: count
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                }
            }
            .padding()

            Divider()

            // Task list
            ScrollView {
                LazyVStack(spacing: 12) {
                    if filteredTemplates.isEmpty {
                        emptySearchView
                            .padding(.top, 60)
                    } else {
                        ForEach(filteredTemplates) { template in
                            TaskTemplateCard(
                                template: template,
                                onSelect: {
                                    selectedTemplate = template
                                    selectedLevel = template.suggestedLevel
                                }
                            )
                        }
                    }
                }
                .padding()
            }
        }
    }

    private var emptySearchView: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No tasks found")
                .font(.headline)

            Text("Try a different search or category")
                .font(.subheadline)
                .foregroundColor(.secondary)

            Button("Clear Search") {
                searchQuery = ""
                selectedCategory = nil
            }
            .buttonStyle(.bordered)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - STEP 2: Task Confirmation View

    private var taskConfirmationView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Selected task preview
                selectedTaskPreview

                // Difficulty adjustment
                difficultyAdjustmentSection

                // Optional: Due date
                dueDateSection

                // Assignment summary
                assignmentSummary
            }
            .padding()
        }
    }

    private var selectedTaskPreview: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Selected Task")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    selectedTemplate = nil
                    showingCustomTask = false
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left")
                        Text("Change")
                    }
                    .font(.subheadline)
                    .foregroundColor(.blue)
                }
            }

            if showingCustomTask {
                VStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Task Name")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextField("Enter task name", text: $customTitle)
                            .textFieldStyle(.roundedBorder)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        TextEditor(text: $customDescription)
                            .frame(height: 80)
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Menu {
                            ForEach(TaskTemplateCategory.allCases) { category in
                                Button(action: { customCategory = category }) {
                                    HStack {
                                        Text(category.icon)
                                        Text(category.rawValue)
                                    }
                                }
                            }
                        } label: {
                            HStack {
                                Text(customCategory.icon)
                                Text(customCategory.rawValue)
                                Spacer()
                                Image(systemName: "chevron.down")
                            }
                            .foregroundColor(.primary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                        }
                    }
                }
            } else if let template = selectedTemplate {
                HStack(spacing: 12) {
                    Text(template.category.icon)
                        .font(.title)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(template.title)
                            .font(.headline)

                        Text(template.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var difficultyAdjustmentSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Adjust Difficulty")
                        .font(.title3)
                        .fontWeight(.bold)

                    if let template = selectedTemplate {
                        Text("Suggested: \(template.suggestedLevel.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: { showingLevelInfo = true }) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                }
            }

            // Compact difficulty selector
            VStack(spacing: 10) {
                ForEach(TaskLevel.allCases) { level in
                    CompactDifficultyRow(
                        level: level,
                        isSelected: selectedLevel == level,
                        isSuggested: selectedTemplate?.suggestedLevel == level,
                        onSelect: { selectedLevel = level }
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $hasDueDate) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Set Due Date")
                        .font(.headline)
                    Text("Optional deadline")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if hasDueDate {
                DatePicker(
                    "Due Date",
                    selection: Binding(
                        get: { dueDate ?? Date() },
                        set: { dueDate = $0 }
                    ),
                    in: Date()...,
                    displayedComponents: [.date, .hourAndMinute]
                )
                .datePickerStyle(.graphical)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    private var assignmentSummary: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Ready to Assign")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
            }

            VStack(spacing: 12) {
                HStack {
                    Text("Task")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(showingCustomTask ? customTitle : (selectedTemplate?.title ?? ""))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                }

                HStack {
                    Text("Difficulty")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(selectedLevel.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }

                Divider()

                // XP Reward - Large and prominent
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Screen Time Earned")
                            .font(.headline)
                        Text("Base XP (×credibility)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(selectedLevel.baseXP)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.blue)
                        Text("XP = \(selectedLevel.baseXP) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)

                if hasDueDate, let date = dueDate {
                    HStack {
                        Text("Due")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(formatDueDate(date))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 2)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Actions

    private func assignTask() {
        let template: TaskTemplate

        if showingCustomTask {
            template = TaskTemplate(
                title: customTitle,
                description: customDescription,
                category: customCategory,
                suggestedLevel: selectedLevel,
                estimatedMinutes: selectedLevel.baseXP,
                isDefault: false,
                createdBy: parentId
            )
        } else if let selected = selectedTemplate {
            template = selected
        } else {
            return
        }

        // Create assignment for EACH selected child
        assignedTasks = selectedChildren.map { child in
            print("📝 Assigning task '\(template.title)' to child: \(child.name) (ID: \(child.id))")
            let assignment = taskService.assignTask(
                template: template,
                childId: child.id,
                parentId: parentId,
                level: selectedLevel,
                dueDate: hasDueDate ? dueDate : nil
            )
            print("✅ Task assigned with ID: \(assignment.id), status: \(assignment.status)")

            // Send notification to child
            notificationManager.sendTaskAssignedNotification(
                childName: child.name,
                taskTitle: template.title,
                xpReward: selectedLevel.baseXP
            )

            // Play haptic feedback for parent
            HapticFeedbackManager.shared.taskAssigned()

            return assignment
        }

        showingConfirmation = true
    }

    private func resetForm() {
        selectedTemplate = nil
        showingCustomTask = false
        selectedLevel = .level3
        customTitle = ""
        customDescription = ""
        customCategory = .other
        searchQuery = ""
        selectedCategory = nil
        hasDueDate = false
        dueDate = nil
    }

    private func formatDueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Category Chip

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let count: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                if icon.count == 1 {
                    Text(icon)
                } else {
                    Image(systemName: icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("(\(count))")
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Task Template Card

struct TaskTemplateCard: View {
    let template: TaskTemplate
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Category icon
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Text(template.category.icon)
                        .font(.title3)
                }

                // Task info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundColor(.primary)

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text(template.suggestedLevel.shortName)
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)

                        Text("•")
                            .foregroundColor(.secondary)

                        Text("\(template.suggestedLevel.baseXP) XP")
                            .font(.caption2)
                            .foregroundColor(.blue)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Compact Difficulty Row

struct CompactDifficultyRow: View {
    let level: TaskLevel
    let isSelected: Bool
    let isSuggested: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                // Level indicator
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.blue : Color(.systemGray5))
                        .frame(width: 36, height: 36)

                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.caption)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                    } else {
                        Text(level.shortName)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.secondary)
                    }
                }

                // Level name
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(level.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)

                        if isSuggested && !isSelected {
                            Text("Suggested")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.orange.opacity(0.2))
                                .foregroundColor(.orange)
                                .cornerRadius(4)
                        }
                    }

                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // XP value
                Text("\(level.baseXP)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? .blue : .primary)
            }
            .padding(12)
            .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Level Info View

struct LevelInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("How Task Levels Work")
                        .font(.title2)
                        .fontWeight(.bold)

                    LevelInfoCard(
                        title: "XP = Screen Time Minutes",
                        description: "1 XP earned equals 1 minute of screen time. A Level 3 task (30 XP) earns 30 minutes.",
                        icon: "clock.fill",
                        color: .blue
                    )

                    LevelInfoCard(
                        title: "Credibility Multiplier",
                        description: "Child's credibility score (0-100%) multiplies the base XP. At 95% credibility, a 30 XP task earns 28.5 XP.",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .green
                    )

                    LevelInfoCard(
                        title: "Suggested Levels",
                        description: "Each task has a suggested difficulty level based on typical effort required. You can always adjust it.",
                        icon: "star.fill",
                        color: .orange
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Level Guide")
                            .font(.headline)

                        ForEach(TaskLevel.allCases) { level in
                            HStack(spacing: 12) {
                                Text(level.shortName)
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .frame(width: 50, alignment: .leading)

                                Text("\(level.baseXP) XP")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .frame(width: 60, alignment: .leading)

                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                }
                .padding()
            }
            .navigationTitle("Level Information")
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

struct LevelInfoCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Preview

struct AssignTaskView_Previews: PreviewProvider {
    static var previews: some View {
        AssignTaskView(
            taskService: DependencyContainer.shared.taskService,
            parentId: UUID(),
            selectedChildren: [
                ChildSummary(
                    id: UUID(),
                    name: "Sarah",
                    credibility: 95,
                    xpBalance: 45,
                    pendingCount: 2
                )
            ],
            notificationManager: NotificationManager()
        )
    }
}
