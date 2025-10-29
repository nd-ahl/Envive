//
//  QuickFamilySetupView.swift
//  EnviveNew
//
//  Quick and simple family member addition
//

import SwiftUI

struct QuickFamilySetupView: View {
    let onComplete: () -> Void
    let onBack: (() -> Void)?

    @StateObject private var authService = AuthenticationService.shared
    @StateObject private var householdService = HouseholdService.shared
    @State private var children: [ChildProfile] = []
    @State private var showingAddChild = false
    @State private var newChildName = ""
    @State private var newChildAge = 8
    @State private var isLoading = false
    @State private var errorMessage: String?

    struct ChildProfile: Identifiable {
        let id = UUID()
        var name: String
        var age: Int
    }

    var body: some View {
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

            VStack(spacing: 28) {
                // Back button
                if let onBack = onBack {
                    HStack {
                        Button(action: onBack) {
                            HStack(spacing: 6) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Back")
                                    .font(.system(size: 17, weight: .medium))
                            }
                            .foregroundColor(.white)
                        }
                        .padding(.leading, 20)
                        .padding(.top, 20)
                        Spacer()
                    }
                } else {
                    Spacer()
                        .frame(height: 40)
                }

                // Header
                headerSection

                // Children list
                if !children.isEmpty {
                    childrenList
                }

                // Error message
                if let error = errorMessage {
                    Text(error)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.white.opacity(0.9))
                        .cornerRadius(10)
                }

                // Add child button
                addChildButton

                Spacer()

                // Continue button
                continueButton
                    .padding(.bottom, 50)
            }
            .padding(.horizontal, 24)
        }
        .sheet(isPresented: $showingAddChild) {
            addChildSheet
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 60))
                .foregroundColor(.white)

            Text("Add Your Kids")
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(.white)

            Text("You can add more later from settings")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
                .multilineTextAlignment(.center)
        }
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
                        children.removeAll { $0.id == child.id }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding(16)
                .background(Color.white.opacity(0.2))
                .cornerRadius(12)
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
                Text(children.isEmpty ? "Add Your First Child" : "Add Another Child")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white.opacity(0.25))
            .cornerRadius(12)
        }
    }

    // MARK: - Continue Button

    private var continueButton: some View {
        Button(action: handleComplete) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                } else {
                    Text(children.isEmpty ? "Skip for Now" : "Continue")
                        .font(.system(size: 18, weight: .bold))
                }
            }
            .foregroundColor(Color.blue.opacity(0.9))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.15), radius: 10, x: 0, y: 4)
        }
        .disabled(isLoading)
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
                            children.append(ChildProfile(name: newChildName, age: newChildAge))
                            showingAddChild = false
                        }
                    }
                    .disabled(newChildName.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    // MARK: - Actions

    private func handleComplete() {
        isLoading = true

        Task {
            do {
                // Get current user's profile
                guard let currentProfile = authService.currentProfile else {
                    throw NSError(domain: "QuickFamilySetup", code: -1, userInfo: [
                        NSLocalizedDescriptionKey: "No authenticated user found"
                    ])
                }

                // Check if household exists, create it if not
                var householdId: String

                if let existingHouseholdId = currentProfile.householdId {
                    // User already has a household (existing user scenario)
                    householdId = existingHouseholdId
                    print("✅ Using existing household: \(householdId)")
                } else {
                    // New user - create household now
                    print("🏠 Creating new household for parent...")

                    // Get family name from UserDefaults (saved during signup)
                    let familyName = UserDefaults.standard.string(forKey: "familyName") ?? "Family"
                    let householdName = makeGrammaticalFamilyName(from: familyName)

                    let household = try await householdService.createHousehold(
                        name: householdName,
                        createdBy: currentProfile.id
                    )
                    householdId = household.id
                    print("✅ Household created: \(household.name) (ID: \(household.id))")

                    // Refresh profile to get updated household_id
                    try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
                    try await authService.refreshCurrentProfile()
                    print("✅ Profile refreshed with household_id")
                }

                print("🏠 Creating \(children.count) child profile(s) in household: \(householdId)")

                // Create each child profile in the database
                for child in children {
                    do {
                        let childId = try await householdService.createChildProfile(
                            name: child.name,
                            age: child.age,
                            householdId: householdId,
                            createdBy: currentProfile.id,
                            avatarUrl: nil
                        )
                        print("✅ Created child profile: \(child.name) (ID: \(childId))")
                    } catch {
                        print("❌ Failed to create child profile for \(child.name): \(error.localizedDescription)")
                        throw error
                    }
                }

                await MainActor.run {
                    isLoading = false
                    onComplete()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = error.localizedDescription
                    print("❌ Error in family setup: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Generate a grammatically correct family name with possessive form
    private func makeGrammaticalFamilyName(from name: String) -> String {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty {
            return "Family"
        }

        // Check if name already ends with "Family" or similar
        let lowercased = trimmed.lowercased()
        if lowercased.hasSuffix("family") || lowercased.hasSuffix("household") {
            return trimmed
        }

        // Add possessive apostrophe
        if trimmed.hasSuffix("s") {
            return "\(trimmed)' Family"
        } else {
            return "\(trimmed)'s Family"
        }
    }
}
