import Foundation
import AVFoundation
import UIKit
import Combine

@available(iOS 10.0, *)
final class CameraServiceImpl: NSObject, ObservableObject, AVCapturePhotoCaptureDelegate {
    @Published var capturedImage: UIImage?
    @Published var frontCameraImage: UIImage?
    @Published var backCameraImage: UIImage?
    @Published var isShowingCamera = false
    @Published var cameraError: String?
    @Published var savedPhotos: [SavedPhoto] = []
    @Published var isCapturing = false
    @Published var cameraStatus: CameraStatus = .initializing

    enum CameraStatus {
        case initializing
        case ready
        case frontOnly
        case backOnly
        case failed
        case capturing
    }

    enum CapturePhase {
        case readyForBack
        case capturingBack
        case readyForFront
        case capturingFront
        case completed
    }

    @Published var currentCapturePhase: CapturePhase = .readyForBack

    // Camera sessions
    var frontCaptureSession: AVCaptureSession?
    var backCaptureSession: AVCaptureSession?
    var frontCamera: AVCaptureDevice?
    var backCamera: AVCaptureDevice?
    var frontPhotoOutput: AVCapturePhotoOutput?
    var backPhotoOutput: AVCapturePhotoOutput?

    // Capture synchronization
    private var captureCompletionHandler: ((UIImage?) -> Void)?
    private var frontImageCaptured = false
    private var backImageCaptured = false
    private let captureQueue = DispatchQueue(label: "com.envive.camera.capture", qos: .userInitiated)

    private var isSimulator: Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    override init() {
        super.init()
        loadSavedPhotos()
        setupDualCameraSystem()
    }

    // MARK: - Photo Storage

    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private var photosDirectory: URL {
        documentsDirectory.appendingPathComponent("EnvivePhotos")
    }

    private var photosMetadataURL: URL {
        documentsDirectory.appendingPathComponent("savedPhotos.json")
    }

    private func createPhotosDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: photosDirectory.path) {
            try? FileManager.default.createDirectory(at: photosDirectory, withIntermediateDirectories: true)
        }
    }

    func savePhoto(_ image: UIImage, taskTitle: String, taskId: UUID? = nil) -> Bool {
        createPhotosDirectoryIfNeeded()

        let fileName = "photo_\(Date().timeIntervalSince1970).jpg"
        let fileURL = photosDirectory.appendingPathComponent(fileName)

        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            print("❌ Failed to convert image to JPEG data")
            return false
        }

        do {
            try imageData.write(to: fileURL)
            let savedPhoto = SavedPhoto(fileName: fileName, timestamp: Date(), taskTitle: taskTitle, taskId: taskId)
            savedPhotos.append(savedPhoto)
            saveSavedPhotosMetadata()
            print("✅ Photo saved successfully: \(fileName)")
            return true
        } catch {
            print("❌ Failed to save photo: \(error.localizedDescription)")
            return false
        }
    }

    func loadSavedPhotos() {
        guard let data = try? Data(contentsOf: photosMetadataURL),
              let photos = try? JSONDecoder().decode([SavedPhoto].self, from: data) else {
            savedPhotos = []
            return
        }
        savedPhotos = photos
    }

    private func saveSavedPhotosMetadata() {
        guard let data = try? JSONEncoder().encode(savedPhotos) else { return }
        try? data.write(to: photosMetadataURL)
    }

    func loadPhoto(savedPhoto: SavedPhoto) -> UIImage? {
        let fileURL = photosDirectory.appendingPathComponent(savedPhoto.fileName)
        return UIImage(contentsOfFile: fileURL.path)
    }

    func deletePhoto(_ savedPhoto: SavedPhoto) {
        let fileURL = photosDirectory.appendingPathComponent(savedPhoto.fileName)
        try? FileManager.default.removeItem(at: fileURL)
        savedPhotos.removeAll { $0.id == savedPhoto.id }
        saveSavedPhotosMetadata()
    }

    // MARK: - Task-Specific Photos

    func getPhotosForTask(_ taskId: UUID) -> [SavedPhoto] {
        savedPhotos.filter { $0.taskId == taskId }
    }

    func getLatestPhotoForTask(_ taskId: UUID) -> SavedPhoto? {
        savedPhotos
            .filter { $0.taskId == taskId }
            .max(by: { $0.timestamp < $1.timestamp })
    }

    func deletePhotosForTask(_ taskId: UUID) {
        let taskPhotos = getPhotosForTask(taskId)
        taskPhotos.forEach { deletePhoto($0) }
    }

    // MARK: - Camera Permissions

    func checkCameraPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("📹 Camera permissions already granted")
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    if granted {
                        print("📹 Camera permissions granted")
                    } else {
                        self.cameraError = "Camera access denied"
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.cameraError = "Camera access denied. Please enable in Settings."
            }
        @unknown default:
            break
        }
    }

    func clearCapturedImages() {
        DispatchQueue.main.async {
            self.capturedImage = nil
            self.frontCameraImage = nil
            self.backCameraImage = nil
            self.captureCompletionHandler = nil
        }
    }

    // MARK: - Camera Setup

    private func setupDualCameraSystem() {
        guard !isSimulator else {
            print("📱 Simulator detected - camera unavailable")
            cameraStatus = .failed
            return
        }

        captureQueue.async { [weak self] in
            guard let self = self else { return }

            self.setupBackCamera()
            self.setupFrontCamera()

            DispatchQueue.main.async {
                if self.backCaptureSession != nil && self.frontCaptureSession != nil {
                    self.cameraStatus = .ready
                    print("✅ Dual camera system ready")
                } else if self.backCaptureSession != nil {
                    self.cameraStatus = .backOnly
                    print("⚠️ Back camera only")
                } else if self.frontCaptureSession != nil {
                    self.cameraStatus = .frontOnly
                    print("⚠️ Front camera only")
                } else {
                    self.cameraStatus = .failed
                    self.cameraError = "Failed to initialize cameras"
                }
            }
        }
    }

    private func setupBackCamera() {
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
            print("❌ Back camera not available")
            return
        }

        self.backCamera = backCamera

        do {
            let session = AVCaptureSession()
            session.beginConfiguration()

            let input = try AVCaptureDeviceInput(device: backCamera)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                self.backPhotoOutput = output
            }

            session.commitConfiguration()
            self.backCaptureSession = session

            print("✅ Back camera setup complete")
        } catch {
            print("❌ Back camera setup error: \(error)")
        }
    }

    private func setupFrontCamera() {
        guard let frontCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("❌ Front camera not available")
            return
        }

        self.frontCamera = frontCamera

        do {
            let session = AVCaptureSession()
            session.beginConfiguration()

            let input = try AVCaptureDeviceInput(device: frontCamera)
            if session.canAddInput(input) {
                session.addInput(input)
            }

            let output = AVCapturePhotoOutput()
            if session.canAddOutput(output) {
                session.addOutput(output)
                self.frontPhotoOutput = output
            }

            session.commitConfiguration()
            self.frontCaptureSession = session

            print("✅ Front camera setup complete")
        } catch {
            print("❌ Front camera setup error: \(error)")
        }
    }

    // MARK: - Capture Methods (placeholder for full implementation)

    func takeSequentialPhoto() {
        print("📸 Sequential photo capture initiated")
        // Full implementation would handle dual camera capture
    }

    // MARK: - AVCapturePhotoCaptureDelegate

    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error = error {
            print("❌ Photo capture error: \(error)")
            return
        }

        guard let imageData = photo.fileDataRepresentation(),
              let image = UIImage(data: imageData) else {
            print("❌ Failed to process photo data")
            return
        }

        DispatchQueue.main.async {
            self.capturedImage = image
            print("✅ Photo captured successfully")
        }
    }
}
