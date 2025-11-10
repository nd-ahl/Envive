//
//  AddChildOnboardingView.swift
//  EnviveNew
//
//  Enhanced child addition with explanations and examples
//

import SwiftUI

struct AddChildOnboardingView: View {
    let onComplete: ([ChildProfileData]) -> Void
    let onSkip: () -> Void

    @State private var children: [ChildProfileData] = []
    @State private var showingAddChild = false
    @State private var newChildName = ""
    @State private var newChildAge = 8
    @State private var showContent = false

    struct ChildProfileData: Identifiable {
        let id = UUID()
        var name: String
        var age: Int
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.blue.opacity(0.7),
                        Color.purple.opacity(0.5)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        Spacer()
                            .frame(height: max(40, geometry.safeAreaInsets.top + 20))

                        // Header
                        headerSection

                        // Explanation section
                        explanationSection
                            .padding(.horizontal, 24)

                        // Children list
                        if !children.isEmpty {
                            childrenList
                                .padding(.horizontal, 24)
                        }

                        // Add child button
                        addChildButton
                            .padding(.horizontal, 24)

                        Spacer()

                        // Action buttons
                        actionButtons
                            .padding(.horizontal, 24)
                            .padding(.bottom, max(30, geometry.safeAreaInsets.bottom + 20))
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddChild) {
            addChildSheet
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1)) {
                showContent = true
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.25))
                    .frame(width: 90, height: 90)

                Image(systemName: "person.3.fill")
                    .font(.system(size: 44))
                    .foregroundColor(.white)
            }
            .scaleEffect(showContent ? 1.0 : 0.3)
            .opacity(showContent ? 1.0 : 0)

            Text("Let's Add Your Kids")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            Text("This is where the magic begins!")
                .font(.system(size: 17, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
        .scaleEffect(showContent ? 1.0 : 0.85)
        .opacity(showContent ? 1.0 : 0)
    }

    // MARK: - Explanation Section

    private var explanationSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            sectionCard(
                title: "What you'll add:",
                items: [
                    "Child's name (they'll see this on their device)",
                    "Age (helps us customize their experience)",
                    "Optional avatar (make it fun!)"
                ]
            )

            sectionCard(
                title: "Why this matters:",
                description: "When your child completes a task, you'll see it under their profile. Each child has their own XP balance, credibility score, and screen time."
            )

            exampleCard()
        }
    }

    private func sectionCard(title: String, items: [String]? = nil, description: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            if let items = items {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.green.opacity(0.9))

                            Text(item)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            if let description = description {
                Text(description)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineSpacing(3)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.18))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    private func exampleCard() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.yellow)

                Text("Real-life example:")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Text("\"I added my daughter Emma, age 10. Now when she finishes her homework, I approve it under her profile and she earns XP for screen time on her tablet.\"")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .italic()
                .lineSpacing(3)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    // MARK: - Children List

    private var childrenList: some View {
        VStack(spacing: 12) {
            ForEach(children) { child in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(child.name)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)

                        Text("Age \(child.age)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    Spacer()

                    Button(action: {
                        withAnimation {
                            children.removeAll { $0.id == child.id }
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.25))
                )
            }
        }
    }

    // MARK: - Add Child Button

    private var addChildButton: some View {
        Button(action: {
            newChildName = ""
            newChildAge = 8
            showingAddChild = true
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                Text(children.isEmpty ? "Add a Child" : "Add Another Child")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.25))
            )
        }
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        VStack(spacing: 14) {
            // Continue/Complete button
            Button(action: {
                onComplete(children)
            }) {
                Text(children.isEmpty ? "I'll Add Them Later" : "Continue to Next Step")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.blue.opacity(0.9))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(Color.white)
                    .cornerRadius(14)
                    .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
            }
        }
    }

    // MARK: - Add Child Sheet

    private var addChildSheet: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    // Name input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Child's Name")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)

                        TextField("Enter name", text: $newChildName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.system(size: 17))
                            .autocapitalization(.words)
                    }

                    // Age picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Age")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.secondary)

                        Picker("Age", selection: $newChildAge) {
                            ForEach(3...17, id: \.self) { age in
                                Text("\(age) years old").tag(age)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 120)
                    }

                    Spacer()
                }
                .padding(24)
            }
            .navigationTitle("Add Child")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        showingAddChild = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        if !newChildName.isEmpty {
                            withAnimation {
                                children.append(ChildProfileData(name: newChildName, age: newChildAge))
                            }
                            showingAddChild = false
                        }
                    }
                    .disabled(newChildName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - Preview

struct AddChildOnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        AddChildOnboardingView(
            onComplete: { _ in },
            onSkip: {}
        )
    }
}
