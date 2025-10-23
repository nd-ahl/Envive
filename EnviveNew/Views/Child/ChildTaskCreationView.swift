import SwiftUI

// MARK: - Child Task Creation View

/// Main view for children to browse task library and create/claim tasks
struct ChildTaskCreationView: View {
    @Environment(\.dismiss) var dismiss
    let childId: UUID
    let taskService: TaskService

    @State private var searchText = ""
    @State private var selectedCategory: TaskTemplateCategory? = nil
    @State private var showClaimSheet = false
    @State private var showCreateSheet = false
    @State private var selectedTemplate: TaskTemplate? = nil
    @State private var allTemplates: [TaskTemplate] = []
    @State private var isLoading = true

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

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search tasks...", text: $searchText)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)
                .padding()

                // Category Filter (Horizontal Scroll)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        // "All" button
                        CategoryFilterButton(
                            title: "All",
                            icon: "square.grid.2x2",
                            isSelected: selectedCategory == nil
                        ) {
                            selectedCategory = nil
                        }

                        // Category buttons
                        ForEach(TaskTemplateCategory.allCases) { category in
                            CategoryFilterButton(
                                title: category.rawValue,
                                icon: category.icon,
                                isSelected: selectedCategory == category
                            ) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 8)

                // Task Count
                HStack {
                    Text("\(filteredTemplates.count) tasks")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                // Task List
                ScrollView {
                    if isLoading {
                        // Loading state
                        VStack(spacing: 20) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Loading tasks...")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 100)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredTemplates) { template in
                                TaskTemplateCard(template: template) {
                                    selectedTemplate = template
                                    showClaimSheet = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Task Library")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadTemplates()
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showCreateSheet = true
                    }) {
                        Label("Create Custom", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showClaimSheet) {
                if let template = selectedTemplate {
                    ClaimTaskSheet(
                        template: template,
                        childId: childId,
                        taskService: taskService,
                        onClaim: {
                            dismiss()
                        }
                    )
                }
            }
            .sheet(isPresented: $showCreateSheet) {
                CreateCustomTaskSheet(
                    childId: childId,
                    taskService: taskService,
                    onCreate: {
                        dismiss()
                    }
                )
            }
        }
    }

    // MARK: - Load Templates

    private func loadTemplates() {
        // Load templates on main thread to ensure UI updates properly
        DispatchQueue.main.async {
            isLoading = true
            // Small delay to ensure view is ready
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                // Load templates from repository (includes default + custom)
                allTemplates = taskService.getAllTemplates()
                isLoading = false
                print("✅ Loaded \(allTemplates.count) task templates")
            }
        }
    }
}

// MARK: - Category Filter Button

private struct CategoryFilterButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if icon.contains(".") {
                    // SF Symbol
                    Image(systemName: icon)
                        .font(.caption)
                } else {
                    // Emoji
                    Text(icon)
                        .font(.caption)
                }
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color(.systemGray6))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(20)
        }
    }
}

// MARK: - Task Template Card

private struct TaskTemplateCard: View {
    let template: TaskTemplate
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                Text(template.category.icon)
                    .font(.title2)
                    .frame(width: 50, height: 50)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)

                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(template.title)
                        .font(.headline)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)

                    Text(template.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)

                    HStack(spacing: 8) {
                        // Suggested Level
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .font(.caption2)
                            Text(template.suggestedLevel.displayName)
                                .font(.caption2)
                        }
                        .foregroundColor(.orange)

                        // Time estimate
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.caption2)
                            Text("~\(template.estimatedMinutes) min")
                                .font(.caption2)
                        }
                        .foregroundColor(.secondary)
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
            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        }
    }
}

// MARK: - Claim Task Sheet

struct ClaimTaskSheet: View {
    @Environment(\.dismiss) var dismiss
    let template: TaskTemplate
    let childId: UUID
    let taskService: TaskService
    let onClaim: () -> Void

    @State private var selectedLevel: TaskLevel
    @State private var showSuccessAlert = false
    @State private var isViewReady = false

    init(template: TaskTemplate, childId: UUID, taskService: TaskService, onClaim: @escaping () -> Void) {
        self.template = template
        self.childId = childId
        self.taskService = taskService
        self.onClaim = onClaim
        _selectedLevel = State(initialValue: template.suggestedLevel)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                if isViewReady {
                    VStack(spacing: 24) {
                    // Task Header
                    VStack(spacing: 12) {
                        Text(template.category.icon)
                            .font(.system(size: 60))

                        Text(template.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text(template.category.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Text(template.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding()

                    Divider()

                    // Task Info
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Task Details", systemImage: "info.circle.fill")
                            .font(.headline)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Estimated Time")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text("~\(template.estimatedMinutes) min")
                                    .font(.body)
                                    .fontWeight(.medium)
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Suggested Level")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(template.suggestedLevel.displayName)
                                    .font(.body)
                                    .fontWeight(.medium)
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                    .padding(.horizontal)

                    Divider()

                    // Level Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Choose Your Level", systemImage: "star.fill")
                            .font(.headline)

                        Text("Select the difficulty level for this task. This determines the screen time you'll earn.")
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Picker("Level", selection: $selectedLevel) {
                            ForEach(TaskLevel.allCases) { level in
                                Text(level.displayName).tag(level)
                            }
                        }
                        .pickerStyle(.segmented)

                        // XP Preview
                        HStack {
                            Text("You'll earn:")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(selectedLevel.baseXP) minutes")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.green)
                        }
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
                .padding(.vertical)
                } else {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading task details...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                }
            }
            .navigationTitle("Claim Task")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    isViewReady = true
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add to My Tasks") {
                        claimTask()
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Task Added!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    // Dismiss the claim sheet first
                    dismiss()
                    // Then call onClaim to dismiss the parent view
                    // Small delay to ensure smooth animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onClaim()
                    }
                }
            } message: {
                Text("\(template.title) has been added to your tasks!")
            }
        }
    }

    private func claimTask() {
        let assignment = taskService.claimTask(template: template, childId: childId, level: selectedLevel)
        print("✅ Child claimed task: \(assignment.title) at level \(selectedLevel.displayName)")
        showSuccessAlert = true
    }
}

// MARK: - Create Custom Task Sheet

struct CreateCustomTaskSheet: View {
    @Environment(\.dismiss) var dismiss
    let childId: UUID
    let taskService: TaskService
    let onCreate: () -> Void

    @State private var taskTitle = ""
    @State private var taskDescription = ""
    @State private var selectedCategory: TaskTemplateCategory = .other
    @State private var selectedLevel: TaskLevel = .level2
    @State private var estimatedMinutes: Int = 30
    @State private var showSuccessAlert = false
    @State private var showValidationError = false

    var isValid: Bool {
        !taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !taskDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Task Details") {
                    TextField("Task title", text: $taskTitle)
                    TextField("Description", text: $taskDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Category") {
                    Picker("Category", selection: $selectedCategory) {
                        ForEach(TaskTemplateCategory.allCases) { category in
                            HStack {
                                Text(category.icon)
                                Text(category.rawValue)
                            }
                            .tag(category)
                        }
                    }
                }

                Section("Level & Time") {
                    Picker("Task Level", selection: $selectedLevel) {
                        ForEach(TaskLevel.allCases) { level in
                            Text(level.displayName).tag(level)
                        }
                    }
                    .pickerStyle(.segmented)

                    HStack {
                        Text("You'll earn:")
                        Spacer()
                        Text("\(selectedLevel.baseXP) minutes")
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                    }

                    Stepper("Estimated time: \(estimatedMinutes) min", value: $estimatedMinutes, in: 5...180, step: 5)
                        .font(.subheadline)
                }

                Section {
                    Text("Your custom task will be submitted for parent approval once you complete it with photo proof.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Create Custom Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create Task") {
                        if isValid {
                            createCustomTask()
                        } else {
                            showValidationError = true
                        }
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Task Created!", isPresented: $showSuccessAlert) {
                Button("OK") {
                    // Dismiss the create sheet first
                    dismiss()
                    // Then call onCreate to dismiss the parent view
                    // Small delay to ensure smooth animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        onCreate()
                    }
                }
            } message: {
                Text("\(taskTitle) has been added to your tasks!")
            }
            .alert("Missing Information", isPresented: $showValidationError) {
                Button("OK") {}
            } message: {
                Text("Please provide a title and description for your task.")
            }
        }
    }

    private func createCustomTask() {
        // Create a custom template
        let customTemplate = TaskTemplate(
            title: taskTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            description: taskDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            suggestedLevel: selectedLevel,
            estimatedMinutes: estimatedMinutes,
            tags: ["custom", "child-created"],
            isDefault: false,
            createdBy: childId  // Track which child created it
        )

        // Save the template to the library for future use
        taskService.saveTemplate(customTemplate)

        // Claim the custom template as an assignment
        let assignment = taskService.claimTask(template: customTemplate, childId: childId, level: selectedLevel)
        print("✅ Child created custom task: \(assignment.title) at level \(selectedLevel.displayName)")
        print("💾 Template saved to task library for future use")
        showSuccessAlert = true
    }
}
