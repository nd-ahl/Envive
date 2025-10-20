import UIKit
import SwiftUI
import Combine

// MARK: - Profile Photo Manager

/// Manages user profile photos - saving, loading, and caching
class ProfilePhotoManager: ObservableObject {
    static let shared = ProfilePhotoManager()

    @Published var profilePhotos: [UUID: UIImage] = [:]

    private init() {
        // Private init for singleton
    }

    // MARK: - Directories

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var profilePhotosDirectory: URL {
        documentsDirectory.appendingPathComponent("ProfilePhotos")
    }

    private func createProfilePhotosDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: profilePhotosDirectory.path) {
            try? FileManager.default.createDirectory(at: profilePhotosDirectory, withIntermediateDirectories: true)
        }
    }

    // MARK: - Save Profile Photo

    /// Save a profile photo for a user
    func saveProfilePhoto(_ image: UIImage, for userId: UUID) -> String? {
        createProfilePhotosDirectoryIfNeeded()

        let fileName = "profile_\(userId.uuidString).jpg"
        let fileURL = profilePhotosDirectory.appendingPathComponent(fileName)

        // Resize image to reasonable size (300x300)
        guard let resizedImage = resizeImage(image, to: CGSize(width: 300, height: 300)),
              let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to process profile photo for user: \(userId)")
            return nil
        }

        do {
            try imageData.write(to: fileURL)
            print("✅ Profile photo saved: \(fileName)")

            // Cache the image
            profilePhotos[userId] = resizedImage

            return fileName
        } catch {
            print("❌ Failed to save profile photo: \(error)")
            return nil
        }
    }

    // MARK: - Load Profile Photo

    /// Load a profile photo from file name
    func loadProfilePhoto(fileName: String) -> UIImage? {
        let fileURL = profilePhotosDirectory.appendingPathComponent(fileName)

        guard FileManager.default.fileExists(atPath: fileURL.path),
              let imageData = try? Data(contentsOf: fileURL),
              let image = UIImage(data: imageData) else {
            print("⚠️ Profile photo not found: \(fileName)")
            return nil
        }

        return image
    }

    /// Load a profile photo for a user ID (with caching)
    func loadProfilePhoto(for userId: UUID, fileName: String?) -> UIImage? {
        // Check cache first
        if let cachedImage = profilePhotos[userId] {
            return cachedImage
        }

        // Load from file
        guard let fileName = fileName,
              let image = loadProfilePhoto(fileName: fileName) else {
            return nil
        }

        // Cache it
        profilePhotos[userId] = image
        return image
    }

    // MARK: - Delete Profile Photo

    /// Delete a profile photo
    func deleteProfilePhoto(fileName: String) {
        let fileURL = profilePhotosDirectory.appendingPathComponent(fileName)

        do {
            try FileManager.default.removeItem(at: fileURL)
            print("✅ Profile photo deleted: \(fileName)")
        } catch {
            print("❌ Failed to delete profile photo: \(error)")
        }
    }

    // MARK: - Image Utilities

    /// Resize image to target size (maintains aspect ratio, crops to square)
    private func resizeImage(_ image: UIImage, to targetSize: CGSize) -> UIImage? {
        let size = image.size
        let aspectWidth = targetSize.width / size.width
        let aspectHeight = targetSize.height / size.height
        let aspectRatio = max(aspectWidth, aspectHeight)

        // Calculate new size
        let newSize = CGSize(
            width: size.width * aspectRatio,
            height: size.height * aspectRatio
        )

        // Create context and draw
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)

        return renderer.image { context in
            // Calculate rect to center crop
            let xOffset = (newSize.width - targetSize.width) / 2
            let yOffset = (newSize.height - targetSize.height) / 2
            let rect = CGRect(
                x: -xOffset,
                y: -yOffset,
                width: newSize.width,
                height: newSize.height
            )

            image.draw(in: rect)
        }
    }

    /// Create initials placeholder image
    func createInitialsImage(for name: String, size: CGSize = CGSize(width: 300, height: 300)) -> UIImage? {
        // Get initials (first letter of first and last name)
        let components = name.split(separator: " ")
        let initials: String
        if components.count >= 2 {
            initials = "\(components[0].prefix(1))\(components[1].prefix(1))".uppercased()
        } else {
            initials = String(name.prefix(2)).uppercased()
        }

        // Create image with gradient background
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: size, format: format)

        return renderer.image { context in
            // Draw gradient background
            let colors = [
                UIColor(red: 0.4, green: 0.5, blue: 0.9, alpha: 1.0).cgColor,
                UIColor(red: 0.6, green: 0.3, blue: 0.8, alpha: 1.0).cgColor
            ]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: [0.0, 1.0])!

            context.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: 0),
                end: CGPoint(x: size.width, y: size.height),
                options: []
            )

            // Draw initials text
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let fontSize = size.width * 0.4
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .semibold),
                .foregroundColor: UIColor.white,
                .paragraphStyle: paragraphStyle
            ]

            let text = initials as NSString
            let textSize = text.size(withAttributes: attributes)
            let textRect = CGRect(
                x: (size.width - textSize.width) / 2,
                y: (size.height - textSize.height) / 2,
                width: textSize.width,
                height: textSize.height
            )

            text.draw(in: textRect, withAttributes: attributes)
        }
    }
}

// MARK: - Profile Photo Picker View

struct ProfilePhotoPicker: View {
    let userId: UUID
    let currentPhotoFileName: String?
    let onPhotoSelected: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Current photo or placeholder
                if let photoFileName = currentPhotoFileName,
                   let image = ProfilePhotoManager.shared.loadProfilePhoto(fileName: photoFileName) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.blue, lineWidth: 4)
                        )
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 200)
                        .overlay(
                            Image(systemName: "person.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.gray)
                        )
                }

                Text("Update Profile Photo")
                    .font(.title2)
                    .fontWeight(.semibold)

                VStack(spacing: 16) {
                    // Choose from library
                    Button(action: {
                        showingImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                                .font(.title3)
                            Text("Choose from Library")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    // Take photo
                    Button(action: {
                        showingCamera = true
                    }) {
                        HStack {
                            Image(systemName: "camera.fill")
                                .font(.title3)
                            Text("Take Photo")
                                .fontWeight(.medium)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    // Remove photo (if exists)
                    if currentPhotoFileName != nil {
                        Button(action: {
                            // Remove photo
                            if let fileName = currentPhotoFileName {
                                ProfilePhotoManager.shared.deleteProfilePhoto(fileName: fileName)
                            }
                            onPhotoSelected("")
                            HapticFeedbackManager.shared.light()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "trash.fill")
                                    .font(.title3)
                                Text("Remove Photo")
                                    .fontWeight(.medium)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 40)
            .navigationTitle("Profile Photo")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage, sourceType: .photoLibrary)
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(image: $selectedImage, sourceType: .camera)
            }
            .onChange(of: selectedImage) { oldImage, newImage in
                print("📸 ProfilePhotoPicker: onChange triggered - old: \(oldImage != nil), new: \(newImage != nil)")
                if let image = newImage {
                    print("📸 ProfilePhotoPicker: New image detected, saving...")
                    savePhoto(image)
                } else {
                    print("⚠️ ProfilePhotoPicker: onChange called but no new image")
                }
            }
        }
    }

    private func savePhoto(_ image: UIImage) {
        print("📸 ProfilePhotoPicker: Saving photo for user \(userId)")
        if let fileName = ProfilePhotoManager.shared.saveProfilePhoto(image, for: userId) {
            print("✅ ProfilePhotoPicker: Photo saved successfully: \(fileName)")
            HapticFeedbackManager.shared.success()
            onPhotoSelected(fileName)

            // Dismiss with a small delay to ensure the callback completes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                dismiss()
            }
        } else {
            print("❌ ProfilePhotoPicker: Failed to save photo")
            HapticFeedbackManager.shared.error()
        }
    }
}

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let sourceType: UIImagePickerController.SourceType

    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = sourceType
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            print("📷 ImagePicker: Image selected")

            // First try to get the edited image (after cropping), then fall back to original
            if let editedImage = info[.editedImage] as? UIImage {
                print("📷 ImagePicker: Using edited image - \(editedImage.size)")
                parent.image = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                print("📷 ImagePicker: Using original image - \(originalImage.size)")
                parent.image = originalImage
            } else {
                print("❌ ImagePicker: No image found in info")
            }

            // Dismiss the picker first, then the image will be processed by onChange
            print("📷 ImagePicker: Dismissing picker")
            picker.dismiss(animated: true) {
                // After picker is dismissed, update the parent
                DispatchQueue.main.async {
                    print("📷 ImagePicker: Calling parent dismiss")
                    self.parent.dismiss()
                }
            }
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true) {
                DispatchQueue.main.async {
                    self.parent.dismiss()
                }
            }
        }
    }
}
