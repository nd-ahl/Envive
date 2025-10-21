import SwiftUI
import PhotosUI

// MARK: - Add Child Profile Sheet

/// Modal sheet for creating or editing a child profile
struct AddChildProfileSheet: View {
    let profile: ChildProfileData?
    let onSave: (ChildProfileData) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var age: Int
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var avatarImage: UIImage?
    @State private var showingImagePicker = false
    @Environment(\.dismiss) private var dismiss

    init(profile: ChildProfileData? = nil, onSave: @escaping (ChildProfileData) -> Void, onCancel: @escaping () -> Void) {
        self.profile = profile
        self.onSave = onSave
        self.onCancel = onCancel

        // Initialize state from profile if editing
        _name = State(initialValue: profile?.name ?? "")
        _age = State(initialValue: profile?.age ?? 10)
        _avatarImage = State(initialValue: profile?.avatarImage)
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color.purple.opacity(0.6),
                        Color.blue.opacity(0.7)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Avatar section
                        avatarSection

                        // Form fields
                        VStack(spacing: 20) {
                            nameField
                            ageField
                        }
                        .padding(.horizontal, 32)

                        // Save button
                        saveButton
                            .padding(.horizontal, 32)
                            .padding(.bottom, 32)
                    }
                    .padding(.top, 40)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(profile == nil ? "Add Child Profile" : "Edit Profile")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                }

                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .onChange(of: selectedPhotoItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    avatarImage = uiImage
                }
            }
        }
    }

    // MARK: - Avatar Section

    private var avatarSection: some View {
        VStack(spacing: 16) {
            ZStack {
                // Avatar circle
                if let avatarImage {
                    Image(uiImage: avatarImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 120, height: 120)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 120, height: 120)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.6))
                        )
                }

                // Camera button overlay
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 36, height: 36)
                                .overlay(
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(Color.purple.opacity(0.8))
                                )
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                    }
                }
                .frame(width: 120, height: 120)
            }

            Text("Add Profile Picture")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
    }

    // MARK: - Name Field

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            TextField("", text: $name)
                .placeholder(when: name.isEmpty) {
                    Text("Enter child's name")
                        .foregroundColor(.gray.opacity(0.6))
                }
                .textContentType(.name)
                .autocapitalization(.words)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .cornerRadius(12)
                .foregroundColor(.black)
        }
    }

    // MARK: - Age Field

    private var ageField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Age")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            AgePickerWheel(selectedAge: $age, ageRange: 5...17, showLabel: false)
        }
    }

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: handleSave) {
            HStack(spacing: 10) {
                Text("Save Profile")
                    .font(.system(size: 17, weight: .semibold))
                Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(canSave ? Color.purple.opacity(0.8) : Color.gray)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.white)
            .cornerRadius(12)
            .opacity(canSave ? 1.0 : 0.5)
        }
        .disabled(!canSave)
    }

    // MARK: - Computed Properties

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Actions

    private func handleSave() {
        guard canSave else { return }

        let profileData = ChildProfileData(
            id: profile?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            age: age,
            avatarImage: avatarImage
        )

        onSave(profileData)

        // Auto-close the sheet
        dismiss()
    }
}

// MARK: - Preview

struct AddChildProfileSheet_Previews: PreviewProvider {
    static var previews: some View {
        AddChildProfileSheet(
            profile: nil,
            onSave: { _ in },
            onCancel: {}
        )
    }
}
