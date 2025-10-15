import SwiftUI

// MARK: - Assign Task View

/// Parent interface for assigning tasks to children
struct AssignTaskView: View {
    let taskService: TaskService
    let parentId: UUID
    let selectedChildren: [ChildSummary]

    @Environment(\.dismiss) private var dismiss

    // View state
    @State private var creationMode: TaskCreationMode = .fromTemplate
    @State private var searchQuery: String = ""
    @State private var selectedCategory: TaskTemplateCategory? = nil
    @State private var selectedTemplate: TaskTemplate? = nil
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
        if creationMode == .custom {
            return !customTitle.isEmpty && !customDescription.isEmpty
        } else {
            return selectedTemplate != nil
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    headerSection

                    // Creation mode toggle
                    creationModeSelector

                    if creationMode == .fromTemplate {
                        // Template search and selection
                        templateSearchSection
                        categoryFilterSection
                        templateListSection
                    } else {
                        // Custom task creation
                        customTaskSection
                    }

                    // Difficulty selector
                    difficultySection

                    // Due date selector
                    dueDateSection

                    // Summary and assign button
                    summarySection
                }
                .padding()
            }
            .navigationTitle("Assign Task")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Assign") {
                        assignTask()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canAssign)
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

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: selectedChildren.count == 1 ? "person.circle.fill" : "person.2.fill")
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
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
            }

            if selectedChildren.count > 1 {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(selectedChildren, id: \.id) { child in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(child.name)
                                .font(.subheadline)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Creation Mode Selector

    private var creationModeSelector: some View {
        Picker("Task Source", selection: $creationMode) {
            Text("Browse Templates").tag(TaskCreationMode.fromTemplate)
            Text("Create Custom").tag(TaskCreationMode.custom)
        }
        .pickerStyle(.segmented)
    }

    // MARK: - Template Search Section

    private var templateSearchSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            .background(Color(.systemGray6))
            .cornerRadius(10)

            Text("\(filteredTemplates.count) tasks available")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Category Filter Section

    private var categoryFilterSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // "All" button
                Button(action: { selectedCategory = nil }) {
                    Text("All")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == nil ? Color.blue : Color(.systemGray5))
                        .foregroundColor(selectedCategory == nil ? .white : .primary)
                        .cornerRadius(20)
                }

                // Category buttons
                ForEach(TaskTemplateCategory.allCases) { category in
                    Button(action: { selectedCategory = category }) {
                        HStack(spacing: 4) {
                            Text(category.icon)
                            Text(category.rawValue)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(selectedCategory == category ? Color.blue : Color(.systemGray5))
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                        .cornerRadius(20)
                    }
                }
            }
        }
    }

    // MARK: - Template List Section

    private var templateListSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Selection prompt
            if selectedTemplate == nil {
                HStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.orange)
                    Text("Tap a task below to select it")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
            }

            if filteredTemplates.isEmpty {
                emptySearchView
            } else {
                ForEach(filteredTemplates.prefix(20)) { template in
                    TemplateCard(
                        template: template,
                        isSelected: selectedTemplate?.id == template.id,
                        onSelect: {
                            if selectedTemplate?.id == template.id {
                                selectedTemplate = nil
                            } else {
                                selectedTemplate = template
                                selectedLevel = template.suggestedLevel
                            }
                        }
                    )
                }

                if filteredTemplates.count > 20 {
                    Text("Showing first 20 results. Refine your search to see more.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.vertical)
                }
            }
        }
    }

    private var emptySearchView: some View {
        VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No tasks found")
                .font(.headline)
                .foregroundColor(.secondary)

            Text("Try a different search term or category")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    // MARK: - Custom Task Section

    private var customTaskSection: some View {
        VStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Task Name")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                TextField("Enter task name", text: $customTitle)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                TextEditor(text: $customDescription)
                    .frame(height: 100)
                    .padding(4)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Category")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Picker("Category", selection: $customCategory) {
                    ForEach(TaskTemplateCategory.allCases) { category in
                        HStack {
                            Text(category.icon)
                            Text(category.rawValue)
                        }
                        .tag(category)
                    }
                }
                .pickerStyle(.menu)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Difficulty Section

    private var difficultySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Task Difficulty")
                    .font(.headline)

                Spacer()

                Button(action: { showingLevelInfo = true }) {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                }
            }

            Text("Select difficulty level to determine XP reward")
                .font(.caption)
                .foregroundColor(.secondary)

            ForEach(TaskLevel.allCases) { level in
                LevelCard(
                    level: level,
                    isSelected: selectedLevel == level,
                    onSelect: { selectedLevel = level }
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Due Date Section

    private var dueDateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle("Set Due Date (Optional)", isOn: $hasDueDate)
                .font(.headline)

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
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Summary")
                .font(.headline)

            if creationMode == .fromTemplate {
                if let template = selectedTemplate {
                    SummaryRow(label: "Task", value: template.title)
                    SummaryRow(label: "Category", value: "\(template.category.icon) \(template.category.rawValue)")
                } else {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("No task selected")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .padding(.vertical, 4)
                }
            } else if creationMode == .custom {
                SummaryRow(label: "Task", value: customTitle.isEmpty ? "Not set" : customTitle)
                SummaryRow(label: "Category", value: "\(customCategory.icon) \(customCategory.rawValue)")
            }

            SummaryRow(label: "Difficulty", value: selectedLevel.displayName)
            SummaryRow(label: "XP Reward", value: "\(selectedLevel.baseXP) XP (+ credibility bonus)")
            SummaryRow(label: "Minutes Earned", value: "\(selectedLevel.baseXP) minutes")

            if hasDueDate, let date = dueDate {
                SummaryRow(label: "Due", value: formatDueDate(date))
            } else {
                SummaryRow(label: "Due", value: "No deadline")
            }

            // Assignment button reminder
            if !canAssign {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.red)
                    if creationMode == .fromTemplate {
                        Text("Select a task to enable assignment")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else {
                        Text("Complete task details to enable assignment")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(canAssign ? Color.blue.opacity(0.1) : Color.red.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(canAssign ? Color.clear : Color.red.opacity(0.3), lineWidth: 2)
        )
    }

    // MARK: - Actions

    private func assignTask() {
        let template: TaskTemplate

        if creationMode == .fromTemplate, let selected = selectedTemplate {
            template = selected
        } else {
            // Create custom template
            template = TaskTemplate(
                title: customTitle,
                description: customDescription,
                category: customCategory,
                suggestedLevel: selectedLevel,
                estimatedMinutes: selectedLevel.baseXP,
                isDefault: false,
                createdBy: parentId
            )
        }

        // Create assignment for EACH selected child
        assignedTasks = selectedChildren.map { child in
            taskService.assignTask(
                template: template,
                childId: child.id,
                parentId: parentId,
                level: selectedLevel,
                dueDate: hasDueDate ? dueDate : nil
            )
        }

        showingConfirmation = true
    }

    private func resetForm() {
        selectedTemplate = nil
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

// MARK: - Task Creation Mode

enum TaskCreationMode {
    case fromTemplate
    case custom
}

// MARK: - Template Card

struct TemplateCard: View {
    let template: TaskTemplate
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            Text(template.category.icon)
                .font(.title2)

            // Task info
            VStack(alignment: .leading, spacing: 4) {
                Text(template.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)

                Text(template.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text(template.category.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(4)

                    Text("Suggested: \(template.suggestedLevel.shortName)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Simple selection indicator - only shows when selected
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(isSelected ? Color.blue.opacity(0.1) : Color(.systemGray6))
        .cornerRadius(12)
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Level Card

struct LevelCard: View {
    let level: TaskLevel
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(level.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Text(level.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(level.baseXP) XP")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(isSelected ? .blue : .primary)

                    Text("\(level.baseXP) min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
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

// MARK: - Summary Row

struct SummaryRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
    }
}

// MARK: - Level Info View

struct LevelInfoView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
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
                        title: "Level vs Duration",
                        description: "Level represents task VALUE/DIFFICULTY, not time required. A hard task gets more reward regardless of duration.",
                        icon: "star.fill",
                        color: .orange
                    )

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Level Guide")
                            .font(.headline)

                        ForEach(TaskLevel.allCases) { level in
                            HStack {
                                Text(level.shortName)
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .frame(width: 70, alignment: .leading)

                                Text("\(level.baseXP) XP")
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .frame(width: 50, alignment: .leading)

                                Text(level.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
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
                ),
                ChildSummary(
                    id: UUID(),
                    name: "Tanner",
                    credibility: 88,
                    xpBalance: 120,
                    pendingCount: 0
                )
            ]
        )
    }
}
