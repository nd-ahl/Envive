import SwiftUI

// MARK: - Child Task Creation View

/// Main view for children to browse task library and create/claim tasks
/// Updated to match parent task selector UI with two-step flow
struct ChildTaskCreationView: View {
    @Environment(\.dismiss) var dismiss
    let childId: UUID
    let taskService: TaskService

    // Task selection state
    @State private var searchText = ""
    @State private var selectedCategory: TaskTemplateCategory? = nil
    @State private var selectedTemplate: TaskTemplate? = nil
    @State private var showingCustomTask: Bool = false
    @State private var allTemplates: [TaskTemplate] = []
    @State private var isLoading = true

    // Task customization (after selection)
    @State private var selectedLevel: TaskLevel = .level3

    // Custom task fields
    @State private var customTitle: String = ""
    @State private var customDescription: String = ""
    @State private var customCategory: TaskTemplateCategory = .other

    // UI state
    @State private var showingSuccessAlert = false
    @State private var claimedTaskTitle: String = ""

    private var filteredTemplates: [TaskTemplate] {
        var templates = allTemplates

        // Filter by category
        if let category = selectedCategory {
            templates = templates.filter { $0.category == category }
        }

        // Filter by search
        if !searchText.isEmpty {
            templates = templates.filter { template in
                template.title.localizedCaseInsensitiveContains(searchText) ||
                template.description.localizedCaseInsensitiveContains(searchText) ||
                template.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }

        return templates
    }

    private var canClaim: Bool {
        if showingCustomTask {
            return !customTitle.isEmpty && !customDescription.isEmpty
        } else {
            return selectedTemplate != nil
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if selectedTemplate == nil && !showingCustomTask {
                    // STEP 1: Task Selection (Search & Browse)
                    taskSelectionView
                } else {
                    // STEP 2: Difficulty Adjustment & Claim
                    taskConfirmationView
                }
            }
            .navigationTitle("Task Library")
            .navigationBarTitleDisplayMode(.large)
            .background(Color(.systemGroupedBackground))
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        if selectedTemplate != nil || showingCustomTask {
                            // Go back to selection
                            selectedTemplate = nil
                            showingCustomTask = false
                        } else {
                            dismiss()
                        }
                    }
                }

                if selectedTemplate != nil || showingCustomTask {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Claim Task") {
                            claimTask()
                        }
                        .fontWeight(.bold)
                        .disabled(!canClaim)
                    }
                }
            }
            .onAppear {
                loadTemplates()
            }
            .alert("Task Claimed!", isPresented: $showingSuccessAlert) {
                Button("Done") {
                    dismiss()
                }
                Button("Claim Another") {
                    resetForm()
                }
            } message: {
                Text("'\(claimedTaskTitle)' has been added to your tasks for \(selectedLevel.baseXP) XP!")
            }
        }
    }

    // MARK: - STEP 1: Task Selection View

    private var taskSelectionView: some View {
        VStack(spacing: 0) {
            // Search bar
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search tasks...", text: $searchText)
                        .textFieldStyle(.plain)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
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
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading tasks...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else {
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
                searchText = ""
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

                // Claim summary
                claimSummary
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
                    Text("Choose Your Level")
                        .font(.title3)
                        .fontWeight(.bold)

                    if let template = selectedTemplate {
                        Text("Suggested: \(template.suggestedLevel.displayName)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()
            }

            Text("Select the difficulty level for this task. Higher levels earn more screen time!")
                .font(.caption)
                .foregroundColor(.secondary)

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

    private var claimSummary: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Ready to Claim")
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
                        Text("You'll Earn")
                            .font(.headline)
                        Text("Screen time reward")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(selectedLevel.baseXP)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)
                        Text("XP = \(selectedLevel.baseXP) min")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
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

    private func claimTask() {
        let template: TaskTemplate

        if showingCustomTask {
            // Create custom template
            template = TaskTemplate(
                title: customTitle,
                description: customDescription,
                category: customCategory,
                suggestedLevel: selectedLevel,
                estimatedMinutes: selectedLevel.baseXP,
                isDefault: false,
                createdBy: childId
            )
        } else if let selected = selectedTemplate {
            template = selected
        } else {
            return
        }

        // Claim the task (assign to self)
        let assignment = taskService.claimTask(
            template: template,
            childId: childId,
            level: selectedLevel
        )

        print("✅ Child claimed task: \(assignment.title) for \(selectedLevel.baseXP) XP")

        // Play haptic feedback
        HapticFeedbackManager.shared.taskAssigned()

        claimedTaskTitle = template.title
        showingSuccessAlert = true
    }

    private func resetForm() {
        selectedTemplate = nil
        showingCustomTask = false
        selectedLevel = .level3
        customTitle = ""
        customDescription = ""
        customCategory = .other
        searchText = ""
        selectedCategory = nil
    }

    private func loadTemplates() {
        DispatchQueue.main.async {
            isLoading = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                allTemplates = taskService.getAllTemplates()
                isLoading = false
                print("✅ Loaded \(allTemplates.count) task templates")
            }
        }
    }
}

// MARK: - Preview
// Note: CategoryChip, TaskTemplateCard, and CompactDifficultyRow are reused from AssignTaskView.swift

struct ChildTaskCreationView_Previews: PreviewProvider {
    static var previews: some View {
        ChildTaskCreationView(
            childId: UUID(),
            taskService: DependencyContainer.shared.taskService
        )
    }
}
